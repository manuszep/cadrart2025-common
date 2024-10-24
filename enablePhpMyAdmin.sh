#!/bin/bash

kubectl apply -f ./infrastructure/kubernetes/phpmyadmin-deployment.yaml
kubectl apply -f ./infrastructure/kubernetes/phpmyadmin-service.yaml
