#!/usr/bin/python2.7

"""
### AUTHOR: 0xreno
### LICENSE: GNU-GPL v3.0
"""

#Below are all of the module imports
import argparse
import os
import subprocess

#This is the program parsing funciton. This is what spins up and tears down the infrastructure.
def prog_parser() :
    parser = argparse.ArgumentParser(prog='numenor')
    parser.add_argument("-a", "--apply", help="Applies the infrastructure and spins up the machines.", action="store_true")
    parser.add_argument("-d", "--destroy", help="Destroys any current infrastructure that is spun up.", action="store_true")
    parser.add_argument("-o", "--output", help="Shows the infrastructure information.", action="store_true")
    #parser.add_argument("--update", help="Updates Numenor code to the latest version.". action="store_true")
    parser.add_argument("op_num", help="Specifies the Op directory to use.")
    args = parser.parse_args()
    return args

def terraform(args) :
    os.chdir("/etc/terraform/{}".format(args.op_num))
    print os.getcwd() #debug - remove when done
    subprocess.call(["terraform", "init"])
    if args.apply :
        print "Building {} for you!".format(args.op_num)
        subprocess.call(["terraform", "apply", "--auto-approve"])
    elif args.destroy :
        print "Initiating destruct sequence of {} for you!".format(args.op_num)
        subprocess.call(["terraform", "destroy", "--auto-approve"])
    elif args.output :
        print "Finding information on {} for you!".format(args.op_num)
        subprocess.call(["terraform", "output"])
    else :
        subprocess.call(["numenor", "-h"])


#def update(args) :

if __name__ == "__main__" :
    terraform(prog_parser())
