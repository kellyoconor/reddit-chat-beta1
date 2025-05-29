"""
Reddit data fetching and analysis utilities for the Reddit Analyzer.

This module provides a class to fetch and process data from the
r/Comcast_Xfinity subreddit using asynchronous HTTP requests.
"""

import asyncio
import json
import os
from typing import List, Dict, Any, Optional
import aiohttp
from datetime import datetime, timezone
import random
import time

class RedditAnalyzer:
    """
    A class for fetching and analyzing Reddit data from r/Comcast_Xfinity.
    
    This class provides methods to fetch recent posts, search for posts,
    and format the data for analysis by the OpenAI model.
    """
    
    def __init__(self):
        """Initialize the RedditAnalyzer with the target subreddit."""
        self.subreddit = "Comcast_Xfinity"
        self.base_url = "https://www.reddit.com/r"
        self.headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36"
        }
        
    async def fetch_recent_posts(self, timeframe: str = "hot", limit: int = 25) -> List[Dict[str, Any]]:
        """
        Fetch recent posts from the subreddit.
        
        Args:
            timeframe: Sort type for posts (hot, new, top)
            limit: Number of posts to return
        
        Returns:
            List of post dictionaries
        """
        url = f"{self.base_url}/{self.subreddit}/{timeframe}.json?limit={limit}"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, headers=self.headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        posts = []
                        
                        for post in data["data"]["children"]:
                            post_data = self._extract_post_data(post["data"])
                            posts.append(post_data)
                        
                        return posts
                    else:
                        return [{"error": f"Error fetching posts: {response.status}"}]
        except Exception as e:
            return [{"error": f"Error fetching posts: {str(e)}"}]
    
    async def search_subreddit(self, query: str, limit: int = 20) -> List[Dict[str, Any]]:
        """
        Search subreddit for posts containing the query.
        
        Args:
            query: Search term
            limit: Maximum number of results to return
        
        Returns:
            List of post dictionaries
        """
        url = f"{self.base_url}/{self.subreddit}/search.json?q={query}&restrict_sr=1&limit={limit}"
        
        try:
            async with aiohttp.ClientSession() as session:
                async with session.get(url, headers=self.headers) as response:
                    if response.status == 200:
                        data = await response.json()
                        posts = []
                        
                        for post in data["data"]["children"]:
                            post_data = self._extract_post_data(post["data"])
                            posts.append(post_data)
                        
                        return posts
                    else:
                        return [{"error": f"Error searching posts: {response.status}"}]
        except Exception as e:
            return [{"error": f"Error searching posts: {str(e)}"}]
    
    def format_posts_for_analysis(self, posts: List[Dict[str, Any]]) -> str:
        """Format posts for analysis by OpenAI"""
        if not posts:
            return "No posts found."
        
        if "error" in posts[0]:
            return f"Error: {posts[0]['error']}"
        
        # Limit to max 5 posts to reduce token usage
        limited_posts = posts[:5]
        
        formatted_posts = []
        for i, post in enumerate(limited_posts):
            # Get formatted time
            post_time = datetime.fromtimestamp(post["created_utc"], tz=timezone.utc).strftime("%Y-%m-%d %H:%M:%S UTC")
            
            # Truncate title and content to reduce token usage
            title = post["title"][:100] + ("..." if len(post["title"]) > 100 else "")
            content = post["content"][:300] + ("..." if len(post["content"]) > 300 else "")
            
            formatted_post = (
                f"Post {i+1}:\n"
                f"Title: {title}\n"
                f"Posted: {post_time}\n"
                f"Score: {post['score']}\n"
                f"Comments: {post['num_comments']}\n"
                f"Content: {content}\n"
                f"URL: {post['url']}\n"
            )
            formatted_posts.append(formatted_post)
        
        result = "Reddit posts from r/Comcast_Xfinity:\n\n" + "\n\n".join(formatted_posts)
        
        if len(posts) > 5:
            result += f"\n\nNote: Showing 5 of {len(posts)} total posts to save token usage."
        
        return result
    
    def _extract_post_data(self, post_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Extract relevant data from a Reddit post.
        
        Args:
            post_data: Raw post data from Reddit API
            
        Returns:
            Dictionary with extracted post data
        """
        return {
            "title": post_data.get("title", ""),
            "created_utc": post_data.get("created_utc", 0),
            "score": post_data.get("score", 0),
            "num_comments": post_data.get("num_comments", 0),
            "content": post_data.get("selftext", "[No content]"),
            "url": f"https://www.reddit.com{post_data.get('permalink', '')}"
        } 