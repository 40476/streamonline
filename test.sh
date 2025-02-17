#!/bin/bash

function canRun(){
  if [ $(($(date +%s) - $(date +%s -r "$1"))) -gt 43200 ]; then
    printf "true"
  else
    printf "false"
  fi
}
if canRun $1 2> /dev/null | grep -sq "true" ; then
  echo true
fi