#!/usr/bin/env python3

import pprint
import traceback
import sys
import logging as log
import argparse
import statistics as s
import subprocess
import json

parser = argparse.ArgumentParser()
parser.add_argument("-j", "--jobid", type=str, default=None, help="Find the nodes for the following job ID")
parser.add_argument("-q", "--queue", type=str, default=None, help="Move the nodes for the job ID to the queue specified")
parser.add_argument("-o", "--offline", action="store_true", help="Offline the nodes for the job ID given")
parser.add_argument("-l", "--logging", type=str, default="INFO", help="Logging level")

args = parser.parse_args()

if args.logging.lower() == "debug":
    log.basicConfig(level=log.DEBUG, format='%(message)s')
elif args.logging.lower() == "error":
    log.basicConfig(level=log.DEBUG, format='%(message)s')
elif args.logging.lower() == "warning":
    log.basicConfig(level=log.WARNING, format='%(message)s')
else:
    log.basicConfig(level=log.INFO, format='%(message)s')

files = list()
if args.jobid is not None:
    log.info("Job ID: {}".format(args.jobid))
    jobid = args.jobid.split(",")
    log.info("Job ID: {}".format(jobid))
else:
    log.info("Job ID not specified. Please specify job ID(s) i.e -j 12344 or -j 12345,123456".format(args.jobid))
    

# Find the nodes for the following VMs
pbs_cmd = "qstat -fx -F json {}"

for id in jobid:
    run_cmd = pbs_cmd.format(id)
    log.info("Run CMD: {}".format(run_cmd))
    jobinfo = subprocess.check_output(run_cmd, shell=True).decode()

    job_data = json.loads(jobinfo)
    fq_jobid = list(job_data["Jobs"].keys())[0]
    print("FQ Job ID: {}".format(fq_jobid))
    print("Job Hosts: {}".format(job_data["Jobs"][fq_jobid]["exec_host"]))
    tmp_data = job_data["Jobs"][fq_jobid]["exec_host"]
    tmp_nodes = tmp_data.split("+")
    nodes = []
    for node in tmp_nodes:
        nodes.append(node.split("/")[0])

    print("Nodes: {}".format(nodes))
    
    if args.queue != None:
        pbs_queue_cmd = 'qmgr -c "s n {} queue={}"'
        for node in nodes:
            run_cmd = pbs_queue_cmd.format(node,args.queue)
            qmove = subprocess.check_output(run_cmd, shell=True).decode()
            print("Queue move status: {}".format(qmove))
    
    if args.offline == True:
        pbs_offline_cmd = 'qmgr -c "s n {} state={}"'
        for node in nodes:
            run_cmd = pbs_offline_cmd.format(node,"offline")
            noffline = subprocess.check_output(run_cmd, shell=True).decode()
            print("Queue move status: {}".format(noffline))
