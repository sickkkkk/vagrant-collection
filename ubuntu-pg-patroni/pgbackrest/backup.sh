#!/bin/bash env
sudo -u postgres pgbackrest --stanza=patroni_backup --config=/etc/pgbackrest/pgbackrest.conf stanza-create