# What is an LLM Agent?

`LlmAgent` is a subclass of **BaseAgent** that leverages an LLM to process input and generate responses. It's the workhorse for handling natural language interactions.  
LLM-based Agents are the "brains" of your application, bringing intelligence and adaptability to your system. They leverage the capabilities of LLMs to understand and respond to natural language, make decisions, and utilize tools effectively.


## Create an `LlmAgent`
### Define Agent and Tool

Let’s start by creating a simple Agent that can find the capital city of a given country and explore some basic attributes that LlmAgent requires. 

To do that: 

* We define a simple tool `get_capital_city` that retrieves the capital of a given country.  
* We create an `LlmAgent` named `capital_agent` that uses the gemini-2.0-flash-001 model.  
* We add instructions that tell the agent how to use the `get_capital_city` tool.


```py
from google.adk.agents import Agent, LlmAgent
from google.genai import types
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from pydantic import BaseModel

# Constant
APP_NAME = "capital_city_app"
USER_ID = "12345"
SESSION_ID = "123344"
AGENT_NAME = "capital_agent"
GEMINI_2_FLASH = "gemini-2.0-flash-001"


# Define a simple tool
def get_capital_city(country: str) -> str:
    """Retrieves the capital city of a given country.

    Args:
        country: The name of the country.

    Returns:
        The capital city of the country.
    """
    country_capitals = {
        "united states": "washington, d.c.",
        "canada": "ottawa",
        "france": "paris",
    }
    return country_capitals.get(country.lower(), "Capital not found")


# Agent
capital_agent = LlmAgent(
    model="gemini-2.0-flash-001",
    name="capital_agent",
    description="An agent that can retrieve the capital city of a country.",
    instruction="""You are an agent that can retrieve the capital city of a country.
    When a user provides a prompt, extract the country name.
    Then, use the `get_capital_city` tool to retrieve the capital city for that country.
    Finally, present the capital city to the user in a clear and concise manner.
    """,
    tools=[get_capital_city],
    generate_content_config=types.GenerateContentConfig(
        max_output_tokens=100,
    ),
)

# Session and Runner
session_service = InMemorySessionService()
session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
runner = Runner(agent=capital_agent, app_name=APP_NAME, session_service=session_service)


# Agent Interaction
def call_agent(query):
  content = types.Content(role='user', parts=[types.Part(text=query)])
  events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)

  for event in events:
      if event.is_final_response():
          final_response = event.content.parts[0].text
          print("Agent Response: ", final_response)

call_agent("What is the capital of france?")
```

The `LlmAgent`  provides several key parameters. These parameters define the agent's behavior, capabilities, and interactions. Let’s explore each of the Agent parameters in detail:

**`model`:** A string representing the name of the LLM model to be used.

* Required for `LlmAgent`.   
* The name should be the standard model name string (e.g., `gemini-2.0-flash`, `claude-3-5-sonnet-v2@20241022`).  

**`name`:** A mandatory, unique, and case-sensitive string identifier:

* Crucial for internal routing and referencing in tools and callbacks, especially in multi-agent systems.  
* It should be descriptive, clearly indicating the agent's function (e.g., "order\_status\_agent").  
* Must be unique within an agent tree to prevent errors.  
* Avoid reserved names like `agent` or `function`. 
     
**`description`:** A concise, single-sentence string summarizing the agent's capabilities.

* Primarily used for dynamic routing in multi-agent systems.  
* Describes what the agent does, not how it does it. (e.g. "Provides order status information").  
* Should be specific enough to differentiate the agent and avoid jargon. 

**`instruction`:** The instruction is the crucial heart of an LLM-powered agent, acting as its operational blueprint.

* Mandatory Instruction: Define the agent's core role, capabilities, and limitations, ensuring clarity for its operation.  
* Tool Utilization and Output Formatting: Detail when and why to use tools, supplementing tool docstrings, and specify the desired output format (e.g., JSON, lists) for consistent results.  
* Enhanced Context and Dynamic Values: Employ Markdown for readability, provide input/output examples (few-shot learning) for complex tasks, and use templating to insert dynamic values from the agent's state.

**`tools`:** A list of abilities or functionalities the agent can utilize.

* Each item can be a Python function tool (FunctionTool), a class implementing BaseTool, or an AgentTool  
* Tools can be referenced by name in the instruction.  
* Multiple tools can be used sequentially and will be executed in the order. 

**`generate_content_config`:** An optional `google.genai.types.GenerateContentConfig` instance.

* Allows providing additional model configuration.  
* Some attributes (e.g., tools, system\_instruction, response\_schema) should not be set here.

**`include_contents`:** An optional literal value (**default** or **None**).  
    \* **default** includes session history in the LLM context.  
    \* **None** disables this behavior.

### Add Input/Output Schema

Next, let’s see how we can add input and output schemas for the `LlmAgent` using Pydantic `BaseModel` 


```py
from pydantic import BaseModel, Field
from google.adk.agents import Agent, LlmAgent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner

# Constant
APP_NAME = "capital_app"
USER_ID = "12345"
SESSION_ID = "123344"
AGENT_NAME = "capital_agent"
GEMINI_2_FLASH = "gemini-2.0-flash-001"


class InputSchema(BaseModel):
    country: str = Field(description="The country to find the capital of.")


class OutputSchema(BaseModel):
    capital: str = Field(description="The capital of the country.")


# Agent
capital_agent = Agent(
    model=GEMINI_2_FLASH,
    name=AGENT_NAME,
    instruction="""You are a Capital Information Agent. Your task is to provide the capital of a given country.

    When a user provides a prompt, extract the country name.
    Then, respond with the capital of that country in the following JSON format:
    {"capital": "capital_name"}
    """,
    description="""You are an agent who can tell the capital of a country.""",
    allow_transfer=False,
    input_schema=InputSchema,
    output_schema=OutputSchema,
)

# Session and Runner
session_service = InMemorySessionService()
session = session_service.create_session(
    app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
)
runner = Runner(
    agent=capital_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(
        user_id=USER_ID, session_id=SESSION_ID, new_message=content
    )

    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("Agent Response: ", final_response)

call_agent('{"country": "France"}')
call_agent('{"country": "Germany"}')
call_agent('{"country": "Japan"}')
```


**`input_schema`:** An optional Pydantic model.  
    \* Enforces a schema on the input content, which must be a JSON string.

**`output_schema`:** An optional Pydantic model.  
    \* Enforces a schema on the output content, which will be a JSON string.  
    \* It is important to note that when `output_schema` is set, LLM requests will use controlled output, which **disallows** tool usage and agent transfer.

### Add Output Key

The "output\_key" parameter is an optional string attribute of the Agent class. If set, the agent will store its output to the session state under the name specified by the value of this attribute. This allows other parts of the agent system, such as other agents, tools, or callbacks, to access the output of this agent through the session state.

```py
from google.adk.agents import Agent, LlmAgent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
import json

# Constant
APP_NAME = "capital_app"
USER_ID = "12345"
SESSION_ID = "123344"
AGENT_NAME = "capital_agent"
GEMINI_2_FLASH = "gemini-2.0-flash-001"

# Agent
capital_agent = Agent(
    model=GEMINI_2_FLASH,
    name=AGENT_NAME,
    instruction="""You are a Capital Information Agent. Your task is to provide the capital of a given country.

    When a user provides a prompt, extract the country name.
    Then, respond with the capital of that country in the following JSON format:
    {"capital": "capital_name"}
    """,
    description="""You are an agent who can tell the capital of a country.""",
    output_key="capital_output",
)

# Session and Runner
session_service = InMemorySessionService()
session = session_service.create_session(
    app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID
)
runner = Runner(
    agent=capital_agent, app_name=APP_NAME, session_service=session_service
)


# Agent Interaction
def call_agent(query):
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(
        user_id=USER_ID, session_id=SESSION_ID, new_message=content
    )

    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("Agent Response: ", final_response)
            print(
                "Session State:",
                session_service.get_session(
                    APP_NAME, USER_ID, SESSION_ID
                ).state.get("capital_output"),
            )


call_agent("What's the capital of France?")
call_agent("What's the capital of Germany?")
call_agent("What's the capital of Japan?")
```

## Additional Parameters

Please note that the following parameters are covered in detail in other sections of this documentation:

**Callbacks:** `before_model_callback`, `after_model_callback`, `before_tool_callback`, `after_tool_callback`  
**Multi-agents:** `planner`, `allow_transfer`, `disallow_transfer_to_sibling`, `global_instruction`  