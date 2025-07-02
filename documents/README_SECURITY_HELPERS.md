# SECURITY Helpers

Acest fișier documentează helperii din `helpers/security/` pentru instalare și configurare componente de securitate în stack-ul WordPress LOMP.

## Fisiere și roluri

- **install_security.sh**: Script pentru instalare și configurare rapidă a pachetelor de securitate (fail2ban, UFW, etc).
- **security_helpers.sh**: Funcții utilitare pentru configurare firewall, reguli, fail2ban, etc.
- **install_cloudflare.sh**: Script pentru instalare și configurare Cloudflare Tunnel.
- **install_redis.sh**: Script pentru instalare și configurare Redis pentru cache.

## Recomandări
- Folosește aceste scripturi pentru a securiza rapid serverul și a integra servicii de cache sau tunelare.
- Pentru reguli personalizate, extinde funcțiile din `security_helpers.sh`.

---
