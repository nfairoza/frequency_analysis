#!/bin/bash


echo "Updating system and installing required packages..."
sudo apt update && sudo apt upgrade -y
sudo apt install -y msr-tools stress-ng sysbench unzip curl

echo "Installing AWS CLI..."
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
rm -rf awscliv2.zip aws

if ! aws --version > /dev/null 2>&1; then
    echo "AWS CLI installation failed."
    exit 1
fi


aws sts get-caller-identity > /dev/null 2>&1
if [ $? -eq 0 ]; then
    echo "AWS CLI configured successfully."
else
    echo "AWS CLI configuration failed. Check your credentials."
    exit 1
fi

sudo chmod u+w .
sudo chmod +x ./showboost.sh
sudo chmod +x ./run-analysis.sh
sudo ./run-analysis.sh
