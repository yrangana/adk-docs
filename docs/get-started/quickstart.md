# Quickstart

This quickstart guides you through installing the Agent Development Kit (ADK),
setting up a basic agent, and running its developer UI, tailored to your chosen
environment.

<img src="../../assets/quickstart.png" alt="Quickstart setup">

<div style="color:red;border: 1px solid red;">
# ## **Pre-launch instructions**
 (TODO: delete this section before launch)

* **TEST ONLY USING IDE (Local Setup)**

<table>
<td>

  1. Open Cloud Shell or other terminal, and authenticate to your @google.com
     email:
  ```
  gcloud auth login
  ```

  2. Set your default project (optional)
  ```
  gcloud config set project your-project-id
  ```


  2. Download the latest .whl file so that you can install the SDK locally:
  ```
  # download the latest whl
  gcloud storage cp gs://agent_framework/latest/*.whl .

  # sort filenames and fetch latest whl as `pkg`
  pkg=$(find . -maxdepth 1 -name "google_adk*.whl" -print | sort -V | tail -n1)

  echo $pkg
  ```

  3. Install the package
  ```
  # install whl
  pip install $pkg --force-reinstall
  ```


</td>
</table>
</div>


This quickstart assumes a local IDE (VS Code, PyCharm, etc.) with Python 3.10+
and terminal access. This method runs the application entirely on your machine
and is recommended for internal development.

**1. Setup Environment & Install ADK**

*   Create & Activate Virtual Environment (Recommended):
    ```bash
    # Create
    python -m venv .venv
    # Activate (each new terminal)
    # macOS/Linux: source .venv/bin/activate
    # Windows CMD: .venv\Scripts\activate.bat
    # Windows PowerShell: .venv\Scripts\Activate.ps1
    ```
*   Install ADK:
    ```bash
    pip install google-adk
    ```

**2. Create Agent Project**

Using the terminal, create the folder structure:
```bash
mkdir multi_tool_agent/
touch \
multi_tool_agent/__init__.py \
multi_tool_agent/agent.py \
multi_tool_agent/.env
```
Your structure:
```
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

```python title="multi_tool_agent/.env"
--8<-- "examples/python/snippets/get-started/multi_tool_agent/.env"
```

```python title="multi_tool_agent/agent.py"
--8<-- "examples/python/snippets/get-started/multi_tool_agent/agent.py"
```

<br>
**3. Setup the LLM Model**

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

**4. Run Your Agent**

Using the terminal, navigate to the parent directory of your agent project
(e.g. using `cd ..`):

```
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

=== "adk web"

    Run the following command to launch the **developer UI**.

    ```
    adk web
    ```

Open the URL provided (usually `http://localhost:8000` or
`http://127.0.0.1:8000`) **directly in your browser**. This connection stays
entirely on your local machine. Select `multi_tool_agent` and interact.

## 📝 Example prompts to try

* What is the weather in New York?
* What is the time in New York?
* What is the weather in Paris?
* What is the time in Paris?

## 🎉 Congratulations!
You've successfully created and interacted with your first
agent using ADK!

---
## 🛣️ Next steps

Regardless of your chosen environment, you've successfully created and
interacted with your first agent using ADK!

*   **Delve into advanced configuration:** Explore the
    [setup](setup-and-installation.md) section for deeper dives into project
    structure, configuration, and other interfaces.
*   **Understand Core Concepts:** Learn about
    [agents concepts](../agents/overview.md).
