#!/bin/bash

#path to configs
kubectl=/usr/local/bin/kubectl

# create nats_cluster_credentials
$kubectl create configmap cassandra-init-scripts \
    --from-file=dockerfile-app_cassandra/cql 