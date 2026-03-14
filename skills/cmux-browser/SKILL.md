---
name: cmux-browser
description: Browser automation using cmux's built-in WebKit browser panes. Use when testing web apps, inspecting pages, filling forms, or interacting with local dev servers. Replaces Playwright MCP when running inside cmux terminal.
---

# cmux Browser Automation

Use cmux's built-in browser panes for web testing and automation. The browser runs as a visible split pane with a full WebKit engine and a Playwright-like CLI API.

## When to Use

- Testing local dev servers (localhost)
- Inspecting page structure and accessibility
- Filling forms, clicking elements, navigating
- Taking screenshots or reading page content
- Any task that would normally use Playwright MCP

## Prerequisites

You must be running inside cmux terminal. Verify with:
```bash
cmux identify --json
```

If this fails, fall back to Playwright MCP tools instead.

## Core Workflow

### 1. Open a Browser Pane
```bash
# Open browser in a new split (visible next to terminal)
cmux browser open https://localhost:3000

# Or open in a specific direction
cmux new-pane --type browser --url https://localhost:3000
```

### 2. Get Page Structure
```bash
# DOM snapshot with interactive element refs (like Playwright's accessibility tree)
cmux browser snapshot --interactive

# Compact snapshot for large pages
cmux browser snapshot --interactive --compact

# Snapshot a specific section
cmux browser snapshot --selector "main"
```

The snapshot returns element refs like `e10`, `e14` that you use for interactions.

### 3. Interact with Elements
```bash
# Click an element by ref
cmux browser click 'e14'

# Type into an input
cmux browser type 'e10' 'search query'

# Fill a form field (clears first)
cmux browser fill 'e5' 'username'

# Press keyboard keys
cmux browser press 'Enter'

# Hover
cmux browser hover 'e8'
```

### 4. Navigate
```bash
cmux browser goto https://localhost:3000/dashboard
cmux browser back
cmux browser forward
cmux browser reload
```

### 5. Wait for Conditions
```bash
# Wait for element to appear
cmux browser wait --selector '.loaded'

# Wait for text content
cmux browser wait --text 'Welcome'

# Wait for URL change
cmux browser wait --url-contains '/dashboard'

# Wait for full page load
cmux browser wait --load-state complete
```

### 6. Read Page Data
```bash
# Get current URL
cmux browser url

# Get page title
cmux browser get title

# Get text content of element
cmux browser get text '.result-count'

# Get element attribute
cmux browser get attr 'e10' 'href'

# Get element value (inputs)
cmux browser get value 'e5'

# Evaluate JavaScript
cmux browser eval 'document.querySelectorAll(".item").length'
```

### 7. Find Elements
```bash
# Find by role
cmux browser find role 'button'

# Find by text
cmux browser find text 'Submit'

# Find by label
cmux browser find label 'Email'

# Find by test ID
cmux browser find testid 'login-form'
```

## Multi-Surface Pattern

When working with multiple browser panes, specify the surface:
```bash
cmux browser --surface surface:2 snapshot --interactive
cmux browser --surface surface:2 click 'e5'
```

List all surfaces to find browser panes:
```bash
cmux list-pane-surfaces
```

## Typical Test Flow

```bash
# 1. Open browser to dev server
cmux browser open http://localhost:4000

# 2. Wait for page load
cmux browser wait --load-state complete

# 3. Inspect the page
cmux browser snapshot --interactive

# 4. Interact (using refs from snapshot)
cmux browser fill 'e5' 'test@example.com'
cmux browser fill 'e8' 'password123'
cmux browser click 'e12'

# 5. Verify result
cmux browser wait --text 'Dashboard'
cmux browser get title
```

## Cleanup

```bash
# Close the browser surface when done
cmux close-surface --surface surface:2
```

## Fallback

If `cmux identify` fails (not running in cmux), browser automation is not available. Ask the user to test manually or switch to a cmux terminal.
