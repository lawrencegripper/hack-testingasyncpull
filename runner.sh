#!/bin/bash

set -e

run () {
    POD_NAME=$1
    RESULTS_DIR=results-$POD_NAME

    mkdir -p $RESULTS_DIR

    kind delete cluster --name control || true
    kind create cluster --name control --image kindest/node:v1.17.0
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 5; echo "--------> waiting for cluster node to be available"; done
    kubectl apply -f ./single-init/$POD_NAME.yaml
    # Wait for pod to complete
    until kubectl get pod -o json | jq ".items[].status.phase" | grep -q "Succeeded"; do sleep 5;echo "--------> waiting for pod to complete"; done
    kubectl get events --field-selector involvedObject.name==$POD_NAME -o json | jq '[.items[] | {"reason": .reason, "message": .message, "time": .firstTimestamp }]'  > ./$RESULTS_DIR/normal-$POD_NAME.json

    kind delete cluster --name control || true
    kind create cluster --name control --image kindest/node:lawrence
    JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'; until kubectl get nodes -o jsonpath="$JSONPATH" 2>&1 | grep -q "Ready=True"; do sleep 5; echo "--------> waiting for cluster node to be available"; done
    kubectl apply -f ./single-init/$POD_NAME.yaml
    # Wait for pod to complete
    until kubectl get pod -o json | jq ".items[].status.phase" | grep -q "Succeeded"; do sleep 5;echo "--------> waiting for pod to complete"; done
    kubectl get events --field-selector involvedObject.name==$POD_NAME -o json | jq '[.items[] | {"reason": .reason, "message": .message, "time": .firstTimestamp }]'  > ./$RESULTS_DIR/async-$POD_NAME.json


    echo "RESULTS: Before"
    python3 ./calc.py ./$RESULTS_DIR/normal-$POD_NAME.json | tee -a ./$RESULTS_DIR/results.txt

    echo "RESULTS: After"
    python3 ./calc.py ./$RESULTS_DIR/async-$POD_NAME.json | tee -a ./$RESULTS_DIR/results.txt
} 

run control
run control

run 200mb-10sec
run 200mb-10sec

run 600mb-10sec
run 600mb-10sec

run 1000mb-10sec
run 1000mb-10sec

