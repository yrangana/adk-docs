# Deploy to Cloud Run

You can use the container method in Cloud Run, or build from source.

## Building from source

Navigate to your agent's directory:

```sh
cd myagent
```

Create a file named `requirements.txt` with your project dependencies, the ADK
and the [Flask](https://flask.palletsprojects.com/) framework. Paste the
following code into it:

```
Flask
google-adk
```

Create a file named `agent.py`, which will contain your agent. For example, here
is an agent that finds the capital of a given country:

```python
from google.adk.agents import LlmAgent

# Agent Constants
AGENT_NAME = "CapitalFinderAgent"
MODEL_ID = "gemini-2.0-flash-001"

# Agent Definition
adk_agent = LlmAgent(
    model=MODEL_ID,
    name=AGENT_NAME,
    instruction="""You are an agent that finds the capital of a given country.
When asked for the capital, respond *only* with the name of the capital city.
""",
    output_key="capital_city",  # Save the agent's final response text to state['capital_city']
)
```

Next, create a file named `main.py`, which will wrap your agent in a Flask
application.

First, copy in the following initialization code that performs these tasks:

* **Initialization:** Sets up a Flask web application, configures logging, and
  imports necessary components from the Google ADK (`Runner`,
  `DatabaseSessionService`) and the local agent definition (`adk_agent` from
  `agent.py`).
* **Database Session Service:** Initializes `DatabaseSessionService` using a
  SQLite database (`sessions.db`) for managing user sessions and conversation
  history. It ensures the database directory exists and exits if initialization
  fails.
* **ADK Runner:** Creates an ADK `Runner` instance, linking the `adk_agent` with
  the `DatabaseSessionService`. The runner handles the core agent interaction
  logic.

```python
import logging
import os
import uuid
from typing import Tuple, Union

from flask import Flask, Request, Response, jsonify, make_response, request
from google.adk.runners import Runner
from google.adk.sessions import (
    BaseSessionService
    DatabaseSessionService,
)
from google.genai import types

# Import the agent definition and its name
from agent import AGENT_NAME, adk_agent

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# --- Constants ---
APP_NAME = AGENT_NAME
DEFAULT_USER_ID = "anonymous"  # Default User ID if header is missing
DB_FILE = "./sessions.db"  # Define the database file path

# --- Initialization ---
app = Flask(__name__)
logger.info(f"Initializing DatabaseSessionService with DB: {DB_FILE}...")
# Ensure the directory exists (useful if DB_FILE includes subdirectories)
DB_DIR = os.path.dirname(DB_FILE)
if DB_DIR and not os.path.exists(DB_DIR):
    os.makedirs(DB_DIR)
    logger.info(f"Created directory for database: {DB_DIR}")

# Instantiate DatabaseSessionService
# The service will handle DB/table creation if they don't exist.
try:
    session_service: BaseSessionService = DatabaseSessionService(
        db_url=f"sqlite:///{DB_FILE}"
    )
    logger.info("DatabaseSessionService initialized successfully.")
except Exception as db_init_err:
    logger.exception(
        f"FATAL: Failed to initialize DatabaseSessionService: {db_init_err}"
    )
    # Exit if the database cannot be initialized, as the app cannot function.
    exit(1)

# Runner Initialization
logger.info(
    f"Initializing Runner for agent: {AGENT_NAME} (App: {APP_NAME}) using database session service..."
)
runner = Runner(agent=adk_agent, app_name=APP_NAME, session_service=session_service)
```

Next, add the following section for session management. The
`get_or_create_session_context` function extracts `User-ID` and `Session-ID`
from request headers. If `Session-ID` is missing, it generates a new one and
explicitly creates the session in the `DatabaseSessionService`. It returns the
user ID, session ID, and a flag indicating if a new session was generated, or an
error response if session creation fails.

```python
# --- Helper Function for Session Context ---
def get_or_create_session_context(
    req: Request, service: BaseSessionService, app_name: str, default_user_id: str
) -> Union[
    Tuple[str, str, bool], Response
]:  # Return tuple on success, Response on error
    """
    Retrieves user/session IDs from headers or creates a new session if needed.

    Args:
        req: The Flask request object.
        service: The session service instance.
        app_name: The application name for session creation.
        default_user_id: The default user ID if the header is missing.

    Returns:
        A tuple containing (user_id, session_id, new_session_generated) on success.
        A Flask Response object if session creation fails.
    """
    user_id = req.headers.get("User-ID", default_user_id)
    session_id = req.headers.get("Session-ID")
    new_session_generated = False

    if not session_id:
        session_id = str(uuid.uuid4())
        new_session_generated = True
        logger.info(
            f"No Session-ID header found, generated new Session-ID: {session_id} for User: {user_id}"
        )
        # --- Explicitly create the session in the service ---
        try:
            logger.info(
                f"Attempting to create new session: {session_id} in app: {app_name}"
            )
            service.create_session(
                app_name=app_name, user_id=user_id, session_id=session_id
            )
            logger.info(f"Successfully created new session: {session_id}")
        except Exception as create_err:
            # Handle potential errors during session creation
            logger.exception(
                f"Failed to create session {session_id} for user {user_id}: {create_err}"
            )
            error_response = make_response(
                jsonify({"error": "Failed to initialize session"}), 500
            )
            error_response.headers["User-ID"] = user_id
            error_response.headers["Session-ID"] = (
                session_id  # Send back the ID we tried to create
            )
            return error_response  # Return error response directly

    # If session existed or was successfully created, return the context tuple
    return user_id, session_id, new_session_generated
```

We will now add API endpoints. The code below provides a basic health check
endpoint (`/` GET) and the main endpoint for agent interaction (`/query` POST).
The `/query` endpoint retrieves or creates session context, validates the
incoming JSON request (checking for a `query` field), prepares the user's input,
calls `runner.run()` with session details, processes events to find the final
response, and returns a JSON response containing the agent's answer (or an
error) along with `User-ID`, `Session-ID`, and `New-Session-Generated` headers.

```python
# --- Flask Routes ---
@app.route("/")
def home():
    """Basic health check / info endpoint."""
    return jsonify(
        {
            "message": f"Welcome to the {APP_NAME} API!",
            "agent_name": adk_agent.name,
        }
    )


@app.route("/query", methods=["POST"])
def query_agent():
    """Endpoint to interact with the agent, delegating session handling."""

    # --- Get Session Context ---
    session_context = get_or_create_session_context(
        request, session_service, APP_NAME, DEFAULT_USER_ID
    )

    # Check if the helper function returned an error response
    if isinstance(session_context, Response):
        return session_context  # Return the error response immediately

    # Unpack the tuple if session handling was successful
    user_id, session_id, new_session_generated = session_context
    logger.info(f"Processing request for User: {user_id}, Session: {session_id}")

    # --- Validate Request Body ---
    if not request.is_json:
        logger.warning(
            f"Received non-JSON request (User: {user_id}, Session: {session_id})"
        )
        return jsonify({"error": "Request must be JSON"}), 400

    data = request.get_json()
    query = data.get("query")

    if not query:
        logger.warning(
            f"Missing 'query' field (User: {user_id}, Session: {session_id})"
        )
        return jsonify({"error": "Missing 'query' in request body"}), 400

    logger.info(f"Received query: '{query}' (User: {user_id}, Session: {session_id})")

    try:
        # Prepare the message content for the agent
        content = types.Content(role="user", parts=[types.Part(text=query)])

        # Use the runner - session is guaranteed to exist at this point
        logger.info(f"Calling runner.run for session: {session_id}")
        events = runner.run(user_id=user_id, session_id=session_id, new_message=content)

        final_response_text = None
        for event in events:
            logger.debug(
                f"Agent Event: {type(event).__name__} - Final: {event.is_final_response()} (Session: {session_id})"
            )
            if event.is_final_response():
                if event.content and event.content.parts:
                    final_response_text = event.content.parts[0].text
                    logger.info(
                        f"Agent final response for session {session_id}: '{final_response_text}'"
                    )
                    break

        # --- Prepare and Return Response ---
        if final_response_text is not None:
            response_data = {"response": final_response_text}
            status_code = 200
        else:
            logger.error(
                f"Agent did not produce a final response (User: {user_id}, Session: {session_id})"
            )
            response_data = {"error": "Agent did not produce a final response"}
            status_code = 500

        response = make_response(jsonify(response_data), status_code)
        response.headers["User-ID"] = user_id
        response.headers["Session-ID"] = session_id
        response.headers["New-Session-Generated"] = str(new_session_generated)
        return response

    except Exception as e:
        logger.exception(
            f"Error during agent processing (User: {user_id}, Session: {session_id}): {e}"
        )
        # Still return headers even on internal error
        response = make_response(jsonify({"error": "An internal error occurred"}), 500)
        response.headers["User-ID"] = user_id
        response.headers["Session-ID"] = session_id
        return response
```

Finally, add a short section for execution. This starts the Flask development
server, listening on host `0.0.0.0` and the port specified by the `PORT`
environment variable (defaulting to 8080).

```python
# --- Main Execution ---
if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8080))
    logger.info(f"Starting Flask server on port {port}...")
    app.run(debug=False, host="0.0.0.0", port=port)
```

## Local Deployment

1. **Create and Activate a Virtual Environment:**

    ```bash
    python -m venv venv
    source venv/bin/activate  # On Windows use `.\venv\Scripts\activate`
    ```

2. **Install Dependencies:**

    ```bash
    pip install -r requirements.txt
    ```

3. **Configure Google Application Default Credentials (ADC):**

    Ensure your local environment can authenticate to Google Cloud services.

    ```bash
    gcloud auth application-default login
    ```

4. **Run Locally:**

    ```bash
    python main.py
    ```

    The application will start, typically listening on `http://0.0.0.0:8080`. It
    will also create a `sessions.db` file in the project root if it doesn't
    exist.

5. **Test Locally:**

    Open a new terminal and use `curl`. The API now uses headers for session
    management:

    **Initial Request (No Session):**

    ```bash
    curl -v -X POST -H "Content-Type: application/json" \
        -H "User-ID: test-user-123" \
        -d '{"query": "What is the capital of France?"}' \
        http://localhost:8080/query
    ```

    *Observe the response headers:* You'll get back `User-ID: test-user-123`, a
    newly generated `Session-ID`, and `New-Session-Generated: True`. The
    response body should be `{"response":"Paris"}`.

    **Subsequent Request (With Session):** Use the `Session-ID` received from
    the previous response.

    ```bash
    # Replace YOUR_SESSION_ID with the actual ID from the previous response header
    curl -v -X POST -H "Content-Type: application/json" \
        -H "User-ID: test-user-123" \
        -H "Session-ID: YOUR_SESSION_ID" \
        -d '{"query": "What about Germany?"}' \
        http://localhost:8080/query
    ```

    *Observe the response headers:* You'll get back the same `User-ID` and
    `Session-ID`, and `New-Session-Generated: False`. The response body should
    be `{"response":"Berlin"}`.

    **Request without User-ID:** If you omit the `User-ID` header, it defaults
    to `anonymous`.

    ```bash
    curl -v -X POST -H "Content-Type: application/json" \
        -d '{"query": "What is the capital of Italy?"}' \
        http://localhost:8080/query
    ```

    *Observe the response headers:* You'll get back `User-ID: anonymous`, a new
    `Session-ID`, and `New-Session-Generated: True`. The response body should be
    `{"response":"Rome"}`.

## Deployment to Google Cloud Run

This project can be easily deployed directly from source using the `gcloud` CLI.
This command uses Google Cloud Buildpacks to automatically detect Python,
install dependencies (including the local wheel), and create a container image.

1. **Set Environment Variables**

    Replace placeholders with your actual project ID and desired region.

    ```sh
    export GOOGLE_CLOUD_PROJECT="your-gcp-project-id"
    export GOOGLE_CLOUD_LOCATION="us-central1" # Or your preferred region
    # Set to True to route GenAI API calls through Vertex AI (recommended for GCP integration)
    export GOOGLE_GENAI_USE_VERTEXAI=True
    ```

2. **Deploy**

    Run the following command from the root directory of the project
    (`capital-agent/`):

    ```sh
    gcloud run deploy capital-agent \
    --source . \
    --region "$GOOGLE_CLOUD_LOCATION" \
    --allow-unauthenticated \
    --set-env-vars="GOOGLE_CLOUD_PROJECT=$GOOGLE_CLOUD_PROJECT,GOOGLE_CLOUD_LOCATION=$GOOGLE_CLOUD_LOCATION,GOOGLE_GENAI_USE_VERTEXAI=$GOOGLE_GENAI_USE_VERTEXAI" \
    --project "$GOOGLE_CLOUD_PROJECT"
    ```

    * `capital-agent`: The name you want to give your Cloud Run service.
    * `--source .`: Tells Cloud Run to build the container from the current
    directory.
    * `--region`: Specifies the deployment region.
    * `--allow-unauthenticated`: Makes the service publicly accessible. Remove this
    flag for IAM-controlled access.
    * `--set-env-vars`: Passes necessary configuration to the running service.
    `GOOGLE_GENAI_USE_VERTEXAI=True` configures the `google-genai` library to use
    Vertex AI endpoints, leveraging GCP authentication and infrastructure.
    * `--project`: Specifies the GCP project ID.

The command will build the container image and deploy the service, providing a
service URL upon completion.

## Using the Deployed Service

Once deployed, you can interact with the API using the service URL provided by
Cloud Run.

1. **Get the Service URL**

    Find the URL in the output of the `gcloud run deploy` command, or retrieve
    it later using:

    ```bash
    gcloud run services describe capital-agent --platform managed --region "$GOOGLE_CLOUD_LOCATION" --format 'value(status.url)' --project "$GOOGLE_CLOUD_PROJECT"
    ```

2. **Send a Request**

    Replace `YOUR_CLOUD_RUN_URL` with the actual URL:

    ```bash
    curl -X POST -H "Content-Type: application/json" \
        -d '{"query": "What is the capital of Spain?"}' \
        YOUR_CLOUD_RUN_URL/query
    ```

Example Response:

```json
{
"response": "Madrid is the capital of Spain."
}
```

## Important Notes

* **Session Management:** This example uses `DatabaseSessionService` from the
  ADK, storing session state persistently in a local SQLite file
  (`sessions.db`). While this provides persistence across restarts for local
  development and simple use cases, it relies on a single file database. For
  production environments, especially those requiring high concurrency or
  scalability, using a managed database service like **Google Cloud SQL**
  (potentially integrated via a custom session service) or **Firestore** (using
  the ADK's `FirestoreSessionService`) is strongly recommended for better
  performance, reliability, and management.
* **User/Session IDs:** The application expects `User-ID` and `Session-ID`
  headers for managing conversations.
  * If `User-ID` is not provided, it defaults to `anonymous`.
  * If `Session-ID` is not provided, a new session is created using the provided
    (or default) `User-ID`, and the new `Session-ID` is returned in the response
    headers along with `New-Session-Generated: True`.
  * Subsequent requests should include both headers to maintain the conversation
    context.
* **Error Handling:** Basic error handling is included (e.g., for session
  creation failures, missing query), but production environments may require
  more comprehensive error logging and reporting.
* **Security:** The deployment command uses `--allow-unauthenticated`. Review
  your security needs and configure appropriate IAM policies or authentication
  methods (like Identity Platform or API Gateway) if required.
