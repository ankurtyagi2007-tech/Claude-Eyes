# cloud-eyes - CLAUDE.md

## Visual Audit System (cloud-eyes)

You have access to a cloud-hosted Chromium browser via the Playwright MCP server. You can navigate to any URL, take screenshots, click elements, fill forms, and inspect the DOM. Use this to visually verify every frontend change you make.

### After every frontend change, run the visual audit loop:

1. **Navigate** to the deployed URL or dev server URL
2. **Screenshot at 3 viewports**:
   - Mobile: 375x812 (iPhone 14)
   - Tablet: 768x1024 (iPad)
   - Desktop: 1440x900
3. **Analyze each screenshot** for:
   - Layout breaks (overflow, overlap, misalignment)
   - Color/contrast issues (unreadable text, poor contrast ratios)
   - Missing or broken images
   - Responsive failures (content hidden, horizontal scroll)
   - Typography issues (font loading failures, size hierarchy)
   - Interactive element visibility (buttons too small on mobile, links too close together)
4. **Report findings** as a numbered list with severity (critical/warning/info)
5. **Fix critical and warning issues** in the code
6. **Re-run screenshots** to verify fixes
7. **Only report "visual audit passed"** when all 3 viewports look correct

### Screenshot commands (via Playwright MCP):

- **Navigate**: `playwright_navigate` with url parameter
- **Screenshot**: `playwright_screenshot` (returns base64 image inline)
- **Click**: `playwright_click` with selector parameter
- **Fill**: `playwright_fill` with selector and value parameters
- **Evaluate**: `playwright_evaluate` to run JavaScript in the page
- **Snapshot**: `playwright_snapshot` for DOM/accessibility tree

### Viewport switching workflow:

For each viewport, use `playwright_evaluate` to resize before screenshotting:

```
Step 1: playwright_navigate to the target URL
Step 2: Wait 2-3 seconds for JS to render
Step 3: playwright_evaluate -> window.innerWidth (confirm current size)
Step 4: playwright_screenshot (capture desktop - default viewport)
Step 5: playwright_evaluate -> document.documentElement.style viewport meta or resize
Step 6: playwright_screenshot (capture at each breakpoint)
```

Alternatively, use `playwright_navigate` with viewport parameters if supported by your MCP server version.

### Trigger phrases:

- When the user says **"audit"** or **"check how it looks"** or **"does this look right"**: Run the full visual audit loop above.
- When the user says **"screenshot"** or **"show me"**: Take a single screenshot at desktop viewport and display it.
- When the user says **"mobile check"**: Take a screenshot at 375x812 only.
- When the user says **"responsive check"**: Take screenshots at all 3 viewports, report differences.

### Visual audit report format:

```
## Visual Audit Results - [URL]

### Mobile (375x812)
[screenshot]
- Issues found: [list or "none"]

### Tablet (768x1024)
[screenshot]
- Issues found: [list or "none"]

### Desktop (1440x900)
[screenshot]
- Issues found: [list or "none"]

### Summary
- Critical: [count]
- Warning: [count]
- Info: [count]

### Status: [PASS / FAIL - fixing issues...]
```

### Important rules:

- Always wait 2-3 seconds after navigation for JavaScript to render
- If a page returns 404 or blank, report it immediately - do not continue the audit
- For SPAs (single-page apps), wait for network idle before screenshotting
- Never skip the mobile viewport. Most bugs hide there.
- If you fix code, always re-screenshot to verify the fix worked
- Take screenshots of the full page, not just the visible viewport, when checking layout
- Compare before/after screenshots when verifying fixes
- If the cloud browser is unreachable, tell the user to check their deployment and token

### Common issues to watch for:

1. **Mobile overflow**: Content wider than viewport causing horizontal scroll
2. **Z-index stacking**: Modals, dropdowns, or sticky headers hiding content
3. **Font fallback**: Custom fonts failing to load, causing layout shifts
4. **Image aspect ratios**: Images stretched or squished on different viewports
5. **Touch targets**: Buttons/links smaller than 44x44px on mobile
6. **Text truncation**: Long strings breaking layouts without proper overflow handling
7. **Dark mode**: If the site supports dark mode, audit both color schemes
8. **Loading states**: Check that skeleton screens or spinners display correctly
