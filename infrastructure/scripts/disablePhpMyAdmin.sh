#!/bin/bash

kubectl delete -f ../kubernetes/phpMyAdmin/phpmyadmin-deployment.yaml
kubectl delete -f ../kubernetes/phpMyAdmin/phpmyadmin-service.yaml
