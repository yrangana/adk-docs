# ADK Setup

This section provides a comprehensive guide to setting up your Agent Development Kit (ADK) environment, covering installation, model configuration, and the different ways to run your agents.

## 1\. Installation

This section covers setting up your Python environment and installing the Agent Development Kit (ADK).

### Create a Virtual Environment (Recommended)

Use a virtual environment to install Agent Development Kit (ADK). This is *highly recommended* to isolate your Agent Development Kit (ADK) project's dependencies and prevent conflicts with other Python projects.

**Creating a Virtual Environment:**  
    
  1. Open your terminal.  
  2. Navigate to the directory where you want to create your project (e.g., `~/projects`).  
  3. Run the following command to create a virtual environment named `.venv` (you can choose a different name, but `.venv` is a common convention):

```
python3 -m venv .venv
```

**Activating the Virtual Environment:**  
    
  * **Linux/macOS:**

```
source .venv/bin/activate
```

  * **Windows:**

```
.venv\Scripts\activate
```

  Your terminal prompt should now change to indicate that the virtual environment is active (e.g., `(.venv) yourname@yourcomputer:~$`).


**Deactivating the Virtual Environment:**  
    
  When you're finished working on your Agent Development Kit (ADK) project, you can deactivate the virtual environment by simply running:

```
deactivate
```

### Install Agent Development Kit

* **Post-launch (After Official Release):**  
    
  With your virtual environment activated, install Agent Development Kit using pip:

```
pip install agent-kit # Python 3.9+
```

* **Pre-launch (Before Official Release):**  
    
  1. Download the Agent Development Kit (ADK) wheel (`.whl`) file from \[link-to-whl-file\].  
  2. Make sure your virtual environment is activated.  
  3. Install using pip:

```
pip install google_genai_agents-0.0.x.devYYYYMMDD-py3-none-any.whl  # Replace with the actual filename
```

  * Verify Installation (optional):

```
pip show agent-kit

or

pip list | grep agent-kit
```

### 


## 2\. Set up Foundation Models

Agent Development Kit (ADK) currently supports the following models:

* **Google Gemini**  
* **Anthropic Claude**  
  * Coming soon...  
* **Meta Llama**  
  * Coming soon...  
* **Other Models**  
  * Coming soon...

### Gemini

To use Gemini, you'll need to obtain an API key. You have two options:

1) **Google AI Studio:**  Generally easier to get started with, suitable for prototyping and smaller-scale projects.  
2) **Vertex AI:**  Provides more control, scalability, and integration with other Google Cloud services. Suitable for production deployments and larger projects.

Learn about which platform is suitable for your needs to use Gemini as a model for ADK:   
[Link](https://ai.google.dev/gemini-api/docs/migrate-to-cloud)

1) **Google AI Studio Gemini API:**

   1. **Get an API Key:** Obtain an API key from [Google AI Studio](https://aistudio.google.com/apikey).  
   2. Set up the following environment variables in your development environment:   
      

```
GOOGLE_API_KEY=YOUR_API_KEY_HERE # Replace YOUR_API_KEY_HERE with your actual API key
GOOGLE_GENAI_USE_VERTEXAI=FALSE  # "FALSE" in notebook 
```

**2\) Vertex AI Gemini API (Express Mode):**

Vertex AI in express mode is the fastest way to start building generative AI applications on Google Cloud. Signing up in express mode is easy, and it doesn't require entering any billing information. 

1. **Get an API Key:** Obtain an API key for Express Mode [here](https://cloud.google.com/vertex-ai/generative-ai/docs/start/express-mode/overview).  
   2. **Eligibility:** Review the eligibility requirements for Express Mode [here](https://cloud.google.com/vertex-ai/generative-ai/docs/start/express-mode/overview#eligibility).  
   3. Set up the following environment variables in your development environment: 

```
GOOGLE_API_KEY=YOUR_API_KEY_HERE # Replace YOUR_API_KEY_HERE with your actual API key
GOOGLE_GENAI_USE_VERTEXAI=TRUE # "TRUE" in notebook 
```

**3\) Vertex AI Gemini API (Project):**

**Note:** This option assumes you have a Google Cloud account with a configured billing account.


1. Set up the following environment variables in your development environment: 

```
GOOGLE_GENAI_USE_VERTEXAI=TRUE
GOOGLE_CLOUD_PROJECT=YOUR-GOOGLE-CLOUD-PROJECT-ID
GOOGLE_CLOUD_LOCATION=YOUR-GOOGLE-CLOUD-REGION  # For the list of regions, see.
```

2. **Authentication:**  Run the following commands in your terminal (with your virtual environment activated) to authenticate with Google Cloud. Make sure to replace your “project-id”.

```
gcloud auth login --no-launch-browser --update-adc
gcloud auth application-default set-quota-project YOUR-PROJECT-ID # replace with your Project-ID
```

These commands will guide you through the authentication process and store your credentials securely. The `--no-launch-browser` flag is useful if you're working in a remote environment or a headless system. The second command sets the quota project so you won't run into permission issues when using the API. 

Refer to the Google Cloud docs for more information on [Authentication](https://cloud.google.com/docs/authentication/set-up-adc-local-dev-environment).

## Next steps

* Learn how to run your agents using various interfaces: \[Running the Agent\](ADD-LINK) 
