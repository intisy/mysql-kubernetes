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
  command=$@
  echo "Executing: $command"
  if ! "$command"
  then
    echo "$(printf "Failed during: %s" "$(shell_join "$@")")"
  fi
}

execute "kubectl delete secret mysql-secret"
execute "kubectl delete pv mysql-pv-volume"
execute "kubectl delete pvc mysql-pv-claim"
execute "kubectl delete deployment mysql"
execute "kubectl delete service mysql-service"
execute "kubectl delete deployment phpmyadmin-deployment"
execute "kubectl delete service phpmyadmin-service"
