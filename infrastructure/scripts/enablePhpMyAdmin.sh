#!/bin/bash

kubectl apply -f ../kubernetes/phpMyAdmin/phpmyadmin-deployment.yaml
kubectl apply -f ../kubernetes/phpMyAdmin/phpmyadmin-service.yaml
