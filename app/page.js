"use client";

import { CopilotKit } from "@copilotkit/react-core";
import { CopilotChat } from "@copilotkit/react-ui";
import "@copilotkit/react-ui/styles.css";

export default function Home() {
  const agentUrl = process.env.NEXT_PUBLIC_AGENT_URL || "http://localhost:8000/awp";

  return (
    <div className="min-h-screen bg-gray-50">
      <div className="max-w-4xl mx-auto p-8">
        <h1 className="text-4xl font-bold text-center pt-10 text-gray-900">
          r/Comcast_Xfinity Analyzer
        </h1>
        <p className="text-xl text-center mt-4 text-gray-600">
          Ask questions about posts and discussions in the Comcast Xfinity subreddit using AI-powered analysis.
        </p>
        
        <div className="bg-white rounded-lg shadow-sm border p-6 mt-8">
          <h2 className="text-2xl font-semibold mb-6 text-center">Try asking:</h2>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            <div className="p-3 bg-blue-50 rounded-lg">
              <p className="text-blue-800 font-medium">Recent Issues</p>
              <p className="text-blue-600 text-sm">"What are the most common complaints this week?"</p>
            </div>
            <div className="p-3 bg-green-50 rounded-lg">
              <p className="text-green-800 font-medium">Outage Analysis</p>
              <p className="text-green-600 text-sm">"Show me recent posts about internet outages"</p>
            </div>
          </div>
        </div>
        
        <div className="bg-white rounded-lg shadow-sm border p-6 mt-8">
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
  );
} 