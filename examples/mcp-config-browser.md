# MCP Configuration for Browser (claude.ai/code)

Browser-based Claude Code cannot run local commands. It connects to remote MCP servers via HTTP.

## Setup

1. Deploy the MCP server using `./scripts/deploy-mcp-fly.sh`
2. Add it as a custom connector in Claude Code settings

## Custom Connector Fields

| Field | Value |
|---|---|
| Name | `cloud-eyes` |
| Remote MCP server URL | `https://cloud-eyes-mcp.fly.dev/mcp` |
| OAuth Client ID | (leave empty unless you added auth) |
| OAuth Client Secret | (leave empty unless you added auth) |

## Why not a config file?

Browser sessions run in ephemeral sandboxes. Any files written during a session (including `~/.claude/mcp.json` and `.mcp.json`) are destroyed when the session ends. The custom connector is saved to your Anthropic account and persists across all sessions.

## Endpoints

The hosted MCP server exposes two endpoints:

- `/mcp` - Streamable HTTP transport (preferred)
- `/sse` - Server-Sent Events transport (fallback)

Use `/mcp` in the custom connector URL. If that does not work, try `/sse`.
