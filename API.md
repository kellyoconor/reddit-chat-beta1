# Reddit Analyzer API Documentation

This document provides detailed information about the API endpoints available in the Reddit Analyzer backend service.

## Base URL

```
http://localhost:8000
```

## Authentication

No authentication is required for local development. In a production environment, proper authentication should be implemented.

## Endpoints

### Health Check

```
GET /
```

Returns basic information about the service.

**Response**

```json
{
  "service": "AG-UI Reddit Analyzer",
  "status": "running",
  "version": "1.0.0",
  "endpoints": {
    "ag_ui": "/awp",
    "health": "/health"
  }
}
```

### Detailed Health Check

```
GET /health
```

Returns detailed health status of the service.

**Response**

```json
{
  "status": "healthy",
  "message": "Reddit Analyzer API is running"
}
```

### AG-UI Protocol Endpoint

```
POST /awp
```

The main endpoint that implements the AG-UI protocol for chat interactions.

**Request Body**

```json
{
  "messages": [
    {
      "role": "user",
      "content": "What are the most common complaints in the Comcast Xfinity subreddit?"
    }
  ]
}
```

**Response**

```json
{
  "message": "Based on recent posts in the r/Comcast_Xfinity subreddit, the most common complaints are...",
  "type": "message",
  "timestamp": "2025-01-01T00:00:00Z"
}
```

## Tools Available to the AG-UI Agent

The AG-UI agent has access to the following tools to fetch and analyze Reddit data:

### fetch_recent_posts

Fetches recent posts from the r/Comcast_Xfinity subreddit.

**Parameters**

- `timeframe` (string, optional): Sort type for posts (hot=trending, new=recent, top=highest scored). Default: "hot"
- `limit` (integer, optional): Number of posts to fetch (1-100). Default: 25

### search_subreddit

Searches r/Comcast_Xfinity for posts containing specific keywords.

**Parameters**

- `query` (string, required): Search query (e.g., 'outage', 'slow internet', 'billing issue')
- `limit` (integer, optional): Number of results to return (1-50). Default: 20

## Error Handling

The API returns appropriate HTTP status codes for different types of errors:

- `400 Bad Request`: Invalid request format
- `500 Internal Server Error`: Server-side error

Error responses include a message explaining the error:

```json
{
  "error": "Error message",
  "details": "Additional error details"
}
```

## Rate Limiting

No rate limiting is implemented in the development environment. In production, rate limiting should be configured based on the expected usage patterns. 