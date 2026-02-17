# Moving Web Apps to Windows AI Server

How to run your Node.js web apps (dashboards, tools) on the AI server.

## Your Current Apps

| App | Port | Repo |
|-----|------|------|
| home-dash | 3333 | github.com/andyritchie/alicebot |
| work-dash | 3334 | github.com/andyritchie/clone-control-center |
| mri-viewer | 8888 | (local, not on GitHub yet) |

---

## Option 1: Docker (Recommended) 🐳

Put your apps in Docker alongside the AI services. One command starts everything.

### Step 1: Create apps folder and clone repos

```powershell
cd C:\AI-Server
mkdir apps
cd apps

git clone https://github.com/andyritchie/alicebot.git home-dash
git clone https://github.com/andyritchie/clone-control-center.git work-dash
```

### Step 2: Add Dockerfile to each app

Copy this into each app folder as `Dockerfile`:

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3333
CMD ["node", "server.js"]
```

(Change the port number for each app)

### Step 3: Add to docker-compose.yml

Add this to your `C:\AI-Server\docker-compose.yml`:

```yaml
  home-dash:
    build: ./apps/home-dash
    container_name: home-dash
    restart: unless-stopped
    ports:
      - "3333:3333"
    environment:
      - NODE_ENV=production

  work-dash:
    build: ./apps/work-dash
    container_name: work-dash
    restart: unless-stopped
    ports:
      - "3334:3334"
    environment:
      - NODE_ENV=production
```

### Step 4: Build and run

```powershell
cd C:\AI-Server
docker compose build
docker compose up -d
```

### Updating apps

```powershell
cd C:\AI-Server\apps\home-dash
git pull
cd C:\AI-Server
docker compose build home-dash
docker compose up -d home-dash
```

### Benefits of Docker

- ✅ One command starts everything: `docker compose up -d`
- ✅ All services in one place
- ✅ Easy to backup (just the compose file)
- ✅ Consistent environment
- ✅ See all apps in Portainer GUI

---

## Option 2: Keep Apps on Main PC (Easiest)

Honestly? **You might not need to move them.**

- AI server handles: Ollama, Whisper, ComfyUI (heavy GPU stuff)
- Main PC handles: Dashboards, OpenClaw gateway (lightweight)

Both are on your home network, they can talk to each other. This is actually cleaner separation.

**If you want everything in one place, continue below.**

---

## Option 2: Move to AI Server

### Step 1: Install Node.js

1. Download from https://nodejs.org (LTS version)
2. Run installer, accept defaults
3. Restart PowerShell

**Verify:**
```powershell
node --version
npm --version
```

### Step 2: Install PM2 (Process Manager)

PM2 keeps your apps running and restarts them if they crash.

```powershell
npm install -g pm2
npm install -g pm2-windows-startup

# Set PM2 to start on boot
pm2-startup install
```

### Step 3: Clone Your Repos

```powershell
# Create apps folder
mkdir C:\Apps
cd C:\Apps

# Clone your repos
git clone https://github.com/andyritchie/alicebot.git home-dash
git clone https://github.com/andyritchie/clone-control-center.git work-dash
```

### Step 4: Install Dependencies

```powershell
cd C:\Apps\home-dash
npm install

cd C:\Apps\work-dash
npm install
```

### Step 5: Start with PM2

```powershell
# Start home dashboard
pm2 start C:\Apps\home-dash\server.js --name home-dash

# Start work dashboard
pm2 start C:\Apps\work-dash\server.js --name work-dash

# Save so they restart on reboot
pm2 save
```

### Step 6: Check Status

```powershell
# See all running apps
pm2 list

# View logs
pm2 logs home-dash

# Restart an app
pm2 restart home-dash

# Stop an app
pm2 stop home-dash
```

## PM2 Cheat Sheet

| Command | What it does |
|---------|--------------|
| `pm2 list` | Show all apps |
| `pm2 logs` | Show all logs |
| `pm2 logs home-dash` | Show specific app logs |
| `pm2 restart all` | Restart everything |
| `pm2 restart home-dash` | Restart one app |
| `pm2 stop home-dash` | Stop one app |
| `pm2 delete home-dash` | Remove from PM2 |
| `pm2 monit` | Live monitoring dashboard |

## Accessing the Apps

After starting, access at:
- http://AI-SERVER-NAME:3333 (home-dash)
- http://AI-SERVER-NAME:3334 (work-dash)

Or by IP:
- http://192.168.x.x:3333

## Setting Up Custom Hostnames

### Option A: Edit hosts file (Simple)

On each device that needs access, edit the hosts file:

**Windows:** `C:\Windows\System32\drivers\etc\hosts`
**Mac:** `/etc/hosts`

Add:
```
192.168.1.100  home-dash
192.168.1.100  work-dash
192.168.1.100  ai-server
```

(Replace 192.168.1.100 with your AI server's IP)

Then access: http://home-dash:3333

### Option B: Use Tailscale (If you have it)

Your AI server will be accessible via Tailscale at:
- `http://ai-server.tailnet-name.ts.net:3333`

## Updating Apps

When you push changes to GitHub:

```powershell
cd C:\Apps\home-dash
git pull
npm install  # if dependencies changed
pm2 restart home-dash
```

## Moving the MRI Viewer

The MRI viewer isn't on GitHub yet. To move it:

### Option 1: Push to GitHub first

On your current PC:
```powershell
cd C:\Users\Andy_\clawd\temp\mum-scans\viewer
git init
git add -A
git commit -m "MRI viewer for Mum"
gh repo create mri-viewer --private --source=. --push
```

Then clone on AI server like the others.

### Option 2: Just copy the folder

1. Copy `C:\Users\Andy_\clawd\temp\mum-scans\viewer` to a USB drive
2. Copy to AI server at `C:\Apps\mri-viewer`
3. Run:
```powershell
cd C:\Apps\mri-viewer
npm install
pm2 start server.js --name mri-viewer
```

## Nginx Reverse Proxy (Optional)

If you want clean URLs without ports (http://home-dash instead of http://home-dash:3333):

1. Download nginx for Windows: https://nginx.org/en/download.html
2. Extract to `C:\nginx`
3. Edit `C:\nginx\conf\nginx.conf`:

```nginx
http {
    server {
        listen 80;
        server_name home-dash;
        location / {
            proxy_pass http://127.0.0.1:3333;
        }
    }
    
    server {
        listen 80;
        server_name work-dash;
        location / {
            proxy_pass http://127.0.0.1:3334;
        }
    }
}
```

4. Start nginx: `C:\nginx\nginx.exe`

**But honestly?** Just use the ports. Less complexity.

## Summary

**Minimal setup:**
1. Install Node.js
2. Install PM2
3. Clone repos
4. `npm install` in each
5. `pm2 start` each app
6. `pm2 save`

**That's it.** Your apps are now running on the AI server and will auto-restart on reboot.
