from flask import Flask, request
import pyautogui

app = Flask(__name__)

def execute_trade(action):
    if action in ["BUY", "SELL"]:
        pyautogui.hotkey('alt', 'c')  # Close any open position
        print("Closed all open positions")

        pyautogui.hotkey('alt', 'x')  # Cancel all TP/SL orders
        print("Canceled existing TP/SL orders")

        if action == "BUY":
            pyautogui.hotkey('alt', 'b')  # Execute BUY
            print("Executed BUY trade")
        elif action == "SELL":
            pyautogui.hotkey('alt', 's')  # Execute SELL
            print("Executed SELL trade")

    elif action == "CLOSE":
        pyautogui.hotkey('alt', 'c')  # Close all positions
        pyautogui.hotkey('alt', 'x')  # Cancel TP/SL
        print("Closed all positions and canceled TP/SL orders")

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