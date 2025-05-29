#!/bin/bash

# Test UI Queries Script
# This script helps test the example queries from the UI for task 5.1.3

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting UI Queries Test${NC}"
echo "=============================="
echo ""

# Check if .env exists in backend directory
if [ ! -f "reddit-analyzer-backend/.env" ]; then
    echo -e "${RED}Error: .env file not found in reddit-analyzer-backend directory${NC}"
    echo "Creating a sample .env file. Please update with your actual OpenAI API key."
    
    # Create a sample .env file
    cat > reddit-analyzer-backend/.env << EOL
OPENAI_API_KEY=YOUR_OPENAI_API_KEY
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3002
EOL
    
    echo -e "${YELLOW}Sample .env file created. Please edit it with your actual OpenAI API key.${NC}"
    exit 1
fi

# Start backend server in background
echo -e "${YELLOW}Starting backend server...${NC}"
cd reddit-analyzer-backend
python -m venv venv 2>/dev/null
source venv/bin/activate 2>/dev/null || source venv/Scripts/activate 2>/dev/null
pip install -q -r requirements.txt
(python main.py > ../backend.log 2>&1) &
BACKEND_PID=$!
cd ..

# Give backend time to start
echo "Waiting for backend to start..."
sleep 5

# Check if backend is running
if ! curl -s http://localhost:8000/health > /dev/null; then
    echo -e "${RED}Error: Backend server failed to start${NC}"
    echo "Check backend.log for details"
    kill $BACKEND_PID 2>/dev/null
    exit 1
fi
echo -e "${GREEN}Backend server running at http://localhost:8000${NC}"

# Start frontend server in background
echo -e "${YELLOW}Starting frontend server...${NC}"
cd reddit-analyzer-frontend
npm install --silent
(npm run dev > ../frontend.log 2>&1) &
FRONTEND_PID=$!
cd ..

# Give frontend time to start
echo "Waiting for frontend to start..."
sleep 10

echo -e "${GREEN}Frontend server running at http://localhost:3000${NC}"
echo ""
echo -e "${YELLOW}Test Example Queries${NC}"
echo "========================="

# List of example queries to test
QUERIES=(
    "What are the most common complaints this week?"
    "Show me recent posts about internet outages"
    "What do people say about Xfinity customer service?"
)

# Test API directly with example queries
for query in "${QUERIES[@]}"; do
    echo -e "${YELLOW}Testing query:${NC} $query"
    
    # Format the query as JSON for the API request
    JSON_QUERY=$(cat <<EOF
{
  "operationName": "generateMessage",
  "variables": {
    "text": "$query"
  }
}
EOF
)
    
    # Send the request to the backend API
    RESPONSE=$(curl -s -X POST http://localhost:8000/awp \
        -H "Content-Type: application/json" \
        -d "$JSON_QUERY")
    
    # Check if we got a response
    if [[ $RESPONSE == *"message"* ]]; then
        echo -e "${GREEN}✓ Query successful${NC}"
    else
        echo -e "${RED}✗ Query failed${NC}"
        echo "API Response: $RESPONSE"
    fi
    echo ""
    
    # Small delay between requests
    sleep 2
done

echo -e "${YELLOW}Browser Testing${NC}"
echo "================="
echo "Please manually test these queries in the browser at http://localhost:3000"
echo "1. \"What are the most common complaints this week?\""
echo "2. \"Show me recent posts about internet outages\""
echo "3. \"What do people say about Xfinity customer service?\""
echo ""

# Ask if user wants to stop the servers
read -p "Press Enter to stop the servers when done testing..." 

# Cleanup
echo "Stopping servers..."
kill $BACKEND_PID 2>/dev/null
kill $FRONTEND_PID 2>/dev/null

echo -e "${GREEN}Test completed.${NC}"
echo "Check backend.log and frontend.log for details." 