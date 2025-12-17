"""
Chuck Norris Jokes Application
A Flask app that displays random Chuck Norris jokes from api.chucknorris.io
"""
import os
import requests
from flask import Flask, render_template, jsonify

app = Flask(__name__)

CHUCK_NORRIS_API = "https://api.chucknorris.io/jokes/random"


def fetch_joke():
    """Fetch a random Chuck Norris joke from the API."""
    try:
        response = requests.get(CHUCK_NORRIS_API, timeout=5)
        response.raise_for_status()
        data = response.json()
        return {
            "joke": data.get("value", "Chuck Norris doesn't need jokes."),
            "icon_url": data.get("icon_url", ""),
            "id": data.get("id", ""),
            "error": None
        }
    except requests.RequestException as e:
        return {
            "joke": "Chuck Norris broke the internet, so we can't fetch jokes right now.",
            "icon_url": "",
            "id": "",
            "error": str(e)
        }


@app.route("/")
def index():
    """Render the main page with a random Chuck Norris joke."""
    joke_data = fetch_joke()
    return render_template("index.html", joke=joke_data["joke"], icon_url=joke_data["icon_url"])


@app.route("/api/joke")
def api_joke():
    """API endpoint returning a random joke as JSON."""
    return jsonify(fetch_joke())


@app.route("/health")
def health():
    """Health check endpoint for container orchestration."""
    return jsonify({"status": "healthy", "service": "chuck-norris-app"})


if __name__ == "__main__":
    port = int(os.environ.get("PORT", 8000))
    app.run(host="0.0.0.0", port=port, debug=False)
