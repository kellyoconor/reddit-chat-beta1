# AG-UI Reddit Analyzer - Complete Implementation Guide

## **Project Overview**
Build a Reddit analyzer for r/Comcast_Xfinity using the AG-UI protocol, allowing users to ask natural language questions about customer complaints, sentiment, and issues.

## **Architecture Overview**

### **Two-Service Architecture**
```
┌─────────────────┐    AG-UI Protocol    ┌──────────────────┐
│   Frontend      │◄────────────────────►│   Backend        │
│   (Next.js)     │    HTTP/Events       │   (Python)       │
│   Port 3000     │                      │   Port 8000      │
└─────────────────┘                      └──────────────────┘
```

### **Frontend Service (Next.js + CopilotKit)**
- **Purpose**: User interface with chat components
- **Technology**: Next.js 15, React 19, CopilotKit UI components
- **Responsibilities**:
  - Render chat interface
  - Connect to Python backend via AG-UI protocol
  - Display Reddit analysis results
  - Handle user interactions

### **Backend Service (Python + FastAPI)**
- **Purpose**: AG-UI compatible agent with Reddit analysis capabilities
- **Technology**: Python 3.12, FastAPI, OpenAI API
- **Responsibilities**:
  - Implement AG-UI protocol endpoints
  - Fetch Reddit data (no auth required)
  - Process data with OpenAI
  - Stream responses back to frontend

---

## **Part 1: Backend Implementation (Python + FastAPI)**

### **Step 1: Project Setup**

```bash
# Create backend directory
mkdir reddit-analyzer-backend
cd reddit-analyzer-backend

# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Create requirements.txt
cat > requirements.txt << EOF
fastapi>=0.104.0
uvicorn>=0.24.0
openai>=1.3.0
requests>=2.31.0
python-multipart>=0.0.6
python-dotenv>=1.0.0
EOF

# Install dependencies
pip install -r requirements.txt
```

### **Step 2: Environment Configuration**

```bash
# Create .env file
cat > .env << EOF
OPENAI_API_KEY=your_openai_api_key_here
CORS_ORIGINS=http://localhost:3000,https://your-frontend-domain.com
EOF
```

### **Step 3: Reddit Tools Implementation**

Create `reddit_tools.py`:

```python
import requests
from typing import Dict, Any, List
import asyncio
from datetime import datetime

class RedditAnalyzer:
    def __init__(self):
        self.headers = {'User-Agent': 'AG-UI Reddit Analyzer 1.0'}
        self.base_url = "https://www.reddit.com/r/Comcast_Xfinity"
    
    async def fetch_recent_posts(self, timeframe: str = "hot", limit: int = 25) -> List[Dict]:
        """Fetch recent posts from r/Comcast_Xfinity"""
        try:
            url = f"{self.base_url}/{timeframe}.json?limit={limit}"
            response = requests.get(url, headers=self.headers, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            posts = []
            for child in data['data']['children']:
                post = child['data']
                posts.append({
                    'title': post.get('title', ''),
                    'selftext': post.get('selftext', ''),
                    'score': post.get('score', 0),
                    'num_comments': post.get('num_comments', 0),
                    'created_utc': post.get('created_utc', 0),
                    'url': f"https://reddit.com{post.get('permalink', '')}",
                    'flair': post.get('link_flair_text', ''),
                    'author': post.get('author', '')
                })
            return posts
        except Exception as e:
            return [{"error": f"Failed to fetch Reddit posts: {str(e)}"}]
    
    async def search_subreddit(self, query: str, limit: int = 20) -> List[Dict]:
        """Search r/Comcast_Xfinity for specific topics"""
        try:
            search_url = f"{self.base_url}/search.json?q={query}&restrict_sr=1&limit={limit}&sort=relevance"
            response = requests.get(search_url, headers=self.headers, timeout=10)
            response.raise_for_status()
            data = response.json()
            
            posts = []
            for child in data['data']['children']:
                post = child['data']
                selftext = post.get('selftext', '')
                if len(selftext) > 500:
                    selftext = selftext[:500] + "..."
                
                posts.append({
                    'title': post.get('title', ''),
                    'selftext': selftext,
                    'score': post.get('score', 0),
                    'num_comments': post.get('num_comments', 0),
                    'created_utc': post.get('created_utc', 0),
                    'url': f"https://reddit.com{post.get('permalink', '')}",
                    'flair': post.get('link_flair_text', ''),
                    'author': post.get('author', '')
                })
            return posts
        except Exception as e:
            return [{"error": f"Failed to search Reddit: {str(e)}"}]
    
    def format_posts_for_analysis(self, posts: List[Dict]) -> str:
        """Format posts for OpenAI analysis"""
        if not posts or (len(posts) == 1 and 'error' in posts[0]):
            return "No posts found or error occurred."
        
        formatted = "Reddit Posts Analysis:\n\n"
        for i, post in enumerate(posts[:20], 1):  # Limit to 20 posts
            if 'error' in post:
                continue
            formatted += f"{i}. Title: {post['title']}\n"
            if post['selftext']:
                formatted += f"   Content: {post['selftext'][:200]}...\n"
            formatted += f"   Score: {post['score']}, Comments: {post['num_comments']}\n"
            if post['flair']:
                formatted += f"   Flair: {post['flair']}\n"
            formatted += f"   URL: {post['url']}\n\n"
        
        return formatted
```

### **Step 4: AG-UI Protocol Implementation**

Create `main.py`:

```python
import asyncio
import json
import os
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
import openai
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv
from reddit_tools import RedditAnalyzer

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="AG-UI Reddit Analyzer",
    description="AG-UI compatible agent for analyzing r/Comcast_Xfinity",
    version="1.0.0"
)

# Configure CORS
cors_origins = os.getenv("CORS_ORIGINS", "http://localhost:3000").split(",")
app.add_middleware(
    CORSMiddleware,
    allow_origins=cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize services
openai.api_key = os.getenv("OPENAI_API_KEY")
if not openai.api_key:
    raise ValueError("OPENAI_API_KEY environment variable is required")

reddit_analyzer = RedditAnalyzer()

# AG-UI Tools Configuration
TOOLS = [
    {
        "type": "function",
        "function": {
            "name": "fetch_recent_posts",
            "description": "Get recent posts from r/Comcast_Xfinity subreddit",
            "parameters": {
                "type": "object",
                "properties": {
                    "timeframe": {
                        "type": "string",
                        "enum": ["hot", "new", "top"],
                        "description": "Sort type for posts (hot=trending, new=recent, top=highest scored)",
                        "default": "hot"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Number of posts to fetch (1-100)",
                        "minimum": 1,
                        "maximum": 100,
                        "default": 25
                    }
                }
            }
        }
    },
    {
        "type": "function",
        "function": {
            "name": "search_subreddit",
            "description": "Search r/Comcast_Xfinity for posts containing specific keywords",
            "parameters": {
                "type": "object",
                "properties": {
                    "query": {
                        "type": "string",
                        "description": "Search query (e.g., 'outage', 'slow internet', 'billing issue')"
                    },
                    "limit": {
                        "type": "integer",
                        "description": "Number of results to return (1-50)",
                        "minimum": 1,
                        "maximum": 50,
                        "default": 20
                    }
                },
                "required": ["query"]
            }
        }
    }
]

SYSTEM_PROMPT = """You are a Reddit analyzer focused on r/Comcast_Xfinity. Help users understand customer sentiment, common issues, and solutions discussed in the subreddit.

When analyzing posts:
1. Categorize issues (billing, outages, speed, equipment, customer service)
2. Identify geographic patterns when mentioned
3. Extract helpful solutions from comments
4. Summarize sentiment and trends
5. Always provide context about when posts were made
6. Be helpful and provide actionable insights based on the Reddit data

You have access to tools to fetch recent posts and search for specific topics. Use these tools to provide accurate, up-to-date information about what Comcast Xfinity customers are discussing."""

async def call_openai_with_tools(messages: List[Dict]) -> Dict:
    """Call OpenAI API with function calling support"""
    try:
        response = await openai.ChatCompletion.acreate(
            model="gpt-4",
            messages=[{"role": "system", "content": SYSTEM_PROMPT}] + messages,
            tools=TOOLS,
            tool_choice="auto",
            stream=False
        )
        return response
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"OpenAI API error: {str(e)}")

async def execute_tool_call(tool_call) -> str:
    """Execute a tool call and return the result"""
    function_name = tool_call.function.name
    function_args = json.loads(tool_call.function.arguments)
    
    if function_name == "fetch_recent_posts":
        posts = await reddit_analyzer.fetch_recent_posts(
            timeframe=function_args.get("timeframe", "hot"),
            limit=function_args.get("limit", 25)
        )
        return reddit_analyzer.format_posts_for_analysis(posts)
    
    elif function_name == "search_subreddit":
        posts = await reddit_analyzer.search_subreddit(
            query=function_args["query"],
            limit=function_args.get("limit", 20)
        )
        return reddit_analyzer.format_posts_for_analysis(posts)
    
    else:
        return f"Unknown function: {function_name}"

# AG-UI Protocol Endpoints

@app.get("/")
async def root():
    """Health check endpoint"""
    return {
        "service": "AG-UI Reddit Analyzer",
        "status": "running",
        "version": "1.0.0",
        "endpoints": {
            "ag_ui": "/awp",
            "health": "/health"
        }
    }

@app.get("/health")
async def health_check():
    """Detailed health check"""
    return {
        "status": "healthy",
        "openai_configured": bool(openai.api_key),
        "reddit_tools": "available",
        "timestamp": "2025-01-01T00:00:00Z"
    }

@app.post("/awp")
async def ag_ui_endpoint(request: Request):
    """Main AG-UI protocol endpoint"""
    try:
        # Parse request body
        body = await request.json()
        messages = body.get("messages", [])
        
        if not messages:
            return JSONResponse(
                content={"error": "No messages provided"},
                status_code=400
            )
        
        # Process with OpenAI
        response = await call_openai_with_tools(messages)
        message = response.choices[0].message
        
        # Handle tool calls if present
        if message.tool_calls:
            # Execute tool calls
            tool_messages = []
            for tool_call in message.tool_calls:
                result = await execute_tool_call(tool_call)
                tool_messages.append({
                    "tool_call_id": tool_call.id,
                    "role": "tool",
                    "content": result
                })
            
            # Get final response with tool results
            final_messages = messages + [message.model_dump()] + tool_messages
            final_response = await call_openai_with_tools(final_messages)
            final_message = final_response.choices[0].message.content
        else:
            final_message = message.content
        
        # Return AG-UI compatible response
        return JSONResponse(content={
            "message": final_message,
            "type": "message",
            "timestamp": "2025-01-01T00:00:00Z"
        })
        
    except Exception as e:
        return JSONResponse(
            content={
                "error": "Internal server error",
                "details": str(e)
            },
            status_code=500
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000, reload=True)
```

### **Step 5: Run Backend Service**

```bash
# Start the server
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Test the endpoints
curl http://localhost:8000/
curl http://localhost:8000/health
```

---

## **Part 2: Frontend Implementation (Next.js + CopilotKit)**

### **Step 6: Frontend Setup**

```bash
# Create frontend directory
npx create-next-app@latest reddit-analyzer-frontend
cd reddit-analyzer-frontend

# Install AG-UI compatible CopilotKit packages
npm install @copilotkit/react-core @copilotkit/react-ui
```

### **Step 7: Environment Configuration**

Create `.env.local`:

```bash
NEXT_PUBLIC_AGENT_URL=http://localhost:8000/awp
```

### **Step 8: Frontend Implementation**

Update `app/page.js`:

```javascript
"use client";

import { CopilotKit } from "@copilotkit/react-core";
import { CopilotChat } from "@copilotkit/react-ui";
import "@copilotkit/react-ui/styles.css";

export default function Home() {
  const agentUrl = process.env.NEXT_PUBLIC_AGENT_URL || "http://localhost:8000/awp";

  return (
    <div className="min-h-screen bg-gray-50">
      <CopilotKit runtimeUrl={agentUrl}>
        <div className="flex h-screen">
          {/* Left Panel - App Description */}
          <div className="flex-1 max-w-4xl mx-auto p-8">
            <div className="max-w-3xl mx-auto">
              <h1 className="text-4xl font-bold text-gray-900 mb-4">
                r/Comcast_Xfinity Analyzer
              </h1>
              <p className="text-xl text-gray-600 mb-8">
                Ask questions about posts and discussions in the Comcast Xfinity subreddit using AI-powered analysis.
              </p>
              
              <div className="bg-white rounded-lg shadow-sm border p-6 mb-8">
                <h2 className="text-2xl font-semibold mb-6">Try asking:</h2>
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  <div className="space-y-3">
                    <div className="p-3 bg-blue-50 rounded-lg">
                      <p className="text-blue-800 font-medium">Recent Issues</p>
                      <p className="text-blue-600 text-sm">"What are the most common complaints this week?"</p>
                    </div>
                    <div className="p-3 bg-green-50 rounded-lg">
                      <p className="text-green-800 font-medium">Outage Analysis</p>
                      <p className="text-green-600 text-sm">"Show me recent posts about internet outages"</p>
                    </div>
                    <div className="p-3 bg-purple-50 rounded-lg">
                      <p className="text-purple-800 font-medium">Customer Service</p>
                      <p className="text-purple-600 text-sm">"What do people say about Xfinity customer service?"</p>
                    </div>
                  </div>
                  <div className="space-y-3">
                    <div className="p-3 bg-orange-50 rounded-lg">
                      <p className="text-orange-800 font-medium">Solutions</p>
                      <p className="text-orange-600 text-sm">"Find posts about slow internet and show solutions"</p>
                    </div>
                    <div className="p-3 bg-red-50 rounded-lg">
                      <p className="text-red-800 font-medium">Billing Issues</p>
                      <p className="text-red-600 text-sm">"What billing issues are people discussing?"</p>
                    </div>
                    <div className="p-3 bg-indigo-50 rounded-lg">
                      <p className="text-indigo-800 font-medium">Equipment Problems</p>
                      <p className="text-indigo-600 text-sm">"Search for posts about modem and router issues"</p>
                    </div>
                  </div>
                </div>
              </div>

              <div className="bg-white rounded-lg shadow-sm border p-6">
                <h3 className="text-lg font-semibold mb-3">How it works:</h3>
                <ol className="space-y-2 text-gray-600">
                  <li className="flex items-start">
                    <span className="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-medium mr-3 mt-0.5">1</span>
                    Ask questions about Comcast Xfinity customer experiences
                  </li>
                  <li className="flex items-start">
                    <span className="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-medium mr-3 mt-0.5">2</span>
                    AI fetches real-time data from r/Comcast_Xfinity subreddit
                  </li>
                  <li className="flex items-start">
                    <span className="bg-blue-500 text-white rounded-full w-6 h-6 flex items-center justify-center text-sm font-medium mr-3 mt-0.5">3</span>
                    Get intelligent analysis of customer sentiment and issues
                  </li>
                </ol>
              </div>
            </div>
          </div>
          
          {/* Right Panel - Chat Interface */}
          <div className="w-96 border-l border-gray-200 bg-white">
            <CopilotChat
              instructions="You are a Reddit analyzer focused on r/Comcast_Xfinity. Help users understand customer sentiment, common issues, and solutions discussed in the subreddit. Use the available tools to fetch and analyze real Reddit data."
              labels={{
                title: "Reddit Analyzer",
                initial: "Hi! I can help you analyze r/Comcast_Xfinity posts and discussions. What would you like to know about customer experiences, complaints, or solutions?"
              }}
            />
          </div>
        </div>
      </CopilotKit>
    </div>
  );
}
```

Update `app/layout.js`:

```javascript
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'] })

export const metadata = {
  title: 'Reddit Analyzer - AG-UI',
  description: 'AI-powered analysis of r/Comcast_Xfinity discussions',
}

export default function RootLayout({ children }) {
  return (
    <html lang="en">
      <body className={inter.className}>{children}</body>
    </html>
  )
}
```

### **Step 9: Run Frontend Service**

```bash
# Start the development server
npm run dev

# Open http://localhost:3000
```

---

## **Part 3: Deployment**

### **Backend Deployment (Railway/Render/Heroku)**

#### **Option A: Railway**
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login and deploy
railway login
railway init
railway add
railway deploy
```

#### **Option B: Render**
1. Connect your GitHub repository
2. Set environment variables in Render dashboard
3. Deploy automatically on git push

### **Frontend Deployment (Vercel)**

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel

# Set environment variables in Vercel dashboard:
# NEXT_PUBLIC_AGENT_URL=https://your-backend-url.com/awp
```

---

## **Part 4: Testing & Usage**

### **Test Backend Directly**

```bash
# Test health endpoint
curl http://localhost:8000/health

# Test AG-UI endpoint
curl -X POST http://localhost:8000/awp \
  -H "Content-Type: application/json" \
  -d '{"messages": [{"role": "user", "content": "What are the most common complaints this week?"}]}'
```

### **Sample Queries to Test**

1. **"What are the most common complaints this week?"**
2. **"Show me posts about internet outages"**
3. **"What do people say about Xfinity customer service?"**
4. **"Find solutions for slow internet speed"**
5. **"What billing issues are people discussing?"**

### **Expected Behavior**

- AI fetches real Reddit data using tools
- Categorizes issues (billing, speed, outages, equipment, service)
- Provides sentiment analysis
- Extracts solutions from discussions
- Shows post timestamps and engagement metrics

---

## **Troubleshooting**

### **Common Issues**

1. **Backend not starting**: Check OpenAI API key in `.env`
2. **CORS errors**: Verify CORS_ORIGINS includes your frontend URL
3. **Tool calls failing**: Check Reddit API accessibility (no auth required)
4. **Frontend not connecting**: Verify NEXT_PUBLIC_AGENT_URL points to backend

### **Debug Endpoints**

- `GET /health` - Backend health check
- `GET /` - Service info
- Browser DevTools → Network tab for AG-UI requests

---

## **Next Steps & Extensions**

### **Potential Enhancements**

1. **Advanced Analytics**
   - Geographic issue mapping
   - Trend analysis over time
   - Sentiment scoring

2. **Additional Data Sources**
   - Twitter mentions
   - Trustpilot reviews
   - FCC complaints

3. **Export Features**
   - PDF reports
   - CSV data export
   - Dashboard views

4. **Real-time Updates**
   - WebSocket streaming
   - Auto-refresh functionality
   - Push notifications

This implementation provides a fully functional AG-UI compatible Reddit analyzer with real-time chat interface and intelligent analysis capabilities.