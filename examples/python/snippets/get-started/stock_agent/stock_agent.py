# --8<-- [start:stock_agent]
from agents import Agent
from agents.tools import google_search
from agents.sessions import InMemorySessionService
from agents.artifacts import InMemoryArtifactService
from google.genai import types
from agents.runners import Runner

import yfinance as yf

# Constants
APP_NAME = "stock_app"
USER_ID = "1234"


# 1) Tool
def get_stock_price(symbol: str):
    """
    Retrieves the current stock price for a given symbol.

    Args:
        symbol (str): The stock symbol (e.g., "AAPL", "GOOG").

    Returns:
        float: The current stock price, or None if an error occurs.
    """
    try:
        stock = yf.Ticker(symbol)
        historical_data = stock.history(period="1d")
        if not historical_data.empty:
            current_price = historical_data["Close"].iloc[-1]
            return current_price
        else:
            return None
    except Exception as e:
        print(f"Error retrieving stock price for {symbol}: {e}")
        return None


# 2) Agent
root_agent = Agent(
    model="gemini-2.0-flash-001",
    name="stock_agent",
    instruction="You are an agent to retrieve stock prices. "
    "If a ticker symbol is provided, fetch the current price. "
    "If only a company name is given, first perform a Google search "
    "to find the correct ticker symbol before retrieving the stock price. "
    "If the provided ticker symbol is invalid or data cannot be retrieved, "
    "inform the user that the stock price could not be found.",
    description="You specialize in retrieving real-time stock prices. "
    "Given a stock ticker symbol (e.g., AAPL, GOOG, MSFT) or the stock name, "
    "use the tools and reliable data sources to provide the most up-to-date price.",
    tools=[google_search, get_stock_price],
    flow="auto",
    planning=True,
)

# 3) Memory
session_service = InMemorySessionService()
artifact_service = InMemoryArtifactService()

# 4) Runner
runner = Runner(
    agent=root_agent,
    artifact_service=artifact_service,
    session_service=session_service,
    app_name=APP_NAME,
)
session = session_service.create_session(app_name=APP_NAME, user_id=USER_ID)

# 5) Query
query = "what is the stock price of Google"
content = types.Content(role="user", parts=[types.Part(text=query)])
events = runner.run(session=session, new_message=content)
for event in events:
    if event.is_final_response():
        final_response = event.content.parts[0].text
        print("Agent Response: Stock price: ", final_response)

# --8<-- [end:stock_agent]
