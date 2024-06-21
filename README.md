Install
---------

1. [Recommended] Installation script (the password field is optional, you can leave it empty to get an random one)
```
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/install.sh | bash -s <root_password> <user_password>
```
2. Manual Installation
 - First we create the secrets for root and user, make sure to replace the passwords with you actual one:
```
kubectl create secret generic mysql-root-pass --from-literal=password=<your_password>
kubectl create secret generic mysql-user-pass --from-literal=password=<your_password>
```
 - now we're gonna apply this MySQL file:
```
kubectl apply -f https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/mysql.yaml
```
 - if you want to use PhpMyAdmin you can also apply this:
```
kubectl apply -f https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/phpmyadmin.yaml
```
Deinstall
---------

```
curl -fsSL https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/deinstall.sh | bash -s
```
