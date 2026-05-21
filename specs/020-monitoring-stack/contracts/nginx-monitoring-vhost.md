# Contrat — Server-block Nginx pour `monitoring.<DOMAINE>`

## Patch attendu de `nginx/nginx.conf`

### Bloc `http {}` — ajouter les zones de rate limiting

```nginx
# Existantes (ne pas toucher)
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=30r/s;

# Ajouts pour la stack monitoring (FR-024, D-08)
limit_req_zone $binary_remote_addr zone=monitoring:10m rate=30r/m;
limit_req_zone $binary_remote_addr zone=monitoring_login:10m rate=5r/m;
```

### Bloc `http {}` — ajouter l'upstream Grafana

```nginx
upstream grafana {
    server grafana:3000;
    keepalive 16;
}
```

### Server-block dédié

```nginx
# HTTP → HTTPS redirect pour monitoring
server {
    listen 80;
    server_name monitoring.usenghor-francophonie.org;
    return 301 https://$host$request_uri;
}

# Server HTTPS pour Grafana
server {
    listen 443 ssl http2;
    server_name monitoring.usenghor-francophonie.org;

    # Certificat partagé (SAN) ou cert dédié, géré par certbot
    ssl_certificate /etc/nginx/ssl/fullchain.pem;
    ssl_certificate_key /etc/nginx/ssl/privkey.pem;
    ssl_session_timeout 1d;
    ssl_session_cache shared:SSL_MONITORING:10m;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES256-GCM-SHA384:ECDHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;

    add_header Strict-Transport-Security "max-age=63072000" always;
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;

    client_max_body_size 32M;

    # Rate limiting global du sous-domaine
    limit_req zone=monitoring burst=20 nodelay;

    # Rate limiting strict pour les routes d'authentification
    location ~ ^/(login|api/login|api/user/password/reset) {
        limit_req zone=monitoring_login burst=5 nodelay;

        proxy_pass http://grafana;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
    }

    # WebSocket pour Grafana Live (pas de buffering)
    location /api/live/ {
        proxy_pass http://grafana;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_buffering off;
    }

    # Tout le reste de Grafana
    location / {
        proxy_pass http://grafana;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_read_timeout 90;
    }
}
```

## Pré-requis

1. Sous-domaine `monitoring.<DOMAINE>` configuré en DNS (enregistrement A vers l'IP du VPS)
2. Certificat Let's Encrypt couvrant ce sous-domaine. Deux options :
   - **Recommandée** : certificat SAN incluant `monitoring.<DOMAINE>`. Refaire un `certbot certonly --webroot -d usenghor-francophonie.org -d www.usenghor-francophonie.org -d monitoring.usenghor-francophonie.org` (ou variante `--standalone` selon la routine du projet)
   - Alternative : certificat dédié. Avantage : autonomie ; inconvénient : 2 cycles de renouvellement à surveiller
3. Le service `grafana` est joignable depuis le conteneur `usenghor_nginx` (réseau `usenghor_network` partagé)

## Invariants

| Invariant | Vérification |
|---|---|
| TLS 1.2 minimum | `ssl_protocols TLSv1.2 TLSv1.3` |
| HSTS actif (durée 2 ans) | `Strict-Transport-Security "max-age=63072000"` |
| Rate limit 30 r/m | `limit_req zone=monitoring burst=20 nodelay` |
| Rate limit login 5 r/m | `limit_req zone=monitoring_login burst=5 nodelay` |
| Pas d'iframe externe | `X-Frame-Options "SAMEORIGIN"` |
| MIME sniffing désactivé | `X-Content-Type-Options "nosniff"` |
| WebSocket fonctionnel | `/api/live/` proxifie avec `Upgrade` |
| Pas de mapping public 3000 | Grafana joint uniquement via le réseau Docker interne |

## Tests d'acceptation

| Test | Procédure | Résultat attendu | Spec |
|---|---|---|---|
| T-NGX-1 | `curl -I https://monitoring.<DOMAINE>` | HTTP 302 ou 200, header `Strict-Transport-Security` présent | SC-005, FR-009 |
| T-NGX-2 | `openssl s_client -connect monitoring.<DOMAINE>:443` | Certificat valide, chaîne complète | SC-005 |
| T-NGX-3 | `curl -I http://monitoring.<DOMAINE>` | HTTP 301 vers HTTPS | FR-009 |
| T-NGX-4 | 35 requêtes en 1 minute depuis une IP | Au moins 5 requêtes renvoient `429 Too Many Requests` | SC-015, FR-024 |
| T-NGX-5 | 10 tentatives `POST /login` en 1 minute | Au moins 5 renvoient `429` | SC-015, FR-024 |
| T-NGX-6 | Test SSL Labs (manuel, optionnel) | Note A ou A+ | — |
| T-NGX-7 | `curl http://<IP-VPS>:3000` depuis Internet | Connection refused / timeout | FR-010, SC-006 |
| T-NGX-8 | `curl http://<IP-VPS>:9090` depuis Internet | Connection refused / timeout | FR-010, SC-006 |
