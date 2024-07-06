#!/bin/bash

kubectl delete service phpmyadmin --grace-period=0 --force
kubectl delete deployment phpmyadmin --grace-period=0 --force
kubectl delete pods -l app=phpmyadmin --grace-period=0 --force
kubectl delete replicaset.apps -l app=phpmyadmin --grace-period=0 --force
kubectl delete deployment mysql --grace-period=0 --force
kubectl delete pods -l app=mysql --grace-period=0 --force
kubectl delete replicaset.apps -l app=mysql --grace-period=0 --force
kubectl delete service mysql --grace-period=0 --force
kubectl delete pvc mysql-pv-claim --grace-period=0 --force
kubectl delete pv mysql-pv --grace-period=0 --force
kubectl delete secret mysql-root-pass --grace-period=0 --force
kubectl delete secret mysql-user-pass --grace-period=0 --force
