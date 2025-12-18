# API Reference

The Chuck Norris Jokes application provides a simple web interface and a basic JSON API.

## Endpoints

### 1. Web Interface
- **Path**: `/`
- **Method**: `GET`
- **Description**: Renders a creative HTML page with a random Chuck Norris joke.
- **Response**: `text/html`

### 2. Random JSON Joke
- **Path**: `/api/joke`
- **Method**: `GET`
- **Description**: Returns a random joke and associated metadata in JSON format.
- **Response**: `application/json`
- **Example**:
  ```json
  {
    "joke": "Chuck Norris's keyboard has a 'Shift' key. He uses it to shift the earth's orbit.",
    "icon_url": "https://api.chucknorris.io/img/avatar/chuck-norris.png",
    "id": "abc123xyz",
    "error": null
  }
  ```

### 3. Health Check
- **Path**: `/health`
- **Method**: `GET`
- **Description**: Standard health check endpoint for container orchestration.
- **Response**: `application/json`
- **Example**:
  ```json
  {
    "status": "healthy",
    "service": "chuck-norris-app"
  }
  ```

## External Dependencies
The application proxies requests to `https://api.chucknorris.io/jokes/random`.
