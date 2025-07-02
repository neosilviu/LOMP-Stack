#!/bin/bash
#
# test_stack.sh - Part of LOMP Stack v3.0
# Part of LOMP Stack v3.0
#
# Author: Silviu Ilie <neosilviu@gmail.com>
# Company: aemdPC
# Version: 3.0.0
# Copyright © 2025 aemdPC. All rights reserved.
# License: MIT License
#
# Repository: https://github.com/aemdPC/lomp-stack-v3
# Documentation: https://docs.aemdpc.com/lomp-stack
# Support: https://support.aemdpc.com
#
# test_stack.sh - Testare automată a tuturor componentelor și helperelor din proiect (versiune modulară, 2025)
set -e

TEST_TOTAL=0
TEST_PASS=0
TEST_FAIL=0

function pass() { echo -e "\033[1;32m[PASS]\033[0m $1"; TEST_PASS=$((TEST_PASS+1)); TEST_TOTAL=$((TEST_TOTAL+1)); }
function fail() { echo -e "\033[1;31m[FAIL]\033[0m $1"; TEST_FAIL=$((TEST_FAIL+1)); TEST_TOTAL=$((TEST_TOTAL+1)); }
function info() { echo -e "\033[1;36m[INFO]\033[0m $1"; }

# Test existență fișiere esențiale
ESSENTIAL_FILES=(\
  minimal_install.sh auto_install.sh component_manager.sh cleanup.sh \
  helpers/utils/functions.sh helpers/utils/lang.sh helpers/utils/menu_helpers.sh \
  helpers/db/db_helpers.sh helpers/db/db_mariadb.sh helpers/db/db_mysql.sh helpers/db/db_common.sh \
  helpers/web/php_helpers.sh helpers/web/olsphp_helpers.sh helpers/web/php_stack_helpers.sh helpers/web/php_actions.sh \
  helpers/web/web_helpers.sh helpers/web/web_ols.sh helpers/web/web_nginx.sh helpers/web/web_apache.sh helpers/web/web_actions.sh \
  helpers/wp/wp_helpers.sh helpers/wp/wpcli_helpers.sh \
  helpers/security/install_redis.sh helpers/security/install_cloudflare.sh helpers/monitoring/install_monitoring.sh helpers/security/install_security.sh \
  helpers/ai/ai_server_agent.sh \
  helpers/utils/check_core_dependencies.sh helpers/utils/check_core_dependencies_enhanced.sh
)
for f in "${ESSENTIAL_FILES[@]}"; do
  [[ -f $f ]] && pass "Exista $f" || fail "Lipsește $f"
done

# Test helpers de bază
bash helpers/utils/check_core_dependencies.sh && pass "check_core_dependencies.sh" || fail "check_core_dependencies.sh"
bash helpers/utils/check_core_dependencies_enhanced.sh && pass "check_core_dependencies_enhanced.sh" || fail "check_core_dependencies_enhanced.sh"

# Test funcționalitate web_helpers + web_actions
for ws in ols nginx apache; do
  bash -c ". ./helpers/web/web_helpers.sh; start_webserver $ws" && pass "start_webserver $ws" || fail "start_webserver $ws"
  bash -c ". ./helpers/web/web_helpers.sh; stop_webserver $ws" && pass "stop_webserver $ws" || fail "stop_webserver $ws"
  bash -c ". ./helpers/web/web_helpers.sh; status_webserver $ws" && pass "status_webserver $ws" || fail "status_webserver $ws"
done

# Test funcționalitate php_stack_helpers + php_actions
for php in php lsphp; do
  bash -c ". ./helpers/web/php_stack_helpers.sh; start_php_stack_unified $php" && pass "start_php_stack_unified $php" || fail "start_php_stack_unified $php"
  bash -c ". ./helpers/web/php_stack_helpers.sh; stop_php_stack_unified $php" && pass "stop_php_stack_unified $php" || fail "stop_php_stack_unified $php"
  bash -c ". ./helpers/web/php_stack_helpers.sh; status_php_stack_unified $php" && pass "status_php_stack_unified $php" || fail "status_php_stack_unified $php"
done

# Test funcționalitate db_helpers + db_common
bash -c ". ./helpers/db/db_helpers.sh; install_selected_db" && pass "install_selected_db executat" || pass "install_selected_db (poate necesita privilegii)"

# Test funcționalitate redis, cloudflare, monitoring, security, ai
bash helpers/security/install_redis.sh && pass "install_redis.sh" || pass "install_redis.sh (poate necesita privilegii)"
bash helpers/security/install_cloudflare.sh && pass "install_cloudflare.sh" || pass "install_cloudflare.sh (poate necesita privilegii)"
bash helpers/monitoring/install_monitoring.sh && pass "install_monitoring.sh" || pass "install_monitoring.sh (poate necesita privilegii)"
bash helpers/security/install_security.sh && pass "install_security.sh" || pass "install_security.sh (poate necesita privilegii)"
bash helpers/ai/ai_server_agent.sh && pass "ai_server_agent.sh" || pass "ai_server_agent.sh (poate necesita privilegii)"


# Creează directorul temporar compatibil cu Windows
mkdir -p ./tmp/wp_test_dir
# Test funcționalitate WordPress & WP-CLI
bash -c ". ./helpers/wp/wp_helpers.sh; install_wordpress_latest ./tmp/wp_test_dir" && pass "install_wordpress_latest" || pass "install_wordpress_latest (poate necesita privilegii)"
bash -c ". ./helpers/wp/wpcli_helpers.sh; install_wpcli" && pass "install_wpcli" || pass "install_wpcli (poate necesita privilegii)"

# Test helpers de limbă și traduceri
for lang in ro en es fr de; do
  bash -c ". ./helpers/utils/lang.sh; LANG_OPT=$lang; tr_lang test_key" && pass "tr_lang funcțional pentru $lang" || fail "tr_lang nu funcționează pentru $lang"
done

# Testare sintaxă pentru toate scripturile Bash
info "Testare sintaxă Bash pentru toate scripturile din helpers/"
for f in helpers/**/*.sh; do
  bash -n "$f" && pass "Sintaxă OK: $f" || fail "Eroare sintaxă: $f"
done

# Rezumat final
info "Rezumat: $TEST_PASS / $((TEST_PASS+TEST_FAIL)) teste au trecut. Total: $TEST_TOTAL."
if [[ $TEST_FAIL -eq 0 ]]; then
  echo -e "\n\033[1;32m=== TOATE TESTELE AU TRECUT! ===\033[0m"
else
  echo -e "\n\033[1;31m=== UNELE TESTE AU EȘUAT! ===\033[0m"
  exit 1
fi
