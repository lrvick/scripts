#!/bin/bash

# A ghetto loop that verifys you are actually online before launching gizmo...
# It then kills gizmo if you lose internet connectivity and relaunches it when connectivity is found again.
#This is a dirty hack since Gizmo itself has no such functionality and will not reconnect if dropped.

while true; do
  proscheck=`ps -A | grep gizmo`
  netcheck=`ping -c 3 google.com` 
  if [ -z $(echo $proscheck| grep received) ]; then 
    if [ -z "$proscheck" ]; then
      /opt/bin/gizmo &
    fi
  else
    if [ -n "$proscheck" ]; then 
      killall gizmo 2>&1 > /dev/null 
    fi
  fi  
  sleep 5
done  
