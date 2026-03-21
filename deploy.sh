#!/bin/bash

# ===========================================
# USenghor Deployment Script (Git-based)
# ===========================================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REMOTE_USER="ubuntu"
REMOTE_HOST="137.74.117.231"
REMOTE_DIR="/opt/usenghor"

# GitHub repositories (public repos - HTTPS)
BACKEND_REPO="https://github.com/angenor/usenghor_backend.git"
FRONTEND_REPO="https://github.com/angenor/usenghor_nuxt.git"

echo -e "${GREEN}=== USenghor Deployment (Git) ===${NC}"

# Function to setup server (first time only)
setup() {
    echo -e "${GREEN}[1/5] Installing Docker on server...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
        # Install Docker if not present
        if ! command -v docker &> /dev/null; then
            echo "Installing Docker..."
            curl -fsSL https://get.docker.com | sudo sh
            sudo usermod -aG docker $USER
            sudo systemctl enable docker
            sudo systemctl start docker
        fi

        # Install Docker Compose plugin if not present
        if ! docker compose version &> /dev/null; then
            echo "Installing Docker Compose..."
            sudo apt-get update
            sudo apt-get install -y docker-compose-plugin
        fi

        # Install Git if not present
        if ! command -v git &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y git
        fi

        echo "Docker version: $(docker --version)"
        echo "Docker Compose version: $(docker compose version)"
        echo "Git version: $(git --version)"
ENDSSH

    echo -e "${GREEN}[2/5] Creating project directory...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} "sudo mkdir -p ${REMOTE_DIR} && sudo chown -R ${REMOTE_USER}:${REMOTE_USER} ${REMOTE_DIR}"

    echo -e "${GREEN}[3/5] Cloning repositories...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}

        # Clone backend if not exists
        if [ ! -d "usenghor_backend" ]; then
            echo "Cloning backend repository..."
            git clone ${BACKEND_REPO}
        fi

        # Clone frontend if not exists
        if [ ! -d "usenghor_nuxt" ]; then
            echo "Cloning frontend repository..."
            git clone ${FRONTEND_REPO}
        fi

        # Create nginx directory
        mkdir -p nginx/ssl
ENDSSH

    echo -e "${GREEN}[4/5] Uploading configuration files...${NC}"
    # Upload docker-compose and nginx config
    scp docker-compose.prod.yml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
    scp nginx/nginx.conf ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/
    scp nginx/maintenance.html ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/
    scp nginx/maintenance_logo.png ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/
    scp .env.production.example ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/

    echo -e "${GREEN}[5/5] Generating secure secrets and creating .env...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << 'ENDSSH'
        cd /opt/usenghor

        # Generate secure secrets
        APP_SECRET=$(openssl rand -hex 32)
        JWT_SECRET=$(openssl rand -hex 32)
        POSTGRES_PWD=$(openssl rand -hex 16)

        # Create .env from example
        cp .env.production.example .env

        # Replace placeholders with generated secrets
        sed -i "s/CHANGE_ME_GENERATE_RANDOM_SECRET/$APP_SECRET/" .env
        sed -i "s/CHANGE_ME_GENERATE_RANDOM_JWT_SECRET/$JWT_SECRET/" .env
        sed -i "s/CHANGE_ME_STRONG_PASSWORD/$POSTGRES_PWD/" .env

        echo ""
        echo "✅ Secrets generated and saved to .env"
        echo ""
        echo "Generated values:"
        echo "  POSTGRES_PASSWORD: $POSTGRES_PWD"
        echo "  APP_SECRET_KEY: $APP_SECRET"
        echo "  JWT_SECRET_KEY: $JWT_SECRET"
        echo ""
        echo "⚠️  Save these values somewhere safe!"
ENDSSH

    echo -e "${GREEN}=== Setup Complete ===${NC}"
    echo ""
    echo -e "${YELLOW}Next step:${NC}"
    echo "  ./deploy.sh deploy"
    echo ""
    echo -e "${YELLOW}Optional - Edit .env to customize (SMTP, CORS, etc.):${NC}"
    echo "  ./deploy.sh connect"
    echo "  nano .env"
}

# Function to deploy/update
deploy() {
    echo -e "${GREEN}[1/4] Pulling latest code from GitHub...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}

        echo "Updating backend..."
        cd usenghor_backend
        git fetch origin
        git reset --hard origin/main || git reset --hard origin/master
        cd ..

        echo "Updating frontend..."
        cd usenghor_nuxt
        git fetch origin
        git reset --hard origin/main || git reset --hard origin/master
        cd ..
ENDSSH

    echo -e "${GREEN}[2/4] Uploading configuration files...${NC}"
    scp docker-compose.prod.yml ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/
    scp nginx/nginx.conf ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/
    scp nginx/maintenance.html ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/
    scp nginx/maintenance_logo.png ${REMOTE_USER}@${REMOTE_HOST}:${REMOTE_DIR}/nginx/

    echo -e "${GREEN}[3/4] Building and starting containers...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}

        # Check if .env exists
        if [ ! -f ".env" ]; then
            echo "ERROR: .env file not found!"
            echo "Please run: cp .env.production.example .env && nano .env"
            exit 1
        fi

        # Ensure nginx is running (serves maintenance page while others rebuild)
        docker compose -f docker-compose.prod.yml up -d nginx

        # Rebuild and restart backend + frontend only (nginx stays up)
        docker compose -f docker-compose.prod.yml up -d --build backend frontend db

        # Reload nginx config if it changed
        docker exec usenghor_nginx nginx -s reload || true

        # Clean up old images
        docker image prune -f
ENDSSH

    echo -e "${GREEN}[4/4] Verifying deployment...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}
        echo "Container status:"
        docker compose -f docker-compose.prod.yml ps

        echo ""
        echo "Waiting for services to be ready..."
        sleep 15

        echo ""
        echo "Health checks:"
        curl -sf http://localhost/health && echo " - Nginx OK" || echo " - Nginx not ready"
        curl -sf http://localhost/api/health && echo " - Backend OK" || echo " - Backend not ready"
ENDSSH

    echo -e "${GREEN}=== Deployment Complete ===${NC}"
    echo -e "Site available at: http://${REMOTE_HOST}"
}

# Function to update only (quick update without rebuild)
update() {
    echo -e "${GREEN}Pulling latest code and restarting...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}

        # Pull backend
        cd usenghor_backend
        git pull origin main || git pull origin master
        cd ..

        # Pull frontend
        cd usenghor_nuxt
        git pull origin main || git pull origin master
        cd ..

        # Ensure nginx is running (serves maintenance page while others rebuild)
        docker compose -f docker-compose.prod.yml up -d nginx

        # Rebuild and restart backend + frontend only (nginx stays up)
        docker compose -f docker-compose.prod.yml up -d --build backend frontend db

        # Reload nginx config if it changed
        docker exec usenghor_nginx nginx -s reload || true
ENDSSH
    echo -e "${GREEN}Update complete!${NC}"
}

# Function to view logs
logs() {
    SERVICE=${2:-}
    if [ -n "$SERVICE" ]; then
        ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml logs -f ${SERVICE}"
    else
        ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml logs -f"
    fi
}

# Function to restart services
restart() {
    SERVICE=${2:-}
    if [ -n "$SERVICE" ]; then
        ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml restart ${SERVICE}"
    else
        ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml restart"
    fi
}

# Function to stop services
stop() {
    ssh ${REMOTE_USER}@${REMOTE_HOST} "cd ${REMOTE_DIR} && docker compose -f docker-compose.prod.yml down"
}

# Function to show status
status() {
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        cd ${REMOTE_DIR}
        echo "=== Container Status ==="
        docker compose -f docker-compose.prod.yml ps

        echo ""
        echo "=== Git Status ==="
        echo "Backend:"
        cd usenghor_backend && git log -1 --oneline && cd ..
        echo "Frontend:"
        cd usenghor_nuxt && git log -1 --oneline && cd ..

        echo ""
        echo "=== Disk Usage ==="
        df -h / | tail -1

        echo ""
        echo "=== Memory Usage ==="
        free -h | head -2
ENDSSH
}

# Function to setup SSL with Let's Encrypt
ssl() {
    DOMAIN=${2:-usenghor-francophonie.org}
    echo -e "${GREEN}Setting up SSL for ${DOMAIN}...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} << ENDSSH
        sudo apt-get update
        sudo apt-get install -y certbot

        # Stop nginx temporarily
        docker stop usenghor_nginx || true

        # Get certificate
        sudo certbot certonly --standalone -d ${DOMAIN} -d www.${DOMAIN} --non-interactive --agree-tos --email admin@${DOMAIN}

        # Copy certificates
        sudo mkdir -p ${REMOTE_DIR}/nginx/ssl
        sudo cp /etc/letsencrypt/live/${DOMAIN}/fullchain.pem ${REMOTE_DIR}/nginx/ssl/
        sudo cp /etc/letsencrypt/live/${DOMAIN}/privkey.pem ${REMOTE_DIR}/nginx/ssl/
        sudo chown -R ${REMOTE_USER}:${REMOTE_USER} ${REMOTE_DIR}/nginx/ssl

        # Restart nginx
        docker start usenghor_nginx

        # Setup auto-renewal cron
        (crontab -l 2>/dev/null; echo "0 3 * * * certbot renew --quiet --post-hook 'docker restart usenghor_nginx'") | crontab -

        echo ""
        echo "SSL certificates installed!"
        echo "Please update nginx.conf to enable HTTPS, then run: ./deploy.sh restart nginx"
ENDSSH
}

# Function to backup database
backup() {
    BACKUP_DIR="backups"
    mkdir -p ${BACKUP_DIR}
    BACKUP_FILE="${BACKUP_DIR}/backup_usenghor_$(date +%Y%m%d_%H%M%S).sql"
    echo -e "${GREEN}Creating database backup...${NC}"
    ssh ${REMOTE_USER}@${REMOTE_HOST} "docker exec usenghor_db pg_dump -U usenghor usenghor" > ${BACKUP_FILE}
    echo -e "${GREEN}Backup saved to: ${BACKUP_FILE}${NC}"
}

# Function to SSH into server
connect() {
    ssh ${REMOTE_USER}@${REMOTE_HOST} -t "cd ${REMOTE_DIR} && bash"
}

# Main script
case "$1" in
    setup)
        setup
        ;;
    deploy)
        deploy
        ;;
    update)
        update
        ;;
    logs)
        logs "$@"
        ;;
    restart)
        restart "$@"
        ;;
    stop)
        stop
        ;;
    status)
        status
        ;;
    ssl)
        ssl "$@"
        ;;
    backup)
        backup
        ;;
    connect)
        connect
        ;;
    *)
        echo "Usage: $0 {command} [options]"
        echo ""
        echo "Commands:"
        echo "  setup          - First-time server setup (install Docker, clone repos)"
        echo "  deploy         - Full deployment (pull code, rebuild, restart)"
        echo "  update         - Quick update (pull code, rebuild)"
        echo "  logs [service] - View logs (optional: backend, frontend, db, nginx)"
        echo "  restart [svc]  - Restart services (optional: specific service)"
        echo "  stop           - Stop all services"
        echo "  status         - Show status (containers, git, resources)"
        echo "  ssl [domain]   - Setup SSL (default: usenghor-francophonie.org)"
        echo "  backup         - Backup database to local file"
        echo "  connect        - SSH into server"
        echo ""
        echo "Examples:"
        echo "  $0 setup                    # First-time setup"
        echo "  $0 deploy                   # Deploy/update application"
        echo "  $0 logs backend             # View backend logs"
        echo "  $0 restart frontend         # Restart only frontend"
        echo "  $0 ssl usenghor-francophonie.org  # Setup SSL for domain"
        exit 1
        ;;
esac
