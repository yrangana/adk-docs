<div style="color:red;border: 1px solid red;">
# ## **Ready for review**
<br>
(TODO: delete this section before launch)
<br>
</div>

# Introduction to Session and State

To have meaningful conversations, agents need memory. They must recall previous interactions to understand context and maintain continuity. 

Why do chat applications remember your conversation history? So you don't have to repeat yourself\! Agents work the same way. To have useful, multi-turn conversations, they need a memory. In the Agent Development Kit (ADK), **Sessions** and **State** provide this crucial capability.

Think of interacting with your agent like having a distinct **chat thread**.

* **`Session`**: The Chat Thread \-  A **`Session`** represents a single, ongoing conversation thread between a user and your agent. It's the main container holding all the information related to *that specific chat*. This includes:  
    
    * Identifiers: Who is chatting (`user_id`), which app they're using (`app_name`), and a unique ID for this specific thread (`id`).  
    * History: A list of all messages and actions that have happened (`session.events`).  
    * Status: When the thread was last updated (`last_update_time`).  
    * Memory: The agent's short-term notes for this chat (`session.state`). Having a `Session` allows your agent to look back at previous messages and understand the context of the current interaction.


* **`State`**: Notes Within the Chat Thread \- While the `Session` holds the whole history, the **`State`** (`session.state`) is like the agent's **scratchpad or sticky notes *for that specific chat thread***. It's a flexible Python dictionary (`dict[str, Any]`) where the agent can temporarily store and update details relevant *only* to the current conversation. Examples include:  
    
    * Remembering the user's name after they mention it.  
    * Keeping track of items added to a shopping cart during the chat.  
    * Noting the current step in a multi-stage booking process. This allows the agent to personalize the conversation and manage tasks that span multiple turns.


* **`SessionService`**: Managing All the Chat Threads \- You need a way to manage all these individual chat threads. That's the job of the **`SessionService`**. Think of it as the **filing system or database** for your agent's conversations. It handles the logistics:  
    
    * `create_session`: Starting a brand new chat thread when a user begins.  
    * `get_session`: Retrieving an existing thread to continue a conversation.  
    * `list_sessions`: Finding all the threads associated with a particular user.  
    * `delete_session`: Removing a thread when it's no longer needed.  
    * `append_event`: Adding a new message (from the user or the agent) to a thread's history, which also updates its `State`.


  ADK offers different storage options for these threads:


  * `InMemorySessionService`: Keeps threads in memory – easy for testing, but lost when the app restarts.  
  * `DatabaseSessionService`: Stores threads persistently in a database.  
  * `VertexAiSessionService`: Uses a scalable Google Cloud service to manage threads.

**Quickstart Example**

This example shows how `Session`, `State`, and `SessionService` work together:

```py
from google.adk.agents import LlmAgent
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types

# --- Constants ---
APP_NAME = "capital_finder_app"
USER_ID = "quickstart_user"
SESSION_ID = "session_abc"
MODEL = "gemini-2.0-flash-001"

# Agent
capital_agent = LlmAgent(
    model=MODEL,
    name="CapitalFinderAgent",
    instruction="""You are an agent that finds the capital of a given country.
    When asked for the capital, respond *only* with the name of the capital city.
    """,
    output_key="capital_city" # Save the agent's final response text to state['capital_city']
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
          print("\nAgent Response: ", final_response)

initial_session = session_service.get_session(APP_NAME, USER_ID, SESSION_ID)
print(f"Initial Session State: {initial_session.state}") # Should be empty {}

call_agent("What is the capital of france?")

final_session = session_service.get_session(APP_NAME, USER_ID, SESSION_ID)
print(f"Final Session State: {final_session.state}") # Should now contain {'capital_city': 'Paris'}
```

**Expected Output:**

```
Initial Session State: {}

Agent Response:  Paris

Final Session State: {'capital_city': 'Paris\n'}
```

Next, we will delve deeper into the `Session` object and explore its components in more detail.