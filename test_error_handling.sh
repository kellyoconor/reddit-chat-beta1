#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Reddit Analyzer Error Handling Test${NC}"
echo "===================================="
echo ""

# Test 1: Invalid request format
echo -e "${YELLOW}Test 1: Invalid request format${NC}"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"invalid":"data"}' -w "\nStatus: %{http_code}" http://localhost:8000/awp)
echo -e "Response: ${RESPONSE}"
if [[ $RESPONSE == *"Status: 400"* ]]; then
    echo -e "${GREEN}✓ Server correctly returned 400 for invalid request${NC}"
else
    echo -e "${RED}✗ Server did not handle invalid request properly${NC}"
fi

# Test 2: Empty messages array
echo -e "\n${YELLOW}Test 2: Empty messages array${NC}"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"messages":[]}' -w "\nStatus: %{http_code}" http://localhost:8000/awp)
echo -e "Response: ${RESPONSE}"
if [[ $RESPONSE == *"Status: 400"* ]]; then
    echo -e "${GREEN}✓ Server correctly returned 400 for empty messages${NC}"
else
    echo -e "${RED}✗ Server did not handle empty messages properly${NC}"
fi

# Test 3: Invalid endpoint
echo -e "\n${YELLOW}Test 3: Invalid endpoint${NC}"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"test"}]}' -w "\nStatus: %{http_code}" http://localhost:8000/invalid-endpoint)
echo -e "Response: ${RESPONSE}"
if [[ $RESPONSE == *"Status: 404"* ]]; then
    echo -e "${GREEN}✓ Server correctly returned 404 for invalid endpoint${NC}"
else
    echo -e "${RED}✗ Server did not handle invalid endpoint properly${NC}"
fi

# Test 4: Complex query
echo -e "\n${YELLOW}Test 4: Complex query with specific search terms${NC}"
RESPONSE=$(curl -s -X POST -H "Content-Type: application/json" -d '{"messages":[{"role":"user","content":"Show me detailed analysis of posts about internet outages in California with customer sentiment breakdown and technical solutions mentioned"}]}' -w "\nStatus: %{http_code}" http://localhost:8000/awp)
if [[ $RESPONSE == *"Status: 200"* ]]; then
    echo -e "${GREEN}✓ Server processed complex query successfully${NC}"
else
    echo -e "${RED}✗ Server failed to process complex query${NC}"
fi

echo -e "\n${YELLOW}Error Handling Test Complete${NC}"
echo "===============================" 