
# GH Copilot - Ghid de dezvoltare și testare

## Limbaj și Formatare
1. Răspunde doar în limba română.
2. `guidelines.md` rămâne mereu în root.
3. Nu crea README.md sau alte documente decât dacă se cere explicit.
4. Explicațiile complexe se structurează în pași numerotați.
5. Folosește titluri/subtitluri pentru răspunsuri lungi.
6. Folosește emoji-uri pentru ⚠️ avertismente și 📝 note.
7. Răspuns maxim: 500 cuvinte (dacă nu se cere altfel).
8. Orice comentariu trebuie sa fie tradus in toate limbile suportate de proiect.
8. Variabilele vor fi cu majuscule și descriptive: `NUME_VARIABILA`.
9. Nu traduce comentariile, doar textul de afișat utilizatorului.
10. Nu TRADUCE NUMELE DE FUNCȚII, CLASE SAU VARIABILE, doar textul de afișat utilizatorului.
11. Nu TRADUCE NUME De programe sau comenzi, doar textul de afișat utilizatorului.
12. Folosește ghilimele simple pentru stringuri: `'text'`.
13. Pune mereu codul in locul unde este necesar, nu doar la final.

## Dezvoltare Cod
1. Comentează detaliat doar secțiunile complexe (>5 linii).
2. Fisierele noi se organizează pe directoare logice.
3. Nu pune cod inainte de `#!/bin/bash` în scripturi.
3. Nume descriptive pentru fișiere/directoare, după convenții.
4. Structură modulară: funcționalități separate pe module/clase.
5. Pentru Helpers, folosește `helpers/` și nume descriptive, iar cele care nu trebuie rulate foloseste '# shellcheck shell=bash'
5. Nu duplica codul, reutilizează funcții/clase existente.
6. Nu adăuga comentarii inutile.
7. Fisier max 300 linii (dacă nu se cere altfel).
8. Docstring complet la orice funcție nouă.
9. Gestionare robustă a erorilor.
10. Folosește typing hints la toate funcțiile/metodele noi.
11. Nu adăuga cod nesolicitat explicit.

## Testare și Validare
1. Scrie teste unitare pentru orice funcționalitate nouă.
2. Testele trebuie să fie documentate și clare.
3. Testele se organizează în directoare dedicate (ex: `tests/unit`).
4. Testarea se face pe WSL2 Debian.
5. Toate testele trebuie să treacă înainte de commit.
6. Nu adăuga teste nesolicitate.
7. Creează `tests/run_all_tests.sh` pentru a rula toate funcțiile și a verifica sintaxa.
8. Testele trebuie să fie independente și ușor de rulat.
9. Nu adăuga teste nerelevante pentru funcționalitatea implementată.

## Colaborare și Commit
1. Fii deschis la feedback și sugestii.
2. Răspunde rapid la comentarii și cereri de modificare.
3. Commit-uri clare și concise, cu motivul modificării.
4. Nu adăuga modificări nesolicitate.

## Alte Cerințe
1. La final, proiectul trebuie să aibă:
   - Meniu complex de instalare
   - Interfață web simplă pentru configurare/monitorizare
   - Agent AI capabil să execute comenzi complexe, să ofere sugestii și să răspundă la întrebări despre sistem
2. Scriptul final trebuie să ruleze pe orice OS (WSL2, Proxmox, Debian, Ubuntu), să fie ușor de instalat/configurat și bine documentat.

## Ajutor Copilot rulare
1. Folosește `guidelines.md` pentru orice neclaritate.
1. Parola user WordPress: `;` pentru a evita problemele de securitate.
