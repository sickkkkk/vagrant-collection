#!/bin/bash
ansible-playbook bootstrap_baseline.yml
sleep 10
ansible-playbook bootstrap_rke2_server.yml
sleep 10
ansible-playbook bootstrap_cilium.yml