MySQL + PhpMyAdmin
---------
Install

1. Manual Installation
 - First we create the mysql-secret, make sure to replace the password with you actual one:
```
kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: kubernetes.io/basic-auth
stringData:
  password: <your_password>
EOF
```
 - now we're gonna apply this MySQL file:
```
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/mysql.yaml
```
 - if you want to use PhpMyAdmin you can also apply this:
```
kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/phpmyadmin.yaml
```
2. Installation script (the password field is optional, you can leave it empty to get an random one)
```
curl -fsSL https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/install.sh | bash -s <your_password>
```
Deinstall

```
curl -fsSL https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/uninstall.sh | bash -s
```
Custom MySQL + InnoDB + PhpMyAdmin
---------
Install

1. Manual Installation
 - First we install the Custom Resource Definition:
```
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-crds.yaml
```
 - Next deploy MySQL Operator for Kubernetes:
```
kubectl apply -f https://raw.githubusercontent.com/mysql/mysql-operator/trunk/deploy/deploy-operator.yaml
```
 - Now once the mysql-operator is set up we create the mysql-secret, make sure to replace the password with you actual one:
```
kubectl create secret generic mysql-secret \
        --from-literal=rootUser=root \
        --from-literal=rootHost=% \
        --from-literal=rootPassword="<your_password>"
```
 - Now we create the InnoDBCluster definition:
```
kubectl apply -f - <<EOF
apiVersion: mysql.oracle.com/v2
kind: InnoDBCluster
metadata:
  name: mysql-cluster
spec:
  secretName: mysql-secret
  tlsUseSelfSigned: true
  instances: 3
  router:
    instances: 1
EOF
```
