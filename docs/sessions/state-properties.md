<div style="color:red;border: 1px solid red;">
# ## **Ready for review**
<br>
(TODO: delete this section before launch)
<br>
</div>

# `State` Properties 

Think back to our "chat thread" (`Session`). While the session holds the entire history (`events`), the **`state`** attribute (`session.state`) is like the agent's **dedicated sticky note or scratchpad *just for that thread***. It's where the agent keeps track of important details that change *during* the conversation.

### What is `session.state`?

At its core, `session.state` is a **standard Python dictionary (`dict[str, Any]`)**. It's designed to hold dynamic information that the agent needs to remember to:

* **Personalize Interaction:** Recall user preferences mentioned earlier (e.g., `{'user_preference_theme': 'dark'}`).  
* **Track Task Progress:** Keep tabs on steps in a multi-turn process (e.g., `{'booking_step': 'confirm_payment', 'selected_flight': 'UA123'}`).  
* **Accumulate Information:** Build lists or summaries over several turns (e.g., `{'shopping_cart_items': ['book', 'pen']}`).  
* **Make Informed Decisions:** Store flags or values that influence its next response (e.g., `{'user_is_authenticated': True}`).

### Key Characteristics of State

Understanding these characteristics is crucial for using state effectively:

1. **Structure: Key-Value Pairs**  
     
    * It's a dictionary, so data is stored as `key: value`.  
    * **Keys:** Always strings (`str`). Use clear, descriptive names (e.g., `'departure_city'`, `'user:language_preference'`).  
    * **Values:** Should be basic, **serializable** Python types. This is important because the `SessionService` needs to be able to save and load this data easily. Stick to:  
        * Strings (`str`)  
        * Numbers (`int`, `float`)  
        * Booleans (`bool`)  
        * Lists (`list`) containing *only* these basic types.  
        * Dictionaries (`dict`) containing *only* these basic types as keys and values.  
    * **⚠️ Avoid Complex Objects:** **Do not store complex Python objects** (like custom class instances, functions, database connections, file handles) directly in the state. They often can't be reliably saved and loaded, leading to errors or unexpected behavior. If you need to associate complex objects, store a simple identifier (like an ID string) in the state and retrieve the full object from another source when needed.

2. **Mutability: It Changes**  
     
    * The contents of the `state` dictionary are expected to change as the conversation progresses. The agent learns new things, completes steps, or updates preferences, and these changes are reflected in the state.


3. **Persistence: Depends on the `SessionService`**  
     
    * How long the state "sticks around" depends entirely on which `SessionService` you're using:  
        * `InMemorySessionService`: **Not Persistent.** State exists only in memory and is **lost** when your application stops or restarts. Good for testing, not production.  
        * `DatabaseSessionService`: **Persistent.** State is saved in your configured database (e.g., PostgreSQL, SQLite) and survives restarts.  
        * `VertexAiSessionService`: **Persistent.** State is managed by the Google Cloud service and is reliably stored.

### Organizing State with Prefixes: Scope Matters

Imagine you have notes just for *this* chat, notes for *this user* across all chats, and maybe even notes for the *entire app*. Prefixes help organize this:

* **No Prefix (Session State):**  
    
    * **Scope:** Specific to the *current* session (`id`). Lost when the session ends if not persistent.  
    * **Persistence:** Depends on the `SessionService` (persistent for `Database` and `VertexAI`, not for `InMemory`).  
    * **Use Cases:** Tracking progress within the current task (e.g., `'current_booking_step'`), temporary flags for the ongoing interaction (e.g., `'needs_clarification'`), results specific to this chat (e.g., `'search_results_list'`).  
    * **Example:** `session.state['current_intent'] = 'book_flight'`


* **`user:` Prefix (User State):**  
    
    * **Scope:** Tied to the `user_id`. Shared across *all* sessions for that specific user within the same `app_name`. Persists independently of any single session.  
    * **Persistence:** **Persistent** when using `DatabaseSessionService` or `VertexAiSessionService`. (`InMemory` stores it but loses it on restart).  
    * **Use Cases:** User preferences (e.g., `'user:theme'`, `'user:language'`), profile details (e.g., `'user:name'`), long-term summaries (e.g., `'user:last_order_id'`).  
    * **Example:** `session.state['user:preferred_language'] = 'fr'`


* **`app:` Prefix (App State):**  
    
    * **Scope:** Tied to the `app_name`. Shared across *all* users and *all* sessions for that application.  
    * **Persistence:** **Persistent** when using `DatabaseSessionService` or `VertexAiSessionService`. (`InMemory` stores it but loses it on restart).  
    * **Use Cases:** Global settings (e.g., `'app:api_endpoint'`), shared templates (e.g., `'app:welcome_message'`), application-wide flags (e.g., `'app:maintenance_mode'`).  
    * **Example:** `session.state['app:global_discount_code'] = 'SAVE10'`


* **`temp:` Prefix (Temporary Session State):**  
    
    * **Scope:** Specific to the *current* session, just like state with no prefix.  
    * **Persistence:** **Never Persistent.** Even with `Database` or `VertexAI`, this state is *guaranteed* to be discarded and will not be saved. It exists only transiently during processing.  
    * **Use Cases:** Intermediate calculation results needed only for the very next step, temporary flags used and discarded within a single complex turn, data you definitely don't want cluttering persistent storage.  
    * **Example:** `session.state['temp:raw_api_response'] = {...}` (used immediately, then ignored).

**How the Agent Sees It:** Your agent code always interacts with the *combined* state through the single `session.state` dictionary. When you access `session.state['user:preference']`, the `SessionService` knows (based on the prefix) to fetch it from the appropriate user-level storage if needed.

**How Services Store It:** `DatabaseSessionService` and `VertexAiSessionService` are smart about prefixes. They typically store `app:` and `user:` state in separate, optimized locations (like dedicated database tables `app_states`, `user_states`) for efficient sharing and retrieval, while session-specific state (no prefix) is stored alongside the main session data. `temp:` state isn't stored at all.

  ```py
  # Example: Accessing different state scopes via session.state
  # (Assuming state has been previously set, perhaps in earlier turns or sessions)

  def process_user_request(session: Session):
      # Get user preference (might come from user-level storage)
      language = session.state.get('user:preferred_language', 'en')

      # Get app-wide setting (might come from app-level storage)
      api_key = session.state.get('app:service_api_key')

      # Get session-specific detail
      current_task = session.state.get('current_task_id')

      print(f"Processing task {current_task} for user preferring {language}.")
      if not api_key:
          print("Warning: App API key not set.")

      # Agent logic would use these values...
  ```

### How State is *Correctly* Updated: The `append_event` Flow

The **standard and recommended** way to update state is by including the changes within an `Event`'s `actions` when you save that event to the session history.

  1. **Define the Changes:** Create a dictionary representing *only* the keys and values you want to add or change. This is the `state_delta`.

    ```py
    state_changes = {
        'order_status': 'confirmed',  # Update existing key
        'confirmation_id': 'ABC789',   # Add new key
        'user:order_count': 5         # Update user-level state
        # To 'delete' a key, set its value to None
        'temp_calculation_needed': None
    }
    ```

  2. **Package in `EventActions`:** Put this delta into the `state_delta` attribute of an `EventActions` object.

    ```py
    from google.adk.events import Event, EventActions, EventContent
    from google.genai.types import Part

    agent_response_content = EventContent(parts=[Part(text="Your order is confirmed!")])
    actions_with_state_update = EventActions(state_delta=state_changes)
    ```

  3. **Create the Event:** Create the `Event` (e.g., the agent's response), including the `actions`.

    ```py
    agent_event = Event(
        invocation_id="inv_confirm_order",
        author="agent",
        content=agent_response_content,
        actions=actions_with_state_update
    )
    ```

  4. **Append the Event:** Use the `SessionService` to add the event to the session. **This is the crucial step.**

    ```py
    # Assume 'session_service' and 'current_session' are already defined
    session_service.append_event(current_session, agent_event)
    ```

**What `append_event` Does:**

* Adds the `agent_event` to `session.events`.  
* Look at `agent_event.actions.state_delta`.  
* Applies those changes (`state_changes`) to the state managed by the `SessionService`.  
  * For `Database` and `VertexAI`, this triggers saving the updates to the appropriate persistent storage (session, user, or app level).  
  * It correctly handles merging the delta with the existing state.  
* Updates the session's `last_update_time`.  
* **It's Thread-Safe:** The `append_event` method is designed to handle concurrent updates safely, preventing race conditions where multiple updates might try to overwrite each other simultaneously.

**The Easy Way: `output_key`**

As shown in Section 2, the simplest way to update state with an agent's text response is using the `output_key` parameter when defining the `Agent`. ADK handles creating the `Event`, `EventActions`, and `state_delta` for you automatically behind the scenes.

```py
# Recap: Using output_key
capital_agent = LlmAgent(
    ...,
    instruction="Find the capital.",
    output_key="capital_city" # Automatically creates state_delta={'capital_city': '...'}
)
# Runner calls append_event, saving the state.
```

### ⚠️ A Warning About Direct State Modification

You *can* technically access `session.state` directly as a Python dictionary after retrieving a session:

```py
# ---- THIS IS GENERALLY A BAD IDEA - DO NOT COPY PASTE BLINDLY ----
# retrieved_session = session_service.get_session(...)
# direct_state = retrieved_session.state
# direct_state['some_key'] = 'some_value' # <<< Direct modification
# ---- AVOID THIS PATTERN ----
```

**Why is this strongly discouraged?**

1. **Bypasses Event History:** The change is *not* recorded as an `Event`. You lose the audit trail of *when* and *why* the state changed, making debugging much harder.  
2. **Breaks Persistence (for `Database`/`VertexAI`):** Critically, with `DatabaseSessionService` or `VertexAiSessionService`, changes made directly to `retrieved_session.state` **will likely NOT be saved** to the database or cloud. These services rely on the `append_event` flow to trigger persistence. Your changes will probably be lost.  
3. **Not Thread-Safe:** Directly modifying the state dictionary from multiple threads or processes can lead to race conditions and lost updates. `append_event` is designed to handle this safely.  
4. **Ignores Event Logic:** Any other logic associated with `EventActions` (like `skip_summarization`) is ignored.  
5. **Doesn't Update Timestamps:** The session's `last_update_time` won't reflect the change.

**When *might* it seem okay (but still use caution)?**

* **Read-Only Access:** Simply *reading* values from `session.state` is generally safe.  
* **`InMemorySessionService` ONLY:** If using `InMemorySessionService` for simple tests *and* you don't care about event history or persistence *and* you understand the risks, direct modification *might* seem to work because it's just an in-memory dict. However, it builds bad habits.

**Recommendation:** Always prefer updating state via `EventActions.state_delta` and `session_service.append_event()`. Stick to the standard flow for reliable, trackable, and persistent state management.

### Best Practices for State Design Recap

* **Minimalism:** Store only essential data. Avoid large blobs or redundant info.  
* **Serialization:** Stick to basic Python types (str, int, float, bool, list/dict of basics).  
* **Descriptive Keys:** Use clear names (e.g., `'user:preference_language'`).  
* **Correct Prefixes:** Choose `app:`, `user:`, `temp:`, or none based on scope/persistence needs.  
* **Shallow Structures:** Avoid deeply nested dictionaries if possible.  
* **Use the Standard Update Flow:** Rely on `EventActions.state_delta` and `append_event`.

By understanding these properties and following best practices, you can effectively leverage the `state` mechanism to build agents with robust, contextual memory.


**Quickstart Example**

```py
import time
# Imports:
from google.adk.sessions import InMemorySessionService, Session 
from google.adk.events import Event, EventActions
from google.genai.types import Part, Content


# 1. Setup
# Instantiate the InMemorySessionService.
session_service = InMemorySessionService()
app_name = "state_demo_app"
user_id = "demo_user_123"
session_id = "demo_session_xyz"

# 2. Create Session with Initial State
# Using literal string prefixes for user and session state.
# 'user:' prefix indicates this should be stored at the user level.
# Keys without prefixes are session-level.
initial_user_state = {"user:preferred_language": "en"}
initial_session_state = {"task_status": "started"}
combined_initial_state = {**initial_user_state, **initial_session_state}

# Create the session using the service.
session = session_service.create_session(
    app_name=app_name,
    user_id=user_id,
    session_id=session_id,
    state=combined_initial_state
)
print(f"Initial Session Created. ID: {session.id}")

# Retrieve and print the initial combined state.
# get_session combines session state with user/app state (adding prefixes back).
retrieved_initial = session_service.get_session(app_name, user_id, session_id)
print(f"Initial State Retrieved: {retrieved_initial.state}")
# Expected: {'user:preferred_language': 'en', 'task_status': 'started'}

# 3. Simulate an Agent Turn Updating State via Event
print("\nSimulating agent turn with state updates...")

# Define the changes using literal prefixes, including a custom 'org:' prefix.
current_time = time.time()
state_changes_delta = {
    "task_status": "processing_payment",        # Update session state
    "payment_method": "credit_card",            # Add session state
    "user:preferred_language": "en-US",         # Update user state
    "user:last_activity_ts": current_time,      # Add user state
    "app:api_version": "v2.1",                  # Add/Update app state
    "org:billing_account": "org_acc_123",       # Add custom 'org' scope state
    "temp:intermediate_result": {"a": 1}        # Add temporary state
}

# Package the changes in EventActions.
actions_with_update = EventActions(state_delta=state_changes_delta)

# Create the Event containing the actions and content.
agent_response_event = Event(
    invocation_id="inv_abc",
    author="agent",
    content=Content(parts=[Part(text="Processing your payment...")]),
    actions=actions_with_update,
    timestamp=current_time
)

# *** THE RECOMMENDED WAY TO UPDATE STATE ***
# append_event applies the state_delta to the session and internal storage.
# - BaseSessionService updates the session object's state dict (ignores 'temp:').
# - InMemorySessionService updates its internal app/user stores (handles 'app:'/'user:').
# - Custom prefixes like 'org:' are added to the session's direct state by BaseSessionService
#   but are *not* handled specially by InMemorySessionService's internal stores.
session_service.append_event(session, agent_response_event)
print("`append_event` called with state delta.")


# 4. Retrieve the Session Again to See Updated State
print("\nRetrieving session after state update...")
# get_session merges state again. It retrieves the session's direct state
# (which now includes 'org:billing_account') and merges the app/user state
# from the service's internal stores (adding prefixes back).
retrieved_updated = session_service.get_session(app_name, user_id, session_id)

print(f"\nState After Update Retrieved:")
print(f"  Full State: {retrieved_updated.state}")
# Expected: Session, User, App, and Org states are updated.
# 'temp:intermediate_result' is NOT present.
# 'org:billing_account' IS present because it was added to the session's direct
# state and InMemorySessionService._merge_state includes all keys from the
# session's direct state.
# Expected structure:
# {'task_status': 'processing_payment', 'payment_method': 'credit_card',
#  'org:billing_account': 'org_acc_123', 'user:preferred_language': 'en-US',
#  'user:last_activity_ts': <timestamp>, 'app:api_version': 'v2.1'}


# 5. Inspect Underlying Storage (InMemorySessionService Specific)
print("\nInspecting InMemorySessionService internal storage:")
print(f"  App State for '{app_name}': {session_service.app_state.get(app_name, {})}")
# Expected: {'api_version': 'v2.1'}
print(f"  User State for '{user_id}' in '{app_name}': {session_service.user_state.get(app_name, {}).get(user_id, {})}")
# Expected: {'preferred_language': 'en-US', 'last_activity_ts': <timestamp>}
print(f"  Session State (direct, includes custom scopes): {session_service.sessions[app_name][user_id][session_id].state}")
# Expected: {'task_status': 'processing_payment', 'payment_method': 'credit_card', 'org:billing_account': 'org_acc_123'}
# Note: The custom 'org:' prefix remains part of the key in the session's direct state dict.
```

**Expected Output:**

```
Initial Session Created. ID: demo_session_xyz
Initial State Retrieved: {'user:preferred_language': 'en-US', 'task_status': 'started', 'app:api_version': 'v2.1', 'user:last_activity_ts': 1743628398.429386}

Simulating agent turn with state updates...
`append_event` called with state delta.

Retrieving session after state update...

State After Update Retrieved:
  Full State: {'user:preferred_language': 'en-US', 'task_status': 'processing_payment', 'payment_method': 'credit_card', 'user:last_activity_ts': 1743628432.8992813, 'app:api_version': 'v2.1', 'org:billing_account': 'org_acc_123'}

Inspecting InMemorySessionService internal storage:
  App State for 'state_demo_app': {'api_version': 'v2.1'}
  User State for 'demo_user_123' in 'state_demo_app': {'preferred_language': 'en-US', 'last_activity_ts': 1743628432.8992813}
  Session State (direct, includes custom scopes): {'user:preferred_language': 'en-US', 'task_status': 'processing_payment', 'payment_method': 'credit_card', 'user:last_activity_ts': 1743628432.8992813, 'app:api_version': 'v2.1', 'org:billing_account': 'org_acc_123'}

```