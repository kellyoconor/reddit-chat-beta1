#!/usr/bin/env bash

# Make sure aiohttp is installed
pip install aiohttp


# Start the application
exec uvicorn main:app --host=0.0.0.0 --port=${PORT:-8000}
