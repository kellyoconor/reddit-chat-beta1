"use client";

import React from 'react';
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