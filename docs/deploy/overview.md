<div style="background-color: #def0da; color: #64946D; padding: 16px 24px;">
<!--TODO: remove div before launch-->
 <div style="font-size: 16px; font-weight: bold;">🔎 Ready for internal review: <a href="https://b.corp.google.com/issues/new?component=1685338&template=2111831&assignee=polong@google.com">Report bugs here</a></div>
</div>

# Deploying Your Agent

Once you've built and tested your agent using the Agent Development Kit (ADK),
the next step is to deploy it so it can be accessed, queried, and used in
production or integrated with other applications. Deployment moves your agent
from your local development machine to a scalable and reliable environment.

<img src="../../assets/deploy-agent.png" alt="Deploying your agent">

## Deployment Options

Your ADK agent can be deployed to a range of different environments based
on your needs for production readiness or custom flexibility:

### Agent Engine in Vertex AI

[Agent Engine](agent-engine.md) is a fully managed auto-scaling service on Google Cloud
specifically designed for deploying, managing, and scaling AI agents built with
frameworks such as ADK.

Learn more about [deploying your agent to Vertex AI Agent Engine](agent-engine.md).

### Cloud Run

[Cloud Run](https://cloud.google.com/run) is a managed auto-scaling compute platform on
Google Cloud that enables you to run your agent as a container-based
application.

Learn more about [deploying your agent to to Cloud Run](cloud-run.md).

### Docker

You can containerize your agent with Docker and self-host it on your favorite platform.

Learn more about [building and deploying containers for your agent](docker.md).
