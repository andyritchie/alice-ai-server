# Web Services & Dashboards

Host Alice's web interfaces and tools on the AI server.

## Current Services to Migrate

From the main PC (`alice` / Windows):

| Service | Port | Description | Repo |
|---------|------|-------------|------|
| home-dash | 3333 | Alice home dashboard | alicebot |
| work-dash | 3334 | Clone control center | clone-control-center |
| mri-viewer | 8888 | MRI scan viewer | temp/mum-scans/viewer |
| local-proxy | 80 | Hostname routing | local-proxy |

## Docker Setup for Web Services

### Nginx Reverse Proxy

Add to `docker-compose.yml`:

```yaml
nginx:
  image: nginx:alpine
  container_name: nginx-proxy
  restart: unless-stopped
  ports:
    - "80:80"
    - "443:443"
  volumes:
    - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
    - ./nginx/sites:/etc/nginx/conf.d:ro
    - ./ssl:/etc/nginx/ssl:ro
  depends_on:
    - home-dash
    - work-dash

home-dash:
  build: ./apps/home-dash
  container_name: home-dash
  restart: unless-stopped
  ports:
    - "3333:3333"
  volumes:
    - ./data/home-dash:/app/data
  environment:
    - NODE_ENV=production

work-dash:
  build: ./apps/work-dash
  container_name: work-dash
  restart: unless-stopped
  ports:
    - "3334:3334"
  volumes:
    - ./data/work-dash:/app/data
  environment:
    - NODE_ENV=production
```

### Nginx Configuration

Create `nginx/nginx.conf`:

```nginx
events {
    worker_connections 1024;
}

http {
    include mime.types;
    default_type application/octet-stream;

    # Upstream servers
    upstream home-dash {
        server home-dash:3333;
    }

    upstream work-dash {
        server work-dash:3334;
    }

    upstream ollama {
        server ollama:11434;
    }

    upstream comfyui {
        server comfyui:8188;
    }

    # Main server
    server {
        listen 80;
        server_name ai-server.local alice.local;

        # Home Dashboard
        location / {
            proxy_pass http://home-dash;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }

        # Work Dashboard
        location /work {
            proxy_pass http://work-dash;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }

        # Ollama API
        location /api/ollama/ {
            proxy_pass http://ollama/;
            proxy_http_version 1.1;
            proxy_set_header Host $host;
        }

        # ComfyUI
        location /comfyui/ {
            proxy_pass http://comfyui/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header Host $host;
        }
    }
}
```

## Migrating Apps

### Home Dashboard (alicebot)

```bash
# On AI server
mkdir -p ~/ai-server/apps
cd ~/ai-server/apps

# Clone from GitHub
git clone https://github.com/andyritchie/alicebot.git home-dash
cd home-dash

# Create Dockerfile
cat > Dockerfile << 'EOF'
FROM node:20-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3333
CMD ["node", "server.js"]
EOF

# Build and run
docker build -t home-dash .
docker run -d -p 3333:3333 --name home-dash home-dash
```

### Work Dashboard (clone-control-center)

Same process:

```bash
cd ~/ai-server/apps
git clone https://github.com/andyritchie/clone-control-center.git work-dash
cd work-dash
# Create Dockerfile, build, run
```

## Hostname Routing

### Option 1: Local DNS (Pi-hole / AdGuard Home)

```yaml
adguard:
  image: adguard/adguardhome
  container_name: adguard
  restart: unless-stopped
  ports:
    - "53:53/tcp"
    - "53:53/udp"
    - "3080:80"
  volumes:
    - adguard_work:/opt/adguardhome/work
    - adguard_conf:/opt/adguardhome/conf
```

Add DNS rewrites:
- `home-dash.local` → AI server IP
- `work-dash.local` → AI server IP
- `ai.local` → AI server IP

### Option 2: /etc/hosts (Simple)

On each device that needs access:

```
192.168.1.100  ai-server.local
192.168.1.100  home-dash.local
192.168.1.100  work-dash.local
192.168.1.100  alice.local
```

### Option 3: Tailscale MagicDNS

If using Tailscale, devices get automatic DNS:
- `ai-server.tailnet-name.ts.net`

## SSL/HTTPS (Optional)

### Self-Signed Certs

```bash
mkdir -p ~/ai-server/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout ~/ai-server/ssl/server.key \
  -out ~/ai-server/ssl/server.crt \
  -subj "/CN=ai-server.local"
```

### Let's Encrypt (If public domain)

```yaml
certbot:
  image: certbot/certbot
  volumes:
    - ./ssl:/etc/letsencrypt
    - ./certbot:/var/www/certbot
  command: certonly --webroot -w /var/www/certbot -d yourdomain.com
```

## Service Management

### PM2 for Node Apps (Alternative to Docker)

```bash
# Install PM2
npm install -g pm2

# Start apps
pm2 start ~/ai-server/apps/home-dash/server.js --name home-dash
pm2 start ~/ai-server/apps/work-dash/server.js --name work-dash

# Save and startup
pm2 save
pm2 startup
```

### Systemd Services (Alternative)

Create `/etc/systemd/system/home-dash.service`:

```ini
[Unit]
Description=Alice Home Dashboard
After=network.target

[Service]
Type=simple
User=alice
WorkingDirectory=/home/alice/ai-server/apps/home-dash
ExecStart=/usr/bin/node server.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

## Monitoring

### Uptime Kuma (Recommended)

```yaml
uptime-kuma:
  image: louislam/uptime-kuma:latest
  container_name: uptime-kuma
  restart: unless-stopped
  ports:
    - "3001:3001"
  volumes:
    - uptime_kuma_data:/app/data
```

Monitor all services:
- Ollama API health
- Whisper API health
- Web dashboards
- ComfyUI
- Home Assistant

## Access Summary

After setup, access everything at:

| Service | URL |
|---------|-----|
| Home Dashboard | http://ai-server.local/ |
| Work Dashboard | http://ai-server.local/work |
| Open WebUI (Chat) | http://ai-server.local:3000 |
| ComfyUI | http://ai-server.local:8188 |
| Portainer | http://ai-server.local:9000 |
| Uptime Kuma | http://ai-server.local:3001 |
