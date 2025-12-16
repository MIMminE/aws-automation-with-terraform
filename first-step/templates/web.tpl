#!/bin/bash

apt-get update
apt-get install -y nginx
echo "Region: ${region}" > /tmp/region.txt
