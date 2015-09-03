#!/bin/bash

function cpu_amount {
  if [ -e /proc/cpuinfo ]
  then
    echo "$(cat /proc/cpuinfo | grep processor | wc -l) processor(s)"
  fi
}

function ram_amount {
  if [ -e /proc/meminfo ]
  then
    echo "$(echo "$(cat /proc/meminfo | grep MemTotal | cut -d ' ' -f 9) / 1000000" | bc)GB RAM"
  fi
}

function disk_usage {
  df -h | grep -v udev | grep -v devfs | grep -v map | grep -v '/run'
}

cpu_amount
ram_amount
disk_usage
