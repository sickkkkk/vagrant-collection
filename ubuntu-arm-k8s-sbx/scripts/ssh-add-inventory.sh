#!/bin/bash
ssh-keyscan $(grep -Eo 'ansible_host=[^ ]+' /vagrant/ansible/inventory | cut -d= -f2) >> /home/vagrant/.ssh/known_hosts
