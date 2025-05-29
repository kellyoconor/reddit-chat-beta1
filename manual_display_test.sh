#!/bin/bash

# Manual Display Test Script
# This script provides a simpler way to test the display of Reddit analysis results

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Reddit Analysis Display Test${NC}"
echo "=============================="

# Check if .env exists in backend directory
if [ ! -f "reddit-analyzer-backend/.env" ]; then
    echo -e "${RED}Error: .env file not found in reddit-analyzer-backend directory${NC}"
    echo "Please create a .env file with your OpenAI API key."
    echo "Example:"
    echo "OPENAI_API_KEY=your_api_key_here"
    exit 1
fi

echo -e "${YELLOW}Testing direct API request...${NC}"

# Test query
TEST_QUERY="What are the top 5 posts on r/Comcast_Xfinity right now?"

# Format the query as a simple message
JSON_QUERY=$(cat <<EOF
{
  "messages": [{"role": "user", "content": "$TEST_QUERY"}]
}
EOF
)

# Send the request to the backend API if it's running
if curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${GREEN}Backend is running.${NC}"
    echo "Sending test query: $TEST_QUERY"
    
    # Send the request and save the response
    RESPONSE=$(curl -s -X POST http://localhost:8000/awp \
        -H "Content-Type: application/json" \
        -d "$JSON_QUERY")
    
    echo -e "${YELLOW}API Response:${NC}"
    echo "$RESPONSE" | python -m json.tool
    
    # Extract just the message content
    MESSAGE=$(echo "$RESPONSE" | grep -o '"message":"[^"]*"' | sed 's/"message":"//;s/"$//')
    
    if [[ -n "$MESSAGE" ]]; then
        echo -e "${GREEN}✓ Message content received:${NC}"
        echo "$MESSAGE"
        
        # Save the response to a file for easier viewing
        echo "$MESSAGE" > test_response.txt
        echo "Response saved to test_response.txt"
    else
        echo -e "${RED}✗ No message content found in the response${NC}"
    fi
else
    echo -e "${RED}Backend is not running at http://localhost:8000${NC}"
    echo "Please start the backend first with:"
    echo "cd reddit-analyzer-backend && python main.py"
fi

echo ""
echo -e "${YELLOW}Manual Browser Testing${NC}"
echo "======================="
echo "To test in the browser:"
echo "1. Make sure both backend (port 8000) and frontend (port 3000) are running"
echo "2. Open http://localhost:3000 in your browser"
echo "3. Try the test query: \"$TEST_QUERY\""
echo ""
echo -e "${YELLOW}Display Verification${NC}"
echo "===================="
echo "When reviewing the response, check for:"
echo "- Proper formatting of post titles and metadata"
echo "- Organized listing of multiple posts"
echo "- Readable text with appropriate spacing"
echo "- Proper handling of special characters" 