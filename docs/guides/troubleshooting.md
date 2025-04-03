This page helps you diagnose and resolve common issues when working with the
Agent Development Kit (ADK).

### On this page:

- [Installation and Setup](#installation-and-setup)
- [Agent Definition Issues](#agent-definition-issues)
- [Execution Problems](#execution-problems)
- [Evaluation Issues](#evaluation-issues)
- [Common Error Messages](#common-error-messages) (Optional)

<h2 id="installation-and-setup">Installation and Setup</h2>

**Common Problems:** Installation failures, import errors, API authentication
issues.

**Check:**

- Python & pip versions
- `.whl` file integrity & path
- `.env` file configuration (API keys, project details)
- `gcloud auth` setup (for Vertex AI)
- Dependency installation (`requirements.txt`)
- Virtual environment activation

<h2 id="agent-definition-issues">Agent Definition Issues</h2>

**Common Problems:** Agent not behaving as expected, tools not called, errors in
`agent.py`.

**Check:**

- `agent.py` code syntax (linting)
- Agent `instruction` clarity and correctness
- Tool definitions (names, descriptions, parameters)
- Agent attributes (`name`, `model`, `tools`, `flow`) - typos, validity
- Code logic within `agent.py` - use print statements for debugging

<h2 id="execution-problems">Execution Problems</h2>

**Common Problems:** CLI commands failing (`adk run`, `adk web`, `adk test`), Web
UI errors, API server issues.

**Check:**

- CLI command syntax and arguments (`--help`)
- Working directory (agent project root)
- Terminal error messages (copy full errors)
- Port conflicts (for Web UI/API Server - try different ports)
- Browser compatibility (for Web UI)
- Browser console errors (for Web UI)

<h2 id="evaluation-issues">Evaluation Issues</h2>

**Common Problems:** Test failures, unexpected evaluation results.

**Check:**

- `*.test.json` file syntax (valid JSON)
- Test file content (queries, `expected_tool_use`, `reference` accuracy)
- File paths in `adk test` command or `pytest` code
- Evaluation criteria in `test_config.json` (if used)
- Run tests in Web UI for visual feedback

<h2 id="common-error-messages">Common Error Messages</h2>

- Installation issue
- API key or auth problem
- Incorrect `model` attribute
- Port conflict on web/API server

**General Troubleshooting Tips:**

*   Simplify and Isolate: Start simple, add complexity gradually.
*   Check Logs: Terminal, Cloud Logging, Browser Console.
*   Refer to Documentation: Re-read relevant sections.
*   Search Online: Stack Overflow, forums.
*   Provide Detailed Info When Asking for Help: Code, errors, steps,
    environment.
