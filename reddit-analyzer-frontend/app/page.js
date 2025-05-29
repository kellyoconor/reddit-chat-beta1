"use client";

import { useState, useEffect } from "react";
import "@copilotkit/react-ui/styles.css";

// Function to format markdown-like text in responses
const formatMessage = (text) => {
  if (!text) return "";
  
  // Convert links: [link text](url) to <a> tags
  let formatted = text.replace(/\[([^\]]+)\]\(([^)]+)\)/g, '<a href="$2" target="_blank" class="text-blue-600 hover:underline">$1</a>');
  
  // Convert bold: **text** to <strong> tags
  formatted = formatted.replace(/\*\*([^*]+)\*\*/g, '<strong>$1</strong>');
  
  // Convert italic: *text* to <em> tags (but not if it's part of a ** bold **)
  formatted = formatted.replace(/(?<!\*)\*([^*]+)\*(?!\*)/g, '<em>$1</em>');
  
  // Convert bullet points
  formatted = formatted.replace(/^- (.+)$/gm, '<li>$1</li>');
  formatted = formatted.replace(/<li>(.+)<\/li>/g, '<ul class="list-disc pl-5 my-2"><li>$1</li></ul>');
  
  // Convert numbered lists
  formatted = formatted.replace(/^\d+\.\s(.+)$/gm, '<li>$1</li>');
  formatted = formatted.replace(/(<li>.+<\/li>\n?)+/g, '<ol class="list-decimal pl-5 my-2">$&</ol>');
  
  // Convert headers: # Header to <h> tags
  formatted = formatted.replace(/^# (.+)$/gm, '<h1 class="text-xl font-bold my-2">$1</h1>');
  formatted = formatted.replace(/^## (.+)$/gm, '<h2 class="text-lg font-bold my-2">$1</h2>');
  formatted = formatted.replace(/^### (.+)$/gm, '<h3 class="text-base font-bold my-2">$1</h3>');
  
  // Handle paragraphs - add spacing between them
  formatted = formatted.replace(/\n\n/g, '</p><p class="my-2">');
  
  // Handle line breaks
  formatted = formatted.replace(/\n/g, '<br />');
  
  return formatted;
};

export default function Home() {
  const backendUrl = "https://reddit-chat-beta1.onrender.com";
  const agentUrl = `${backendUrl}/awp`;
  const [backendStatus, setBackendStatus] = useState('Checking...');
  const [error, setError] = useState(null);
  const [debugInfo, setDebugInfo] = useState(null);
  const [messages, setMessages] = useState([]);
  const [inputValue, setInputValue] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [activeTab, setActiveTab] = useState("chat"); // "chat" or "info"

  // Check if the backend is accessible
  useEffect(() => {
    const checkBackend = async () => {
      try {
        console.log("Checking backend health at:", `${backendUrl}/health`);
        const response = await fetch(`${backendUrl}/health`);
        
        if (response.ok) {
          const data = await response.json();
          console.log("Backend health response:", data);
          setBackendStatus('Connected');
          setError(null);
          
          // Test an actual chat request
          try {
            console.log("Testing an actual chat request...");
            const chatResponse = await fetch(`${backendUrl}/awp`, {
              method: 'POST',
              headers: {
                'Content-Type': 'application/json',
              },
              body: JSON.stringify({
                operationName: "generateMessage",
                variables: {
                  text: "Say hello without using any tools"
                }
              })
            });
            
            const chatData = await chatResponse.json();
            console.log("Chat test response:", chatData);
            
            if (chatData.data?.generateMessage?.message?.content) {
              setDebugInfo(`✅ Chat API working: "${chatData.data.generateMessage.message.content.substring(0, 50)}..."`);
            } else {
              setDebugInfo(`⚠️ Chat API responded but message format unexpected: ${JSON.stringify(chatData).substring(0, 100)}...`);
            }
          } catch (chatError) {
            console.error("Chat test failed:", chatError);
            setDebugInfo(`❌ Chat API test failed: ${chatError.message}`);
          }
        } else {
          setBackendStatus(`Error: ${response.status}`);
          setError(`Server returned ${response.status}`);
        }
      } catch (error) {
        console.error("Backend connection error:", error);
        setBackendStatus(`Connection failed`);
        setError(error.message);
      }
    };
    
    checkBackend();
    // Check less frequently to avoid overwhelming the backend
    const interval = setInterval(checkBackend, 15000);
    return () => clearInterval(interval);
  }, [backendUrl]);

  // Custom handler to manually send a message - for debugging
  const sendTestMessage = async () => {
    try {
      const response = await fetch(`${backendUrl}/awp`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          messages: [{ role: "user", content: "What are the top 5 posts on r/Comcast_Xfinity right now?" }]
        })
      });
      
      const data = await response.json();
      console.log("Manual test response:", data);
      alert(`Test response: ${data.message ? data.message.substring(0, 100) + '...' : 'No message'}`);
    } catch (error) {
      console.error("Manual test error:", error);
      alert(`Test error: ${error.message}`);
    }
  };

  // Direct chat implementation
  const sendMessage = async () => {
    if (!inputValue.trim()) return;

    // Add user message
    const userMessage = { role: "user", content: inputValue };
    setMessages(prev => [...prev, userMessage]);
    setInputValue("");
    setIsLoading(true);

    try {
      // Call the backend API directly
      const response = await fetch(`${backendUrl}/awp`, {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [...messages, userMessage].map(m => ({ role: m.role, content: m.content }))
        }),
      });

      const data = await response.json();
      console.log("Chat response:", data);

      // Add assistant response
      if (data.message) {
        setMessages(prev => [...prev, { role: "assistant", content: data.message }]);
      } else {
        setMessages(prev => [...prev, { role: "assistant", content: "Sorry, I encountered an error. Please try again." }]);
      }
    } catch (error) {
      console.error("Error sending message:", error);
      setMessages(prev => [...prev, { role: "assistant", content: `Error: ${error.message}` }]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="min-h-screen flex flex-col bg-gray-50">
      {/* Header with tabs */}
      <header className="bg-white border-b border-gray-200 shadow-sm">
        <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
          <div className="flex justify-between items-center h-16">
            <div className="flex items-center">
              <h1 className="text-xl font-bold text-blue-600">Reddit Analyzer</h1>
              <span className="ml-2 text-sm text-gray-500">r/Comcast_Xfinity</span>
            </div>
            
            {/* Tabs */}
            <div className="flex space-x-4">
              <button
                onClick={() => setActiveTab("chat")}
                className={`px-3 py-2 text-sm font-medium rounded-md ${
                  activeTab === "chat" 
                    ? "bg-blue-100 text-blue-700" 
                    : "text-gray-500 hover:text-gray-700 hover:bg-gray-100"
                }`}
              >
                Chat
              </button>
              <button
                onClick={() => setActiveTab("info")}
                className={`px-3 py-2 text-sm font-medium rounded-md ${
                  activeTab === "info" 
                    ? "bg-blue-100 text-blue-700" 
                    : "text-gray-500 hover:text-gray-700 hover:bg-gray-100"
                }`}
              >
                Info
              </button>
            </div>
            
            {/* Backend status badge */}
            <div className={`text-xs px-2 py-1 rounded-full ${
              backendStatus === 'Connected' 
                ? 'bg-green-100 text-green-800' 
                : 'bg-red-100 text-red-800'
            }`}>
              {backendStatus}
            </div>
          </div>
        </div>
      </header>
      
      {/* Main content area */}
      <div className="flex-1 flex">
        {/* Chat Tab */}
        {activeTab === "chat" && (
          <div className="flex-1 flex flex-col max-w-5xl mx-auto w-full p-4">
            {/* Connection Error Message */}
            {backendStatus !== 'Connected' && (
              <div className="mb-4 p-4 bg-red-50 text-red-800 rounded-lg">
                <div className="font-bold">Cannot connect to backend</div>
                {error && <div className="mt-1 text-sm">{error}</div>}
                <div className="mt-2 text-sm">
                  Make sure the backend server is running on {backendUrl}
                </div>
              </div>
            )}
            
            {/* Chat Messages */}
            <div className="flex-1 bg-white rounded-lg shadow-md p-4 mb-4 overflow-y-auto">
              <div className="space-y-4">
                {messages.length === 0 ? (
                  <div className="text-center text-gray-500 my-8">
                    <h2 className="text-2xl font-bold text-blue-600 mb-4">Welcome to Reddit Analyzer</h2>
                    <p className="mb-2">I can help you analyze posts and discussions from r/Comcast_Xfinity.</p>
                    <p className="mb-6">What would you like to know about customer experiences, complaints, or solutions?</p>
                    
                    <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-8 max-w-3xl mx-auto">
                      <div 
                        className="p-3 bg-blue-50 rounded-lg cursor-pointer hover:bg-blue-100"
                        onClick={() => setInputValue("What are the top posts this week?")}
                      >
                        <p className="font-medium text-blue-800">Top Posts</p>
                        <p className="text-sm text-blue-600">What are the top posts this week?</p>
                      </div>
                      <div 
                        className="p-3 bg-green-50 rounded-lg cursor-pointer hover:bg-green-100"
                        onClick={() => setInputValue("Show me recent posts about internet outages")}
                      >
                        <p className="font-medium text-green-800">Outage Analysis</p>
                        <p className="text-sm text-green-600">Show me recent posts about internet outages</p>
                      </div>
                      <div 
                        className="p-3 bg-purple-50 rounded-lg cursor-pointer hover:bg-purple-100"
                        onClick={() => setInputValue("What are common complaints about customer service?")}
                      >
                        <p className="font-medium text-purple-800">Customer Service</p>
                        <p className="text-sm text-purple-600">What are common complaints about customer service?</p>
                      </div>
                    </div>
                  </div>
                ) : (
                  <div className="space-y-4">
                    {messages.map((message, index) => (
                      <div 
                        key={index}
                        className={`p-3 rounded-lg ${
                          message.role === "assistant" 
                            ? "bg-blue-50 text-blue-800 border border-blue-100" 
                            : "bg-gray-100 text-gray-800 ml-auto"
                        } max-w-[85%] ${message.role === "user" ? "ml-auto" : ""}`}
                      >
                        {message.role === "assistant" ? (
                          <div 
                            className="assistant-message prose prose-blue max-w-none"
                            dangerouslySetInnerHTML={{ __html: formatMessage(message.content) }}
                          />
                        ) : (
                          <div>{message.content}</div>
                        )}
                      </div>
                    ))}
                    {isLoading && (
                      <div className="p-3 bg-blue-50 text-blue-800 rounded-lg max-w-[80%] border border-blue-100">
                        <div className="flex items-center">
                          <div className="mr-2">Thinking</div>
                          <div className="flex space-x-1">
                            <div className="w-2 h-2 bg-blue-800 rounded-full animate-bounce"></div>
                            <div className="w-2 h-2 bg-blue-800 rounded-full animate-bounce" style={{ animationDelay: "0.2s" }}></div>
                            <div className="w-2 h-2 bg-blue-800 rounded-full animate-bounce" style={{ animationDelay: "0.4s" }}></div>
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
            
            {/* Chat Input */}
            <div className="bg-white rounded-lg shadow-md p-4">
              <div className="flex">
                <input
                  type="text"
                  value={inputValue}
                  onChange={(e) => setInputValue(e.target.value)}
                  onKeyPress={(e) => e.key === "Enter" && sendMessage()}
                  placeholder="Ask about Comcast Xfinity posts and discussions..."
                  className="flex-1 p-3 border border-gray-300 rounded-l-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
                />
                <button
                  onClick={sendMessage}
                  disabled={isLoading || backendStatus !== 'Connected'}
                  className="bg-blue-600 text-white px-6 py-3 rounded-r-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-blue-300"
                >
                  Send
                </button>
              </div>
            </div>
          </div>
        )}
        
        {/* Info Tab */}
        {activeTab === "info" && (
          <div className="flex-1 max-w-5xl mx-auto w-full p-8">
            <h2 className="text-3xl font-bold text-gray-900 mb-6">
              About Reddit Analyzer
            </h2>
            
            {/* Backend Status Details */}
            <div className={`mb-8 p-4 rounded-lg ${
              backendStatus === 'Connected' 
                ? 'bg-green-50 border border-green-100' 
                : 'bg-red-50 border border-red-100'
            }`}>
              <h3 className="text-lg font-bold mb-2">Backend Status: {backendStatus}</h3>
              {error && <div className="mb-2 text-sm">{error}</div>}
              {debugInfo && <div className="mb-2 text-sm font-mono">{debugInfo}</div>}
              <div className="flex mt-2">
                <button 
                  onClick={sendTestMessage}
                  className="text-xs bg-blue-500 text-white px-2 py-1 rounded hover:bg-blue-600"
                >
                  Test API
                </button>
              </div>
            </div>
            
            <div className="bg-white rounded-lg shadow-md border p-6 mb-8">
              <h3 className="text-xl font-semibold mb-6">How it works:</h3>
              <ol className="space-y-4 text-gray-600">
                <li className="flex items-start">
                  <span className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg font-medium mr-3 mt-0.5">1</span>
                  <div>
                    <p className="font-medium">Ask Questions</p>
                    <p className="text-sm">Query the AI about Comcast Xfinity customer experiences, issues, or solutions</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg font-medium mr-3 mt-0.5">2</span>
                  <div>
                    <p className="font-medium">Fetch Reddit Data</p>
                    <p className="text-sm">The AI connects to r/Comcast_Xfinity to retrieve relevant posts and discussions</p>
                  </div>
                </li>
                <li className="flex items-start">
                  <span className="bg-blue-500 text-white rounded-full w-8 h-8 flex items-center justify-center text-lg font-medium mr-3 mt-0.5">3</span>
                  <div>
                    <p className="font-medium">Get Insights</p>
                    <p className="text-sm">Receive intelligent analysis of customer sentiment, common issues, and potential solutions</p>
                  </div>
                </li>
              </ol>
            </div>
            
            <div className="bg-white rounded-lg shadow-md border p-6">
              <h3 className="text-xl font-semibold mb-4">Example Questions:</h3>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                <div className="p-3 bg-blue-50 rounded-lg">
                  <p className="font-medium text-blue-800">Recent Issues</p>
                  <p className="text-sm text-blue-600">"What are the most common complaints this week?"</p>
                </div>
                <div className="p-3 bg-green-50 rounded-lg">
                  <p className="font-medium text-green-800">Outage Analysis</p>
                  <p className="text-sm text-green-600">"Show me recent posts about internet outages"</p>
                </div>
                <div className="p-3 bg-purple-50 rounded-lg">
                  <p className="font-medium text-purple-800">Customer Service</p>
                  <p className="text-sm text-purple-600">"What do people say about Xfinity customer service?"</p>
                </div>
                <div className="p-3 bg-yellow-50 rounded-lg">
                  <p className="font-medium text-yellow-800">Technical Issues</p>
                  <p className="text-sm text-yellow-600">"What common Wi-Fi problems are people reporting?"</p>
                </div>
              </div>
            </div>
          </div>
        )}
      </div>

      {/* Add custom styles for better formatting */}
      <style jsx global>{`
        .assistant-message ul {
          list-style-type: disc;
          margin-left: 1.5rem;
          margin-top: 0.5rem;
          margin-bottom: 0.5rem;
        }
        
        .assistant-message ol {
          list-style-type: decimal;
          margin-left: 1.5rem;
          margin-top: 0.5rem;
          margin-bottom: 0.5rem;
        }
        
        .assistant-message li {
          margin-bottom: 0.25rem;
        }
        
        .assistant-message p {
          margin-bottom: 0.75rem;
        }
        
        .assistant-message h1, .assistant-message h2, .assistant-message h3 {
          margin-top: 1rem;
          margin-bottom: 0.5rem;
          font-weight: bold;
        }
        
        .assistant-message h1 {
          font-size: 1.25rem;
        }
        
        .assistant-message h2 {
          font-size: 1.15rem;
        }
        
        .assistant-message h3 {
          font-size: 1.05rem;
        }
        
        .assistant-message a {
          color: #2563eb;
          text-decoration: underline;
        }
        
        .assistant-message a:hover {
          text-decoration: none;
        }
      `}</style>
    </div>
  );
}
