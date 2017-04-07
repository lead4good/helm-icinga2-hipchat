#!/bin/bash

while true; do
  icingacli director core
  if [ "$?" = 0 ]; then
    break
  fi
  sleep 5
done

http_warn_time=$(jq -r '.http_warn_time' < values.json)
http_timeout=$(jq -r '.http_timeout' < values.json)

hostcmd="{\"check_command\":\"http\",\"object_name\":\"http-host\",\"object_type\":\"template\",\"vars\":{\"http_timeout\":\"$http_timeout\",\"http_warn_time\":\"$http_warn_time\",\"http_vhost\":\"www.\$check_address\$\",\"http_onredirect\":\"follow\"}}"
eval "icingacli director host create --json '$hostcmd'"
while IFS= read -r value; do
  json="{\"address\":$value,\"imports\":[\"http-host\"],\"object_name\":$value,\"object_type\":\"object\",\"vars\":{\"http_timeout\":\"$http_timeout\",\"http_warn_time\":\"$http_warn_time\",\"http_vhost\":\"www.\$check_address\$\",\"http_onredirect\":\"follow\"}}"
  cmd="icingacli director host create --json '$json'"
  echo $cmd
  eval $cmd
done < <(jq -r  '.[] | .[] |@json' < urls-current.json)


declare -A values=( ) descriptions=( )

while IFS= read -r key &&
      IFS= read -r value; do
  values[$key]=$value
  descriptions[$key]=$description
  if [ "$value" = '"null"' ]; then
    cmd="icingacli director $(echo $key|tr -d '"')"
  else
    cmd="icingacli director $(echo $key|tr -d '"') --json $(echo $value)"
  fi
  echo $cmd
  eval $cmd
done < <(jq '.[] | (.command, (.json | @json))' < config.json)
