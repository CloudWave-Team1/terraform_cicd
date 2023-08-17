#!/bin/bash
cd /var/www/inc
echo $(aws rds describe-db-clusters --query 'DBClusters[?DBClusterIdentifier==`aurora-cluster`].Endpoint' | grep -oE '"[^"]+"' | awk -F'"' '{print $2}') >> TMP
sed -i "s|AURORA_CLUSTER_ENDPOINT|$(cat TMP)|g" dbinfo.inc