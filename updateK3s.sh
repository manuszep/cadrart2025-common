#!/bin/bash

kubectl apply -f ./infrastructure/kubernetes/configmap.yaml
kubectl apply -f ./infrastructure/kubernetes/secrets.yaml

kubectl apply -f ./infrastructure/kubernetes/static-volume-persistentvolumeclaim.yaml
kubectl apply -f ./infrastructure/kubernetes/db-volume-persistentvolumeclaim.yaml

kubectl apply -f ./infrastructure/kubernetes/db-deployment.yaml
kubectl apply -f ./infrastructure/kubernetes/db-service.yaml

kubectl apply -f ./infrastructure/kubernetes/ingress.yaml
