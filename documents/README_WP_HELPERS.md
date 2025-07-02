# WP Helpers

Acest fișier documentează helperii din `helpers/wp/` pentru gestionarea instalării și configurării WordPress în cadrul stack-ului LOMP.

## Fisiere și roluri

- **wp_stack_helpers.sh**: Funcții pentru instalare completă WordPress stack (OLS/Nginx), configurare LSCache, permisiuni .htaccess, etc.
- **wp_helpers.sh**: Funcții utilitare pentru management WordPress (ex: detectare, backup, update, etc).
- **wpcli_helpers.sh**: Funcții pentru instalare și management WP-CLI (inclusiv download, fallback, execuție comenzi).
- **wp_config_helper.sh**: Funcții pentru generare și modificare fișier `wp-config.php` (setări DB, chei, etc).

## Recomandări
- Folosește `wp_stack_helpers.sh` pentru instalare rapidă WordPress cu OLS sau Nginx.
- Pentru acțiuni automate sau scriptate, folosește WP-CLI prin funcțiile din `wpcli_helpers.sh`.
- Pentru configurare avansată, folosește funcțiile din `wp_config_helper.sh`.

---
