# Build a Weather Multi-Agent with Agent Development Kit

This tutorial builds on the agent documented in the quickstart. If you haven't
already, go through the steps in the quickstart and come back here to continue!

**In this tutorial, you will learn how to:**

**✅ Define a "tool"**: Create a Python function (`get_weather`) to give your main agent the ability to fetch weather data.
**✅ Design a main `LlmAgent`**: Instantiate the primary Weather Agent, providing its instructions and linking the `get_weather` tool.
**✅ Design specialized sub-agents**: Create child `LlmAgent`s for specific tasks (greeting, farewell), each equipped with *its own* simple tool (`say_hello`, `say_goodbye`).
**✅ Establish agent relationships**: Define the parent-child structure connecting your main agent to its sub-agents.
**✅ Enable automatic delegation**: Use `allow_transfer=True` to let the main agent intelligently route tasks to the appropriate sub-agent.
**✅ Run and Interact**: Use a `Runner` to execute your main agent and observe how the agent team collaborates to respond to different user inputs.

By the end of this tutorial, you'll have built a small, functional \*\*team of agents\*\*: a primary Weather Agent capable of using its \`get\_weather\` tool, and two sub-agents for greetings and farewells, all linked together and able to automatically delegate tasks based on your requests.

**Pre-requisites:** [Setup your environment](?tab=t.6hy0n5jc8ev5) **and [Running the agents](?tab=t.dgbksvkj7amm).**


## **Step 1: Define a Tool**

**Tools are like special skills for your agent\!** They are Python functions that you define and connect to your agent, allowing it to perform specific tasks beyond just chatting.  In our case, we want our Weather Agent to actually *fetch current weather information*, so we need to give it a "tool" to do this.

Let's create our mock `get_weather` tool as a Python function. You can also swap this mock for actual data from the [Open Weather API](https://openweathermap.org/) or other similar APIs.

```py
def get_weather(city: str) -> str:
   """Retrieves weather information for the given city.

   Args:
       city: The name of the city for which to retrieve weather information.

   Returns:
       A string containing the weather information for the specified city,
       or a message indicating that the weather information was not found.
   """
   cities = {
       'chicago': {'temperature': 25, 'condition': 'sunny', 'sky': 'clear'},
       'toronto': {'temperature': 30, 'condition': 'partly cloudy', 'sky': 'overcast'},
       'chennai': {'temperature': 15, 'condition': 'rainy', 'sky': 'cloudy'},
   }

   city_lower = city.lower()
   if city_lower in cities:
       weather_data = cities[city_lower]
       return f"Weather in {city} is {weather_data['temperature']} degrees Celsius, {weather_data['condition']} with a {weather_data['sky']} sky."
   else:
       return f"Weather information for {city} not found."

```

**🔑 Docstrings are important\!** The agent uses the docstring to understand what your tool does. Be clear and descriptive for effective tool use.

With this `get_weather` tool defined, we can now connect it to our agent and give it the power to get weather information\!

## **Step 2: Define the Agents and Their Relationship**

Now we create the "brains" of our operation using the `LlmAgent` class. We'll design a small team: a main **Weather Agent** and two specialized **Sub-Agents** for greetings and farewells.

**🧠 Agent Team Structure:** We'll structure them with a parent (`weather_agent`) and children (`greeting_agent`, `farewell_agent`). This hierarchy helps the framework understand how agents relate and manage task delegation.

First, let's define the **Sub-Agents** (children):

```py
# --- Import LlmAgent ---
from google.adk.agents import LlmAgent
import google.genai.types as types # For Content/Part later

# --- Constants ---
AGENT_NAME_GREETING = "greeting_agent"
AGENT_NAME_FAREWELL = "farewell_agent"
AGENT_NAME_WEATHER = "weather_agent" # Define parent name for use in instructions
MODEL_NAME = "gemini-2.0-flash-001" # Use a recent flash model

# --- Child Agent 1: Greeting ---
greeting_agent = LlmAgent(
    model=MODEL_NAME,
    name=AGENT_NAME_GREETING,
    instruction=f"""You are the Greeting Agent. Your only task is to greet the user.
    - Use the 'say_hello' tool. Extract a name if the user provides one.
    - If the user asks about something else (like weather) after you greet them, transfer back to the main agent ('{AGENT_NAME_WEATHER}').
    """,
    description="""Handles simple greetings using the 'say_hello' tool.""", # Keep descriptions concise!
    tools=[say_hello],
    allow_transfer=True, # Allow transfer back to parent or siblings
)

# --- Child Agent 2: Farewell ---
farewell_agent = LlmAgent(
    model=MODEL_NAME,
    name=AGENT_NAME_FAREWELL,
    instruction="""You are the Farewell Agent. Your only task is to say goodbye.
    - Use the 'say_goodbye' tool to respond when the user indicates they are leaving (e.g., 'bye', 'see you').
    """,
    description="""Handles simple farewells using the 'say_goodbye' tool.""",
    tools=[say_goodbye],
    allow_transfer=True, # Allow transfer (less critical here, but good practice)
)

print(f"Defined sub-agents: {greeting_agent.name}, {farewell_agent.name}")

```

**📌 Key Point:** Sub-agents focus on specific, narrow tasks. Their descriptions should clearly state their capability.

Now, let's define the main **Parent Agent**:

```py
# --- Parent Agent: Weather ---
weather_agent = LlmAgent(
    model=MODEL_NAME,
    name=AGENT_NAME_WEATHER,
    instruction=f"""You are the main Weather Agent in charge.
    - Your main job is to provide weather info using the 'get_weather' tool.
    - **Delegate tasks:** If the user gives a simple greeting (like 'Hi', 'Hello'), transfer to the '{AGENT_NAME_GREETING}'. If they say goodbye (like 'Bye', 'See you'), transfer to the '{AGENT_NAME_FAREWELL}'.
    - Handle all other weather requests yourself.
    """,
    description="""Provides weather forecasts. Can delegate greetings and farewells to sub-agents.""",
    tools=[get_weather],
    allow_transfer=True, # MUST be True to allow delegation to children
)

print(f"Defined parent agent: {weather_agent.name}")
```

**🔗 Linking Agents: Parent-Child Relationships**

To make the automatic transfer work, we need to tell the framework how these agents are connected. We do this by assigning the list of child agents to the `children` attribute of the parent agent.

```py
# --- Define the Parent-Child Relationship ---
weather_agent.children = [greeting_agent, farewell_agent]

# The framework automatically sets the `.parent_agent` attribute on the children
# when the parent's .children list is assigned.

print(f"Set children for {weather_agent.name}: {[child.name for child in weather_agent.children]}")
# You could verify the link: print(f"{greeting_agent.name}'s parent is {greeting_agent.parent_agent.name}")
```

**🚀 Understanding `allow_transfer=True` (Auto Flow):**

* **What it does:** Setting `allow_transfer=True` enables the **Auto Flow** mechanism within the `LlmAgent`. This means the underlying Large Language Model (LLM) is given extra instructions and context about related agents (parent, children, and by default, siblings).
* **How it works:** When the agent receives a user message, the LLM doesn't just decide *how* to respond or *which tool* to use; it also considers *if another agent is better suited* for the request. It makes this decision based on:
  * The current user query.
  * The `description` of the current agent.
  * The `description` fields of the available related agents (parent, children, siblings unless `disallow_transfer_to_sibling=True`).
* **Delegation:** If the LLM determines another agent is a better fit (e.g., the user says "Hello" and the `greeting_agent` description matches "Handles simple greetings"), it will internally request a transfer to that agent. The framework then routes the execution accordingly.
* **Hierarchy Matters:** Defining the `parent_agent` and `children` structure is crucial for Auto Flow to know *which* agents are available for transfer. The parent agent can delegate to children, and children can usually delegate back to the parent or potentially to siblings (other children of the same parent).

**❗ Important:** For `allow_transfer` to be effective, the `description` fields of your agents must be clear, concise, and accurately reflect their unique capabilities. The LLM relies heavily on these descriptions to make transfer decisions.

With our agent team defined and linked, the `weather_agent` can now intelligently handle weather requests itself or delegate greetings and farewells to its specialized sub-agents\!

## **Step 3: Set up Session Services**

Let's set up in-memory services:

```py

from agents.sessions import InMemorySessionService

session_service = InMemorySessionService()
```

Now,  create a **session** for our user.  Each conversation with your agent happens within a session:

```py
# Required. Unique identifier for the application.
APP_NAME = "weather_app"
# Required. Identifier for the user interacting with the agent. This is a dynamic variable.
USER_ID = "12345"

session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID)
```

We've created a session linked to our app name (`weather_app`) and a user (`12345`).  All interactions with our agent will now be tracked within this session.

## **Step 4: Create the Runner**

Let's create our `runner` instance. We need to tell the `Runner` which agent to run and which services to use:

```py
from agents.runners import Runner

runner = Runner(
    agent=root_agent,
    app_name=APP_NAME,
    session_service=session_service,
)
```

## **Step 5: Interact with Your Agent**

We've built all the pieces – the tool, the agent, the runner, and the session. Now it's time to actually talk to our agent and see it in action\!

```py
query = "What's the weather in nyc?"
content = types.Content(role='user', parts=[types.Part(text=query)])
events = runner.run(session=ecom_agent_session, new_message=content)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print("Agent Response: ", final_response)
        return None
```

For the above query, you should see output like this:

```
Agent Response:  Weather in the New York city is 25 degree Celsius, sunny with a clear sky.
```

Your Weather Agent is working\! It understood your request and used its `get_weather` tool to give you the answer.

🎉Congratulations\! In just a few minutes, you've built a functional agent using the Agent Development Kit (ADK) and learned how to:

* Install the Agent Development Kit (ADK) SDK.
* Define a **tool** to give your agent a specific capability.
* Create an **agent** and connect it to your tool.
* Run your agent and see it in action\!

## **What's Next?**

* **Dive deeper into the documentation:**  Explore the Agent Development Kit (ADK). User Guide to discover more advanced features and agent building techniques.
