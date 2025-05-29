#!/bin/bash

# Test Reddit Display Script
# This script helps test the proper display of Reddit analysis results for task 5.1.4

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Starting Reddit Display Test${NC}"
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
echo -e "${YELLOW}Display Verification Tests${NC}"
echo "========================="

# Test queries designed to verify specific display elements
DISPLAY_TESTS=(
    # Test 1: Basic formatting test
    "What are the top 5 posts on r/Comcast_Xfinity right now?"
    
    # Test 2: List formatting test
    "Categorize the most common issues people are having with Comcast"
    
    # Test 3: Post details test
    "Find a detailed post about internet connection problems and summarize it"
    
    # Test 4: Sentiment analysis display test
    "Analyze the sentiment of recent customer service posts"
    
    # Test 5: Geographic mentions test
    "Are there any service outages reported by location?"
)

# Run each display test and save responses for inspection
echo -e "${YELLOW}Running automated display tests...${NC}"
mkdir -p test_results

for i in "${!DISPLAY_TESTS[@]}"; do
    query="${DISPLAY_TESTS[$i]}"
    echo -e "${YELLOW}Test $((i+1)): ${NC}$query"
    
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
    
    # Save the full response for later inspection
    echo "$RESPONSE" > test_results/test_$((i+1))_response.json
    
    # Extract just the message content for readability
    MESSAGE=$(echo "$RESPONSE" | grep -o '"content":"[^"]*"' | sed 's/"content":"//;s/"$//')
    echo "$MESSAGE" > test_results/test_$((i+1))_message.txt
    
    # Check if we got a response
    if [[ $RESPONSE == *"message"* ]]; then
        echo -e "${GREEN}✓ Response received${NC}"
        
        # Display verification checks
        if [[ "$MESSAGE" == *"["* && "$MESSAGE" == *"]"* ]]; then
            echo -e "${GREEN}✓ Contains bracketed references${NC}"
        else
            echo -e "${YELLOW}⚠ No bracketed references found${NC}"
        fi
        
        if [[ "$MESSAGE" == *"-"* ]]; then
            echo -e "${GREEN}✓ Contains list formatting${NC}"
        else
            echo -e "${YELLOW}⚠ No list formatting detected${NC}"
        fi
        
        WORD_COUNT=$(echo "$MESSAGE" | wc -w)
        if [[ $WORD_COUNT -gt 50 ]]; then
            echo -e "${GREEN}✓ Response is substantial ($WORD_COUNT words)${NC}"
        else
            echo -e "${YELLOW}⚠ Response may be too brief ($WORD_COUNT words)${NC}"
        fi
    else
        echo -e "${RED}✗ Test failed${NC}"
        echo "API Response: $RESPONSE"
    fi
    echo ""
    
    # Small delay between requests
    sleep 3
done

echo -e "${YELLOW}Manual Display Verification${NC}"
echo "============================="
echo "Please open http://localhost:3000 in your browser and verify the following display elements:"
echo ""
echo "1. Post References: Check that Reddit post titles are clearly identifiable"
echo "2. Formatting: Verify that lists, paragraphs, and sections are properly formatted"
echo "3. Content Length: Responses should be detailed enough to be useful"
echo "4. Special Characters: Ensure that quotes, brackets, and other special characters display correctly"
echo "5. UI Responsiveness: The chat interface should remain responsive with long responses"
echo ""
echo "Backend server is running at http://localhost:8000"
echo "Frontend application is running at http://localhost:3000"
echo ""
echo "Test results have been saved to the 'test_results' directory for review."
echo ""

# Create a checklist file for manual verification
cat > test_results/display_verification_checklist.md << EOL
# Reddit Analysis Display Verification Checklist

## Date: $(date +"%Y-%m-%d")

For each test, verify the following display elements in the browser:

### Test 1: Basic Post Display
- [ ] Post titles are clearly displayed
- [ ] Post dates are formatted properly
- [ ] Post content snippets are readable
- [ ] Overall formatting is clean and organized

### Test 2: List Formatting
- [ ] Categories are clearly separated
- [ ] List items use proper bullet points or numbering
- [ ] Indentation is consistent
- [ ] Hierarchical information is visually organized

### Test 3: Post Details
- [ ] Long post content is properly formatted
- [ ] Links (if any) are distinguished from regular text
- [ ] Quotes or code blocks are properly formatted
- [ ] Important details are highlighted or emphasized

### Test 4: Sentiment Analysis
- [ ] Sentiment categories are clearly labeled
- [ ] Positive/negative classifications are distinguishable
- [ ] Supporting examples are properly attributed
- [ ] Analysis is presented in a readable format

### Test 5: Geographic Information
- [ ] Location information is clearly presented
- [ ] Related outage information is properly grouped
- [ ] Temporal information (when outages occurred) is clear
- [ ] Information is organized in a meaningful way

## Overall UI Verification
- [ ] Responses appear in the chat thread correctly
- [ ] Long responses don't break the UI layout
- [ ] Scrolling through chat history works smoothly
- [ ] Text is readable at different screen sizes
EOL

echo -e "${YELLOW}Created verification checklist:${NC} test_results/display_verification_checklist.md"
echo ""

# Ask if user wants to stop the servers
read -p "Press Enter to stop the servers when done testing..." 

# Cleanup
echo "Stopping servers..."
kill $BACKEND_PID 2>/dev/null
kill $FRONTEND_PID 2>/dev/null

echo -e "${GREEN}Test completed.${NC}"
echo "Check backend.log and frontend.log for details." 