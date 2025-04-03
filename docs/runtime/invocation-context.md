# What is `InvocationContext`? 

Think of the `InvocationContext` as the **"briefcase" or "backpack"** that an agent carries with it during a single job or task run. In ADK, this "job" starts when a user sends a message and ends when the agent provides its final response for that specific interaction. This entire cycle is called an **invocation**.

* **Purpose:** The `InvocationContext` holds all the essential information and connections the agent needs to do its work *during that specific invocation*. It bundles together session data, details about the current agent, the user's original request, and links to important services like storage.  
* **Lifecycle:** You don't usually create an `InvocationContext` yourself. When you start an agent run using the `Runner` (e.g., `runner.run_async(...)`), the `Runner` automatically creates a unique `InvocationContext` for that specific run. This context object is then passed along automatically as the agent executes, potentially transferring between different agents within the same invocation.

```py
# Conceptual: Runner creates and passes the context
# (You don't write this code, it happens internally)

# runner = Runner(...)
# user_message = types.Content(...)
# session = session_service.get_session(...)
# artifact_service = ...

# Internal Runner Logic:
# ctx = InvocationContext(
#     invocation_id=new_invocation_context_id(),
#     session=session,
#     user_content=user_message,
#     agent=root_agent, # Starting agent
#     session_service=session_service,
#     artifact_service=artifact_service,
#     # ... other fields ...
# )
# # Pass 'ctx' to the agent's run method
# await root_agent.run_async(ctx)
```

Essentially, it's the container holding everything relevant for the current task run, passed implicitly where needed.

# What's Inside? (The Essentials)

The `InvocationContext` (often referred to as `ctx` in agent code) contains several useful attributes. Here are the most important ones you'll likely interact with:

1. **`session` (`Session`)**: **This is the most crucial part\!** It's your direct link to the current conversation session (`google.adk.sessions.session.py`). Through `ctx.session`, you access:  
     
   * **`session.state` (`dict[str, Any]`):** The shared dictionary holding data that persists across different steps or agent turns *within this invocation* (and potentially across invocations if using a persistent `SessionService`). This is the primary way agents share information passively.  
   * **`session.events` (`list[Event]`):** The history of all events that have occurred in this session so far. Useful for context or debugging.  
   * Other session details like `session.id`, `session.user_id`, `session.app_name`.

```py
# Conceptual: Accessing session state via context
# (Inside an agent's _run_async_impl(self, ctx: InvocationContext))

# Read from state
user_pref = ctx.session.state.get("user_preference", "default_value")
print(f"User preference found in state: {user_pref}")

# Write to state (changes are tracked automatically)
ctx.session.state["last_action"] = "processed_data"
print("Updated 'last_action' in session state.")
```

2. **`agent` (`BaseAgent`)**: A direct reference to the specific agent instance that is *currently executing*. This is useful if the agent needs to know its own name or description dynamically.

```py
# Conceptual: Accessing the current agent's info
# (Inside an agent's _run_async_impl(self, ctx: InvocationContext))

my_name = ctx.agent.name
my_description = ctx.agent.description
print(f"Currently running agent: {my_name}")
```

3. **`invocation_id` (`str`)**: A unique identifier string created specifically for this single run (from user message to final response). It helps distinguish this run from any other runs, even within the same session. Very useful for logging and tracing requests across different agents or system components.

```py
# Conceptual: Using the invocation ID
# (Inside an agent's _run_async_impl(self, ctx: InvocationContext))

print(f"Logging for Invocation ID: {ctx.invocation_id} - Agent {ctx.agent.name} starting.")
```

4. **`user_content` (`Optional[types.Content]`)**: The original `types.Content` object representing the user's message that initiated *this specific invocation*. Useful if an agent needs to refer back to the exact initial trigger for the current task.

```py
# Conceptual: Accessing the initial user message
# (Inside an agent's _run_async_impl(self, ctx: InvocationContext))

if ctx.user_content and ctx.user_content.parts:
    initial_query = ctx.user_content.parts[0].text
    print(f"This run was triggered by user message: '{initial_query}'")
```

5. **Services (`session_service`, `artifact_service`, `memory_service`)**: References to the service instances configured in the `Runner`. These allow the agent (or more commonly, callbacks and tools via their specific contexts) to interact with external systems like session storage, artifact storage (e.g., `InMemoryArtifactService`, `GcsArtifactService`), or long-term memory.

```py
# Conceptual: Checking if services are available
# (Inside an agent's _run_async_impl(self, ctx: InvocationContext))

if ctx.artifact_service:
    print("Artifact service is configured for this run.")
else:
    print("Artifact service is *not* configured.")

# Note: Direct interaction with services usually happens via
# context objects in callbacks/tools (e.g., context.save_artifact),
# which internally use ctx.artifact_service.
```

While there are other fields, these are the core components you'll leverage most often when building agents that need context, shared data, or access to framework services. The `session` attribute, in particular, is fundamental for communication and state management between agent steps.

# How Do You Use It?

You'll interact with the information held in `InvocationContext` in two main ways:

## 1\. Directly in Agent Implementation:

When you define the core logic of your custom agent by overriding the `_run_async_impl` (or `_run_live_impl`) method, the framework automatically passes the `InvocationContext` object as the `ctx` argument.

```py
from google.adk.agents import BaseAgent, InvocationContext
from google.adk.events import Event
from google.genai import types
from typing import AsyncGenerator
from typing_extensions import override

class MyCustomAgent(BaseAgent):
    @override
    async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:
        # --- Direct access using 'ctx' ---

        # Get my own name
        my_name = ctx.agent.name
        print(f"Agent '{my_name}' starting work for invocation {ctx.invocation_id}.")

        # Read something from shared session state
        previous_step_result = ctx.session.state.get("result_from_previous_agent")
        if previous_step_result:
            print(f"Found previous result in state: {previous_step_result}")
        else:
            print("No previous result found in state.")

        # Refer to the initial user query
        if ctx.user_content and ctx.user_content.parts:
             initial_query = ctx.user_content.parts[0].text
             print(f"Remembering the initial query was: '{initial_query}'")

        # Perform work and maybe update state
        processed_value = "my_processed_value_123"
        ctx.session.state["my_custom_agent_output"] = processed_value # Write to state

        # Yield an event
        yield Event(
            author=my_name,
            invocation_id=ctx.invocation_id,
            content=types.Content(parts=[types.Part(text=f"Finished processing, saved '{processed_value}' to state.")])
        )
```

## 2\. Indirectly via Callback & Tool Contexts:

When you write callback functions (like `before_agent_callback`, `after_model_callback`, `before_tool_callback`, etc.) or the functions backing your tools, you don't receive the `InvocationContext` directly. Instead, you receive a specialized context object:

* `CallbackContext` (`google.adk.agents.callback_context.py`): For agent and model callbacks.  
* `ToolContext` (`google.adk.agents.tool_context.py`): For tool callbacks (inherits from `CallbackContext`).

These specialized contexts (`callback_context` or `tool_context`) internally hold a reference to the main `InvocationContext`. They provide convenient, higher-level methods or direct access to the most commonly needed parts, especially `state` and artifact methods.

```py
from google.adk.agents import CallbackContext, ToolContext
from google.adk.models import LlmRequest
from google.adk.tools import BaseTool
from google.genai import types
from typing import Optional, Dict, Any

# --- Example: In a Callback ---
def my_before_model_callback(callback_context: CallbackContext, llm_request: LlmRequest) -> Optional[None]:
    # Accessing state via CallbackContext
    user_name = callback_context.state.get("user_name", "Guest")
    print(f"[Callback] Modifying request for user: {user_name}")

    # Modify request based on state (ctx.session.state is accessed implicitly)
    # llm_request.config.system_instruction += f"\nUser's name is {user_name}."

    # Accessing invocation ID via CallbackContext
    print(f"[Callback] Processing invocation: {callback_context.invocation_id}")

    # Saving an artifact (uses ctx.artifact_service implicitly)
    # try:
    #     log_part = types.Part.from_data(b"Log data", "text/plain")
    #     callback_context.save_artifact("callback_log.txt", log_part)
    # except ValueError:
    #     print("[Callback] Artifact service not configured.")

    return None # Allow LLM call to proceed


# --- Example: In a Tool Function ---
def my_tool_function(query: str, tool_context: ToolContext) -> Dict[str, Any]:
    # Accessing state via ToolContext
    api_key = tool_context.state.get("user_api_key")
    if not api_key:
        # Requesting credentials (uses ToolContext specific method)
        # tool_context.request_credential(...)
        return {"error": "API key not found in state."}

    # Accessing user ID via ToolContext (inherited from CallbackContext)
    user_id = tool_context.user_id
    print(f"[Tool] Executing for user {user_id} with query: {query}")

    # Loading an artifact (uses ctx.artifact_service implicitly)
    # config_artifact = tool_context.load_artifact("user:tool_config.json")
    # if config_artifact:
    #     # process config_artifact.inline_data.data
    #     pass

    # Execute tool logic using api_key...
    result = f"Processed '{query}' for user {user_id}"
    return {"result": result}

```

So, while `InvocationContext` is the central carrier, your direct interaction point is often the `ctx` in agents or the `callback_context`/`tool_context` in callbacks and tools, which provide managed access to the underlying invocation's data and services.

# Other Fields

The `InvocationContext` contains a few other fields tailored for more specific or advanced scenarios. You generally won't need these when starting out, but it's good to know they exist:

* **`branch` (`Optional[str]`):** Used internally, primarily by `ParallelAgent`, to track execution paths when running multiple agents concurrently. Helps potentially isolate conversation history in complex flows.  
* **`streaming` (`StreamingMode`):** Indicates if the current run is operating in a streaming mode (like Server-Sent Events or Bidirectional).  
* **`live_request_queue` (`Optional[LiveRequestQueue]`):** Used in bidirectional streaming (`StreamingMode.BIDI`) to receive incoming requests (like audio chunks or user interruptions) during an active agent run.  
* **`active_streaming_tools` (`Optional[dict[str, ActiveStreamingTool]]`):** Keeps track of tools that are currently processing a stream of data in live mode.  
* **`response_modalities` (`Optional[list[str]]`):** Specifies the expected output types (e.g., audio, video) for live/streaming runs.  
* **`support_cfc` (`bool`):** Flag related to supporting Compositional Function Calling in specific streaming modes.  
* **`transcription_cache` (`Optional[list[TranscriptionEntry]]`):** Internal cache used for audio transcription in live mode.  
* **`end_invocation` (`bool`):** A flag that can be set (usually by callbacks or tools) to signal that the entire invocation should terminate prematurely, stopping further processing.

**Don't worry about these advanced fields initially.** Focus on using `ctx.session.state`, `ctx.agent`, `ctx.invocation_id`, and leveraging the methods on `CallbackContext`/`ToolContext` for state and artifact management. You can explore the other fields if you delve into real-time streaming or complex parallel execution patterns later.  