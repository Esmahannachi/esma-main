#!/bin/bash


#path to configs
config=devsecrets
kubectl=/usr/local/bin/kubectl


# create nats_cluster_credentials
$kubectl create secret generic nats-cluster-credentials \
    --from-file=$config/nats_cluster_password_secret \
    --from-file=$config/nats_cluster_username_secret \
    --dry-run=client -o=yaml |  $kubectl apply -f -

# create nats_client_credentials
$kubectl create secret generic nats-client-credentials \
    --from-file=$config/nats_password_secret \
    --from-file=$config/nats_username_secret \
    --dry-run=client -o=yaml |  $kubectl apply -f -