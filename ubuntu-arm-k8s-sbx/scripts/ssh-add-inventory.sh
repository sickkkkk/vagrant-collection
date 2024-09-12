#!/bin/bash
ssh-keyscan $(grep -E '^[^#[]' ../ansible/inventory | awk '{print $1}') >> ~/.ssh/known_hosts