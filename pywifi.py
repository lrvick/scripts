#! /usr/bin/python

import os

child_stdin, child_stdout, child_stderr = os.popen3("/sbin/iwlist scan | grep -e ESSID -e Quality -e Encryption | sed -e 's/^\s*//g' | tr '\n' ' '")
network_list = child_stdout.read()

network_number = network_list.count("\n")

counter = 1
if network_number > 1 :
  for network in network_list:
    counter += 1
    print counter,":",network
else:
	print "1:",network_list

network_choice = raw_input("Please enter the number of the network you wish to connect to: ")

