#!/bin/sh

# 실패한 명령어 발생 시 스크립트 종료
set -e

# 시스템 패키지 업데이트
yum -y update

# 필요한 유틸리티 설치
yum install -y wget unzip

# Install a LAMP stack
amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
yum -y install httpd php-mbstring

export AWS_ACCESS_KEY_ID=${aws_access_key_id}
export AWS_SECRET_ACCESS_KEY=${aws_secret_access_key}
export AWS_DEFAULT_REGION="ap-northeast-2"
export json_data=$(aws rds describe-db-clusters --query '*[]. {Endpoint:Endpoint}')
export AURORA_CLUSTER_ENDPOINT=$(echo "$json_data" | jq -r '.[].Endpoint')

# Start and enable the web server
systemctl enable httpd
systemctl start httpd

# Install the web pages for our lab
if [ ! -f /var/www/html/immersion-day-app-php7.tar.gz ]; then
   cd /var/www/html
   wget https://aws-joozero.s3.ap-northeast-2.amazonaws.com/immersion-day-app-php7.tar.gz  
   tar xvfz immersion-day-app-php7.tar.gz
fi

# Install the AWS SDK for PHP
if [ ! -f /var/www/html/aws.zip ]; then
   cd /var/www/html
   mkdir -p vendor
   cd vendor
   wget https://docs.aws.amazon.com/aws-sdk-php/v3/download/aws.zip
   unzip aws.zip
fi

cd /var/www/inc
# Save the endpoint value to the ENDPOINT file
aws rds describe-db-clusters --query 'DBClusters[?DBClusterIdentifier==`aurora-cluster`].Endpoint' --output text > ENDPOINT
# Read the value from the ENDPOINT file
VALUE=$(cat ENDPOINT)
# Replace the AURORA_CLUSTER_ENDPOINT string with the fetched value in dbinfo.inc
sed -i "s|AURORA_CLUSTER_ENDPOINT|$VALUE|g" dbinfo.inc