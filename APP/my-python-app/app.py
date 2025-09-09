from flask import Flask
import random

app = Flask(__name__)

def fibonacci(n):
    if n <= 1:
        return n
    else:
        return fibonacci(n-1) + fibonacci(n-2)

@app.route('/')
def home():
    # Simulate CPU load by calculating a Fibonacci number
    # A number between 30 and 35 will create noticeable but not overwhelming load
    n = random.randint(30, 35)
    result = fibonacci(n)
    return f"Calculated Fibonacci({n}) = {result}. This was CPU intensive!"

if __name__ == '__main__':
    # This is for local testing, Gunicorn will be used in production
    app.run(host='0.0.0.0', port=8000)
