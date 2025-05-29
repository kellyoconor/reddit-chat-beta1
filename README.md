# Reddit Analyzer

An AI-powered application for analyzing posts and discussions from r/Comcast_Xfinity subreddit. This tool helps users understand customer sentiment, common issues, and solutions discussed in the subreddit.

## Features

- Real-time analysis of Reddit posts
- Search for specific topics or issues
- Summarize customer sentiment and trends
- Identify common problems and solutions
- Explore geographic patterns in customer issues

## Project Structure

The project consists of two main components:

### Backend (FastAPI)

- Built with FastAPI for API endpoints
- Uses OpenAI API for AI-powered analysis
- Includes Reddit tools for fetching and analyzing posts
- Tool-based architecture for extensibility

### Frontend (Next.js)

- Built with Next.js for the UI
- Features a clean, modern chat interface
- Supports markdown formatting for better readability
- Provides example queries and information about how the system works

## Getting Started

### Prerequisites

- Node.js 18+ and npm
- Python 3.9+
- OpenAI API key
- Reddit credentials (for API access)

### Installation

1. Clone the repository:
   ```bash
   git clone <repository-url>
   cd reddit-analyzer
   ```

2. Set up the backend:
   ```bash
   cd reddit-analyzer-backend
   pip install -r requirements.txt
   # Create a .env file with your API keys
   ```

3. Set up the frontend:
   ```bash
   cd reddit-analyzer-frontend
   npm install
   ```

### Running the Application

1. Start the backend server:
   ```bash
   cd reddit-analyzer-backend
   python main.py
   ```

2. Start the frontend development server:
   ```bash
   cd reddit-analyzer-frontend
   npm run dev
   ```

3. Open your browser and navigate to http://localhost:3000

## Usage

- Ask questions about posts and discussions in the r/Comcast_Xfinity subreddit
- Use the example queries for guidance
- Explore the Info tab for more information about how the system works

## License

MIT

## Acknowledgments

- Built with OpenAI API
- Uses Reddit API for data access
- Frontend built with Next.js and TailwindCSS 