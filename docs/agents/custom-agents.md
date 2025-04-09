!!! warning "Advanced Concept"

    Building custom agents by directly implementing `_run_async_impl` provides powerful control but is more complex than using the predefined `LlmAgent` or standard `WorkflowAgent` types. We recommend understanding those foundational agent types first before tackling custom orchestration logic.

# Custom agents

Custom agents provide the ultimate flexibility in ADK, allowing you to define **arbitrary orchestration logic** by inheriting directly from `BaseAgent` and implementing your own control flow. This goes beyond the predefined patterns of `SequentialAgent`, `LoopAgent`, and `ParallelAgent`, enabling you to build highly specific and complex agentic workflows.

## Introduction: Beyond Predefined Workflows

### What is a Custom Agent?

A Custom Agent is essentially any class you create that inherits from `google.adk.agents.BaseAgent` and implements its core execution logic within the `_run_async_impl` asynchronous method. You have complete control over how this method calls other agents (sub-agents), manages state, and handles events.

### Why Use Them?

While the standard [Workflow Agents](workflow-agents/index.md) (`SequentialAgent`, `LoopAgent`, `ParallelAgent`) cover common orchestration patterns, you'll need a Custom agent when your requirements include:

* **Conditional Logic:** Executing different sub-agents or taking different paths based on runtime conditions or the results of previous steps.
* **Complex State Management:** Implementing intricate logic for maintaining and updating state throughout the workflow beyond simple sequential passing.
* **External Integrations:** Incorporating calls to external APIs, databases, or custom Python libraries directly within the orchestration flow control.
* **Dynamic Agent Selection:** Choosing which sub-agent(s) to run next based on dynamic evaluation of the situation or input.
* **Unique Workflow Patterns:** Implementing orchestration logic that doesn't fit the standard sequential, parallel, or loop structures.

## Implementing Custom Logic:

The heart of any custom agent is the `_run_async_impl` method. This is where you define its unique behavior.

* **Signature:** `async def _run_async_impl(self, ctx: InvocationContext) -> AsyncGenerator[Event, None]:`
* **Asynchronous Generator:** It must be an `async def` function and return an `AsyncGenerator`. This allows it to `yield` events produced by sub-agents or its own logic back to the runner.
* **`ctx` (InvocationContext):** Provides access to crucial runtime information, most importantly `ctx.session.state`, which is the primary way to share data between steps orchestrated by your custom agent.

**Key Capabilities within `_run_async_impl`:**

1. **Calling Sub-Agents:** You invoke sub-agents (which are typically stored as instance attributes like `self.my_llm_agent`) using their `run_async` method and yield their events:

    ```python
    async for event in self.some_sub_agent.run_async(ctx):
        # Optionally inspect or log the event
        yield event # Pass the event up
    ```

2. **Managing State:** Read from and write to the session state dictionary (`ctx.session.state`) to pass data between sub-agent calls or make decisions:
    ```python
    # Read data set by a previous agent
    previous_result = ctx.session.state.get("some_key")

    # Make a decision based on state
    if previous_result == "some_value":
        # ... call a specific sub-agent ...
    else:
        # ... call another sub-agent ...

    # Store a result for a later step (often done via a sub-agent's output_key)
    # ctx.session.state["my_custom_result"] = "calculated_value"
    ```

3. **Implementing Control Flow:** Use standard Python constructs (`if`/`elif`/`else`, `for`/`while` loops, `try`/`except`) to create sophisticated, conditional, or iterative workflows involving your sub-agents.

## Managing Sub-Agents and State

Typically, a custom agent orchestrates other agents (like `LlmAgent`, `LoopAgent`, etc.).

* **Initialization:** You usually pass instances of these sub-agents into your custom agent's `__init__` method and store them as instance attributes (e.g., `self.story_generator = story_generator_instance`). This makes them accessible within `_run_async_impl`.
* **`sub_agents` List:** When initializing the `BaseAgent` using `super().__init__(...)`, you should pass a `sub_agents` list. This list tells the ADK framework about the agents that are part of this custom agent's immediate hierarchy. It's important for framework features like lifecycle management, introspection, and potentially future routing capabilities, even if your `_run_async_impl` calls the agents directly via `self.xxx_agent`. Include the agents that your custom logic directly invokes at the top level.
* **State:** As mentioned, `ctx.session.state` is the standard way sub-agents (especially `LlmAgent`s using `output_key`) communicate results back to the orchestrator and how the orchestrator passes necessary inputs down.

## Design Pattern Example: `StoryFlowAgent`

Let's illustrate the power of custom agents with an example pattern: a multi-stage content generation workflow with conditional logic.

**Goal:** Create a system that generates a story, iteratively refines it through critique and revision, performs final checks, and crucially, *regenerates the story if the final tone check fails*.

**Why Custom?** The core requirement driving the need for a custom agent here is the **conditional regeneration based on the tone check**. Standard workflow agents don't have built-in conditional branching based on the outcome of a sub-agent's task. We need custom Python logic (`if tone == "negative": ...`) within the orchestrator.

---

### Part 1: Simplified custom agent Initialization

We define the `StoryFlowAgent` inheriting from `BaseAgent`. In `__init__`, we store the necessary sub-agents (passed in) as instance attributes and tell the `BaseAgent` framework about the top-level agents this custom agent will directly orchestrate.

```python
# agent.py (Initialization part)
import logging
from typing import AsyncGenerator
from typing_extensions import override

from google.adk.agents import Agent, LlmAgent, BaseAgent, LoopAgent, SequentialAgent
from google.adk.agents.invocation_context import InvocationContext
from google.adk.events import Event

logger = logging.getLogger(__name__)

class StoryFlowAgent(BaseAgent):
    """
    custom agent demonstrating a conditional story generation workflow.
    Illustrates using custom logic to orchestrate LLM, Loop, and Sequential agents.
    """
    # --- Field Declarations for Clarity (Optional but good practice) ---
    story_generator: LlmAgent
    # loop_agent and sequential_agent are created internally but used directly
    loop_agent: LoopAgent
    sequential_agent: SequentialAgent

    model_config = {"arbitrary_types_allowed": True} # Allow agent types

    def __init__(
        self,
        name: str,
        story_generator: LlmAgent, # Generates initial/regenerated story
        critic: LlmAgent,          # Critiques story (used by loop)
        reviser: LlmAgent,         # Revises story (used by loop)
        grammar_check: LlmAgent,   # Checks grammar (used by sequence)
        tone_check: LlmAgent,      # Checks tone (used by sequence)
    ):
        # Store agents needed by _run_async_impl
        self.story_generator = story_generator

        # Create internal workflow agents used by our custom logic
        self.loop_agent = LoopAgent(
            name="CriticReviserLoop", sub_agents=[critic, reviser], max_iterations=2
        )
        self.sequential_agent = SequentialAgent(
            name="PostProcessing", sub_agents=[grammar_check, tone_check]
        )

        # Define the list of agents directly orchestrated by _run_async_impl
        # This list informs the ADK framework.
        framework_sub_agents = [
            self.story_generator,
            self.loop_agent,
            self.sequential_agent,
            # critic, reviser, grammar_check, tone_check are managed *within*
            # the loop_agent and sequential_agent, so not listed here directly.
        ]

        # Initialize BaseAgent, telling it about the direct sub-agents
        super().__init__(
            name=name,
            sub_agents=framework_sub_agents,
            # Pydantic automatically assigns the passed-in agents to the declared fields
            story_generator=story_generator,
            critic=critic, # Still pass these if needed for Pydantic validation/typing
            reviser=reviser,
            grammar_check=grammar_check,
            tone_check=tone_check,
        )

```

---

### Part 2: Defining the Custom Execution Logic

This method orchestrates the sub-agents using standard Python async/await and control flow.

```python
# agent.py (_run_async_impl part, inside StoryFlowAgent class)

    @override
    async def _run_async_impl(
        self, ctx: InvocationContext
    ) -> AsyncGenerator[Event, None]:
        """Implements the custom story workflow logic."""
        logger.info(f"[{self.name}] Starting story generation workflow.")

        # --- Step 1: Initial Story Generation ---
        logger.info(f"[{self.name}] Running StoryGenerator...")
        async for event in self.story_generator.run_async(ctx):
            yield event # Pass events up

        # Check state: Ensure story was generated before proceeding
        if "current_story" not in ctx.session.state or not ctx.session.state["current_story"]:
             logger.error(f"[{self.name}] Failed to generate initial story. Aborting.")
             return

        # --- Step 2: Critic-Reviser Loop ---
        # Use the pre-configured LoopAgent instance
        logger.info(f"[{self.name}] Running CriticReviserLoop...")
        async for event in self.loop_agent.run_async(ctx):
            yield event

        # --- Step 3: Sequential Post-Processing ---
        # Use the pre-configured SequentialAgent instance
        logger.info(f"[{self.name}] Running PostProcessing (Grammar & Tone)...")
        async for event in self.sequential_agent.run_async(ctx):
            yield event

        # --- Step 4: Conditional Logic based on Tone Check ---
        # Read the result stored in state by the 'tone_check' agent
        tone_check_result = ctx.session.state.get("tone_check_result")
        logger.info(f"[{self.name}] Tone check result: {tone_check_result}")

        if str(tone_check_result).strip().lower() == "negative": # Check tone
            logger.warning(f"[{self.name}] Tone is negative. Regenerating story...")
            # Re-run the story generator if tone is negative
            async for event in self.story_generator.run_async(ctx):
                 yield event
        else:
            logger.info(f"[{self.name}] Tone is acceptable. Keeping current story.")
            # Optionally yield a final status event here if needed

        logger.info(f"[{self.name}] Workflow finished.")

```

**Explanation of Logic:**

1. The initial `story_generator` runs. Its output is expected to be in `ctx.session.state["current_story"]`.
2. The `loop_agent` runs, which internally calls the `critic` and `reviser` sequentially for `max_iterations` times. They read/write `current_story` and `criticism` from/to the state.
3. The `sequential_agent` runs, calling `grammar_check` then `tone_check`, reading `current_story` and writing `grammar_suggestions` and `tone_check_result` to the state.
4. **Custom Part:** The `if` statement checks the `tone_check_result` from the state. If it's "negative", the `story_generator` is called *again*, overwriting the `current_story` in the state. Otherwise, the flow ends.

---

### Part 3: Defining the LLM Sub-Agents

These are standard `LlmAgent` definitions, responsible for specific tasks. Their `output_key` parameter is crucial for placing results into the `session.state` where other agents or the custom orchestrator can access them.

```python
# agent.py (LLM Agent Definitions part)

GEMINI_FLASH = "gemini-2.0-flash-exp" # Define model constant

story_generator = LlmAgent(
    name="StoryGenerator", model=GEMINI_FLASH,
    instruction="Write a short story (~100 words) about the topic in state['topic'].",
    output_key="current_story",
)

critic = LlmAgent(
    name="Critic", model=GEMINI_FLASH,
    instruction="Review the story in state['current_story']. Provide 1-2 sentences of constructive criticism.",
    output_key="criticism",
)

reviser = LlmAgent(
    name="Reviser", model=GEMINI_FLASH,
    instruction="Revise the story in state['current_story'] based on criticism in state['criticism']. Output only the revised story.",
    output_key="current_story", # Overwrites previous story
)

grammar_check = LlmAgent(
    name="GrammarCheck", model=GEMINI_FLASH,
    instruction="Check grammar of story in state['current_story']. Output corrections or 'Grammar is good!'.",
    output_key="grammar_suggestions",
)

tone_check = LlmAgent(
    name="ToneCheck", model=GEMINI_FLASH,
    instruction="Analyze tone of story in state['current_story']. Output one word: 'positive', 'negative', or 'neutral'.",
    output_key="tone_check_result", # Crucial for conditional logic
)
```

---

### Part 4: Instantiating and Running the custom agent

Finally, you instantiate your `StoryFlowAgent` and use the `Runner` as usual.

```python
# agent.py (Instantiation and Runner Setup part)
from google.adk.sessions import InMemorySessionService
from google.adk.runners import Runner
from google.genai import types
import asyncio # Import asyncio

# Create the custom agent instance, passing in the LLM agents
story_flow_agent = StoryFlowAgent(
    name="StoryFlowOrchestrator", # Give the orchestrator a distinct name
    story_generator=story_generator,
    critic=critic,
    reviser=reviser,
    grammar_check=grammar_check,
    tone_check=tone_check,
)

# --- Setup Runner and Session (Example) ---
async def run_story_agent():
    session_service = InMemorySessionService()
    initial_state = {"topic": "a curious squirrel discovering sunglasses"}
    session_id = "story_session_001"
    user_id = "user_abc"
    app_name = "story_creator_app"

    session = session_service.create_session(
        app_name=app_name, user_id=user_id, session_id=session_id, state=initial_state
    )
    logger.info(f"Initial session state: {session.state}")

    runner = Runner(
        agent=story_flow_agent, # Use the custom orchestrator agent
        app_name=app_name,
        session_service=session_service
    )

    # Trigger the agent (content here is just a trigger, actual topic is in state)
    start_content = types.Content(role='user', parts=[types.Part(text="Start story flow.")])
    events = []
    async for event in runner.run_async(user_id=user_id, session_id=session_id, new_message=start_content):
         events.append(event)
         # You can inspect events here as they are yielded

    print("\n--- Agent Workflow Complete ---")
    final_session = session_service.get_session(app_name, user_id, session_id)
    print("Final Session State:")
    import json
    print(json.dumps(final_session.state, indent=2))
    print("-----------------------------\n")

if __name__ == "__main__":
    logging.basicConfig(level=logging.INFO) # Ensure logging is configured
    asyncio.run(run_story_agent())

```

*(Note: The full runnable code, including imports and execution logic, can be found linked below.)*

---

## Full Code Example

```python
# Full runnable code for the StoryFlowAgent example
--8<-- "examples/python/snippets/agents/custom-agent/storyflow-agent.py"
```