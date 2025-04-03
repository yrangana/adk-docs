# Agents

This document explains what Agents are, the types of Agents, including those
powered by LLMs and non-LLM controllers, and their collaborative capabilities.

<img src="../../assets/agent-types.png" alt="Types of agents in Agent Development Kit">

## What is an Agent?

Agents are the **core building blocks** for executing specific tasks. Consider
an agent to be a **self-contained execution unit** that can perform tasks,
interact with users, utilize external tools, and coordinate with other agents.

The foundation for all agents is the `BaseAgent` class. This class acts as a
general template or blueprint. You can create specific types of agents by
extending this `BaseAgent`. There are three main ways to do this:

1. **LLM Agents (`LlmAgent`):** These agents use Large Language Models (LLMs) as
   their "brains." They can reason, plan, use tools, and collaborate to achieve
   goals, even on complex tasks.

2. **Non-LLM Agents (e.g., `SequentialAgent`, `ParallelAgent`, `LoopAgent`):**
   These agents *don't* rely on LLMs. Instead, they are designed to manage how
   multiple agents work together, creating workflows. Examples include agents
   that execute tasks in sequence, in parallel, or in loops.

3. **Custom Agents:** If the existing agent types (LLM or Non-LLM) don't fit
   your needs, you can create your own custom agent. You do this by extending
   the `BaseAgent` class and implementing your own specific logic and workflows.

This means that developers can create intricate multi-agent systems that can
handle complex tasks and interact meaningfully with users by combining these
agent types and configuring their behavior through instructions, tools, and
defined flows all defined through the `BaseAgent.`

Let's explore these agent types in greater detail.

## 1. LLM-based Agents

`LlmAgent` is a subclass of BaseAgent that leverages a Large Language Model (LLM) to process input and generate responses. It's the workhorse for handling natural language interactions.

LLM-based Agents are the "brains" of your application, bringing intelligence and adaptability to your system. They leverage the capabilities of Large Language Models to understand and respond to natural language, make decisions, and utilize tools effectively.

**Key Capabilities of LLM-based Agents**

* **Instruction Following (Reasoning):** They are designed to understand and execute instructions given in natural language. This makes them highly flexible and easy to program.
* **Tool Use:** They can intelligently decide when and how to use available tools to accomplish their tasks. This allows them to interact with the real world and access external information.
    **Example:** An agent instructed to "Write a blog post about the latest advancements in AI" could use a search engine tool to research recent publications and news articles before generating the blog post.
* **Agent Transfer (Routing)**
When an `LlmAgent` is configured with child agents and the `allow_transfer=True` flag (which is the default), it can act as an intelligent router. Based on the current conversation and the descriptions of its child agents, the parent agent uses its reasoning ability to automatically determine which child is best suited for the current sub-task and delegates the work accordingly. **Example:**
      *   A top-level "Customer Support Agent" is configured with child agents: "Billing Agent," "Technical Support Agent," and "Sales Inquiry Agent."
      *   When a user asks, "I think I was overcharged last month," the "Customer Support Agent" (using Auto Flow) analyzes the query and routes the conversation to the "Billing Agent" because its description indicates expertise in billing matters.

* **Workflow Execution:** LLM-based agents often lead to **non-deterministic workflow execution**. This means that the exact path the agent takes to complete a task might vary each time, depending on the specific instructions, the data it encounters, and the LLM's reasoning process. This flexibility is a strength, but it also means the outcome might not always be predictable in every detail.

## 2. Non-LLM Agents (Controller Agents)

Non-LLM Agents, are the "managers" within your application. They are designed to control the flow of execution between other agents, including LLM-based agents. They are not powered by LLMs directly for their core function but act as directors, ensuring tasks are performed in the desired sequence and under specific conditions.

**Types of Non-LLM Agents:**

* **`SequentialAgent` (Sequential Execution):** They can execute a predefined list of agents one after another in a specific order. This is useful for tasks that have a linear flow.
  * **Example:** A workflow to "Process a new order" might sequentially execute: "Order Validation Agent" \-\> "Inventory Check Agent" \-\> "Payment Processing Agent" \-\> "Order Confirmation Agent."

* **`LoopAgent` (Looping):** They can repeatedly execute a set of agents until a certain condition is met. This is helpful for tasks that require iteration or continuous monitoring.
  * **Example:** A "Data Monitoring Agent" might loop through a set of "Data Analysis Agents" every hour to check for anomalies in different datasets.

* **`ParallelAgent` (Parallel Execution):** They can run multiple agents simultaneously. This can significantly speed up tasks that can be broken down into independent sub-tasks.
  * **Example:** To "Generate reports for multiple regions," a Non-LLM agent could execute several "Report Generation Agents" in parallel, each responsible for a different region.

**Workflow Execution:** Non-LLM agents typically result in **deterministic workflow execution**. This means that for a given input and configuration, the sequence of agents executed will always be the same. This predictability is valuable for structured processes where consistent and reliable execution is crucial.

## 3. Custom Agents

* **`Custom Agent` (Custom Logic):** You can extend the `BaseAgent` to implement your own custom control flow logic. The custom agent can have ***both*** the components of an LLM or non-LLM agents.
  This allows you to create complex and highly tailored workflows based on specific application requirements. This could involve conditional branching, error handling, or integration with external systems to determine the next steps in the workflow.
  * **Example:** A "Document Processing Agent" might use custom logic to:
    * First, send a document to a "Language Detection Agent."
    * Based on the detected language, route it to a specific "Translation Agent."
    * After translation, send it to a "Summarization Agent."

## Choosing the Right Agent Type

| Feature | LLM-based Agent (Reasoning Agent) | Non-LLM Agent (Controller/Orchestrator Agent) |
| :---- | :---- | :---- |
| **Primary Function** | Reasoning, natural language processing, generation, tool use | Managing workflow, controlling agent execution sequence |
| **Uses LLM Directly?** | Yes, at its core | No, primarily controls other agents |
| **Workflow Execution** | Non-deterministic (flexible, adaptable) | Deterministic (predictable, structured) |
| **Key Capabilities** | Instruction following, tool use, agent transfer, dynamic routing | Sequential, loop, parallel, custom logic execution |
| **Best Suited For** | Tasks requiring understanding language, creative problem solving, tool interaction, dynamic decision making | Structured workflows, complex process orchestration, reliable and predictable task sequences |
| **"Thinking" vs. "Organizing"** | Handles the "thinking" and reasoning steps | Handles the "organizing" and workflow management |

**Note:** In many powerful applications (especially multi-agent architectures), you will use **all types of agents in combination**. LLM-based agents excel at handling individual tasks that require intelligence and flexibility, while Non-LLM agents provide the structure and control to orchestrate these tasks into complex, reliable systems. Think of it as using LLM agents for the smart "work" and Non-LLM agents to manage the overall "process."
