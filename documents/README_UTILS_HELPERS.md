# UTILS Helpers

Acest fișier documentează helperii din `helpers/utils/` pentru funcții utilitare, meniuri, platformă, backup, logo, traduceri și alte acțiuni comune în stack-ul WordPress LOMP.

## Fisiere și roluri

- **functions.sh**: Funcții generale (color_echo, log_info, log_error, detectare mediu, etc).
- **lang.sh**: Funcții pentru traduceri și încărcare mesaje din JSON (tr_lang).
- **menu_helpers.sh**: Funcții pentru meniuri interactive și navigare CLI.
- **platform_steps.sh**: Funcții pentru pași de instalare platformă (detectare, orchestrare, etc).
- **backup_manager.sh**: Funcții pentru backup/restore utilizator/domeniu.
- **check_core_dependencies.sh, check_core_dependencies_enhanced.sh**: Verificare și instalare dependențe de bază.
- **update_system.sh**: Funcții pentru update sistem și componente.
- **clean_demo.sh**: Funcții pentru curățare demo/test.
- **logo.sh**: Funcții pentru afișare logo personalizat per user.
- **first_install_menu.sh**: Meniu interactiv pentru prima instalare (user/domain setup).

## Recomandări
- Folosește aceste funcții pentru orice logică comună, logging, traduceri, meniuri sau acțiuni de platformă.
- Integrează logarea și traducerile în toate scripturile pentru robustețe și i18n.

---
