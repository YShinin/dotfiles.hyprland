#!/bin/bash

counter=0
while :
do
  response=$(hyprctl monitors -j | jq ".[${counter}] |  .height")
  if [[ ! "$response" =~ "null" ]]; then
    heights+=${response}
    ((counter++))
  else
    break
  fi
done


echo ${heights}
