import asyncio
import json
import os
from fastapi import FastAPI, Request, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse, JSONResponse
from openai import AsyncOpenAI
from typing import Dict, Any, List, Optional
from dotenv import load_dotenv
from reddit_tools import RedditAnalyzer
import time

# Load environment variables
load_dotenv()

# Initialize FastAPI app
app = FastAPI(
    title="AG-UI Reddit Analyzer",
    description="AG-UI compatible agent for analyzing r/Comcast_Xfinity",
    version="1.0.0"
)

# Setup CORS - Allow all origins for development
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Initialize OpenAI client
openai_api_key = os.getenv("OPENAI_API_KEY", "dummy_key_for_testing")
client = AsyncOpenAI(api_key=openai_api_key)

# Initialize Reddit analyzer
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

# Helper function to validate messages before sending to OpenAI
def validate_messages(messages):
    """Ensure all messages have valid content and structure"""
    valid_messages = []
    
    print(f"VALIDATING MESSAGES: Received {len(messages)} messages to validate")
    for i, msg in enumerate(messages):
        # Debug log each message
        print(f"  Validating message [{i}]: {json.dumps(msg)}")
        
        # Make sure role exists
        if "role" not in msg:
            print(f"  WARNING: Message [{i}] missing role, skipping: {msg}")
            continue
            
        # Handle null content
        if "content" not in msg or msg["content"] is None:
            print(f"  WARNING: Message [{i}] has null content, setting to empty string: {msg}")
            msg = msg.copy()  # Create a copy to avoid modifying the original
            msg["content"] = ""  # Replace null with empty string
        
        # Special handling for assistant messages with tool_calls
        if msg.get("role") == "assistant" and "tool_calls" in msg and not msg.get("content"):
            print(f"  WARNING: Assistant message with tool_calls has empty content, setting default: {msg}")
            msg = msg.copy()
            msg["content"] = ""
            
        valid_messages.append(msg)
    
    print(f"VALIDATION COMPLETE: {len(valid_messages)} valid messages for OpenAI API")
    # Log all validated messages for debugging
    for i, msg in enumerate(valid_messages):
        print(f"  Final message [{i}]: role={msg.get('role')}, content_type={type(msg.get('content'))}, content_length={len(str(msg.get('content') or ''))}")
    
    return valid_messages

async def call_openai_with_tools(messages: List[Dict]) -> Dict:
    """Call OpenAI API with function calling support"""
    try:
        # Validate messages before sending to OpenAI
        validated_messages = validate_messages(messages)
        
        # Final safety check before API call
        for i, msg in enumerate(validated_messages):
            if msg.get("content") is None:
                print(f"CRITICAL ERROR: Message {i} still has null content after validation")
                # Force to empty string as last resort
                msg["content"] = ""
        
        system_message = {"role": "system", "content": SYSTEM_PROMPT}
        final_messages = [system_message] + validated_messages
        
        print(f"Sending {len(final_messages)} messages to OpenAI API")
        response = await client.chat.completions.create(
            model="gpt-3.5-turbo",
            messages=final_messages,
            tools=TOOLS,
            tool_choice="auto"
        )
        return response
    except Exception as e:
        print(f"OpenAI API error: {str(e)}")
        # For debugging, print the full message array
        print("Message array that caused the error:")
        for i, msg in enumerate(messages):
            content_type = type(msg.get("content"))
            content_preview = str(msg.get("content", ""))[:50] + "..." if msg.get("content") else "None"
            print(f"  Message {i}: role={msg.get('role')}, content_type={content_type}, content_preview={content_preview}")
        
        raise HTTPException(status_code=500, detail=f"OpenAI API error: {str(e)}")

# Modify the tool execution part to handle any message conversion issues
async def execute_tool_call(tool_call) -> str:
    """Execute a tool call and return the result"""
    function_name = tool_call.function.name
    function_args = json.loads(tool_call.function.arguments)
    
    print(f"Executing tool call: {function_name} with args: {function_args}")
    
    try:
        result = None
        if function_name == "fetch_recent_posts":
            posts = await reddit_analyzer.fetch_recent_posts(
                timeframe=function_args.get("timeframe", "hot"),
                limit=function_args.get("limit", 25)
            )
            result = reddit_analyzer.format_posts_for_analysis(posts)
        
        elif function_name == "search_subreddit":
            posts = await reddit_analyzer.search_subreddit(
                query=function_args["query"],
                limit=function_args.get("limit", 20)
            )
            result = reddit_analyzer.format_posts_for_analysis(posts)
        
        else:
            result = f"Unknown function: {function_name}"
        
        # Ensure result is never None or non-string
        if result is None:
            print(f"WARNING: Tool call {function_name} returned None result")
            return "No results available"
        
        # Ensure result is a string
        if not isinstance(result, str):
            print(f"WARNING: Tool call {function_name} returned non-string result: {type(result)}")
            return str(result)
            
        return result
    except Exception as e:
        print(f"Error executing tool call {function_name}: {str(e)}")
        return f"Error executing {function_name}: {str(e)}. Please try again with different parameters or contact support if the issue persists."

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
    return {"status": "healthy", "message": "Reddit Analyzer API is running"}

@app.post("/awp")
async def ag_ui_endpoint(request: Request):
    """Main AG-UI protocol endpoint"""
    try:
        # Get raw content for debugging
        raw_body = await request.body()
        print(f"Raw request body: {raw_body}")
        
        # Parse request body
        try:
            body = await request.json()
            print(f"Received request: {json.dumps(body, indent=2)}")
        except json.JSONDecodeError:
            print(f"Error parsing JSON from request body: {raw_body.decode()}")
            return JSONResponse(
                content={"error": "Invalid JSON in request body"},
                status_code=400
            )
        
        # Handle GraphQL query for CopilotKit
        if "operationName" in body and body.get("operationName") == "availableAgents":
            print("Handling availableAgents GraphQL query")
            return JSONResponse(content={
                "data": {
                    "availableAgents": {
                        "agents": [
                            {
                                "name": "Reddit Analyzer",
                                "id": "reddit-analyzer",
                                "description": "Analyzes r/Comcast_Xfinity subreddit",
                                "__typename": "Agent"
                            }
                        ],
                        "__typename": "AvailableAgents"
                    }
                }
            })
        
        # Handle GraphQL mutation for CopilotKit chat
        if "operationName" in body and body.get("operationName") == "generateMessage":
            print("Handling generateMessage GraphQL mutation")
            variables = body.get("variables", {})
            text = variables.get("text", "")
            
            if not text:
                return JSONResponse(
                    content={"error": "No message text provided"},
                    status_code=400
                )
                
            # Convert to messages format
            messages = [{"role": "user", "content": text}]
            
            # Process with OpenAI and continue with existing logic
            print(f"Sending messages to OpenAI: {messages}")
            response = await call_openai_with_tools(messages)
            message = response.choices[0].message
            
            # Handle tool calls if present (existing code)
            if message.tool_calls:
                # Execute tool calls
                tool_messages = []
                for tool_call in message.tool_calls:
                    result = await execute_tool_call(tool_call)
                    # Ensure result is not None and is a string
                    if result is None:
                        print(f"WARNING: Tool call {tool_call.id} returned None result")
                        result = "No results available"
                    
                    # Create tool message with guaranteed string content
                    tool_message = {
                        "tool_call_id": tool_call.id,
                        "role": "tool",
                        "content": str(result)  # Force to string
                    }
                    print(f"Adding tool message: {json.dumps(tool_message)}")
                    tool_messages.append(tool_message)
                
                # Get final response with tool results
                print("Creating final message array with tool results")
                assistant_message = {"role": message.role, "content": message.content or ""}
                
                # Make sure the assistant message has tool_calls property from the API response
                if hasattr(message, 'tool_calls') and message.tool_calls:
                    # Convert tool_calls object to dict for JSON serialization
                    tool_calls_data = []
                    for tc in message.tool_calls:
                        tool_calls_data.append({
                            "id": tc.id,
                            "type": "function",
                            "function": {
                                "name": tc.function.name,
                                "arguments": tc.function.arguments
                            }
                        })
                    assistant_message["tool_calls"] = tool_calls_data
                
                # First add the assistant message with tool_calls, then add tool messages
                final_messages = messages + [assistant_message] + tool_messages
                
                # Print the message array for debugging
                print(f"Final message array before validation (length={len(final_messages)}):")
                for i, msg in enumerate(final_messages):
                    role = msg.get('role')
                    has_tool_calls = 'tool_calls' in msg
                    content_type = type(msg.get('content'))
                    content_len = len(str(msg.get('content') or ""))
                    print(f"  Message {i}: role={role}, has_tool_calls={has_tool_calls}, content_type={content_type}, content_len={content_len}")
                
                # Validate messages before sending to OpenAI
                validated_messages = validate_messages(final_messages)
                final_response = await call_openai_with_tools(validated_messages)
                final_message = final_response.choices[0].message.content
            else:
                final_message = message.content
                
            # Return GraphQL-formatted response
            return JSONResponse(content={
                "data": {
                    "generateMessage": {
                        "message": {
                            "id": "msg_" + str(int(time.time())),
                            "content": final_message,
                            "role": "assistant",
                            "__typename": "Message"
                        },
                        "__typename": "GenerateMessagePayload"
                    }
                }
            })
        
        # For non-GraphQL requests, continue with existing logic
        messages = body.get("messages", [])
        
        # Handle single message format (CopilotKit might send this)
        if not messages and "message" in body:
            print(f"Converting single message format: {body['message']}")
            messages = [{"role": "user", "content": body["message"]}]
            
        # Handle empty string content (convert to empty list)
        if messages == "":
            messages = []
            
        if not messages:
            print("Error: No messages provided in request")
            return JSONResponse(
                content={"error": "No messages provided", "received": body},
                status_code=400
            )
        
        # Process with OpenAI
        print(f"Sending messages to OpenAI: {messages}")
        response = await call_openai_with_tools(messages)
        message = response.choices[0].message
        
        # Handle tool calls if present
        if message.tool_calls:
            # Execute tool calls
            tool_messages = []
            for tool_call in message.tool_calls:
                result = await execute_tool_call(tool_call)
                # Ensure result is not None and is a string
                if result is None:
                    print(f"WARNING: Tool call {tool_call.id} returned None result")
                    result = "No results available"
                    
                # Create tool message with guaranteed string content
                tool_message = {
                    "tool_call_id": tool_call.id,
                    "role": "tool",
                    "content": str(result)  # Force to string
                }
                print(f"Adding tool message: {json.dumps(tool_message)}")
                tool_messages.append(tool_message)
            
            # Get final response with tool results
            print("Creating final message array with tool results")
            assistant_message = {"role": message.role, "content": message.content or ""}
            
            # Make sure the assistant message has tool_calls property from the API response
            if hasattr(message, 'tool_calls') and message.tool_calls:
                # Convert tool_calls object to dict for JSON serialization
                tool_calls_data = []
                for tc in message.tool_calls:
                    tool_calls_data.append({
                        "id": tc.id,
                        "type": "function",
                        "function": {
                            "name": tc.function.name,
                            "arguments": tc.function.arguments
                        }
                    })
                assistant_message["tool_calls"] = tool_calls_data
            
            # First add the assistant message with tool_calls, then add tool messages
            final_messages = messages + [assistant_message] + tool_messages
            
            # Print the message array for debugging
            print(f"Final message array before validation (length={len(final_messages)}):")
            for i, msg in enumerate(final_messages):
                role = msg.get('role')
                has_tool_calls = 'tool_calls' in msg
                content_type = type(msg.get('content'))
                content_len = len(str(msg.get('content') or ""))
                print(f"  Message {i}: role={role}, has_tool_calls={has_tool_calls}, content_type={content_type}, content_len={content_len}")
            
            # Validate messages before sending to OpenAI
            validated_messages = validate_messages(final_messages)
            final_response = await call_openai_with_tools(validated_messages)
            final_message = final_response.choices[0].message.content
        else:
            final_message = message.content
        
        # Return AG-UI compatible response
        result = {
            "message": final_message,
            "type": "message",
            "timestamp": "2025-01-01T00:00:00Z"
        }
        print(f"Returning result: {json.dumps(result, indent=2)}")
        return JSONResponse(content=result)
        
    except Exception as e:
        print(f"Error processing request: {str(e)}")
        import traceback
        traceback.print_exc()
        return JSONResponse(
            content={
                "error": "Internal server error",
                "details": str(e)
            },
            status_code=500
        )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000) 