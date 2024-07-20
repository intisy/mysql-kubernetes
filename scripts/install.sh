#!/bin/bash

args=$@
pat=$1
sha=$2
password=$3
using_nfs=$4
local_ip=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | awk '{print $2}' | cut -d'/' -f1 | head -n 1)

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
echo2 "Installing MySQL"
if [ "$using_nfs" = true ]; then
  echo2 "Installing MySQL with NFS support"
  kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolume
metadata:
  name: mysql-pv
  namespace: default
spec:
  capacity:
    storage: 10Gi
  accessModes:
    - ReadWriteMany
  claimRef:
    namespace: default
    name: mysql-pv-claim
  nfs: 
    server: $local_ip
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
kubectl apply -f - <<OEF
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: mysql-pv-claim
  namespace: default
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 10Gi
OEF
kubectl apply -f - <<OEF
apiVersion: v1
kind: Service
metadata:
  name: mysql
spec:
  type: NodePort
  selector:
    app: mysql
  ports:
    - port: 3306
      targetPort: 3306
      nodePort: 30007
OEF
kubectl apply -f - <<OEF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mysql
  labels:
    app: mysql
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mysql
  template:
    metadata:
      labels:
        app: mysql
    spec:
      restartPolicy: Always
      volumes:
      - name: mysql-pv
        persistentVolumeClaim:
          claimName: mysql-pv-claim
      containers:
      - name: mysql
        image: mysql:9.0.0
        env:
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-root-pass
              key: password
        - name: MYSQL_DATABASE
          value: blizzity
        volumeMounts:
        - name: mysql-pv
          mountPath: /var/lib/mysql
        ports:
        - containerPort: 3306
          name: mysql
OEF
echo2 "Waiting for MySQL to be ready..." >&2
while [ $(kubectl get deployment mysql | grep -c "1/1") != "1" ]; do
    sleep 1
done
echo2 "Installing PhpMyAdmin"
kubectl apply -f - <<OEF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: phpmyadmin
  labels:
    app: phpmyadmin
spec:
  replicas: 1
  selector:
    matchLabels:
      app: phpmyadmin
  strategy:
    type: Recreate
  template:
    metadata:
      labels:
        app: phpmyadmin
    spec:
      restartPolicy: Always
      containers:
      - name: phpmyadmin
        image: phpmyadmin:5.2.1
        ports:
        - containerPort: 80
          name: phpmyadmin
        env:
        - name: PMA_HOST
          value: mysql
        - name: PMA_PORT
          value: "3306"
        - name: MYSQL_ROOT_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-root-pass
              key: password
        - name: MYSQL_DATABASE
          value: blizzity
OEF
kubectl apply -f - <<OEF
apiVersion: v1
kind: Service
metadata:
  name: phpmyadmin
spec:
  type: LoadBalancer
  selector:
    app: phpmyadmin
  ports:
  - protocol: TCP
    port: 720
    targetPort: 80
OEF
