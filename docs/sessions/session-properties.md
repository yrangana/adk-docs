<div style="color:red;border: 1px solid red;">
# ## **Ready for review**
<br>
(TODO: delete this section before launch)
<br>
</div>

# Why Your Agent Needs Memory

Remember our "chat thread" analogy from the introduction? Just like you wouldn't start every text message from scratch, agents need to remember what's been said to hold a sensible conversation. Without memory, every user message would be treated as the very first one. **Sessions** are the ADK's way of giving your agent this vital context, allowing it to track and recall individual conversation threads.

## The `Session` Object: 

When a user starts interacting with your agent, ADK creates a `Session` object (`google.adk.sessions.Session`). Think of this object as the digital container holding everything related to that *one specific chat thread*. Here's what it keeps track of and why it's important:

* **Identification (`id`, `app_name`, `user_id`):** These strings act like labels on the container.  
  * `id`: A unique serial number for *this specific* conversation thread. Essential for picking up the chat later.  
  * `app_name`: Tells you which agent application this chat belongs to (useful if you build multiple agents).  
  * `user_id`: Links the chat to a particular user, enabling personalized interactions.  
* **History (`events`):** This is a list (`list[Event]`) containing the actual back-and-forth – every user message, agent response, or tool action that has occurred in this thread, recorded chronologically. Your agent can potentially look back at this history to understand the flow of the conversation.  
* **Working Memory (`state`):** This is a Python dictionary (`dict[str, Any]`) acting as the agent's short-term memory or scratchpad *specifically for this chat thread*. It's where the agent jots down dynamic details learned or decided during the conversation. We'll dive deeper into using `state` next.  
* **Activity Tracking (`last_update_time`):** A simple timestamp (a `float`) indicating the last time something was added to this chat thread. This can be useful for things like knowing if a conversation has gone idle.

Understanding these components helps you see how the `Session` object provides the foundation for context-aware agent interactions. Next, let's look more closely at how agents use the `state` dictionary as their working memory.

```py
# Example: Accessing Session Properties

from google.adk.sessions import InMemorySessionService


# Create a simple session to examine its properties
temp_service = InMemorySessionService()
example_session = temp_service.create_session(
    app_name="my_app",
    user_id="example_user",
    state={"initial_value": 1}
)

print(f"--- Examining Session Properties ---")
print(f"ID (`id`):                {example_session.id}")   # Unique identifier       
print(f"Application Name (`app_name`): {example_session.app_name}") # Which app it belongs to
print(f"User ID (`user_id`):         {example_session.user_id}")    # Who the user is
print(f"State (`state`):           {example_session.state}")       # The dynamic 'notes' dictionary
print(f"Events (`events`):         {example_session.events}")      # The conversation history (initially empty)
print(f"Last Update (`last_update_time`): {example_session.last_update_time:.2f}") # When it was last triggered
print(f"---------------------------------")
```

## Using `State`:

Inside every `Session` object lives the `state` attribute. This is simply a **standard Python dictionary (`dict[str, Any]`)** that acts as your agent's dynamic memory or "scratchpad" for that specific conversation thread.

### What goes on in the `state`?

Anything your agent needs to remember temporarily to make the current conversation flow better or achieve a goal. For example:

* **User Preferences:** If a user mentions they prefer vegetarian options, the agent could store `state['dietary_preference'] = 'vegetarian'`.  
* **Task Progress:** For a flight booking agent, it might track `state['departure_city'] = 'London'`, `state['destination_city'] = 'Paris'`, and `state['current_step'] = 'select_dates'`.  
* **Accumulated Items:** A shopping agent could maintain a list `state['cart_items'] = ['item1', 'item2']`.

### How does the state get updated?

The agent doesn't usually modify the `state` dictionary directly. Instead, updates typically happen when an `Event` (like an agent's response) is added to the session history via the `SessionService`. There are two main ways this occurs:

1. **Using `output_key` in `Agent`:** This is the simplest method. When you configure an `Agent`, you can specify an `output_key`. The agent's final text response will automatically be saved into the `state` dictionary under that key.

    ```py
    # In your Agent definition:
    summary_agent = Agent(
        model="gemini-1.5-flash-001",
        name="SummarizerAgent",
        instruction="Summarize the user's input.",
        # Tell the agent to save its summary text into state['summary']
        output_key="summary"
    )

    # After running the agent with user input "Summarize this long article...":
    # session = session_service.get_session(...)
    # print(session.state)
    # Expected output might include: {'summary': 'The article discusses...'}
    ```

2. **Via Callbacks or Tool Actions (Advanced):** For more complex updates (like adding to a list in the cart example, or modifying multiple state variables), you can use callbacks (`before_agent_callback`, `after_tool_callback`, etc.) or custom `Tool` logic. These functions can specify changes to the state via `EventActions.state_delta` when creating an `Event`. (These advanced techniques are covered elsewhere.)

### State Scoping (Session, User, App):

While `session.state` provides access to all relevant states, the underlying `SessionService` (especially `DatabaseSessionService` and `VertexAiSessionService`) can manage state at different levels:

* **Session State (Default):** Keys without a prefix (e.g., `'summary'`) are specific to the current session.  
* **User State (`user:` prefix):** Keys like `'user:theme_preference'` can persist across different sessions for the *same user*.  
* **App State (`app:` prefix):** Keys like `'app:global_announcement'` can be shared across *all users* of the application.

Your agent accesses all these through the single `session.state` dictionary, but how they are stored and retrieved depends on the `SessionService` implementation and the key prefixes used.

Now that we understand how `Session` and `State` hold the conversation data, let's look at how the `SessionService` manages these sessions.

## Managing Sessions with a `SessionService`

Your agent needs a system to handle all its conversation threads (`Session` objects). This is where the **`SessionService`** comes in. Think of it as the **database or filing system** responsible for storing, retrieving, and updating your agent's conversation logs.

## What does the `SessionService` do?

Every session service provides a standard set of operations (defined by `BaseSessionService`) to manage the lifecycle of conversations:

* **Starting New Chats (`create_session`):** When a user initiates a conversation, the service creates a new, empty `Session` log.  
* **Resuming Chats (`get_session`):** If a user comes back, the service retrieves their existing `Session` log using its unique ID, allowing the agent to pick up where it left off.  
* **Saving Progress (`append_event`):** As the user and agent interact, each message or action (`Event`) is added to the session's history. Crucially, this is also how the `session.state` (the agent's scratchpad) gets updated and saved based on changes specified in the event.  
* **Listing Chats (`list_sessions`):** Allows you to find all the conversation threads associated with a specific user for a given application.  
* **Cleaning Up (`delete_session`):** Permanently removes a conversation log when it's finished or no longer needed.

## Choosing the Right Filing System: Session Service Implementations

ADK offers different ways to store session data, each suited for different situations:

1. **`InMemorySessionService`**: For Getting Started & Testing  
     
    * **How it works:** Stores all session data (history and state) directly in your computer's active memory.  
    * **Persistence:** **None.** If your application restarts, all conversation data is lost.  
    * **Best for:** Quick tests, development, running simple examples where you don't need to save conversations long-term.

    ```py
    from google.adk.sessions import InMemorySessionService

    # Simple to set up, no external dependencies
    session_service = InMemorySessionService()
    ```

2. **`DatabaseSessionService`**: For Persistent Storage You Manage  
     
    * **How it works:** Connects to a relational database (like PostgreSQL, MySQL, or SQLite) and stores session history and state in dedicated tables. It intelligently manages session-specific, user-level (`user:` prefix), and app-level (`app:` prefix) state in different tables for better organization.  
    * **Persistence:** **Yes.** Data survives application restarts as it's stored in your database.  
    * **Requires:** Database setup and the `sqlalchemy` library (install with `pip install google-adk[database]`).  
    * **Best for:** Production applications where you need reliable, persistent storage for conversations and state, and you manage your own database infrastructure.

    ```py
    # Requires sqlalchemy installed
    from google.adk.sessions import DatabaseSessionService

    # Connect to a local SQLite file (creates 'my_agent_sessions.db' if it doesn't exist)
    # For production, use connection strings for PostgreSQL, MySQL, etc.
    db_url = "sqlite:///./my_agent_sessions.db"
    session_service = DatabaseSessionService(db_url=db_url)
    ```

3. **`VertexAiSessionService`**: For Scalable Cloud Storage  
     
    * **How it works:** Leverages Google Cloud's Vertex AI infrastructure to store and manage sessions via API calls.  
    * **Persistence:** **Yes.** Data is managed reliably and scalably by Google Cloud.  
    * **Requires:** Google Cloud project setup, appropriate permissions, and providing your project ID, location, and the relevant Vertex AI Reasoning Engine resource name/ID.  
    * **Best for:** Production applications deployed on Google Cloud, especially those needing high scalability, reliability, and integration with other Vertex AI features.

    ```py
    # Requires google-cloud-aiplatform SDK
    from google.adk.sessions import VertexAiSessionService

    # Ensure your environment is authenticated (e.g., gcloud auth application-default login)
    PROJECT_ID = "your-gcp-project-id"
    LOCATION = "us-central1" # e.g., us-central1
    # Can be the full resource name or just the numeric ID
    REASONING_ENGINE = "projects/your-gcp-project-id/locations/us-central1/reasoningEngines/123456789"

    session_service = VertexAiSessionService(project=PROJECT_ID, location=LOCATION)

    # Use REASONING_ENGINE as app_name when creating/getting sessions
    # session = session_service.create_session(app_name=REASONING_ENGINE, ...)
    ```

Selecting the appropriate `SessionService` early on is important for how your agent's memory will behave, especially regarding persistence and scalability. You can start simple with `InMemorySessionService` and switch later as your needs evolve.

## A Session's Journey: The Workflow

So, how do the `Session`, `State`, and `SessionService` actually work together when a user talks to your agent? Let's walk through a typical conversation turn:

1. **The Conversation Starts (or Resumes):**  
     
    * A user sends their first message to your agent application.  
    * Your application's `Runner` needs to establish the context. It uses the `SessionService` to either:  
        * `create_session`: If this is a brand new chat thread, the service creates a new `Session` object (often with some initial `state`, if provided) and stores it.  
        * `get_session`: If the user is continuing an existing chat (identified by `user_id` and `session_id`), the service retrieves the existing `Session` object, loading its history (`events`) and current `state`.

2. **Agent Gets the Context:**  
     
    * The `Runner` now has the relevant `Session` object (either newly created or retrieved).  
    * It prepares to run the agent logic, providing the agent access to the `session.state` (its scratchpad) and potentially the `session.events` (the chat history).

   
3. **Agent Thinks and Acts:**  
     
    * The agent receives the latest user message.  
    * It can be read from the `session.state` dictionary to recall information specific to this conversation (e.g., "Ah, this user prefers vegetarian food").  
    * It might look at the recent `session.events` history for conversational context.  
    * Based on its instructions, the user's message, and the state/history, the agent decides what to do next (e.g., answer a question, ask for clarification, use a tool).

4. **Agent Updates Its Memory (Optional but Common):**  
     
    * If the agent learns something new or needs to track progress, it flags this information to be saved in the `state`.  
    * A common way is using the `output_key` on the `Agent` definition – the agent's final text response gets automatically earmarked for saving under that key in the `state`.  
    * More complex updates can be triggered via advanced mechanisms like callbacks or tools, which signal changes via `EventActions.state_delta`.

5. **Saving the Turn's Interaction:**  
     
    * The agent generates its response (e.g., a text message).  
    * The `Runner` takes this response, packages it as an `Event`, and includes any state changes flagged in the previous step within the event's `actions`.  
    * Crucially, the `Runner` calls `session_service.append_event(...)`. This does two things:  
        * Adds the new agent response `Event` to the `session.events` history.  
        * Updates the persistent `session.state` within the `SessionService` according to the `state_delta` in the event's actions.  
    * The `Session`'s `last_update_time` is also updated.


6. **Ready for the Next Turn:**  
     
    * The agent's response is sent back to the user.  
    * The `SessionService` now holds the updated log (history \+ state), ready for when the user sends their next message, restarting the cycle from step 1 (usually with `get_session`).


7. **The Conversation Ends:**  
     
    * Eventually, the conversation concludes.  
    * To manage resources, your application should ideally call `session_service.delete_session(...)` to remove the log and its associated state from the storage system (memory, database, or cloud). This cleanup might be triggered by specific user commands (like "goodbye"), application logic (task completed), or timeout mechanisms you implement.

This cycle shows how the `SessionService` acts as the central coordinator, ensuring the agent always has access to the relevant history and state for the current conversation thread, and that progress is saved persistently (depending on the service implementation).


**Quickstart Example**

```py
# Example: Using InMemorySessionService
# Example: Using InMemorySessionService Methods

from google.adk.sessions import InMemorySessionService
from google.adk.events import Event, EventActions
from google.genai import types
import time
import uuid

print("\n--- Demonstrating InMemorySessionService ---")

# 1. Instantiate
session_service = InMemorySessionService()  
app_name, user_id = "memory_app", "user_mem"  
session_id = "mem_session_1" 

# 2. Create Session
current_session = session_service.create_session(
    app_name=app_name, user_id=user_id, session_id=session_id, state={"counter": 0}
)
print(f"Created Session: ID={current_session.id}, State={current_session.state}")

# 3. Append Event with State Delta
user_event = Event(
    invocation_id="inv_1", author="user", content=types.Content(parts=[types.Part(text="Increment")])
)
session_service.append_event(current_session, user_event)  # No state change yet

agent_event = Event(
    invocation_id="inv_2", author="agent",
    actions=EventActions(state_delta={"counter": 1})  # Increment counter
)
session_service.append_event(current_session, agent_event)
print(f"Appended Event, state['counter'] should be 1")

# 4. Get Session
retrieved_session = session_service.get_session(app_name, user_id, session_id)
print(f"Retrieved Session: ID={retrieved_session.id}, State={retrieved_session.state}")
print(f"Events in session: {len(retrieved_session.events)}")  # Shows 2 events were added

# 5. List Sessions
session_list = session_service.list_sessions(app_name, user_id)
print(f"List Sessions for {user_id}: {session_list.session_ids}")

# 6. Delete Session
session_service.delete_session(app_name, user_id, session_id)
print(f"Deleted Session: {session_id}")

# 7. Get Session (should fail)
deleted_session = session_service.get_session(app_name, user_id, session_id)
print(f"Retrieve after delete: {'Session found (unexpected!)' if deleted_session else 'Session not found (correct)'}")
print("------------------------------------------")


```

**Expected Output:**

```
--- Demonstrating InMemorySessionService ---
Created Session: ID=mem_session_1, State={'counter': 0}
Appended Event, state['counter'] should be 1
Retrieved Session: ID=mem_session_1, State={'counter': 1}
Events in session: 2
List Sessions for user_mem: ['mem_session_1']
Deleted Session: mem_session_1
Retrieve after delete: Session not found (correct)
------------------------------------------
```