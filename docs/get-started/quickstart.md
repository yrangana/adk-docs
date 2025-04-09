# Quickstart

This quickstart guides you through installing the Agent Development Kit (ADK),
setting up a basic agent with multiple tools, and running it locally either in the terminal or in the interactive, browser-based dev UI.

<!-- <img src="../../assets/quickstart.png" alt="Quickstart setup"> -->

This quickstart assumes a local IDE (VS Code, PyCharm, etc.) with Python 3.9+
and terminal access. This method runs the application entirely on your machine
and is recommended for internal development.

## 1. Setup Environment & Install ADK {#venv-install}

Create & Activate Virtual Environment (Recommended):

```bash
# Create
python -m venv .venv
# Activate (each new terminal)
# macOS/Linux: source .venv/bin/activate
# Windows CMD: .venv\Scripts\activate.bat
# Windows PowerShell: .venv\Scripts\Activate.ps1
```

Install ADK:

```bash
pip install google-adk
```

## 2. Create Agent Project {#create-agent-project}

Using the terminal, create the folder structure:

```bash
mkdir multi_tool_agent/
touch \
multi_tool_agent/__init__.py \
multi_tool_agent/agent.py \
multi_tool_agent/.env
```

Your structure:

```console
parent_folder/
    multi_tool_agent/
        __init__.py
        agent.py
        .env
```

Copy paste the following code to the respective files:

```python title="multi_tool_agent/__init__.py"
--8<-- "examples/python/snippets/get-started/multi_tool_agent/__init__.py"
```

```python title="multi_tool_agent/agent.py"
--8<-- "examples/python/snippets/get-started/multi_tool_agent/agent.py"
```

For `.env` below, just copy and paste the following code for now, as more instructions are describe in the next section on [Setup the model](#setup-the-model).

```python title="multi_tool_agent/.env"
--8<-- "examples/python/snippets/get-started/multi_tool_agent/.env"
```

## 3. Setup the model {#setup-the-model}

Your agent's ability to understand user requests and generate responses is
powered by a Large Language Model (LLM). Your agent needs to make secure calls
to this external LLM service, which requires authentication credentials. Without
valid authentication, the LLM service will deny the agent's requests, and the
agent will be unable to function.

=== "Gemini - Google AI Studio"
    1. Get an API key from [Google AI Studio](https://aistudio.google.com/apikey).
    2. Open the **`.env`** file located inside (`multi_tool_agent/`) and copy-paste the following code.
        ```env title="multi_tool_agent/.env"
        GOOGLE_GENAI_USE_VERTEXAI=FALSE
        GOOGLE_API_KEY=PASTE_YOUR_ACTUAL_API_KEY_HERE
        ```
    3. Replace `GOOGLE_API_KEY` with your actual `API KEY`.

=== "Gemini - Google Cloud Vertex AI"
    1. You need an existing [Google Cloud](https://cloud.google.com/?e=48754805&hl=en) account and a project.
        * Set up a [Google Cloud project](https://cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart-multimodal#setup-gcp)
        * Set up the [gcloud CLI](https://cloud.google.com/vertex-ai/generative-ai/docs/start/quickstarts/quickstart-multimodal#setup-local)
        * Authenticate to Google Cloud, from the terminal by running `gcloud auth login`.
        * [Enable the Vertex AI API](https://console.cloud.google.com/flows/enableapi?apiid=aiplatform.googleapis.com).
    2. Open the **`.env`** file located inside (`multi_tool_agent/`). Copy-paste the following code and update the project ID and location.
        ```env title="multi_tool_agent/.env"
        GOOGLE_GENAI_USE_VERTEXAI=TRUE
        GOOGLE_CLOUD_PROJECT=YOUR_PROJECT_ID
        GOOGLE_CLOUD_LOCATION=LOCATION
        ```

## 4. Run Your Agent {#run-your-agent}

Using the terminal, navigate to the parent directory of your agent project
(e.g. using `cd ..`):

```console
parent_folder/      <-- navigate to this directory
    multi_tool_agent/
        __init__.py
        agent.py
        .env
```

=== "adk run"

    Run the following command, to chat with your Google Search agent.

    ```
    adk run multi_tool_agent
    ```
    To exit, use Cmd/Ctrl+C.

=== "adk web (dev UI)"
    Run the following command to launch the **dev UI**.

    ```
    adk web
    ```

    Open the URL provided (usually `http://localhost:8000` or
    `http://127.0.0.1:8000`) **directly in your browser**. This connection stays
    entirely on your local machine. Select `multi_tool_agent` and interact with the agent.

    !!!note
        
        If you do not see "my_sample_agent" in the dropdown menu, make sure you are running `adk web` in the **parent folder** of your agent folder (i.e. the parent folder of my_sample_agent).

    1. In the top-left corner of the UI, you can select your agent in the dropdown. Select "my_sample_agent".
    2. Now you can chat with your agent.

### 📝 Example prompts to try

* What is the weather in New York?
* What is the time in New York?
* What is the weather in Paris?
* What is the time in Paris?

## 🎉 Congratulations!

You've successfully created and interacted with your first agent using ADK!

---

## 🛣️ Next steps

* **Go to the tutorial**: Learn how to add memory, session, state to your agent: [tutorial](tutorial.md).
* **Delve into advanced configuration:** Explore the [setup](installation.md) section for deeper dives into project structure, configuration, and other interfaces.
* **Understand Core Concepts:** Learn about [agents concepts](../agents/index.md).
