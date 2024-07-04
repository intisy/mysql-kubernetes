#!/bin/bash

action=$1
arg1=$2
arg2=$2

execute() {
  substring="#!/bin/bash"
  sha=$(curl -sSL https://api.github.com/repos/WildePizza/mysql-kubernetes/commits?per_page=2 | jq -r '.[1].sha')
  url="https://raw.githubusercontent.com/WildePizza/mysql-kubernetes/HEAD/.commits/$sha/scripts/$action.sh"
  echo "Executing: $url"
  output=$(curl -fsSL $url 2>&1)
  if [[ $output =~ $substring ]]; then
    curl -fsSL $url | bash -s $sha $arg1 $arg2
  else
    sleep 1
    execute
  fi
}
execute
