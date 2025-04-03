from typing import Tuple

import pytest
from agents import Runner
from agents.artifacts import InMemoryArtifactService
from agents.sessions import InMemorySessionService, Session
from google.genai import types

from stock_agent import root_agent, get_stock_price


@pytest.fixture(scope="module")
def setup():
    session_service = InMemorySessionService()
    artifact_service = InMemoryArtifactService()

    runner = Runner(
        agent=root_agent,
        artifact_service=artifact_service,
        session_service=session_service,
        app_name="test",
    )
    session = session_service.create_session(app_name="test", user_id="123")
    yield runner, session


# Test the Agent call
def test_agent(setup: Tuple[Runner, Session]):
    runner, session = setup

    query = "what is the stock price of GOOG?"
    content = types.Content(role="user", parts=[types.Part(text=query)])
    events = runner.run(session=session, new_message=content)
    for event in events:
        if event.is_final_response():
            final_response = event.content.parts[0].text
            print(final_response)
            assert final_response is not None


# Test tool
# TBD: Mocking or actual tool call?
def test_get_stock_price_valid_symbol():
    price = get_stock_price("GOOG")
    assert isinstance(price, float)
    assert price > 0
