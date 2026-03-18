# Contract: Email Service

**Feature**: `005-vps-domain-smtp` | **Date**: 2026-03-18

## Interface du service email (Python async)

### EmailService

```python
class EmailService:
    async def send_email(
        self,
        to: str | list[str],
        subject: str,
        template_name: str,
        context: dict | None = None,
        html_content: str | None = None,
    ) -> bool:
        """
        Envoie un email via SMTP Gmail.

        Args:
            to: Destinataire(s)
            subject: Sujet de l'email
            template_name: Nom du template Jinja2 (sans extension)
            context: Variables pour le template
            html_content: Contenu HTML direct (alternative au template)

        Returns:
            True si envoyé avec succès, False sinon

        Raises:
            Ne lève jamais d'exception — journalise les erreurs et retourne False.
        """
```

### Endpoint de test (admin uniquement)

```
POST /api/admin/email/test
Authorization: Bearer <jwt>
Content-Type: application/json

{
    "to": "test@example.com",
    "subject": "Test email USenghor",
    "message": "Ceci est un email de test."
}

Response 200:
{
    "success": true,
    "message": "Email envoyé avec succès"
}

Response 500:
{
    "success": false,
    "message": "Erreur d'envoi : <détail>"
}
```

## Configuration Nginx (HTTPS)

### Redirection HTTP → HTTPS
```
server {
    listen 80;
    server_name usenghor-francophonie.org www.usenghor-francophonie.org;
    return 301 https://usenghor-francophonie.org$request_uri;
}
```

### Redirection www → non-www
```
server {
    listen 443 ssl;
    server_name www.usenghor-francophonie.org;
    return 301 https://usenghor-francophonie.org$request_uri;
}
```

### Serveur principal HTTPS
```
server {
    listen 443 ssl;
    server_name usenghor-francophonie.org;
    # ... proxies vers frontend/backend
}
```
