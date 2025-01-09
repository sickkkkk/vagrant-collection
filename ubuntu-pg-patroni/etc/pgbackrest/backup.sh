#!/bin/bash env
pgbackrest --stanza=postgres_sandbox stanza-create
pgbackrest --stanza=postgres_sandbox backup --type=full #full backup
pgbackrest --stanza=postgres_sandbox check
# delete stanza
pgbackrest --stanza=postgres_sandbox --log-level-console=info stop && \
pgbackrest --stanza=postgres_sandbox --repo=2 --log-level-console=info stanza-delete