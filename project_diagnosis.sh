#!/bin/bash

# Project Diagnostic Script
# This script checks each component of the Reddit Analyzer project
# and provides a clear status report

# Color coding
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}===== Reddit Analyzer Project Diagnostic =====${NC}"
echo "Running diagnostic checks on each component..."
echo ""

# Create a diagnostic report file
REPORT_FILE="project_diagnostic_report.md"
echo "# Reddit Analyzer Project Diagnostic Report" > $REPORT_FILE
echo "Generated on: $(date)" >> $REPORT_FILE
echo "" >> $REPORT_FILE

# 1. Check project structure
echo -e "${YELLOW}1. Checking Project Structure${NC}"
echo "## 1. Project Structure" >> $REPORT_FILE

# Check backend directory and key files
if [ -d "reddit-analyzer-backend" ]; then
  echo -e "${GREEN}✓ Backend directory exists${NC}"
  echo "- ✅ Backend directory exists" >> $REPORT_FILE
  
  # Check key backend files
  for file in "main.py" "reddit_tools.py" "requirements.txt"; do
    if [ -f "reddit-analyzer-backend/$file" ]; then
      echo -e "${GREEN}✓ Backend file $file exists${NC}"
      echo "- ✅ Backend file $file exists" >> $REPORT_FILE
    else
      echo -e "${RED}✗ Backend file $file missing${NC}"
      echo "- ❌ Backend file $file missing" >> $REPORT_FILE
    fi
  done
  
  # Check .env file
  if [ -f "reddit-analyzer-backend/.env" ]; then
    echo -e "${GREEN}✓ Backend .env file exists${NC}"
    echo "- ✅ Backend .env file exists" >> $REPORT_FILE
    
    # Check if .env contains OPENAI_API_KEY
    if grep -q "OPENAI_API_KEY" "reddit-analyzer-backend/.env"; then
      echo -e "${GREEN}✓ OPENAI_API_KEY is set in .env${NC}"
      echo "- ✅ OPENAI_API_KEY is set in .env" >> $REPORT_FILE
    else
      echo -e "${RED}✗ OPENAI_API_KEY is missing in .env${NC}"
      echo "- ❌ OPENAI_API_KEY is missing in .env" >> $REPORT_FILE
    fi
  else
    echo -e "${RED}✗ Backend .env file missing${NC}"
    echo "- ❌ Backend .env file missing" >> $REPORT_FILE
  fi
else
  echo -e "${RED}✗ Backend directory missing${NC}"
  echo "- ❌ Backend directory missing" >> $REPORT_FILE
fi

# Check frontend directory and key files
if [ -d "reddit-analyzer-frontend" ]; then
  echo -e "${GREEN}✓ Frontend directory exists${NC}"
  echo "- ✅ Frontend directory exists" >> $REPORT_FILE
  
  # Check key frontend files
  if [ -d "reddit-analyzer-frontend/app" ]; then
    echo -e "${GREEN}✓ Frontend app directory exists${NC}"
    echo "- ✅ Frontend app directory exists" >> $REPORT_FILE
    
    # Check page.js and layout.js
    for file in "page.js" "layout.tsx"; do
      if [ -f "reddit-analyzer-frontend/app/$file" ]; then
        echo -e "${GREEN}✓ Frontend file $file exists${NC}"
        echo "- ✅ Frontend file $file exists" >> $REPORT_FILE
      else
        echo -e "${RED}✗ Frontend file $file missing${NC}"
        echo "- ❌ Frontend file $file missing" >> $REPORT_FILE
      fi
    done
  else
    echo -e "${RED}✗ Frontend app directory missing${NC}"
    echo "- ❌ Frontend app directory missing" >> $REPORT_FILE
  fi
  
  # Check package.json
  if [ -f "reddit-analyzer-frontend/package.json" ]; then
    echo -e "${GREEN}✓ Frontend package.json exists${NC}"
    echo "- ✅ Frontend package.json exists" >> $REPORT_FILE
    
    # Check if package.json contains CopilotKit
    if grep -q "copilotkit" "reddit-analyzer-frontend/package.json"; then
      echo -e "${GREEN}✓ CopilotKit dependency exists in package.json${NC}"
      echo "- ✅ CopilotKit dependency exists in package.json" >> $REPORT_FILE
    else
      echo -e "${RED}✗ CopilotKit dependency missing in package.json${NC}"
      echo "- ❌ CopilotKit dependency missing in package.json" >> $REPORT_FILE
    fi
  else
    echo -e "${RED}✗ Frontend package.json missing${NC}"
    echo "- ❌ Frontend package.json missing" >> $REPORT_FILE
  fi
else
  echo -e "${RED}✗ Frontend directory missing${NC}"
  echo "- ❌ Frontend directory missing" >> $REPORT_FILE
fi

echo ""

# 2. Check backend setup
echo -e "${YELLOW}2. Checking Backend Setup${NC}"
echo "## 2. Backend Setup" >> $REPORT_FILE

# Check if Python is installed
if command -v python3 &> /dev/null; then
  PYTHON_VERSION=$(python3 --version)
  echo -e "${GREEN}✓ Python is installed: $PYTHON_VERSION${NC}"
  echo "- ✅ Python is installed: $PYTHON_VERSION" >> $REPORT_FILE
else
  echo -e "${RED}✗ Python is not installed${NC}"
  echo "- ❌ Python is not installed" >> $REPORT_FILE
fi

# Check if virtual environment exists
if [ -d "reddit-analyzer-backend/venv" ]; then
  echo -e "${GREEN}✓ Python virtual environment exists${NC}"
  echo "- ✅ Python virtual environment exists" >> $REPORT_FILE
else
  echo -e "${RED}✗ Python virtual environment missing${NC}"
  echo "- ❌ Python virtual environment missing" >> $REPORT_FILE
fi

# Check installed packages (without activating venv)
echo -e "${YELLOW}Key backend dependencies:${NC}"
echo "### Key backend dependencies:" >> $REPORT_FILE

for pkg in "fastapi" "uvicorn" "openai" "python-dotenv"; do
  if [ -d "reddit-analyzer-backend/venv/lib/python"*/site-packages/$pkg ]; then
    echo -e "${GREEN}✓ $pkg is installed${NC}"
    echo "- ✅ $pkg is installed" >> $REPORT_FILE
  else
    echo -e "${RED}✗ $pkg is not installed${NC}"
    echo "- ❌ $pkg is not installed" >> $REPORT_FILE
  fi
done

# Check for aiohttp specifically (needed for Reddit tools)
if [ -d "reddit-analyzer-backend/venv/lib/python"*/site-packages/aiohttp ]; then
  echo -e "${GREEN}✓ aiohttp is installed (required for Reddit tools)${NC}"
  echo "- ✅ aiohttp is installed (required for Reddit tools)" >> $REPORT_FILE
else
  echo -e "${RED}✗ aiohttp is not installed (required for Reddit tools)${NC}"
  echo "- ❌ aiohttp is not installed (required for Reddit tools)" >> $REPORT_FILE
fi

echo ""

# 3. Check frontend setup
echo -e "${YELLOW}3. Checking Frontend Setup${NC}"
echo "## 3. Frontend Setup" >> $REPORT_FILE

# Check if Node.js is installed
if command -v node &> /dev/null; then
  NODE_VERSION=$(node --version)
  echo -e "${GREEN}✓ Node.js is installed: $NODE_VERSION${NC}"
  echo "- ✅ Node.js is installed: $NODE_VERSION" >> $REPORT_FILE
else
  echo -e "${RED}✗ Node.js is not installed${NC}"
  echo "- ❌ Node.js is not installed" >> $REPORT_FILE
fi

# Check if npm is installed
if command -v npm &> /dev/null; then
  NPM_VERSION=$(npm --version)
  echo -e "${GREEN}✓ npm is installed: $NPM_VERSION${NC}"
  echo "- ✅ npm is installed: $NPM_VERSION" >> $REPORT_FILE
else
  echo -e "${RED}✗ npm is not installed${NC}"
  echo "- ❌ npm is not installed" >> $REPORT_FILE
fi

# Check if node_modules exists
if [ -d "reddit-analyzer-frontend/node_modules" ]; then
  echo -e "${GREEN}✓ Frontend dependencies are installed${NC}"
  echo "- ✅ Frontend dependencies are installed" >> $REPORT_FILE
else
  echo -e "${RED}✗ Frontend dependencies are not installed${NC}"
  echo "- ❌ Frontend dependencies are not installed" >> $REPORT_FILE
fi

echo ""

# 4. Check key configuration
echo -e "${YELLOW}4. Checking Key Configuration${NC}"
echo "## 4. Key Configuration" >> $REPORT_FILE

# Check backend port configuration
if [ -f "reddit-analyzer-backend/main.py" ]; then
  BACKEND_PORT=$(grep -o "port=[0-9]*" "reddit-analyzer-backend/main.py" | cut -d= -f2)
  if [ -n "$BACKEND_PORT" ]; then
    echo -e "${GREEN}✓ Backend port: $BACKEND_PORT${NC}"
    echo "- ✅ Backend port: $BACKEND_PORT" >> $REPORT_FILE
  else
    echo -e "${YELLOW}⚠ Could not determine backend port from code${NC}"
    echo "- ⚠️ Could not determine backend port from code" >> $REPORT_FILE
  fi
else
  echo -e "${RED}✗ Cannot check backend port: main.py missing${NC}"
  echo "- ❌ Cannot check backend port: main.py missing" >> $REPORT_FILE
fi

# Check frontend backend URL configuration
if [ -f "reddit-analyzer-frontend/app/page.js" ]; then
  FRONTEND_BACKEND_URL=$(grep -o "backendUrl = \"[^\"]*\"" "reddit-analyzer-frontend/app/page.js" | cut -d\" -f2)
  if [ -n "$FRONTEND_BACKEND_URL" ]; then
    echo -e "${GREEN}✓ Frontend is configured to connect to: $FRONTEND_BACKEND_URL${NC}"
    echo "- ✅ Frontend is configured to connect to: $FRONTEND_BACKEND_URL" >> $REPORT_FILE
    
    # Check if backend and frontend ports match
    if [ -n "$BACKEND_PORT" ]; then
      if [[ "$FRONTEND_BACKEND_URL" == *":$BACKEND_PORT"* ]]; then
        echo -e "${GREEN}✓ Frontend and backend ports match${NC}"
        echo "- ✅ Frontend and backend ports match" >> $REPORT_FILE
      else
        echo -e "${RED}✗ Frontend and backend ports DO NOT match${NC}"
        echo "- ❌ Frontend and backend ports DO NOT match" >> $REPORT_FILE
      fi
    fi
  else
    echo -e "${YELLOW}⚠ Could not determine backend URL from frontend code${NC}"
    echo "- ⚠️ Could not determine backend URL from frontend code" >> $REPORT_FILE
  fi
else
  echo -e "${RED}✗ Cannot check frontend configuration: page.js missing${NC}"
  echo "- ❌ Cannot check frontend configuration: page.js missing" >> $REPORT_FILE
fi

echo ""
echo -e "${BLUE}===== Diagnostic Complete =====${NC}"
echo -e "Detailed report saved to: ${GREEN}$REPORT_FILE${NC}"
echo ""
echo -e "${YELLOW}Next Steps:${NC}"
echo "1. Review the diagnostic report"
echo "2. Fix any issues marked with ❌"
echo "3. Start the backend and frontend servers separately to verify each component"
echo ""
echo "To start the backend (after fixing issues):"
echo "cd reddit-analyzer-backend && source venv/bin/activate && python3 main.py"
echo ""
echo "To start the frontend (in a separate terminal, after fixing issues):"
echo "cd reddit-analyzer-frontend && npm run dev" 