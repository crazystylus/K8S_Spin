#!/bin/bash
./packer build -var zone="us-east1-c" -var project_id="mykubeadm" -var account_file="mykubeadm-c0e2bb703f16.json" pak.json
