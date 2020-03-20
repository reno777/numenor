#!/usr/bin/env python
#slackhook.py - Slack API hook for Cobalt Strike
#This file needs to be copied into the "/cobaltstrike" directory that will be
#transfered to the teamserver.

import argparse
import slackweb
import socket

parser = argparse.ArgumentParser(description='beacon info')
parser.add_argument('--computername')
parser.add_argument('--internalip')
parser.add_argument('--username')

hostname = socket.gethostname()

args = parser.parse_args()

#Insert the slack API key here, replace <APIKey>
slackUrl ="<APIKey>"
computername = args.computername
internalip = args.internalip
username = args.username

slack = slackweb.Slack(url=slackUrl)
message = "New Beacon: {}@{} ({}) on {}".format(username,computername,internalip,hostname)
#Be sure to change the channel and username variables 
slack.notify(text=message, channel="#general", username="CSBOT")
