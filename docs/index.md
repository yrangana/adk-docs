---
hide:
  - toc
---

<div style="text-align: center;">
  <div class="centered-logo-text-group">
    <img src="assets/agent-development-kit.png" alt="Agent Development Kit Logo" width="100">
    <h1>Agent Development Kit</h1>
  </div>
</div>

<p style="text-align:center; font-size: 1.2em;">
  <b>Build, evaluate, and deploy sophisticated AI agents with code-first flexibility!</b>
</p>

<p style="text-align:center;"> The Agent Development Kit (ADK) is an
open-source, code-first Python toolkit designed to simplify building,
evaluating, and deploying advanced AI agents anywhere. It's designed for
developers building AI applications or teams needing to rapidly prototype and
deploy robust agent-based solutions.</p>

<div class="install-command-container">
  <p style="text-align:center;">
    Get started:
    <br/>
    <code>pip install google-adk</code>
  </p>
</div>

<p style="text-align:center;">
  <a href="get-started/quickstart/" class="md-button">Quickstart</a>
  <a href="http://github.com/google/adk-samples" class="md-button">Sample agents</a>
  <a href="reference/" class="md-button">API reference</a>
</p>

<!-- [TODO: Placeholder for diagram] -->

---

## Why Agent Development Kit?

ADK empowers developers seeking control and flexibility. Based on Google's
internal best practices for production agents, it prioritizes a seamless
developer experience integrated with standard coding workflows. Define agent
behavior, orchestration, and tool use directly in Python, enabling robust
debugging, versioning, and deployment.

<div class="grid cards" markdown>

-   :material-graph: **Multi-Agent Architecture**

    ---

    Build modular and scalable applications by composing multiple specialized
    agents in a hierarchy. Enable complex coordination and delegation.

    [**Explore multi-agent systems**](agents/multi-agents.md)

-   :material-toolbox-outline: **Rich Tool Ecosystem**

    ---

    Equip agents with diverse capabilities: use pre-built tools (Search, Code
    Exec), create custom functions, integrate 3rd-party libraries (LangChain,
    CrewAI), or even use other agents as tools.

    [**Browse tools**](tools/overview.md)

-   :material-transit-connection-variant: **Flexible Orchestration**

    ---

    Define workflows using container agents (`Sequential`, `Parallel`, `Loop`)
    for predictable pipelines, or leverage LLM-driven dynamic routing
    (`LlmAgent` transfer) for adaptive behavior.

    [**Learn about agents**](agents/overview.md)

-   :material-console-line: **Integrated Developer Experience**

    ---

    Develop, test, and debug locally with a powerful CLI and a visual Web UI.
    Inspect events, state, and agent execution step-by-step.

    [**Running your agent**](get-started/running-the-agent.md)

-   :material-clipboard-check-outline: **Built-in Evaluation**

    ---

    Systematically assess agent performance by evaluating both the final
    response quality and the step-by-step execution trajectory against
    predefined test cases.

    [**Evaluate agents**](guides/evaluate-agents.md)

-   :material-rocket-launch-outline: **Deployment Ready**

    ---

    Containerize and deploy your agents anywhere – run locally, scale with
    Vertex AI Agent Engine, or integrate into custom infrastructure using Cloud
    Run or Docker.

    [**Deploy agents**](deploy/overview.md)

</div>

<div class="footer"></div>
