# Sample Visual Audit Conversation

This shows how a developer uses cloud-eyes with Claude Code to audit a live website.

---

## Example 1: Full audit

```
User: I just pushed changes to onlyexit.ai. Audit the homepage.

Claude: Running visual audit on https://onlyexit.ai...

[Navigating to https://onlyexit.ai]
[Taking screenshot at 375x812 - Mobile]
[Taking screenshot at 768x1024 - Tablet]
[Taking screenshot at 1440x900 - Desktop]

Visual Audit Results - https://onlyexit.ai

Mobile (375x812):
1. CRITICAL: Hero text overflows on mobile (375px). The h1 "Convert Big Tech
   Talent..." wraps into the CTA button. The text container needs max-width
   and proper padding.
2. WARNING: Nav hamburger menu icon is only 24x24px. Recommend 44x44px minimum
   tap target per WCAG guidelines.

Tablet (768x1024):
3. INFO: Footer social links could use more spacing. Currently 8px gap,
   recommend 16px for better touch targets.

Desktop (1440x900):
4. INFO: Hero section has 20px extra whitespace on the right edge. Not
   breaking but could be tightened.

Summary:
- Critical: 1
- Warning: 1
- Info: 2

Fixing issue #1 (hero text overflow)...
[Editing styles.css - adding max-width: 100% and padding adjustments to .hero h1]

Fixing issue #2 (hamburger tap target)...
[Editing nav.css - increasing .menu-toggle min-width and min-height to 44px]

Re-auditing mobile viewport...
[Taking screenshot at 375x812]

Issues #1 and #2 resolved. Hero text fits within bounds. Hamburger menu
meets tap target guidelines.

Status: PASS - All 3 viewports clean.
```

---

## Example 2: Quick screenshot

```
User: Screenshot the pricing page.

Claude: [Navigating to https://onlyexit.ai/pricing]
[Taking screenshot at 1440x900]

Here is the pricing page at desktop resolution. The three-tier layout
renders correctly. All prices are visible and the CTA buttons are
properly aligned.

Want me to check mobile and tablet too?
```

---

## Example 3: Interactive testing

```
User: Test the signup form on the landing page. Make sure it works.

Claude: [Navigating to https://onlyexit.ai]
[Scrolling to signup form]
[Taking screenshot - form visible]

I can see the signup form with email input and "Get Started" button.
Testing the form now...

[Clicking email input field]
[Filling "test@example.com" into the email field]
[Taking screenshot - email entered]

Email field accepts input correctly. Clicking submit...

[Clicking "Get Started" button]
[Waiting 3 seconds for response]
[Taking screenshot - form submitted]

The form submits successfully. I see a "Check your email" confirmation
message. The form validation and submission flow works correctly.

Visual check:
- Form layout: OK on desktop
- Input field sizing: OK
- Button is clearly visible and clickable
- Success message renders properly

Want me to test this on mobile too?
```

---

## Example 4: Before/after comparison

```
User: I changed the header background to dark blue. Does it look right?

Claude: [Navigating to https://onlyexit.ai]
[Taking screenshot at 1440x900 - Desktop]
[Taking screenshot at 375x812 - Mobile]

The dark blue header (#1a1a4e) looks good on both viewports.

However, I noticed one issue:

1. WARNING: The white logo on dark blue has a contrast ratio of 4.3:1.
   This passes WCAG AA but fails AAA. The nav links (light gray #999
   on #1a1a4e) only hit 3.1:1 - this fails WCAG AA. Recommend
   changing nav link color to #ccc or lighter.

Want me to fix the contrast issue?
```

---

## Setup

To use cloud-eyes in your own projects, copy the CLAUDE.md file from this repo
into your project root. Then configure the MCP server using one of the configs
in this examples directory.
