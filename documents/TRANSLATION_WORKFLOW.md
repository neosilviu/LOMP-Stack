# Translation System Migration: JSON-based Workflow

## Overview

Translations are now managed using per-language JSON files in the `translations/` directory. This system is designed to be robust, maintainable, and compatible with both shell scripts and future web interfaces.

## Directory Structure

- `translations/ro.json`  (Romanian, fallback/default)
- `translations/en.json`  (English)
- `translations/fr.json`  (French)
- `translations/es.json`  (Spanish)
- `translations/de.json`  (German)

## How It Works

- Each JSON file contains key-value pairs for translation strings.
- The shell function (see `helpers/lang.sh`) loads the appropriate file based on the selected language.
- If a key is missing in the selected language, the system falls back to Romanian (`ro.json`).
- This structure is future-proof for web integration: web code can load the same JSON files.

## For Shell Developers

- Use the `tr_lang` function to fetch translations:
  ```sh
  tr_lang <key>
  # Example:
  tr_lang apache_install
  ```
- The function automatically selects the correct language file and falls back to Romanian if needed.
- To add or update a translation, edit the appropriate JSON file in `translations/`.

## For Web Developers

- Load the relevant JSON file(s) from the `translations/` directory.
- Use the same keys as in shell scripts for consistency.
- Implement fallback to `ro.json` if a key is missing in the selected language.

## Adding a New Language

1. Copy `ro.json` to `translations/<lang>.json` (e.g., `it.json` for Italian).
2. Translate the values.
3. Update any language selection logic in your shell or web code.

## Removing Legacy Files

- The old `translations.json` (monolithic) is now deleted.
- Legacy Bash translation files (`helpers/lang/lang_*.sh`) are no longer used and can be deleted if not needed for reference.

## Example JSON Entry

```json
{
  "apache_install": "[Apache] Installing Apache...",
  "nginx_start": "[Nginx] Starting Nginx service..."
}
```

## Questions?

See `helpers/lang.sh` for the shell implementation, or contact the project maintainer for more details.
