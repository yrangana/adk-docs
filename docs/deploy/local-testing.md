<div style="background-color: #def0da; color: #64946D; padding: 16px 24px;">
<!--TODO: remove div before launch-->
 <div style="font-size: 16px; font-weight: bold;">🔎 Ready for internal review: <a href="https://b.corp.google.com/issues/new?component=1685338&template=2111831&assignee=polong@google.com">Report bugs here</a></div>
</div>

# Local testing

Before you deploy your agent, you should test it locally to make sure it is
working as intended.

The easiest way is to test your a local agent is to use the ADK CLI with `adk api_server`, which launches a local Fast API server, where you can run cURL commands to test your agent.

#### Working directory 

First, ensure you are in the correct working directory:
```
parent_folder    <-- you should be here
|- my_sample_agent
  |- __init__.py
  |- .env
  |- agent.py
```

### Launching your local Fast API server with `adk api_server`

Next, launch the local Fast API server:
```shell
adk api_server 
```

##### Expected Output:
```shell
INFO:     Started server process [12345]
INFO:     Waiting for application startup.
INFO:     Application startup complete.
INFO:     Uvicorn running on http://0.0.0.0:8000 (Press CTRL+C to quit)
```
Your server is now running locally at http://0.0.0.0:8000.

### Creating a new session for your agent

Without closing this terminal, open a new terminal and create a new session with the agent using:
```shell
curl -X POST http://0.0.0.0:8000/apps/my_sample_agent/users/u_123/sessions/s_123 \
  -H "Content-Type: application/json" \
  -d '{"state": {"key1": "value1", "key2": 42}}'
```

Let's break down what's happening:
* `http://0.0.0.0:8000/apps/my_sample_agent/users/u_123/sessions/s_123`: This creates a new session for your agent `my_sample_agent`, which is the name of the agent folder, for a user ID (`u_123`) and for a session ID (`s_123`). You can replace `my_sample_agent` with the name of your agent folder. You can replace `u_123` with a specific user ID, and `s_123` with a specific session ID.
* `{"state": {"key1": "value1", "key2": 42}}`: This is optional. You can use this to customize the agent's pre-existing state (dict) when creating the session.

This should return the session information, if created successfully.

##### Expected Output:
```shell
{"id":"s_1234","app_name":"hello_world","user_id":"u_123","state":{"state":{"key1":"value1","key2":42}},"events":[],"last_update_time":1743673882.4027488}
```

A few tips:
- you cannot create multiple sessions with exactly the same user ID and session ID. If you try to, you may see a response, like: `{"detail":"Session already exists: s_123"}`. To fix this, you can either delete that session (e.g. `s_123`), or choose a different session ID.

### Sending a query to your agent:

```shell
curl -X POST http://0.0.0.0:8000/apps/my_sample_agent/agent/run_sse \
-H "Content-Type: application/json" \
-d '{
"user_id": "u_123",
"session_id": "s_123",
"new_message": {
    "role": "user",
    "parts": [{
    "text": "Hey whats up"
    }]
},
"streaming": false
}'
```

##### Expected Output:
```shell
data: {"content":{"parts":[{"text":"I am doing well. How can I help you today?\n"}],"role":"model"},"invocation_id":"e-d44e8e68-4e0c-41fd-b98e-743120482506","author":"weather_time_agent","actions":{"state_delta":{},"artifact_delta":{},"requested_auth_configs":{}},"id":"Gip4JhpP","timestamp":1743674367.969573}
```


Now that you've verified the local operation of your agent, you're ready to move on to deploying your agent!
