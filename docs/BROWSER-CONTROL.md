# Browser Control

How Alice can control browsers on the AI server for automation, screenshots, and web scraping.

## Options

### Option 1: Playwright (Recommended)

Headless browser automation that works great on Linux servers.

#### Installation

```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs

# Install Playwright
npm install -g playwright
npx playwright install chromium
npx playwright install-deps
```

#### Docker Setup

Add to `docker-compose.yml`:

```yaml
playwright:
  image: mcr.microsoft.com/playwright:v1.40.0-focal
  container_name: playwright
  restart: unless-stopped
  ports:
    - "3001:3000"
  environment:
    - PLAYWRIGHT_BROWSERS_PATH=/ms-playwright
  volumes:
    - playwright_data:/ms-playwright
  command: npx playwright run-server --port 3000
```

#### Usage from Alice

```javascript
const { chromium } = require('playwright');

async function takeScreenshot(url, outputPath) {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto(url);
    await page.screenshot({ path: outputPath, fullPage: true });
    await browser.close();
}

async function scrapeContent(url) {
    const browser = await chromium.launch();
    const page = await browser.newPage();
    await page.goto(url);
    const content = await page.content();
    await browser.close();
    return content;
}
```

### Option 2: Chrome Remote Debugging

Run Chrome with remote debugging enabled.

#### Installation

```bash
# Install Chrome
wget https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo dpkg -i google-chrome-stable_current_amd64.deb
sudo apt --fix-broken install -y
```

#### Start with Remote Debugging

```bash
google-chrome \
  --headless \
  --disable-gpu \
  --remote-debugging-port=9222 \
  --remote-debugging-address=0.0.0.0
```

#### Docker Setup

```yaml
chrome:
  image: browserless/chrome:latest
  container_name: chrome
  restart: unless-stopped
  ports:
    - "9222:3000"
  environment:
    - MAX_CONCURRENT_SESSIONS=5
    - CONNECTION_TIMEOUT=60000
```

### Option 3: OpenClaw Browser Relay

If AI server has a desktop environment, can use OpenClaw's browser control.

#### Setup

1. Install desktop environment (optional):
```bash
sudo apt install -y ubuntu-desktop-minimal
```

2. Install OpenClaw node on AI server

3. Pair with main gateway

4. Use browser tool to control

## Use Cases

### Screenshot Capture

```javascript
// Take screenshot of any URL
await takeScreenshot('https://example.com', '/tmp/screenshot.png');

// Send to user
await sendImage('/tmp/screenshot.png');
```

### Web Scraping

```javascript
// Scrape content from a page
const html = await scrapeContent('https://news.ycombinator.com');
const $ = cheerio.load(html);
const headlines = $('.titleline').map((i, el) => $(el).text()).get();
```

### Form Automation

```javascript
// Fill and submit forms
await page.fill('#email', 'user@example.com');
await page.fill('#password', 'secret');
await page.click('button[type="submit"]');
```

### PDF Generation

```javascript
await page.pdf({ path: 'output.pdf', format: 'A4' });
```

## Security Considerations

- Run browsers in sandboxed containers
- Don't expose debugging ports to public internet
- Use Tailscale for secure remote access
- Limit concurrent sessions to prevent resource exhaustion

## Integration with Alice

Add browser capabilities to OpenClaw config:

```json
{
  "tools": {
    "browser": {
      "enabled": true,
      "endpoint": "http://ai-server:9222"
    }
  }
}
```

Voice commands:
- "Alice, take a screenshot of [url]"
- "Alice, what does [website] look like?"
- "Alice, scrape the headlines from [news site]"
