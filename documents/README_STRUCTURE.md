# Structură recomandată pentru helperi

- `web/`        → nginx_helpers.sh, ols_helpers.sh, web_nginx.sh, web_ols.sh, web_apache.sh etc.
- `db/`         → db_helpers.sh, db_stack_helpers.sh, db_mariadb.sh, db_mysql.sh etc.
- `security/`   → install_security.sh, security_helpers.sh etc.
- `monitoring/` → install_monitoring.sh, system_helpers.sh (sau doar partea de monitoring)
- `wp/`         → wp_stack_helpers.sh, wp_helpers.sh, wpcli_helpers.sh, wp_config_helper.sh etc.
- `utils/`      → functions.sh, lang.sh, color_echo, etc.

> Actualizează scripturile principale să folosească noile căi după mutare!
