#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Reddit Analyzer Integration Test${NC}"
echo "=============================="
echo ""

# Test Backend Health
echo -e "${YELLOW}Testing Backend Health...${NC}"
BACKEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8000/health)

if [ "$BACKEND_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ Backend is running (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Backend is not running properly (HTTP $BACKEND_RESPONSE)${NC}"
    echo "  Make sure to start the backend with:"
    echo "  cd reddit-analyzer-backend && source venv/bin/activate && python main.py"
fi

# Test Frontend
echo -e "\n${YELLOW}Testing Frontend...${NC}"
FRONTEND_RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3001)

if [ "$FRONTEND_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ Frontend is running (HTTP 200)${NC}"
else
    echo -e "${RED}✗ Frontend is not accessible (HTTP $FRONTEND_RESPONSE)${NC}"
    echo "  Make sure to start the frontend with:"
    echo "  cd reddit-analyzer-frontend && npm run dev"
fi

# Test AG-UI Protocol Endpoint
echo -e "\n${YELLOW}Testing AG-UI Protocol Endpoint...${NC}"
AGUI_RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"Test"}]}' -o /dev/null -w "%{http_code}" http://localhost:8000/awp)

if [ "$AGUI_RESPONSE" == "200" ]; then
    echo -e "${GREEN}✓ AG-UI Protocol endpoint is working (HTTP 200)${NC}"
else
    echo -e "${RED}✗ AG-UI Protocol endpoint is not responding correctly (HTTP $AGUI_RESPONSE)${NC}"
    echo "  Check backend logs for errors."
fi

echo -e "\n${YELLOW}Integration Test Complete${NC}"
echo "============================" 