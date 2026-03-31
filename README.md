# cloud-eyes

> Give Claude Code eyes. Cloud-hosted visual feedback for browser and mobile users.

Claude Code in the browser is blind. It writes frontend code, deploys it, and hopes for the best. It cannot see what it built. No screenshots. No visual diff. No way to catch that the hero text overlaps the CTA button on mobile. **cloud-eyes** fixes that. It connects Claude Code to a cloud-hosted headless Chromium browser so it can navigate to any URL, take screenshots at multiple viewports, spot visual bugs, and fix them - all from the browser or a phone. No local install required.

---

## The Problem

| Environment | Can Claude see what it builds? |
|---|---|
| Claude Desktop | Yes - has preview pane |
| Claude Code CLI (local) | Yes - can install Playwright MCP locally |
| Claude Code in browser (claude.ai/code) | **No** |
| Claude Code on mobile | **No** |

Perplexity ships with a built-in computer that can browse and screenshot. Claude Code users working from a browser tab or a phone get nothing. They are building UIs blind.

cloud-eyes gives Claude Code a cloud-hosted browser it can control via the Playwright MCP server. Navigate. Screenshot. Click. Fill forms. Audit layouts at three viewports. Fix issues. Re-verify. All without installing anything locally.

---

## Architecture

```
┌─────────────────────────────────┐
│  Claude Code (browser / mobile) │
└──────────────┬──────────────────┘
               │ MCP protocol
               v
┌──────────────────────────────┐
│    Playwright MCP Server     │
│  (runs as MCP tool bridge)   │
└──────────────┬───────────────┘
               │ CDP WebSocket
               │ wss://your-cloud-browser-url?token=XXX
               v
┌──────────────────────────────┐
│  Browserless Chromium        │
│  (Docker on Fly.io/Railway/  │
│   any VPS)                   │
└──────────────┬───────────────┘
               │ navigates to
               v
┌──────────────────────────────┐
│  Your website / dev server   │
│  (any public URL)            │
└──────────────────────────────┘
```

---

## Quickstart

Four paths. Pick the one that fits.

### Path A: Browserless Cloud (fastest, free tier available)

No infrastructure to manage. Sign up, get a token, connect.

1. Create an account at [browserless.io](https://www.browserless.io)
2. Copy your API token from the dashboard
3. Add this MCP config to Claude Code:

```json
{
  "mcpServers": {
    "cloud-eyes": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--cdp-endpoint", "wss://production-sfo.browserless.io/chromium/playwright?token=YOUR_BROWSERLESS_TOKEN"
      ]
    }
  }
}
```

4. Tell Claude: "audit my website at https://your-site.com"

Done. No Docker. No deploy. No server.

---

### Path B: Self-host on Fly.io (~5 min)

You own the browser. No third-party dependency.

```bash
# Clone this repo
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

# Deploy to Fly.io
./scripts/deploy-fly.sh
```

The script will:
- Create a Fly app called `cloud-eyes`
- Set a secure token as a secret
- Deploy the Browserless container
- Print your WebSocket URL

Then add the MCP config:

```json
{
  "mcpServers": {
    "cloud-eyes": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--cdp-endpoint", "wss://cloud-eyes.fly.dev?token=YOUR_TOKEN"
      ]
    }
  }
}
```

---

### Path C: Self-host on Railway (~3 min)

One-click deploy with Railway.

```bash
# Clone and deploy
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

./scripts/deploy-railway.sh
```

Or use the Railway dashboard to deploy from this repo directly.

Then add the same MCP config with your Railway URL:

```json
{
  "mcpServers": {
    "cloud-eyes": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--cdp-endpoint", "wss://your-railway-url.up.railway.app?token=YOUR_TOKEN"
      ]
    }
  }
}
```

---

### Path D: Local Docker (for testing)

Spin up Browserless locally to test before deploying.

```bash
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

docker-compose up -d

# Verify it works
./scripts/health-check.sh http://localhost:3000 local-dev-token
```

MCP config for local:

```json
{
  "mcpServers": {
    "cloud-eyes": {
      "command": "npx",
      "args": [
        "-y", "@playwright/mcp@latest",
        "--cdp-endpoint", "ws://localhost:3000?token=local-dev-token"
      ]
    }
  }
}
```

---

## MCP Configuration

### Claude Code CLI

Copy `examples/mcp-config-claude-code.json` and update the endpoint URL and token. Then either:

- Add it to your project's `.mcp.json` file, or
- Add it to your global Claude Code MCP config at `~/.claude/mcp.json`

### Claude Desktop

Copy `examples/mcp-config-claude-desktop.json` into your Claude Desktop config file:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

### Claude Code in Browser (claude.ai/code)

For browser-based Claude Code, add the MCP server configuration through the Claude Code settings panel. The Playwright MCP server will run as a remote tool bridge.

---

## How the Visual Audit Loop Works

The `CLAUDE.md` file in this repo teaches Claude Code a visual audit skill. When you say "audit", "check how it looks", or "does this look right", Claude will:

1. **Navigate** to your deployed URL
2. **Screenshot at 3 viewports**:
   - Mobile: 375x812 (iPhone 14)
   - Tablet: 768x1024 (iPad)
   - Desktop: 1440x900
3. **Analyze each screenshot** for layout breaks, contrast issues, broken images, responsive failures, typography problems, and tap target sizing
4. **Report findings** as a numbered list with severity levels (critical / warning / info)
5. **Fix** critical and warning issues in the code
6. **Re-screenshot** to verify the fixes
7. **Only report "visual audit passed"** when all 3 viewports look correct

This loop runs automatically after every frontend change when CLAUDE.md is loaded into your project.

---

## Verification

After deploying, verify everything works:

```bash
# Health check
./scripts/health-check.sh https://cloud-eyes.fly.dev YOUR_TOKEN

# Full visual audit test
./scripts/test-visual-audit.sh https://onlyexit.ai https://cloud-eyes.fly.dev YOUR_TOKEN
```

The test script will:
- Take screenshots at mobile, tablet, and desktop viewports
- Save them to `./audit-results/` with timestamps
- Print a summary of what was captured

---

## Security Considerations

A cloud browser is powerful. Lock it down.

- **Always set a strong TOKEN**. Never deploy with the default token in production.
- **Use HTTPS/WSS only** for remote connections. Never expose the WebSocket over plain `ws://` on the internet.
- **Restrict concurrent sessions**. The default `CONCURRENT=5` prevents abuse. Lower it if you are the only user.
- **Set timeouts**. The default `TIMEOUT=60000` (60s) kills hung sessions. Do not disable this.
- **Network isolation**. If your cloud browser only needs to reach specific domains, configure network policies at the infrastructure level (Fly.io private networking, Railway private services, firewall rules).
- **Do not expose port 3000 publicly without token auth**. The Browserless image requires a token by default. Do not override this behavior.

---

## Project Structure

```
cloud-eyes/
  README.md                          # This file
  CLAUDE.md                          # Visual audit skill for Claude Code
  Dockerfile                         # Browserless Chromium with defaults
  docker-compose.yml                 # Local development setup
  fly.toml                           # Fly.io deployment config
  railway.json                       # Railway deployment config
  scripts/
    deploy-fly.sh                    # One-command Fly.io deploy
    deploy-railway.sh                # One-command Railway deploy
    health-check.sh                  # Verify cloud browser is running
    test-visual-audit.sh             # End-to-end screenshot test
  examples/
    mcp-config-claude-code.json      # MCP config for Claude Code CLI
    mcp-config-claude-desktop.json   # MCP config for Claude Desktop
    sample-audit-prompt.md           # Example visual audit conversation
  .github/
    workflows/
      test.yml                       # CI: health check + screenshot test
  LICENSE                            # MIT
```

---

## Contributing

Contributions welcome. Keep it simple.

1. Fork the repo
2. Create a branch (`git checkout -b feature/your-feature`)
3. Make your changes
4. Test locally with `docker-compose up` and the health check script
5. Submit a PR

Guidelines:
- No em dashes in any text. Use " - " or rewrite the sentence.
- Keep the terminal aesthetic. No corporate fluff.
- All shell scripts must have shebangs and be executable.
- All configs must be valid JSON/YAML/TOML.
- Test your changes against a real URL before submitting.

---

## License

MIT. See [LICENSE](LICENSE).

---

Built for developers who are tired of deploying blind.
