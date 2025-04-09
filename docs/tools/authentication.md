# Authenticating with Tools

## Core Concepts

Many tools, especially those interacting with external APIs (like Google Workspace, Salesforce, etc.), require authentication. ADK provides mechanisms to handle this securely. The key components are:

1.  **`AuthScheme`**: Defines *what kind* of authentication the target API needs (e.g., OAuth 2.0 Bearer token, API Key). This usually corresponds to OpenAPI `securitySchemes`.
2.  **`AuthCredential`**: Holds the *initial* information to start the authentication process (e.g., OAuth Client ID/Secret, API Key value, Service Account details).

## Configuring Authentication on Tools

You set up authentication when defining your tool:

*   **`RestApiTool` / `OpenAPIToolset`**: Pass `auth_scheme` and `auth_credential` during initialization or use `.configure_auth_scheme()` or `.configure_auth_credential()`.
*   **`GoogleApiToolSet` Tools**: ADK has [built-in 1st party tools](../tools/built-in-tools.md) like Google Calendar, BigQuery etc,. Use the toolset's specific method.
   ```py
   tool.configure_auth(client_id=..., client_secret=...)
   ```
*   **Custom `FunctionTool`**: Handle authentication logic *inside* your function using the `ToolContext`.

## Supported Initial Credential Types
   * API_KEY: For simple key/value authentication. Usually requires no exchange.
   * HTTP: Can represent Basic Auth (not recommended/supported for exchange) or already obtained Bearer tokens. If it's a Bearer token, no exchange is needed.
   * OAUTH2: For standard OAuth 2.0 flows. Requires configuration (client ID, secret, scopes) and often triggers the interactive flow for user consent.
   * OPEN_ID_CONNECT: For authentication based on OpenID Connect. Similar to OAuth2, often requires configuration and user interaction.
   * SERVICE_ACCOUNT: For Google Cloud Service Account credentials (JSON key or Application Default Credentials). Typically exchanged for a Bearer token.

## The Authentication Flow (General)

1.  **Initial Credential Provided:** You configure the tool with the starting credential.
2.  **Exchange (if needed):** ADK automatically tries to exchange the initial credential for one usable in an API request (e.g., Service Account key -> Bearer token). This uses internal `CredentialExchanger`. API Keys or existing Bearer tokens usually skip this.
3.  **Interactive Flow (if needed):** If user interaction (login/consent) is required (common for OAuth 2.0/OIDC), the specific interactive flow (detailed below) is triggered.
4.  **API Call:** The final credential (e.g., Bearer token) is injected into the API request by tools like `RestApiTool`. Custom `FunctionTool`s must manually use the obtained credential from the `ToolContext`.

!!! tip "WARNING" 
    Storing sensitive credentials like access tokens and especially refresh tokens directly in the session state might pose security risks depending on your session storage backend (`SessionService`) and overall application security posture.

    *   **`InMemorySessionService`:** Suitable for testing and development, but data is lost when the process ends. Less risk as it's transient.
    *   **Database/Persistent Storage:** **Strongly consider encrypting** the token data before storing it in the database using a robust encryption library (like `cryptography`) and managing encryption keys securely (e.g., using a key management service).
    *   **Secure Secret Stores:** For production environments, storing sensitive credentials in a dedicated secret manager (like Google Cloud Secret Manager or HashiCorp Vault) is the **most recommended approach**. Your tool could potentially store only short-lived access tokens or secure references (not the refresh token itself) in the session state, fetching the necessary secrets from the secure store when needed.

    Always prioritize secure handling of credentials according to your application's security requirements and compliance standards. Avoid storing raw refresh tokens in plain text in persistent storage accessible by the application server.

## Interactive Flow Step-by-Step (OAuth 2.0 / OpenID Connect)

This flow requires coordination between your Tool code, the ADK Framework, and your Agent Client application (e.g., UI, Spark job).

![Authentication](../assets/auth_part1.svg)

**Step 1: (Tool Function) Check for Cached Credentials**

Inside your tool function, first check if valid credentials (e.g., access/refresh tokens) are already stored from a previous run in this session. Use `tool_context.state` for this.

**Step 2: (Tool Function) Check for Auth Response from Client**

If no valid cached credentials exist, check if the user just completed the external OAuth flow and the client sent the results back in this turn. Use `tool_context.get_auth_response()`.

**Step 3: (Tool Function) Initiate Authentication Request**

If no valid credentials (Step 1) and no auth response (Step 2) are found, the tool needs to start the OAuth flow. Define the `AuthScheme` and initial `AuthCredential` and call `tool_context.request_credential()`. Return a status indicating authorization is needed.

**Step 4: (ADK Framework) Generate Auth Event**

ADK intercepts the `request_credential` action. It uses the provided scheme and credential to generate the appropriate authorization URL (and potentially state parameter). It then stops the tool and yields a special long-running function call event.

**Step 5: (Agent Client) Handle Auth Request & Redirect User**

Your application (UI, Spark job, etc.) receives the `af_request_euc` event.

* Parse the event and extract the auth_uri from `args['auth_config']`.

* Extract the id (af-generated-uuid in the example above) - you'll need this later.

* Redirect the user to the `auth_uri` (e.g., open a new browser tab).

**Step 6: (User & OAuth Provider) User Authorizes**

* The user interacts with the OAuth provider (e.g., logs into Google, grants permissions).

* The OAuth provider redirects the user back to the **REDIRECT_URI** you configured in your OAuth Client ID settings (and potentially provided in the initial auth request). This redirect URL will include an authorization_code (or an error) in the query parameters.

![Authentication](../assets/auth_part2.svg)

**Step 7: (Agent Client) Capture Callback & Send Response**

* Your Agent Client application must be listening on the **REDIRECT_URI**.

* Capture the full callback URL (including the code, state, scope, etc.).

* Construct a types.FunctionResponse part:

      * name: Must be "af_request_euc".

      * id: Must match the id received in Step 4 (af-generated-uuid in the example).

      * response: A dictionary containing the full callback URL, e.g., ```{'response': 'https://your-redirect-uri/callback?code=XYZ&state=ABC...'}```.

* Call `runner.run_async()` again, passing only this FunctionResponse within a `types.Content` object as the new_message.

**Step 8 & 9: (ADK & Tool Function) Receive Response & Retry Tool**

* ADK receives the FunctionResponse, processes it, and makes the response data (the callback URL) available via `tool_context.get_auth_response()`.

* The framework automatically re-invokes your original tool function (e.g., list_upcoming_events).

* This time, inside your tool function, the check in Step 2 [`tool_context.get_auth_response()`] will succeed and return the dictionary ```{'response': 'https://your-redirect-uri/callback?code=XYZ...'}```.

**Step 10: (Tool Function) Exchange Code for Tokens**

Your tool function now extracts the `authorization_code` from the callback URL received in `get_auth_response()`. It uses this code (along with client ID/secret) to make a request to the OAuth provider's token endpoint to get the access token and refresh token. Use appropriate libraries like **google-auth-oauthlib**.

**Step 11: (Tool Function) Cache Credentials**

Store the newly obtained Credentials object (containing access and refresh tokens) in `tool_context.state` for future use within the session. Remember the security warning about storing tokens.

**Step 12: (Tool Function) Make Authenticated API Call**

Use the now valid Credentials object (creds) to make the authenticated call to the target API (e.g., Google Calendar API).

**Step 13: (Tool Function) Return Result**

Return the actual result from the API call as a dictionary, including a success status.
