# OpenAPI Integration

## Concept

The ADK allows you to automatically generate callable tools (RestApiTool) directly from an OpenAPI (v3.x) specification. This drastically simplifies the process of enabling your agent to interact with existing REST APIs, as you don't need to manually define each API call as a separate function tool.

## Mechanism

1. **Class:** This class is the entry point for processing OpenAPI specs.  
2. **Specification Input:** You initialize OpenAPIToolset by providing the specification in one of these ways:  
   * As a Python dictionary (spec\_dict).  
   * As a JSON string (spec\_str with spec\_str\_type="json").  
   * As a YAML string (spec\_str with spec\_str\_type="yaml").  
3. **Parsing:** When initialized, OpenAPIToolset performs the following:  
   * Uses OpenApiSpecParser to load and parse the raw spec. This includes resolving internal $ref references (essential for complex specs).  
   * Identifies all valid API operations defined within the paths object of the spec.  
   * For each operation, it uses OperationParser to extract:  
     * operationId (used to generate the tool name).  
     * summary and description (used for the tool description).  
     * HTTP method (GET, POST, etc.) and path.  
     * Server information (base URL).  
     * Parameters (path, query, header, cookie) and their schemas.  
     * requestBody schema (if present).  
     * Response schemas (primarily for documentation, not strict output validation currently).  
     * Security requirements (security field).  
4. **Tool Generation (** For every operation successfully parsed, an instance of RestApiTool is created.  
   * **name:** Derived from operationId (converted to snake\_case, max 60 chars).  
   * **description:** Taken from the operation's summary or description.  
   * **endpoint:** Stores the base URL, path, and HTTP method.  
   * **operation:** Holds the parsed OpenAPI Operation object.  
   * **\_get\_declaration():** This method within RestApiTool dynamically generates the FunctionDeclaration (the schema describing the tool to the LLM) based on the parsed parameters and request body.  
   * **call() / run\_async():** This method executes the actual HTTP request. It uses the arguments provided by the LLM (during a function call), constructs the URL, headers, query parameters, and request body according to the OpenAPI definition, handles authentication, makes the requests call, and returns the response (usually as JSON).  
5. **Authentication:** Global authentication for all generated tools can be set during OpenAPIToolset initialization using auth\_scheme and auth\_credential. These are passed down to each created RestApiTool.  
6. **Retrieving Tools:**  
   * openapi\_toolset.get\_tools(): Returns a list of all generated RestApiTool instances.  
   * openapi\_toolset.get\_tool(tool\_name: str): Retrieves a specific RestApiTool by its generated snake\_case name.

## Workflow

1. Obtain your OpenAPI specification (e.g., load from a file, fetch from a URL).  
2. Instantiate OpenAPIToolset, passing the spec (as a dict or string) and any global authentication details.  
3. Use get\_tools() or get\_tool() to get the RestApiTool instances you need.  
4. Add these tools to your LlmAgent's tools list (e.g., tools=\[\*petstore\_toolset.get\_tools()\]).  
5. Provide instructions to your agent mentioning the capabilities and names of the generated tools.  
6. Run your agent. When the LLM decides to use an API defined in the spec, it will generate a function call targeting the corresponding RestApiTool. The tool instance will then automatically handle the API interaction based on the OpenAPI definition.

## Code Example: Using OpenAPIToolset with a Pet Store Spec

This example uses a simple Pet Store OpenAPI spec (as a JSON string) to generate tools and then uses an agent to interact with them (calling a mock server).

```py
import asyncio
import json
import uuid # For unique session IDs
from google.adk.agents import LlmAgent
from google.adk.runners import Runner
from google.adk.sessions import InMemorySessionService
from google.genai import types

# --- OpenAPI Tool Imports ---
# Main class to parse the spec and generate tools
from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_toolset import OpenAPIToolset
# Though not directly used here, these are involved internally:
# from google.adk.tools.openapi_tool.openapi_spec_parser.rest_api_tool import RestApiTool
# from google.adk.tools.openapi_tool.openapi_spec_parser.openapi_spec_parser import OpenApiSpecParser
# from google.adk.tools.openapi_tool.openapi_spec_parser.operation_parser import OperationParser

# --- Constants ---
APP_NAME_OPENAPI = "openapi_petstore_app"
USER_ID_OPENAPI = "user_openapi_1"
SESSION_ID_OPENAPI = f"session_openapi_{uuid.uuid4()}" # Unique session ID
AGENT_NAME_OPENAPI = "petstore_manager_agent"
GEMINI_2_FLASH = "gemini-2.0-flash-001"

# --- Sample OpenAPI Specification (JSON String) ---
# A basic Pet Store API example using httpbin.org as a mock server
openapi_spec_string = """
{
  "openapi": "3.0.0",
  "info": {
    "title": "Simple Pet Store API (Mock)",
    "version": "1.0.1",
    "description": "An API to manage pets in a store, using httpbin for responses."
  },
  "servers": [
    {
      "url": "https://httpbin.org",
      "description": "Mock server (httpbin.org)"
    }
  ],
  "paths": {
    "/get": {
      "get": {
        "summary": "List all pets (Simulated)",
        "operationId": "listPets",
        "description": "Simulates returning a list of pets. Uses httpbin's /get endpoint which echoes query parameters.",
        "parameters": [
          {
            "name": "limit",
            "in": "query",
            "description": "Maximum number of pets to return",
            "required": false,
            "schema": { "type": "integer", "format": "int32" }
          },
          {
             "name": "status",
             "in": "query",
             "description": "Filter pets by status",
             "required": false,
             "schema": { "type": "string", "enum": ["available", "pending", "sold"] }
          }
        ],
        "responses": {
          "200": {
            "description": "A list of pets (echoed query params).",
            "content": { "application/json": { "schema": { "type": "object" } } }
          }
        }
      }
    },
    "/post": {
      "post": {
        "summary": "Create a pet (Simulated)",
        "operationId": "createPet",
        "description": "Simulates adding a new pet. Uses httpbin's /post endpoint which echoes the request body.",
        "requestBody": {
          "description": "Pet object to add",
          "required": true,
          "content": {
            "application/json": {
              "schema": {
                "type": "object",
                "required": ["name"],
                "properties": {
                  "name": {"type": "string", "description": "Name of the pet"},
                  "tag": {"type": "string", "description": "Optional tag for the pet"}
                }
              }
            }
          }
        },
        "responses": {
          "201": {
            "description": "Pet created successfully (echoed request body).",
            "content": { "application/json": { "schema": { "type": "object" } } }
          }
        }
      }
    },
    "/get?petId={petId}": {
      "get": {
        "summary": "Info for a specific pet (Simulated)",
        "operationId": "showPetById",
        "description": "Simulates returning info for a pet ID. Uses httpbin's /get endpoint.",
        "parameters": [
          {
            "name": "petId",
            "in": "path",
            "description": "This is actually passed as a query param to httpbin /get",
            "required": true,
            "schema": { "type": "integer", "format": "int64" }
          }
        ],
        "responses": {
          "200": {
            "description": "Information about the pet (echoed query params)",
            "content": { "application/json": { "schema": { "type": "object" } } }
          },
          "404": { "description": "Pet not found (simulated)" }
        }
      }
    }
  }
}
"""

# --- Create OpenAPIToolset ---
generated_tools_list = []
try:
    # Instantiate the toolset with the spec string
    petstore_toolset = OpenAPIToolset(
        spec_str=openapi_spec_string,
        spec_str_type="json"
        # No authentication needed for httpbin.org
    )
    # Get all tools generated from the spec
    generated_tools_list = petstore_toolset.get_tools()
    print(f"Generated {len(generated_tools_list)} tools from OpenAPI spec:")
    for tool in generated_tools_list:
        # Tool names are snake_case versions of operationId
        print(f"- Tool Name: '{tool.name}', Description: {tool.description[:60]}...")

except ValueError as ve:
    print(f"Validation Error creating OpenAPIToolset: {ve}")
except Exception as e:
    print(f"Unexpected Error creating OpenAPIToolset: {e}")

# --- Agent Definition ---
openapi_agent = LlmAgent(
    name=AGENT_NAME_OPENAPI,
    model=GEMINI_2_FLASH,
    tools=generated_tools_list, # Pass the list of RestApiTool objects
    instruction=f"""You are a Pet Store assistant managing pets via an API.
    Use the available tools to fulfill user requests.
    Available tools: {', '.join([t.name for t in generated_tools_list])}.
    When creating a pet, confirm the details echoed back.
    When listing pets, mention the parameters that were used in the simulated call.
    When showing a pet by ID, state the ID requested.
    """,
    description="Manages a Pet Store using tools generated from an OpenAPI spec.",
    allow_transfer=False
)

# --- Session and Runner Setup ---
session_service_openapi = InMemorySessionService()
runner_openapi = Runner(
    agent=openapi_agent, app_name=APP_NAME_OPENAPI, session_service=session_service_openapi
)
session_openapi = session_service_openapi.create_session(
    app_name=APP_NAME_OPENAPI, user_id=USER_ID_OPENAPI, session_id=SESSION_ID_OPENAPI
)

# --- Agent Interaction Function ---
async def call_openapi_agent_async(query):
  print(f"\n--- Running OpenAPI Pet Store Agent ---")
  print(f"Query: {query}")
  if not generated_tools_list:
      print("Skipping execution: No tools were generated.")
      print("-" * 30)
      return

  content = types.Content(role='user', parts=[types.Part(text=query)])
  final_response_text = "No response received."
  try:
    async for event in runner_openapi.run_async(
        user_id=USER_ID_OPENAPI, session_id=SESSION_ID_OPENAPI, new_message=content
    ):
        if event.get_function_calls():
             call = event.get_function_calls()[0]
             print(f"  Debug: Agent called function: {call.name} with args {call.args}")
        elif event.get_function_responses():
             print(f"  Debug: Tool Response received for: {event.get_function_responses()[0].name}")
             # print(f"  Tool Response Snippet: {str(event.get_function_responses()[0].response)[:200]}...") # Optional
        elif event.is_final_response() and event.content and event.content.parts:
            final_response_text = event.content.parts[0].text.strip()
            print(f"Agent Response: {final_response_text}")

  except Exception as e:
    print(f"An error occurred during agent run: {e}")
  print("-" * 30)

# --- Run Examples ---
async def run_openapi_example():
    # Trigger listPets
    await call_openapi_agent_async("List the pets, maybe limit to 5.")
    # Trigger createPet
    await call_openapi_agent_async("Add a cat named 'Whiskers' with tag 'fluffy'.")
    # Trigger showPetById
    await call_openapi_agent_async("Show me pet 42.")

# --- Execute ---
# await run_openapi_example()

# Running locally due to potential colab asyncio issues
try:
    asyncio.run(run_openapi_example())
except RuntimeError as e:
     if "cannot be called from a running event loop" in str(e):
         print("Skipping execution in running event loop (like Colab/Jupyter). Run locally.")
     else:
         raise e
```
