# UI Queries Testing Documentation

This document outlines the test cases for task 5.1.3: Test example queries from UI.

## Test Cases

### Basic Connectivity
1. **Test Backend Health Endpoint**
   - Send a GET request to `http://localhost:8000/health`
   - Verify the response contains `{"status": "healthy"}`

2. **Test Frontend Loading**
   - Navigate to `http://localhost:3000` in a browser
   - Verify the application loads and displays the Reddit Analyzer UI
   - Confirm the backend connection status shows "Connected"

### Example Queries Testing

These test cases validate that the example queries suggested in the UI work properly:

#### Test Case 1: Recent Complaints
- **Query**: "What are the most common complaints this week?"
- **Expected Behavior**:
  - The backend processes the query
  - OpenAI calls the `fetch_recent_posts` tool
  - The tool fetches "hot" posts from r/Comcast_Xfinity
  - The response contains a summary of common complaint categories
  - Response displays correctly in the UI

#### Test Case 2: Outage Analysis
- **Query**: "Show me recent posts about internet outages"
- **Expected Behavior**:
  - The backend processes the query
  - OpenAI calls the `search_subreddit` tool with "outage" or similar terms
  - The tool returns relevant posts about outages
  - The response contains formatted outage-related posts
  - Response displays correctly in the UI

#### Test Case 3: Customer Service Sentiment
- **Query**: "What do people say about Xfinity customer service?"
- **Expected Behavior**:
  - The backend processes the query
  - OpenAI calls the `search_subreddit` tool with "customer service" or similar terms
  - The tool returns relevant posts about customer service experiences
  - The response contains sentiment analysis about customer service
  - Response displays correctly in the UI

### UI Response Validation

For each query, validate that:

1. The chat interface shows a loading indicator while processing
2. The response appears in the chat thread
3. The response is properly formatted (paragraphs, bullet points)
4. Any referenced Reddit posts include relevant context
5. The response contains useful insights rather than generic statements

### Error Handling

Test error scenarios:

1. **Backend Connection Loss**
   - Stop the backend server while the frontend is running
   - Verify the UI shows an appropriate error message
   - Restart the backend and verify the connection recovers

2. **Invalid Queries**
   - Enter a query that doesn't relate to Reddit or Comcast
   - Verify the response appropriately handles the irrelevant query

## Running Tests

Execute the automated test script:

```bash
./test_ui_queries.sh
```

The script will:
1. Start both backend and frontend services
2. Test API endpoints directly
3. Provide instructions for manual browser testing
4. Clean up processes when testing is complete

## Test Results Documentation

For each test case, document:

- Test date and time
- Pass/Fail status
- Response time
- Any unexpected behavior
- Screenshots of UI responses (if available)

## Common Issues and Troubleshooting

- **Backend Not Starting**: Check for proper Python environment and dependencies
- **OpenAI API Issues**: Verify API key is valid and has sufficient credits
- **Reddit API Rate Limiting**: The script may hit Reddit API rate limits during testing
- **Frontend Connection Issues**: Verify port configuration matches in both services 