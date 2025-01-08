#!/bin/bash env
pgbackrest --stanza=postgres_sandbox stanza-create
pgbackrest --stanza=postgres_sandbox backup --type=full #full backup
pgbackrest --stanza=postgres_sandbox check