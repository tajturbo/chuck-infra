"""
Unit tests for Chuck Norris Jokes Application
"""
import pytest
import responses
from app import app, fetch_joke, CHUCK_NORRIS_API


@pytest.fixture
def client():
    """Create a test client for the Flask application."""
    app.config['TESTING'] = True
    with app.test_client() as client:
        yield client


class TestHealthEndpoint:
    """Tests for the health check endpoint."""

    def test_health_returns_200(self, client):
        """Health endpoint should return 200 status."""
        response = client.get('/health')
        assert response.status_code == 200

    def test_health_returns_healthy_status(self, client):
        """Health endpoint should return healthy status in JSON."""
        response = client.get('/health')
        data = response.get_json()
        assert data['status'] == 'healthy'
        assert data['service'] == 'chuck-norris-app'


class TestFetchJoke:
    """Tests for the joke fetching function."""

    @responses.activate
    def test_fetch_joke_success(self):
        """Successfully fetch a joke from the API."""
        mock_response = {
            "value": "Chuck Norris can divide by zero.",
            "icon_url": "https://api.chucknorris.io/img/avatar/chuck-norris.png",
            "id": "test-123"
        }
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json=mock_response,
            status=200
        )

        result = fetch_joke()
        
        assert result['joke'] == "Chuck Norris can divide by zero."
        assert result['icon_url'] == "https://api.chucknorris.io/img/avatar/chuck-norris.png"
        assert result['id'] == "test-123"
        assert result['error'] is None

    @responses.activate
    def test_fetch_joke_api_error(self):
        """Handle API errors gracefully."""
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json={"error": "Internal Server Error"},
            status=500
        )

        result = fetch_joke()
        
        assert "can't fetch jokes" in result['joke']
        assert result['error'] is not None

    @responses.activate
    def test_fetch_joke_timeout(self):
        """Handle timeout errors gracefully."""
        from requests.exceptions import Timeout
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            body=Timeout("Connection timed out")
        )

        result = fetch_joke()
        
        assert "can't fetch jokes" in result['joke']
        assert result['error'] is not None


class TestIndexEndpoint:
    """Tests for the main index page."""

    @responses.activate
    def test_index_returns_200(self, client):
        """Index page should return 200 status."""
        mock_response = {
            "value": "Chuck Norris test joke.",
            "icon_url": "https://api.chucknorris.io/img/avatar/chuck-norris.png",
            "id": "test-123"
        }
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json=mock_response,
            status=200
        )

        response = client.get('/')
        assert response.status_code == 200

    @responses.activate
    def test_index_contains_joke(self, client):
        """Index page should contain the joke text."""
        mock_response = {
            "value": "Chuck Norris counted to infinity. Twice.",
            "icon_url": "https://api.chucknorris.io/img/avatar/chuck-norris.png",
            "id": "test-456"
        }
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json=mock_response,
            status=200
        )

        response = client.get('/')
        assert b"Chuck Norris counted to infinity" in response.data

    @responses.activate
    def test_index_contains_html_structure(self, client):
        """Index page should contain expected HTML elements."""
        mock_response = {
            "value": "Test joke",
            "icon_url": "",
            "id": "test"
        }
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json=mock_response,
            status=200
        )

        response = client.get('/')
        html = response.data.decode('utf-8')
        
        assert '<title>Chuck Norris Jokes</title>' in html
        assert 'Get New Joke' in html
        assert 'joke-text' in html


class TestApiJokeEndpoint:
    """Tests for the JSON API endpoint."""

    @responses.activate
    def test_api_joke_returns_json(self, client):
        """API joke endpoint should return JSON."""
        mock_response = {
            "value": "API test joke",
            "icon_url": "https://example.com/icon.png",
            "id": "api-test"
        }
        responses.add(
            responses.GET,
            CHUCK_NORRIS_API,
            json=mock_response,
            status=200
        )

        response = client.get('/api/joke')
        
        assert response.content_type == 'application/json'
        data = response.get_json()
        assert data['joke'] == "API test joke"
