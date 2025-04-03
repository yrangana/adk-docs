# Containerizing your agent

You can containerize your agent by following these steps:

Navigate to your agent's directory:

```
cd myagent
```

Create a Dockerfile with the following contents:

```
FROM python:3

WORKDIR /app
COPY . /app
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install requests  # and other required packages
CMD ["python", "main.py"]
```

Build the Dockerfile:

```
docker build .
```

Push it to a registry:

```
docker push ...
```

Now, you're ready to deploy your agent as a Docker container in Cloud Run!
