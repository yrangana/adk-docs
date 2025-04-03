# Ecosystem Tools

ADK is designed to be highly extensible, allowing you to seamlessly integrate tools from other AI Agent frameworks like CrewAI and LangChain. This interoperability is crucial because it allows for faster development time and allows you to reuse existing tools.

## Using LangChain Tools

ADK provides the `LangchainTool` wrapper to integrate tools from the LangChain ecosystem into your agents.

### How to Use

1. **Install Dependencies:** Ensure you have the necessary LangChain packages installed. For example, for the Tavily search tool:

    ```bash
    pip install langchain_community tavily-python
    ```

2. **Import:** Import the `LangchainTool` wrapper from the ADK and the specific `LangChain` tool you wish to use.

    ```py
    from google.adk.tools.langchain_tool import LangchainTool
    from langchain_community.tools import TavilySearchResults
    ```

3. **Instantiate & Wrap:** Create an instance of your LangChain tool and pass it to the LangchainTool constructor.

    ```py
    tavily_tool_instance = TavilySearchResults(
        max_results=5,
        # ... other LangChain tool parameters
    )
    adk_wrapped_tool = LangchainTool(tool=tavily_tool_instance)
    ```

4. **Add to Agent:** Include the wrapped LangchainTool instance in your agent's tools list during definition.

    ```py
    from google.adk.agents import Agent

    my_agent = Agent(
        # ... other agent parameters
        tools=[adk_wrapped_tool]
    )
    ```

### Example: Tavily Search

Note: Create a [Tavily](https://tavily.com/) API KEY and set it as an environment variable before running this sample.

```py
from agents import Agent, Runner
from agents.sessions import InMemorySessionService
from agents.tools.langchain_tool import LangchainTool
from langchain_community.tools import TavilySearchResults
from google.genai import types

APP_NAME = "news_app"
USER_ID = "1234"

root_agent = Agent(
    name="langchain_tool_agent",
    model="gemini-2.0-flash-001",
    description="Agent to answer questions using TavilySearch.",
    instruction="I can answer your questions by searching the internet. Just ask me anything!",
    # Add the LangChain Tavily tool
    tools = [LangchainTool(
        tool= TavilySearchResults(
            max_results=5,
            search_depth="advanced",
            include_answer=True,
            include_raw_content=True,
            include_images=True,
        )
    )]
)

session_service = InMemorySessionService()

runner = Runner(
    agent=root_agent,
    session_service=session_service,
    app_name=APP_NAME,
)

session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID)

# Query
query = "what's the latest news in Toronto"
content = types.Content(role="user", parts=[types.Part(text=query)])
events = runner.run(session=session, new_message=content)
for event in events:
    if event.is_final_response():
        final_response = event.content.parts[0].text
        print("Agent Response: ", final_response)
```

## Using CrewAI tools

ADK provides the `CrewaiTool` wrapper to integrate tools from the CrewAI library.

### How to Use

1. **Install Dependencies:** Install the necessary CrewAI tools package.

    ```bash
    pip install crewai-tools
    Use code with caution.
    ```

2. **Import:** Import `CrewaiTool` from ADK and the desired CrewAI tool.

    ```py
    from google.adk.tools.crewai_tool import CrewaiTool
    from crewai_tools import SerperDevTool
    ```

3. **Instantiate & Wrap:** Create an instance of the CrewAI tool. Pass it to the `CrewaiTool` constructor. You must also provide a name and description to the ADK wrapper, as these might differ from the CrewAI tool's internal naming.

    ```py
    serper_tool_instance = SerperDevTool(
        n_results=10,
        search_type="news",
        # ... other CrewAI tool parameters
    )
    adk_wrapped_tool = CrewaiTool(
        name="InternetNewsSearch", # Define a clear name for ADK
        description="Searches the internet for recent news articles.", # Define a description for ADK
        tool=serper_tool_instance
    )
    ```

4. **Add to Agent:** Include the wrapped `CrewaiTool` instance in your agent's tools list.

    ```py
    from google.adk.agents import Agent

    my_agent = Agent(
        # ... other agent parameters
        tools=[adk_wrapped_tool]
    )
    ```

### Example: Serper Search for News

Here’s an example of a `CrewaiTool` using Serper API to fetch the latest news.

```py
from google.adk import Agent, Runner
from google.adk.sessions import InMemorySessionService
from google.adk.tools.crewai_tool import CrewaiTool
from crewai_tools import SerperDevTool
from google.genai import types

# Constants
APP_NAME="news_app"
USER_ID="user1234"
SESSION_ID="1234"

root_agent = Agent(
    name="basic_search_agent",
    model="gemini-2.0-flash-001",
    description="Agent to answer questions using Google Search.",
    instruction="I can answer your questions by searching the internet. Just ask me anything!",
    # Add the Serper tool
    tools = [CrewaiTool(
        name="Serper Tool",
        description="A tool to search the internet for news.",
        tool = SerperDevTool(
            n_results=10,
            save_file=False,
            search_type="news",
        )
    )]
)

# Session and Runner
session_service = InMemorySessionService()
session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID, session_id=SESSION_ID)
runner = Runner(agent=root_agent, app_name=APP_NAME, session_service=session_service)


# Agent Interaction
def call_agent(query):
  content = types.Content(role='user', parts=[types.Part(text=query)])
  events = runner.run(user_id=USER_ID, session_id=SESSION_ID, new_message=content)
 
  for event in events:
      if event.is_final_response():
          final_response = event.content.parts[0].text
          print("Agent Response: ", final_response)

call_agent("what's the latest ai?")
```
