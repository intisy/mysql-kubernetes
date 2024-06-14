#!/bin/bash

kubectl delete pv mysql-pv-volume
kubectl delete pvc mysql-pv-claim
kubectl delete deployment mysql
kubectl delete service mysql-service
kubectl delete deployment phpmyadmin-deployment
kubectl delete service phpmyadmin-service
