#!/usr/bin/python2.7

"""
### AUTHOR: 0xreno
### LICENSE: GNU-GPL v3.0
"""

#Libraries
import argparse
import os
import subprocess

#Parses and creates arguements as an object from commandline arugments.
def prog_parser() :
    parser = argparse.ArgumentParser(prog='numenor')
    parser.add_argument("-a", "--apply", help="Applies the infrastructure and spins up the machines.", action="store_true")
    parser.add_argument("-d", "--destroy", help="Destroys any current infrastructure that is spun up.", action="store_true")
    parser.add_argument("-o", "--output", help="Shows the infrastructure information.", action="store_true")
    #parser.add_argument("--update", help="Updates Numenor code to the latest version.". action="store_true")
    parser.add_argument("op_num", help="Specifies the Op directory to use.")
    args = parser.parse_args()
    return args

#Used to spin up, tear down, and query the infrastructure.
def terraform(args) :
    os.chdir("/etc/terraform/{}".format(args.op_num))
    subprocess.call(["terraform", "init"])
    if args.apply :
        print "\n[!] Building {} for you!\n".format(args.op_num)
        subprocess.call(["terraform", "apply", "--auto-approve"])
    elif args.destroy :
        print "\n[!] Initiating the destruct sequence of {}!\n".format(args.op_num)
        subprocess.call(["terraform", "destroy", "--auto-approve"])
    elif args.output :
        print "\n[!] Finding information on {}!\n".format(args.op_num)
        subprocess.call(["terraform", "output"])
    else :
        print "\n[ERROR] Incorrect options! Please refer to 'numenor -h' for correct syntax!\n"

#Main function call
if __name__ == "__main__" :
    terraform(prog_parser())
