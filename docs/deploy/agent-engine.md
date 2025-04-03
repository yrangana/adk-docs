<div style="background-color: #def0da; color: #64946D; padding: 16px 24px;">
<!--TODO: remove div before launch-->
 <div style="font-size: 16px; font-weight: bold;">🔎 Ready for internal review: <a href="https://b.corp.google.com/issues/new?component=1685338&template=2111831&assignee=polong@google.com">Report bugs here</a></div>
</div>

# Deploy to Vertex AI Agent Engine

[Agent Engine](https://cloud.google.com/vertex-ai/generative-ai/docs/reasoning-engine/overview)
is a fully managed Google Cloud service enabling developers to deploy, manage,
and scale AI agents in production. Agent Engine handles the infrastructure to
scale agents in production so you can focus on creating intelligent and
impactful applications.

You can use either the `adk` CLI or the Vertex AI Python package.

=== "Python"

    <div style="color:red;border: 1px solid red;">
    <!-- TODO: Remove div before launch -->

    ### Pre-launch (TODO: remove this section before launch)
    
    ```shell
    !pip3 install "google-cloud-aiplatform[agent_engines] @ git+https://github.com/googleapis/python-aiplatform.git@copybara_738852226" --force-reinstall --quiet ## for the prebuilt template
    ```
    ```python
    from vertexai import agent_engines

    remote_app = agent_engines.create(
        root_agent,
        requirements=[
            "google_adk-0.0.2.dev20250402+nightly742991363-py3-none-any.whl",
            "google-cloud-aiplatform[agent_engines] @ git+https://github.com/googleapis/python-aiplatform.git@copybara_738852226",
        ],

        extra_packages=["google_adk-0.0.2.dev20250402+nightly742991363-py3-none-any.whl"],
    )
    ```
    </div>

    ## Install Vertex AI SDK

    Agent Engine is part of the Vertex AI SDK for Python. For more information, you can review the [Agent Engine quickstart documentation](https://cloud.google.com/vertex-ai/generative-ai/docs/agent-engine/quickstart).

    ### Install the Vertex AI SDK.
    
    ```shell
    !pip install google-adk google-cloud-aiplatform[agent_engines]
    ```

    ### Initialization

    ```py
    import vertexai
    from vertexai import agent_engines

    PROJECT_ID = "reasoning-engine-test-1" #@param {type:"string"}
    STAGING_BUCKET = "gs://reasoning-engine-test-1-bucket" #@param {type:"string"}

    vertexai.init(
        project=PROJECT_ID,
        location="us-central1",
        staging_bucket=STAGING_BUCKET,
    )
    ```

    ### Create your agent

    ```python
    --8<-- "examples/python/snippets/get-started/multi_tool_agent/agent.py"
    ```

    ### Prepare your agent for Agent Engine

    Use `agent_engines.ADKApp()` to wrap your agent to make it deployable to Agent Engine

    ```py
    app = agent_engines.ADKApp(
        agent=root_agent,
        enable_tracing=True,
        app_name="test-app", # optional
    )
    ```

    ### Try your agent locally

    You can try it locally before deploying to Agent Engine.

    #### Create session (local)

    ```py
    session = app.create_session(user_id="u_123")
    session
    ```

    ##### Expected Output:

    ```
    Session(id='c6a33dae-26ef-410c-9135-b434a528291f', app_name='test-app', user_id='u_123', state={}, events=[], last_update_time=1743440392.8689594)
    ```

    #### List sessions (local)

    ```py
    app.list_sessions(user_id="u_123")
    ```

    ##### Expected Output:

    ```
    ListSessionsResponse(session_ids=['c6a33dae-26ef-410c-9135-b434a528291f'])
    ```

    #### Get a specific session (local)

    ```py
    session = app.get_session(user_id="u_123", session_id=session.id)
    session
    ```

    ##### Expected Output:

    ```
    Session(id='c6a33dae-26ef-410c-9135-b434a528291f', app_name='test-app', user_id='u_123', state={}, events=[], last_update_time=1743681991.95696)
    ```

    #### Send queries to your agent (local)

    ```py
    for event in app.stream_query(
        user_id="u_123",
        session_id=session.id,
        message="whats the weather in new york",
    ):
    print(event)
    ```
    
    ##### Expected Output:

    ```
    {'parts': [{'function_call': {'id': 'af-a33fedb0-29e6-4d0c-9eb3-00c402969395', 'args': {'city': 'new york'}, 'name': 'get_weather'}}], 'role': 'model'}
    {'parts': [{'function_response': {'id': 'af-a33fedb0-29e6-4d0c-9eb3-00c402969395', 'name': 'get_weather', 'response': {'status': 'success', 'report': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}}}], 'role': 'user'}
    {'parts': [{'text': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}], 'role': 'model'}
    ```

    ### Deploy your agent to Agent Engine

    ```python
    from vertexai import agent_engines

    remote_app = agent_engines.create(
        root_agent,
        requirements=[
            "google-adk",
            "google-cloud-aiplatform[agent_engines]",
        ],
        extra_packages=[]
    )
    ```
    This step may take several minutes to finish.

    ### Try your agent on Agent Engine
    
    #### Create session (remote)

    ```py
    remote_session = remote_app.create_session(user_id="u_456")
    remote_session
    ```

    ##### Expected Output:
    ```
    {'events': [],
    'user_id': 'u_456',
    'state': {},
    'id': '7543472750996750336',
    'app_name': '7917477678498709504',
    'last_update_time': 1743683353.030133}
    ```

    #### List sessions (remote)
    ```py
    remote_app.list_sessions(user_id="u_456")
    ```

    #### Get a specific session (remote)
    ```py
    remote_app.get_session(user_id="u_456", session_id=remote_session["id"])
    ```

    #### Send queries to your agent (remote)
    
    ```py
    for event in remote_app.stream_query(
        user_id="u_456",
        session_id=session1["id"],
        message="whats the weather in new york",
    ):
        print(event)
    ```

    ##### Expected Output:
    
    ```
    {'parts': [{'function_call': {'id': 'af-f1906423-a531-4ecf-a1ef-723b05e85321', 'args': {'city': 'new york'}, 'name': 'get_weather'}}], 'role': 'model'}
    {'parts': [{'function_response': {'id': 'af-f1906423-a531-4ecf-a1ef-723b05e85321', 'name': 'get_weather', 'response': {'status': 'success', 'report': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}}}], 'role': 'user'}
    {'parts': [{'text': 'The weather in New York is sunny with a temperature of 25 degrees Celsius (41 degrees Fahrenheit).'}], 'role': 'model'}
    ```
    
    ## Clean up

    After you've finished, it's a good practice to clean up your cloud resources.
    You can delete the deployed Agent Engine instance to avoid any unexpected
    charges on your Google Cloud account.

    ```python
    remote_app.delete()
    ```

=== "adk CLI"
    TODO: _Not currently working as of Apr 3. May need to remove before launch._
    ```shell
    adk deploy agent_engine \
        --project=gcp_project_id \
        --region=us-central1 \
        path/to/agent_folder
    ```



