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

<p style="text-align:center;"> Agent Development Kit (ADK) is an
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
  <a href="get-started/tutorial/" class="md-button">Tutorial</a>
  <a href="http://github.com/google/adk-samples" class="md-button" target="_blank">Sample Agents</a>
  <a href="api-reference/" class="md-button">API Reference</a>
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

-   :material-transit-connection-variant: **Flexible Orchestration**

    ---

    Define workflows using workflow agents (`Sequential`, `Parallel`, `Loop`)
    for predictable pipelines, or leverage LLM-driven dynamic routing
    (`LlmAgent` transfer) for adaptive behavior.

    [**Learn about agents**](agents/index.md)

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

    [**Browse tools**](tools/index.md)

-   :material-rocket-launch-outline: **Deployment Ready**

    ---

    Containerize and deploy your agents anywhere – run locally, scale with
    Vertex AI Agent Engine, or integrate into custom infrastructure using Cloud
    Run or Docker.

    [**Deploy agents**](deploy/index.md)

-   :material-clipboard-check-outline: **Built-in Evaluation**

    ---

    Systematically assess agent performance by evaluating both the final
    response quality and the step-by-step execution trajectory against
    predefined test cases.

    [**Evaluate agents**](guides/evaluate-agents.md)

-   :material-console-line: **Building Responsible Agents**

    ---

    Learn how to building powerful and trustworthy agents by implementing
    responsible AI patterns and best practices into your agent's design.

    [**Responsible agents**](guides/responsible-agents.md)

</div>

<div class="footer"></div>
