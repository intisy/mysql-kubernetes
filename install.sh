#!/bin/bash

root_password=$1
user_password=$2
using_nfs=false

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
curl -fsSL https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/uninstall.sh | bash -s false
echo "Root password: $password"
kubectl create secret generic mysql-root-pass --from-literal=password=$root_password
generate_secure_password
echo "User password: $password"
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
  storageClassName: local-storage
  local:
    path: "/var/lib/mysql"
  nodeAffinity:
    required:
      nodeSelectorTerms:
      - matchExpressions:
        - key: kubernetes.io/role
          operator: In
          values:
          - control-plane
OEF
fi
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/mysql.yaml
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/phpmyadmin.yaml
echo "waiting for mysql to be ready..." >&2
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    sleep 1
done
