#!/bin/bash
NATS_USERNAME=${NATS_USERNAME:=`cat ${NATS_USERNAME_FILE:=NATS_USERNAME_FILE}`} || echo "/NATS_USERNAME_FILE does not exist"
NATS_PASSWORD=${NATS_PASSWORD:=`cat ${NATS_PASSWORD_FILE:=NATS_PASSWORD_FILE}`} || echo "/NATS_USERNAME_FILE does not exist"
export NATS_URI="nats://${NATS_USERNAME}:${NATS_PASSWORD}@${NATS_NAME}:4222"
