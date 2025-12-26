# MCP (Model Context Protocol) Setup

MCP allows Claude Code to connect to external tools and APIs.

## Configuration

MCP servers are configured in `.claude/mcp.json`:

```json
{
  "mcpServers": {
    "server-name": {
      "type": "http",
      "url": "https://api.example.com/mcp/"
    }
  }
}
```

## Server Types

### HTTP (Recommended)
```json
{
  "github": {
    "type": "http",
    "url": "https://api.githubcopilot.com/mcp/"
  }
}
```

### Stdio (Local)
```json
{
  "filesystem": {
    "type": "stdio",
    "command": "npx",
    "args": ["-y", "@anthropic/mcp-server-filesystem", "${HOME}"]
  }
}
```

## Common Integrations

### GitHub
```bash
claude mcp add github https://api.githubcopilot.com/mcp/
```

### Database
```bash
claude mcp add db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://user:pass@localhost:5432/mydb"
```

### Jira
Requires environment variables:
- `JIRA_URL` - Your Jira instance
- `JIRA_EMAIL` - Your email
- `JIRA_API_TOKEN` - API token from Atlassian

## Usage

Once configured, use naturally:
```
> @github List my open PRs
> @db Show recent user signups
```

## Authentication

For servers requiring auth:
```bash
claude /mcp   # Opens auth flow
```

## Troubleshooting

```bash
# List configured servers
claude mcp list

# Test connection
claude mcp test github

# View logs
claude --debug
```

## Resources

- [MCP Specification](https://modelcontextprotocol.io)
- [Available Servers](https://github.com/anthropics/mcp-servers)
