#!/bin/bash
pip install apache-libcloud
mkdir inventory
chmod 755 inventory
cd inventory
rm -rf *
wget "https://github.com/ansible/ansible/raw/devel/contrib/inventory/gce.ini"
wget "https://github.com/ansible/ansible/raw/devel/contrib/inventory/gce.py"
chmod +x gce.py
