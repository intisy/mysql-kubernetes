#!/bin/bash

action=$1
password=$2
using_nfs=$3

execute() {
  substring="#!/bin/bash"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/mysql-kubernetes/commits | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/$sha/scripts/$action.sh"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring ]]; then
    curl -fsSL $url | bash -s $sha $password $using_nfs
  else
    sleep 1
    execute
  fi
}
execute
