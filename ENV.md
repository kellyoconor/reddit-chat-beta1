# Environment Variables Documentation

This document describes all environment variables used in the Reddit Analyzer project.

## Backend Environment Variables

These variables should be defined in `.env` file in the `reddit-analyzer-backend` directory.

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `OPENAI_API_KEY` | Your OpenAI API key for accessing GPT models | None | Yes |
| `CORS_ORIGINS` | Comma-separated list of allowed origins for CORS | `http://localhost:3000,http://localhost:3001,http://localhost:3002` | No |

Example `.env` file for backend:

```
OPENAI_API_KEY=sk-your_openai_api_key_here
CORS_ORIGINS=http://localhost:3000,http://localhost:3001,http://localhost:3002
```

## Frontend Environment Variables

These variables should be defined in `.env.local` file in the `reddit-analyzer-frontend` directory.

| Variable | Description | Default | Required |
|----------|-------------|---------|----------|
| `NEXT_PUBLIC_AGENT_URL` | URL for the AG-UI backend endpoint | `http://localhost:8000/awp` | No |

Example `.env.local` file for frontend:

```
NEXT_PUBLIC_AGENT_URL=http://localhost:8000/awp
```

## Production Considerations

For production deployment, consider the following:

1. Use secure methods to store and access API keys (environment variables, secrets management)
2. Update CORS settings to allow only your production domains
3. Set proper API rate limits and authentication

## Additional Configuration

If deploying to platforms like Vercel, Railway, or Render, you'll need to configure environment variables through their respective dashboards or CLI tools.

### Vercel Example (Frontend)

```bash
vercel env add NEXT_PUBLIC_AGENT_URL
```

### Railway Example (Backend)

Configure environment variables through the Railway dashboard or using the Railway CLI:

```bash
railway variables set OPENAI_API_KEY=sk-your_openai_api_key_here
railway variables set CORS_ORIGINS=https://your-frontend-domain.com
``` 