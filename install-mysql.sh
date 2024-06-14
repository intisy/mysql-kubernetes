#!/bin/bash

shell_join() {
  local arg
  printf "%s" "$1"
  shift
  for arg in "$@"
  do
    printf " "
    printf "%s" "${arg// /\ }"
  done
}

execute() {
  command="$@"
  $command
  if [[ $? -ne 0 ]]; then
    echo "Error: '$command' failed with exit code: $?."
  else
    echo "Successfully executed command: '$command'"
  fi
}

execute "kubectl apply -f - <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: mysql-secret
type: kubernetes.io/basic-auth
stringData:
  password: your_root_password
EOF"
execute "kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/mysql.yaml"
execute "kubectl apply -f https://raw.githubusercontent.com/WildePizza/kubernetes-apps/HEAD/phpmyadmin.yaml"
