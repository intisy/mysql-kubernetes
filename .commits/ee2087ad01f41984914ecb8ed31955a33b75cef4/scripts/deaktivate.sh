#!/bin/bash

kubectl delete deployment phpmyadmin
kubectl delete pods -l app=phpmyadmin
kubectl delete replicaset.apps -l app=phpmyadmin
kubectl delete deployment mysql
kubectl delete pods -l app=mysql
kubectl delete replicaset.apps -l app=mysql