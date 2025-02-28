from flask import Flask, request
import pyautogui
import time
import pygetwindow as gw

app = Flask(__name__)

current_position = None  # Track current open position (None, "BUY", "SELL")

def focus_tradingview():
    """Brings the TradingView window to the front before executing trades."""
    windows = gw.getWindowsWithTitle("TradingView")
    if windows:
        windows[0].activate()
        time.sleep(0.5)  # Small delay to ensure focus

def execute_trade(action):
    global current_position

    focus_tradingview()  # Ensure TradingView is active before sending hotkeys

    if action == "BUY":
        if current_position == "SELL":  # If SELL is open, close it first
            pyautogui.hotkey('shift', 'b')  # Close SELL position
            time.sleep(0.2)  # Small delay to ensure execution
            print("Closed SELL position before opening BUY")

        pyautogui.hotkey('shift', 'b')  # Open BUY trade
        print("Executed BUY trade")
        current_position = "BUY"

    elif action == "SELL":
        if current_position == "BUY":  # If BUY is open, close it first
            pyautogui.hotkey('shift', 's')  # Close BUY position
            time.sleep(0.2)  # Small delay to ensure execution
            print("Closed BUY position before opening SELL")

        pyautogui.hotkey('shift', 's')  # Open SELL trade
        print("Executed SELL trade")
        current_position = "SELL"

    elif action == "CLOSE":
        if current_position == "BUY":
            pyautogui.hotkey('shift', 's')  # Close BUY position
            print("Closed BUY position")

        elif current_position == "SELL":
            pyautogui.hotkey('shift', 'b')  # Close SELL position
            print("Closed SELL position")

        current_position = None  # Reset tracking

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.json
    print("Received Webhook Data:", data)  # Debugging

    action = data.get('action', '').upper()
    if action in ["BUY", "SELL", "CLOSE"]:
        execute_trade(action)
        return {"status": "Trade Executed"}, 200
    else:
        return {"error": "Invalid action"}, 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)