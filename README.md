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

There are two different architectures depending on how you use Claude Code.

### Browser / Mobile (claude.ai/code)

Browser-based Claude Code cannot run local commands like `npx`. It can only connect to **remote MCP servers** via HTTP/SSE. So you need a hosted Playwright MCP server that bridges Claude Code to the cloud browser.

```
┌─────────────────────────────────┐
│  Claude Code (browser / mobile) │
└──────────────┬──────────────────┘
               │ HTTP/SSE (custom connector)
               │ https://your-mcp-server.fly.dev/mcp
               v
┌──────────────────────────────┐
│  Playwright MCP Server       │
│  (hosted on Fly.io/Railway)  │
│  Dockerfile.mcp              │
└──────────────┬───────────────┘
               │ CDP WebSocket
               │ wss://browserless-url?token=XXX
               v
┌──────────────────────────────┐
│  Browserless Chromium        │
│  (browserless.io or          │
│   self-hosted)               │
└──────────────┬───────────────┘
               │ navigates to
               v
┌──────────────────────────────┐
│  Your website / dev server   │
│  (any public URL)            │
└──────────────────────────────┘
```

### CLI / Desktop

CLI and Desktop users can run `npx` locally. The Playwright MCP server runs as a local process (stdio) and connects directly to the cloud browser. No need to host the MCP server separately.

```
┌──────────────────────────────┐
│  Claude Code CLI / Desktop   │
└──────────────┬───────────────┘
               │ stdio (local process)
               v
┌──────────────────────────────┐
│  Playwright MCP Server       │
│  (npx @playwright/mcp)       │
│  runs locally on your machine│
└──────────────┬───────────────┘
               │ CDP WebSocket
               │ wss://browserless-url?token=XXX
               v
┌──────────────────────────────┐
│  Browserless Chromium        │
│  (browserless.io or          │
│   self-hosted)               │
└──────────────────────────────┘
```

---

## Quickstart

### Path A: Browser / Mobile users (claude.ai/code)

This is the path for people who use Claude Code in the browser or on their phone. You need two things: a cloud browser and a hosted MCP server.

**Step 1: Get a cloud browser**

1. Create an account at [browserless.io](https://www.browserless.io)
2. Copy your API token from the dashboard
3. Your CDP endpoint is: `wss://production-sfo.browserless.io/chromium/playwright?token=YOUR_TOKEN`

**Step 2: Deploy the MCP server**

The MCP server is a small service that translates HTTP requests from Claude Code into browser commands. Deploy it on Fly.io:

```bash
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

# Deploy the MCP server (pass your Browserless CDP endpoint)
./scripts/deploy-mcp-fly.sh "wss://production-sfo.browserless.io/chromium/playwright?token=YOUR_TOKEN"
```

This deploys `Dockerfile.mcp` to Fly.io and prints your MCP server URL (something like `https://cloud-eyes-mcp.fly.dev`).

> **No terminal?** You can also deploy `Dockerfile.mcp` from the Fly.io dashboard by connecting your GitHub repo. Set the `CDP_ENDPOINT` environment variable to your Browserless WebSocket URL.

**Step 3: Add the connector in Claude Code**

1. Open [claude.ai/code](https://claude.ai/code)
2. Go to **Settings**
3. Find **Connectors** (may also be under a **Customize** page)
4. Click **Add custom connector**
5. Fill in:
   - **Name:** `cloud-eyes`
   - **Remote MCP server URL:** `https://cloud-eyes-mcp.fly.dev/mcp`
6. Save

**Step 4: Verify**

Start a new Claude Code session. You should see Playwright tools available (like `playwright_navigate`, `playwright_screenshot`). Say "audit my website at https://your-site.com" and it should work.

> **Why not just a file?** Browser sessions run in ephemeral sandboxes. Files like `~/.claude/mcp.json` or `.mcp.json` written during a session are destroyed when it ends. The custom connector persists on your account.

---

### Path B: CLI / Desktop users

You only need a cloud browser. The MCP server runs locally via `npx`.

1. Create an account at [browserless.io](https://www.browserless.io)
2. Copy your API token
3. Add this MCP config:

**Claude Code CLI** - add to `~/.claude/mcp.json` (global) or `.mcp.json` (project):

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

**Claude Desktop** - add to your Claude Desktop config:

- macOS: `~/Library/Application Support/Claude/claude_desktop_config.json`
- Windows: `%APPDATA%\Claude\claude_desktop_config.json`

Same JSON format as above.

4. Tell Claude: "audit my website at https://your-site.com"

---

### Path C: Self-host everything (~10 min, requires terminal)

For users who want full control. Deploy both the cloud browser and the MCP server on your own infrastructure.

**Deploy the cloud browser:**

```bash
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

# Deploy Browserless to Fly.io
./scripts/deploy-fly.sh
# Note the WebSocket URL it prints
```

**Deploy the MCP server (browser users only):**

```bash
# Deploy the MCP server, pointing it at your Browserless instance
./scripts/deploy-mcp-fly.sh "wss://cloud-eyes.fly.dev?token=YOUR_TOKEN"
```

**For CLI/Desktop users**, skip the MCP server deployment and just use the `npx` config pointing at your self-hosted Browserless URL.

---

### Path D: Local Docker (for testing)

> Requires Docker. Good for testing before deploying.

```bash
git clone https://github.com/ankurtyagi2007-tech/Claude-Eyes.git
cd Claude-Eyes

docker-compose up -d

# Verify it works
./scripts/health-check.sh http://localhost:3000 local-dev-token
```

MCP config for local (CLI/Desktop only):

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
# Health check (Browserless)
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
- **MCP server access**. Anyone who discovers your MCP server URL can use your cloud browser. Consider adding authentication via the OAuth fields in the custom connector settings, or restrict access at the infrastructure level.

---

## Project Structure

```
cloud-eyes/
  README.md                          # This file
  CLAUDE.md                          # Visual audit skill for Claude Code
  Dockerfile                         # Browserless Chromium (cloud browser)
  Dockerfile.mcp                     # Playwright MCP Server (HTTP/SSE bridge)
  docker-compose.yml                 # Local development setup
  fly.toml                           # Fly.io config for Browserless
  fly.mcp.toml                       # Fly.io config for MCP server
  railway.json                       # Railway deployment config
  scripts/
    deploy-fly.sh                    # Deploy Browserless to Fly.io
    deploy-mcp-fly.sh               # Deploy MCP server to Fly.io
    deploy-railway.sh                # Deploy Browserless to Railway
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
