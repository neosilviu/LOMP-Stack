# README_CLEAN_APPROACH.md

## Clean Installation Philosophy
- Instalează doar componentele absolut necesare
- Fiecare pas trebuie să fie clar, documentat și reversibil
- Fără pachete suplimentare sau servicii care nu sunt cerute explicit
- Orice componentă suplimentară se instalează doar la cerere, după instalarea de bază

## Exemple de scenarii
- Instalare ultra-minimală pentru testare rapidă
- Instalare standard pentru producție
- Adăugare progresivă de componente (Redis, AI, Cloudflare, etc.)

## Recomandări
- Folosește scripturile din `helpers/` pentru orice extensie
- Folosește `component_manager.sh` pentru management interactiv
- Respectă mereu `guidelines.md` pentru orice modificare
