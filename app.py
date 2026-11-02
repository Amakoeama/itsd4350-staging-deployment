
import os

from flask import Flask, jsonify

app = Flask(__name__)

# Read the environment configuration.
APP_ENV = os.getenv("APP_ENV", "development")
app.config["APP_ENV"] = APP_ENV


@app.route("/")
def home():
    return f"""
    <!DOCTYPE html>
    <html lang="en">
    <head>
        <meta charset="UTF-8">
        <title>ITSD-4350 Staging Deployment</title>
    </head>
    <body>
        <h1>ITSD-4350 Automated Deployment Pipeline</h1>
        <p>Mini Project 2.1: Continuous Delivery to Staging</p>
        <p>Environment: {APP_ENV}</p>
        <p>Status: Application Running Successfully</p>
    </body>
    </html>
    """


@app.route("/health")
def health():
    return jsonify({
        "status": "healthy",
        "environment": app.config["APP_ENV"],
        "application": "ITSD-4350 Mini Project 2.1"
    }), 200


if __name__ == "__main__":
    app.run(debug=APP_ENV == "development")
