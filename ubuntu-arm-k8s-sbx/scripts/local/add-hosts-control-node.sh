#!/bin/bash
cat >>/etc/hosts<<EOF
# vagrant local sandbox
172.18.50.71    kmaster1.cluster.local    kmaster1
172.18.50.72    kmaster2.cluster.local    kmaster2
172.18.50.61    kworker.cluster.local  kworker
EOF