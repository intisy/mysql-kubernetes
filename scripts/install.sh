#!/bin/bash

args=$@
pat=$1
sha=$2
password=$3
using_nfs=$4

echo2() {
  echo -e "\033[0;33m$@\033[0m"
}
generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo2 "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  echo2 $(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}

echo2 "Setting up using options: $@"
if [ ! -n "$password" ]; then
  password=$(generate_secure_password)
  echo2 "Generated root password: $password"
fi

sudo bash kubernetes-center/run.sh repo=mysql-kubernetes raw_args="$args" action=deinstall pat=$pat sha=$sha
sudo mkdir /mnt/data/mysql
kubectl create secret generic mysql-root-pass --from-literal=password=$password
if [ "$using_nfs" = true ]; then
  echo2 "Installing MySQL with NFS support"
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: nfs-server.default.svc.cluster.local
    path: /mysql
OEF
else
  echo2 "Installing MySQL without NFS"
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 20Gi
  volumeMode: Filesystem
  accessModes:
  - ReadWriteOnce
  persistentVolumeReclaimPolicy: Delete
  claimRef:
    namespace: default
    name: mysql-pv-claim
  storageClassName: local-storage
  local:
    path: "/mnt/data/mysql"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: node-role.kubernetes.io/control-plane
          operator: In
          values:
          - "true"
OEF
fi
echo2 "Installing MySQL"
sudo bash kubernetes-center/run.sh repo=mysql-kubernetes action=mysql pat=$pat sha=$sha yaml=true
echo2 "Waiting for MySQL to be ready..." >&2
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    sleep 1
done
echo2 "Installing PhpMyAdmin"
sudo bash kubernetes-center/run.sh repo=mysql-kubernetes action=phpmyadmin pat=$pat sha=$sha yaml=true
