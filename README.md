MySQL + PhpMyAdmin
---------
Install

1. Manual Installation
 - First we create the mysql-secret, make sure to replace the password:
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
