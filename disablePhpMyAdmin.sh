#!/bin/bash

kubectl delete -f ./infrastructure/kubernetes/phpmyadmin-deployment.yaml
kubectl delete -f ./infrastructure/kubernetes/phpmyadmin-service.yaml
