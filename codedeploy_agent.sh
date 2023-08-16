#!/bin/bash

# Install ruby, wget, and jq
sudo yum install -y ruby
sudo yum install -y wget
sudo yum install -y jq

# Change directory (Note: 'sudo cd' is not meaningful. We just use 'cd' here.)
cd /home/ec2-user

# Download the CodeDeploy agent installation script
sudo wget https://aws-codedeploy-ap-northeast-2.s3.ap-northeast-2.amazonaws.com/latest/install

# Make the installation script executable
sudo chmod +x ./install

# Install the CodeDeploy agent
sudo ./install auto

# Start the CodeDeploy agent service
sudo service codedeploy-agent start

# Check the status of the CodeDeploy agent
sudo service codedeploy-agent status

# Get the RDS endpoint using AWS CLI and jq
export json_data=$(aws rds describe-db-clusters --query '*[]. {Endpoint:Endpoint}')
export ENDPOINT=$(echo "$json_data" | jq -r '.[].Endpoint')