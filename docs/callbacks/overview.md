# Callbacks

## What are Callbacks?

Callbacks are a fundamental mechanism within the Agent Development Kit that allows you to extend and customize the behavior of your agents. They provide powerful hooks into the agent's execution lifecycle, enabling you to observe, modify, or augment the agent's operations without altering the core agent class logic directly.

At their core, callbacks are Python functions that you define and then register with **an agent**. The framework automatically invokes these functions at specific, predefined points during an agent's run. Think of them as designated interception or interrupt points where you can inject your custom code.

[TODO: Placeholder for diagram]

For example, you can define a function to run:

* Just before the agent starts its processing logic (`before_agent_callback`).
* Right after the agent finishes its processing (`after_agent_callback`).
* Immediately before a request is sent to the Large Language Model (LLM) (`before_model_callback`).
* Immediately after a response is received from the LLM (`after_model_callback`).
* Just before a specific tool (like a function or another agent) is executed (`before_tool_callback`).
* Right after a tool finishes execution (`after_tool_callback`).

When the framework reaches one of these points, it checks if a corresponding callback function has been provided for the current agent and executes it, passing relevant contextual information.

## Why Use Callbacks?

Callbacks unlock a wide range of possibilities for enhancing your agents:

1. **Customize & Control:** Modify requests/responses or bypass LLM calls entirely with custom logic.
2. **Implement Guardrails:** Check prompts or validate tool inputs before execution to enforce safety and rules.
3. **Enhance Observability:** Log detailed information at key stages for easier debugging and monitoring.
4. **Manage State Dynamically:** Read from or write to the agent's session state during execution.
5. **Integrate External Systems:** Trigger actions like API calls, database updates, or notifications.
6. **Optimize with Caching:** Avoid redundant LLM/tool calls by returning cached results.

By strategically implementing callbacks, you can build more sophisticated, robust, observable, and tailored agentic applications using the ADK. They provide the flexibility to inject custom logic precisely where it's needed within the framework's defined execution flow.

# Context Objects

When the framework calls your callback function, it doesn't just run it in isolation. It passes special **context objects** as arguments. These objects are your callback's way to access information about the current agent run and interact with the framework.

There are two main context objects: `CallbackContext` and `ToolContext`.

## CallbackContext

This context object is passed to the agent lifecycle callbacks (`before_agent_callback`, `after_agent_callback`) and the model interaction callbacks (`before_model_callback`, `after_model_callback`).

It provides access to:

* **Read-only Invocation Info:**

  * `invocation_id` (str): Unique ID for the entire user request-response cycle.
  * `agent_name` (str): Name of the agent whose callback is running.
  * `user_content` (Optional\[types.Content\]): The user's message that started this invocation.
  * `session_id`, `app_name`, `user_id`: Via inherited properties.


* **Mutable Session State:**

  * `state` (State): This property lets you read and **modify** the current session's state dictionary. Changes made here are automatically tracked and saved by the framework.

```py
# Example: Modifying state in a callback
def my_stateful_callback(callback_context: CallbackContext):
    current_count = callback_context.state.get("visit_count", 0)
    callback_context.state["visit_count"] = current_count + 1 # Modify state
    print(f"Callback updated visit_count in state to: {callback_context.state['visit_count']}")

    # Check if state was changed within this callback instance
    if callback_context.state.has_delta():
         print("State delta detected.")
```

* **Artifact Management (if `artifact_service` is configured):**

  * `load_artifact(filename, version=None)`: Loads a file associated with the session.
  * `save_artifact(filename, artifact)`: Saves a file (as a `types.Part`) and associates it with the session. The framework records this action.

```py
# Example: Saving an artifact in a callback
from google.genai import types

def my_artifact_saver(callback_context: CallbackContext):
    try:
        # Assume 'my_data_part' is a types.Part containing your artifact data
        my_data_part = types.Part(text="This is artifact content.") # Simplified example
        version = callback_context.save_artifact("report.txt", my_data_part)
        print(f"Callback saved artifact 'report.txt' as version {version}")
    except ValueError as e:
        print(f"Callback artifact error: {e}") # e.g., if artifact_service isn't available
```

## ToolContext

This context object is passed specifically to the tool execution callbacks (`before_tool_callback`, `after_tool_callback`). It **inherits everything** from `CallbackContext` and adds information and capabilities relevant only during tool execution.

**Additional `ToolContext` Capabilities:**

* `function_call_id` (Optional\[str\]): The specific ID of the LLM's request to call this tool.
* `actions` (EventActions): Direct access to the `EventActions` object for the current step. This allows fine-grained control, like skipping the LLM summary after a tool runs.

```py
# Example: Skipping summarization in after_tool_callback
def my_tool_finisher(tool, args, tool_context: ToolContext, tool_response):
    # If the tool result is simple, tell the LLM not to summarize it
    if len(str(tool_response)) < 50:
         print("Tool result is short, skipping summarization.")
         tool_context.actions.skip_summarization = True
    return None # Use original tool_response
```

* **Authentication Flow:**
  * `request_credential(auth_config)`: Used within `before_tool_callback` to signal that the tool requires user authentication before it can run.
  * `get_auth_response()`: Retrieves the credentials provided by the user/client if `request_credential` was previously called for this tool invocation.
* **Other Contextual Data Access (if services are configured):**
  * `list_artifacts()`: Lists all artifact filenames for the current session.
  * `search_memory(query)`: Searches the user's memory via the `memory_service`.

By understanding which context object your callback receives and what properties/methods it offers, you can effectively hook into the ADK's execution flow to build more powerful and customized agents.
