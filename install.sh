#!/bin/bash

password=$1

generate_secure_password() {
  if ! command -v openssl &> /dev/null; then
    echo "Error: OpenSSL not found. Secure password generation unavailable."
    return 1
  fi
  length=20
  password=$(openssl rand -base64 $length | tr -dc 'A-Za-z0-9')
}

if [ ! -n "$password" ]; then
  generate_secure_password
fi
echo "Root password: $password"
curl -fsSL https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/uninstall.sh | bash -s false
kubectl create secret generic mysql-root-pass --from-literal=password=$password
generate_secure_password
echo "User password: $password"
kubectl create secret generic mysql-user-pass --from-literal=password=$password
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
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/mysql.yaml
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/phpmyadmin.yaml
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    echo "waiting for mysql to be ready..." >&2
    sleep 1
done
