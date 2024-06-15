#!/bin/bash

log=$1

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
  if [ "$log" = false ]; then
    void=$($command)
  else
    $command
    if [[ $? -ne 0 ]]; then
      echo "Error: '$command' failed with exit code: $?."
    fi
  fi
}

execute "kubectl delete secret mysql-secret" &
execute "kubectl delete pv mysql-pv-volume" &
execute "kubectl delete pvc mysql-pvc" &
execute "kubectl delete deployment mysql" &
execute "kubectl delete service mysql" &
execute "kubectl delete deployment phpmyadmin" &
execute "kubectl delete service phpmyadmin" &
