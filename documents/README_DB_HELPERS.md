# DB Helpers

Acest fișier documentează helperii din `helpers/db/` pentru gestionarea bazelor de date MySQL/MariaDB în cadrul stack-ului WordPress LOMP.

## Fisiere și roluri

- **db_helpers.sh**: Funcții utilitare generale pentru detectare, credentiale, conexiune (port/socket), argumente CLI, versiune DB, test port.
- **db_common.sh**: Funcții generice pentru backup, restore și testare conexiune pentru MySQL/MariaDB (indiferent de implementare).
- **db_mariadb.sh**: Funcții specifice pentru instalare și securizare MariaDB.
- **db_mysql.sh**: Funcții specifice pentru instalare și securizare MySQL.
- **db_stack_helpers.sh**: (opțional) Funcții de orchestrare pentru instalare/stack DB, folosește funcții din celelalte scripturi.

## Exemplu de utilizare

```bash
. helpers/db/db_helpers.sh
select_db_credentials
conn_args=$(get_db_conn_args)
mysqldump $conn_args -u"$MYSQL_USER" -p"$MYSQL_PASS" nume_baza > backup.sql
```

## Recomandări
- Folosește funcțiile din `db_helpers.sh` pentru orice script care trebuie să fie agnostic la port/socket sau la tipul de DB.
- Pentru backup/restore, folosește funcțiile din `db_common.sh`.
- Pentru instalare/securizare, folosește funcțiile din `db_mariadb.sh` sau `db_mysql.sh` după caz.

---
