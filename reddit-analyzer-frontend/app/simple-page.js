"use client";

import { useState } from "react";

export default function SimpleChatPage() {
  const [messages, setMessages] = useState([
    { role: "assistant", content: "Hi! I can help you analyze r/Comcast_Xfinity posts and discussions. What would you like to know?" }
  ]);
  const [inputValue, setInputValue] = useState("");
  const [isLoading, setIsLoading] = useState(false);

  const sendMessage = async () => {
    if (!inputValue.trim()) return;

    // Add user message
    const userMessage = { role: "user", content: inputValue };
    setMessages(prev => [...prev, userMessage]);
    setInputValue("");
    setIsLoading(true);

    try {
      // Call the backend API directly
      const response = await fetch("http://localhost:8000/awp", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify({
          messages: [...messages, userMessage].map(m => ({ role: m.role, content: m.content }))
        }),
      });

      const data = await response.json();
      console.log("Response:", data);

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
    <div className="min-h-screen bg-gray-100 flex flex-col">
      <header className="bg-blue-600 text-white p-4 shadow-md">
        <h1 className="text-xl font-bold">Reddit Analyzer - Simple Chat</h1>
        <p className="text-sm">Ask questions about r/Comcast_Xfinity</p>
      </header>

      <main className="flex-1 flex flex-col max-w-3xl mx-auto w-full p-4">
        <div className="flex-1 bg-white rounded-lg shadow-md p-4 mb-4 overflow-y-auto">
          <div className="space-y-4">
            {messages.map((message, index) => (
              <div 
                key={index} 
                className={`p-3 rounded-lg ${
                  message.role === "assistant" 
                    ? "bg-blue-100 text-blue-800" 
                    : "bg-green-100 text-green-800 ml-auto"
                } max-w-[80%]`}
              >
                {message.content}
              </div>
            ))}
            {isLoading && (
              <div className="p-3 bg-blue-100 text-blue-800 rounded-lg max-w-[80%]">
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
        </div>

        <div className="flex">
          <input
            type="text"
            value={inputValue}
            onChange={(e) => setInputValue(e.target.value)}
            onKeyPress={(e) => e.key === "Enter" && sendMessage()}
            placeholder="Ask about Comcast Xfinity posts..."
            className="flex-1 p-2 border border-gray-300 rounded-l-lg focus:outline-none focus:ring-2 focus:ring-blue-500"
          />
          <button
            onClick={sendMessage}
            disabled={isLoading}
            className="bg-blue-600 text-white px-4 py-2 rounded-r-lg hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:bg-blue-300"
          >
            Send
          </button>
        </div>

        <div className="mt-4 text-center">
          <a href="/" className="text-blue-600 hover:underline">
            Go back to main interface
          </a>
        </div>
      </main>
    </div>
  );
} 