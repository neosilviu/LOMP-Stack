# WEB Helpers

Acest fișier documentează helperii din `helpers/web/` pentru gestionarea webserverelor și PHP în cadrul stack-ului WordPress LOMP.

## Fisiere și roluri

- **nginx_helpers.sh**: Funcții pentru instalare, configurare și optimizare Nginx + PHP pentru WordPress.
- **ols_helpers.sh**: Funcții pentru instalare, configurare și optimizare OpenLiteSpeed + lsphp pentru WordPress.
- **php_helpers.sh**: Funcții pentru managementul instanțelor PHP-FPM (start/stop/status) și integrare cu alte webservere.
- **php_actions.sh**: Funcții generice pentru instalare, build, acțiuni asupra PHP și lsphp (inclusiv din sursă).
- **olsphp_helpers.sh**: Funcții pentru managementul lsphp (start/stop/status) pentru OLS.
- **web_helpers.sh**: Funcții utilitare generale pentru webservere (detectare, selectare, etc).
- **web_nginx.sh, web_ols.sh, web_apache.sh**: Scripturi de orchestrare pentru instalare/configurare rapidă a unui anumit webserver.
- **php_stack_helpers.sh, php_packages_menu.sh, web_actions.sh**: Funcții pentru orchestrare, meniuri și acțiuni complexe cu pachete PHP/web.

## Recomandări
- Folosește helperul specific webserverului pentru instalare/configurare.
- Pentru acțiuni asupra PHP/lsphp, folosește funcțiile din `php_helpers.sh` sau `olsphp_helpers.sh`.
- Pentru build/instalare avansată PHP, folosește `php_actions.sh`.

---
