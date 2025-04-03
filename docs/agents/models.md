
<div style="color:red;border: 1px solid red;">
# ## **Ready for review**
<br>
(TODO: delete this section before launch)
<br>
</div>


# Using Different Models with ADK

The Agent Development Kit (ADK) is designed for flexibility, allowing you to plug in various Large Language Models (LLMs) beyond the standard Google Gemini models. While detailed setup for Gemini is covered in the [Setup Foundation Models](http://link-to-gemini-setup) section, this page focuses on integrating other popular models into your ADK agents.

There are two primary ways models are integrated within ADK:

1. **Via Wrapper Classes:** This method is ideal when you need broad compatibility or want to leverage specific client libraries. ADK provides wrapper classes (like `LiteLlm`) that you instantiate and pass to your agent. This is particularly useful for accessing models from multiple providers (e.g., OpenAI, Anthropic outside Vertex, Cohere) through abstraction layers.  
     
2. **Via Model/Endpoint String:** For models tightly integrated with Google Cloud, such as those hosted on Vertex AI (including models deployed from Model Garden or fine-tuned versions) or models natively registered within ADK, you can often simply provide the model name or Vertex AI endpoint resource string directly to your agent. ADK's internal registry resolves the string to the correct backend service.

**Prerequisites:**

Before integrating different models, ensure you have:

* Installed the Google Agent Development Kit:

```shell
pip install google-adk
```

* A basic understanding of authentication methods for the cloud services or model providers you intend to use (e.g., setting API keys via environment variables, using `gcloud` for Google Cloud authentication).

The following sections detail how to use each integration method.

## Method 1: Using Models via Wrapper Classes (Broad Compatibility)

This approach offers the greatest flexibility for integrating a wide array of models, especially those outside the Google Cloud ecosystem. ADK provides specific "wrapper" classes that manage the interaction with underlying libraries or APIs. You instantiate the relevant wrapper object and pass it as the `model` parameter when creating your `LlmAgent`.

### Using LiteLLM

[LiteLLM](https://docs.litellm.ai/) is a popular library that provides a standardized, OpenAI-compatible interface to call over 100+ LLMs from various providers like OpenAI, Azure OpenAI, Anthropic (non-Vertex endpoints), Cohere, Hugging Face, and many others. ADK offers a `LiteLlm` wrapper to seamlessly integrate these models into your agents.

**Use Case:**

* Accessing models not hosted on Google Cloud (e.g., GPT-4o directly from OpenAI, Claude directly from Anthropic).  
* Rapidly experimenting with different models from multiple providers without changing your core agent logic significantly.  
* Leveraging LiteLLM's features like fallbacks, retries, and unified logging across different providers.

**Setup:**

1. **Install LiteLLM:** Add the `litellm` library to your Python environment.

    ```shell
    pip install litellm
    ```

2. **Set Provider API Keys:** Configure the necessary API keys as environment variables for the *specific* LLM provider(s) you intend to use via LiteLLM.  
    
    * **Example for OpenAI:**

    ```shell
    export OPENAI_API_KEY="YOUR_OPENAI_API_KEY"
    ```

    * **Example for Anthropic (non-Vertex):**

    ```shell
    export ANTHROPIC_API_KEY="YOUR_ANTHROPIC_API_KEY"
    ```

* *Refer to the [LiteLLM Providers Documentation](https://docs.litellm.ai/docs/providers) for the correct environment variable names and required keys for each supported provider.*

**Integration:**

Import the `LlmAgent` and the `LiteLlm` wrapper from ADK. When creating your agent, instantiate `LiteLlm`, passing the specific model string recognized by LiteLLM (typically `provider/model_name`), and assign this object to the `model` parameter of `LlmAgent`.

```py
from google.adk.agents import LlmAgent
from google.adk.models.lite_llm import LiteLlm # Import the ADK wrapper

# --- Example Agent using OpenAI's GPT-4o via LiteLLM ---
# (Requires OPENAI_API_KEY to be set)
agent_openai = LlmAgent(
    # Pass the LiteLlm wrapper object, specifying the LiteLLM model string
    model=LiteLlm(model="openai/gpt-4o"),
    name="openai_powered_agent",
    instruction="You are a helpful assistant powered by GPT-4o.",
    # ... other agent parameters (tools, description, etc.)
)

# --- Example Agent using Anthropic's Claude Haiku via LiteLLM ---
# (Requires ANTHROPIC_API_KEY to be set)
agent_claude_lite = LlmAgent(
    # Pass the LiteLlm wrapper object
    model=LiteLlm(model="anthropic/claude-3-haiku-20240307"),
    name="claude_lite_agent",
    instruction="You are an assistant powered by Claude Haiku.",
    # ... other agent parameters
)

# --- Example Agent using Cohere's Command R+ via LiteLLM ---
# (Requires COHERE_API_KEY to be set)
agent_cohere = LlmAgent(
    model=LiteLlm(model="cohere/command-r-plus"),
    name="cohere_agent",
    instruction="You are an assistant powered by Cohere Command R+.",
    # ... other agent parameters
)

# --- Running the agent (example using the OpenAI agent) ---
# (Assumes runner and session_service are set up as shown in previous examples)
# async def call_agent_async(runner, user_id, session_id, query, agent_instance):
#    content = types.Content(role='user', parts=[types.Part(text=query)])
#    async for event in runner.run_async(user_id=user_id, session_id=session_id, new_message=content):
#        if event.is_final_response():
#            final_response = event.content.parts[0].text
#            print(f"Agent ({agent_instance.name}) Response: {final_response}")
#
# # Example call
# # await call_agent_async(runner, USER_ID, SESSION_ID, "Explain quantum entanglement simply.", agent_openai)
```

**Key Advantage:**

The `LiteLlm` wrapper simplifies using a diverse set of models. You can easily swap the `model` string within the `LiteLlm` instantiation (e.g., from `"openai/gpt-4o"` to `"anthropic/claude-3-opus-20240229"`) and, provided the necessary API key is configured, your agent will use the new model without further code changes to the agent's definition or execution logic.

## Method 2: Using Models via Direct String (Google Cloud & Vertex AI Integration)

For models that are deeply integrated with Google Cloud, particularly those hosted on Vertex AI or models natively recognized by ADK's internal registry (like standard Gemini models), you can often specify the model simply by passing its name or resource identifier string directly to the `model` parameter of the `LlmAgent`. ADK's registry automatically detects these strings and routes the request to the appropriate backend client (usually the `google-genai` library configured for Vertex AI).

### Using Vertex AI Endpoints

This is the standard way to connect your ADK agent to *any* model that has been deployed as a Vertex AI endpoint.

**Use Case:**

* Connecting to foundation models deployed from **Google Cloud Model Garden** (e.g., Llama 3, Mistral, etc.).  
* Using **fine-tuned** Gemini or other models that result in a Vertex AI endpoint.  
* Integrating with custom models served via a standard Vertex AI endpoint interface.

**Setup:**

1. **Deploy Model to Endpoint:** Ensure your desired model is deployed and active on a Vertex AI Endpoint in your Google Cloud project. Note the **Endpoint resource name** (it looks like `projects/PROJECT_ID/locations/LOCATION/endpoints/ENDPOINT_ID`).  
2. **Set Environment Variables:** Configure your environment to point to your Google Cloud project and the location of your endpoint.

    ```shell
    export GOOGLE_CLOUD_PROJECT="YOUR_PROJECT_ID"
    export GOOGLE_CLOUD_LOCATION="YOUR_ENDPOINT_LOCATION" # e.g., us-central1
    ```

3. **Authenticate:** Ensure your environment is authenticated to Google Cloud. The standard way is using Application Default Credentials (ADC):

    ```shell
    gcloud auth application-default login
    ```

4. **(Crucial) Enable Vertex AI Backend:** Set the following environment variable to explicitly tell the underlying client library to use the Vertex AI APIs:

    ```shell
    export GOOGLE_GENAI_USE_VERTEXAI="true"
    ```

   *Note: If this isn't set, the library might default to Google AI Studio APIs, which won't work for Vertex AI endpoints.*

**Integration:**

Pass the full Vertex AI Endpoint resource string directly as the `model` parameter in your `LlmAgent`.

```py
from google.adk.agents import LlmAgent
from google.genai import types # Often needed for config/content types

# --- Example Agent using a deployed Llama 3 model from Model Garden ---

# Replace with your actual Vertex AI Endpoint resource name
llama3_endpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_LLAMA3_ENDPOINT_ID"

agent_llama3_vertex = LlmAgent(
    # Pass the Vertex AI endpoint string directly
    model=llama3_endpoint,
    name="llama3_vertex_agent",
    instruction="You are a helpful assistant based on Llama 3.",
    # Vertex endpoints might have specific generation constraints
    generate_content_config=types.GenerateContentConfig(
        max_output_tokens=1024,
        # temperature=0.7, # Add other config as needed
    ),
    # ... other agent parameters (tools, description, etc.)
)

# --- Example Agent using a fine-tuned Gemini model endpoint ---

# Replace with your fine-tuned model's endpoint resource name
finetuned_gemini_endpoint = "projects/YOUR_PROJECT_ID/locations/us-central1/endpoints/YOUR_FINETUNED_ENDPOINT_ID"

agent_finetuned_gemini = LlmAgent(
    model=finetuned_gemini_endpoint,
    name="finetuned_gemini_agent",
    instruction="You are a specialized assistant trained on specific data.",
    # ... other agent parameters
)

# --- Running the agent ---
# (Assumes runner and session_service are set up)
# Example call:
# await call_agent_async(runner, USER_ID, SESSION_ID, "What can you tell me about project X?", agent_finetuned_gemini)
```

### Using Anthropic Claude on Vertex AI

You can also use Anthropic's Claude models directly if they are available and enabled in your Vertex AI region.

**Use Case:**

* Leveraging Claude models (e.g., Claude 3 Sonnet, Haiku, Opus) through your existing Google Cloud infrastructure and billing.

**Setup:**

1. **Vertex AI Setup:** Complete the same Vertex AI setup steps as detailed above:  
    * Set `GOOGLE_CLOUD_PROJECT` and `GOOGLE_CLOUD_LOCATION` (ensure Claude is available in your chosen location, e.g., `us-east5`, `europe-west1`).  
    * Authenticate via `gcloud auth application-default login`.  
    * **Crucially**, set `export GOOGLE_GENAI_USE_VERTEXAI="true"`.  
2. **(Important) Manual Registration:** Currently, ADK requires you to explicitly register the `Claude` model integration class in your application code *before* you create an agent that uses a Claude model string. This allows ADK's registry to recognize and correctly handle Claude model identifiers. Future ADK versions might automate this step.  

**Add this registration code near the start of your application:**

```py
# Required for using Claude model strings directly with LlmAgent
from google.adk.models.anthropic_llm import Claude
from google.adk.models.registry import LLMRegistry

LLMRegistry.register(Claude)
print("Claude models registered with ADK.") # Optional confirmation
```

**Integration:**

Once the Vertex AI environment is set up and the `Claude` class is registered, you can pass the standard Claude model name for Vertex AI directly to the `LlmAgent`.

```py
from google.adk.agents import LlmAgent
from google.genai import types

# Ensure the registration code above has executed earlier in your app lifecycle

# --- Example Agent using Claude 3 Sonnet on Vertex AI ---

# Standard model name for Claude 3 Sonnet on Vertex AI
claude_model_vertex = "claude-3-sonnet@20240229"

agent_claude_vertex = LlmAgent(
    # Pass the Claude model string directly (works after registration)
    model=claude_model_vertex,
    name="claude_vertex_agent",
    instruction="You are an assistant powered by Claude 3 Sonnet on Vertex AI.",
    generate_content_config=types.GenerateContentConfig(
        max_output_tokens=1000, # Claude models often support large contexts/outputs
    ),
    # ... other agent parameters
)

# --- Running the agent ---
# (Assumes runner and session_service are set up)
# Example call:
# await call_agent_async(runner, USER_ID, SESSION_ID, "Summarize the benefits of using Vertex AI.", agent_claude_vertex)

```

## Note on Standard Gemini Models

It's worth noting that the standard Google Gemini models provided through the `google-genai` library (like `"gemini-2.0-flash"`, `"gemini-2.0-pro"`,`"gemini-2.5-pro"` etc.) also utilize the **Direct String** integration method described in Method 2\.

* You typically pass the model name directly to the `LlmAgent`:

```py
from google.adk.agents import LlmAgent

agent_gemini = LlmAgent(
    model="gemini-2.0-flash", # Direct string for standard Gemini
    name="gemini_agent",
    instruction="You are a helpful Gemini assistant.",
    # ... other agent parameters
)
```

* The setup for these models depends on how your `google-genai` library is configured:  
  * It might use an API key (often set via `GOOGLE_API_KEY`) for **Google AI Studio**.  
  * Or, if `GOOGLE_GENAI_USE_VERTEXAI="true"` is set and you've authenticated with `gcloud`, it will use **Vertex AI** as the backend (recommended for production applications).

For comprehensive instructions on setting up and using the standard Gemini models with ADK, please refer to the dedicated Setup Foundation Models documentation.
