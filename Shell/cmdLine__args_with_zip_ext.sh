#!/usr/bin/env bash

## Takes last argument ##
destPath=${!#}

if [[ $# -le 1 ]]
then
  echo "Exit"
  echo "Count less then 1: $#"
else
  echo "Total arguments : $@"
  echo "Last value : ${destPath}"
  for cmd in "$@"
  do
## Checking for .zip extensio ##
    if [[ ${cmd: -4} == ".zip" ]]
    then
      echo "Only with .zip extensio : ${cmd}"
      echo "Copying ${cmd} to  ${destPath} ..."
      #cp -rp ${cmd} ${destPath}
    fi
  done
fi
