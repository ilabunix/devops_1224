from flask import Flask, request
import pyautogui

app = Flask(__name__)

# Track position manually (since we can't use an API)
current_position = None  # Possible values: None, "BUY", "SELL"

def execute_trade(action):
    global current_position

    if action == "BUY":
        if current_position == "SELL":  # If a SELL is open, close it first
            pyautogui.hotkey('alt', 'c')  # Close SELL
            print("Closed SELL before opening BUY")

        pyautogui.hotkey('alt', 'b')  # Enter BUY
        current_position = "BUY"
        print("Executed BUY trade")

    elif action == "SELL":
        if current_position == "BUY":  # If a BUY is open, close it first
            pyautogui.hotkey('alt', 'c')  # Close BUY
            print("Closed BUY before opening SELL")

        pyautogui.hotkey('alt', 's')  # Enter SELL
        current_position = "SELL"
        print("Executed SELL trade")

    elif action == "CLOSE":
        if current_position:  # Only close if a trade is open
            pyautogui.hotkey('alt', 'c')  # Close all positions
            print("Closed Position")
            current_position = None  # Reset tracking

@app.route('/webhook', methods=['POST'])
def webhook():
    data = request.json
    action = data.get('action', '').upper()

    if action in ["BUY", "SELL", "CLOSE"]:
        execute_trade(action)
        return {"status": "Trade Executed"}, 200
    else:
        return {"error": "Invalid action"}, 400

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)