import os
import requests
from datetime import datetime

url = "https://query1.finance.yahoo.com/v8/finance/chart/AAPL?interval=1d&range=5d"

headers = {
    "User-Agent": "MyCustomAgent/1.0"
}

debug = os.getenv("DEBUG", "").lower() in ("1", "true", "yes", "on")

response = requests.get(url, headers=headers)

if debug:
    print("=== DEBUG: HTTP Response ===")
    print("Status:", response.status_code)
    print("Headers:")
    for key, value in response.headers.items():
        print(f"  {key}: {value}")
    print("\nResponse body:")
    print(response.text)
    print("=== END DEBUG ===\n")

response.raise_for_status()

result = response.json()["chart"]["result"][0]

timestamp = result["timestamp"][-1]
quote = result["indicators"]["quote"][0]

last_data = {
    "date": datetime.fromtimestamp(timestamp).strftime("%Y-%m-%d"),
    "open": quote["open"][-1],
    "high": quote["high"][-1],
    "low": quote["low"][-1],
    "close": quote["close"][-1],
    "volume": quote["volume"][-1],
}

print(last_data)

