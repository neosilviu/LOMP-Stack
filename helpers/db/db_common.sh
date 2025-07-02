# shellcheck shell=bash
# db_common.sh - Funcții comune pentru backup, restore și testare conexiune pentru baze de date compatibile MySQL/MariaDB

# Backup generic pentru MySQL/MariaDB
# Usage: db_generic_backup <db_name> <out_file>
db_generic_backup() {
  local db_name="$1" out_file="$2"
  mysqldump -u"$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" > "$out_file"
}

# Restore generic pentru MySQL/MariaDB
# Usage: db_generic_restore <db_name> <in_file>
db_generic_restore() {
  local db_name="$1" in_file="$2"
  mysql -u"$MYSQL_USER" -p"$MYSQL_PASS" "$db_name" < "$in_file"
}

# Testare conexiune generică pentru MySQL/MariaDB
# Usage: db_generic_test_connection <user> <pass> <host> <port>
db_generic_test_connection() {
  mysql -u"$1" -p"$2" -h"$3" -P"$4" -e "SELECT VERSION();" 2>&1
}
