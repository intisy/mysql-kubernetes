#!/bin/bash

sha=$1
root_password=$2
user_password=$3
using_nfs=false #...

generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  password=$(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}

if [ ! -n "$root_password" ]; then
  generate_secure_password
  root_password=$password
fi

if [ ! -n "$user_password" ]; then
  generate_secure_password
  user_password=$password
fi
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/$sha/scripts/deinstall.sh | bash -s
echo "Root password: $root_password"
kubectl create secret generic mysql-root-pass --from-literal=password=$root_password
echo "User password: $user_password"
kubectl create secret generic mysql-user-pass --from-literal=password=$user_password
if [ "$using_nfs" = true ]; then
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
spec:
  capacity:
    storage: 20Gi
  accessModes:
    - ReadWriteOnce
  nfs:
    server: $(hostname -I | awk {'print $1'})
    path: /exports/documents
  persistentVolumeReclaimPolicy: Recycle
OEF
else
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
        - key: kubernetes.io/hostname
          operator: In
          values:
          - blizzity2
OEF
fi
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/mysql.yaml
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/.commits/$sha/phpmyadmin.yaml
echo "waiting for mysql to be ready..." >&2
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    sleep 1
done
