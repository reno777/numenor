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
    parser.add_argument("--ops1", help="Uses OPS1 as target infrasture.", action="store_true")
    parser.add_argument("--ops2", help="Uses OPS2 as target infrasture.", action="store_true")
    parser.add_argument("--ops3", help="Uses OPS3 as target infrasture.", action="store_true")
    args = parser.parse_args()
    terra = "terraform apply --auto-approve"
    terrd = "terraform destroy --auto-approve"
    terro = "terraform output"
    if args.apply :
        if args.ops1 :
            print "[!] Spinning up OPS1"
            os.chdir("/etc/terraform/ops1")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terra, shell=True)
        elif args.ops2 :
            print "[!] Spinning up OPS2!"
            os.chdir("/etc/terraform/ops2")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terra, shell=True)
        elif args.ops3 :
            print "[!] Spinning up OPS3!"
            os.chdir("/etc/terraform/ops3")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terra, shell=True)
        else :
            print "[!!!] Please specify the infrastructure to apply!"
        print "[DEBUG] Infrastructure has been built!"
    if args.destroy :
        if args.ops1 : 
            print "[!] Destroying OPS1!"
            os.chdir("/etc/terraform/ops1")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terrd, shell=True)
        elif args.ops2 :
            print "[!] Destroying OPS2!"
            os.chdir("/etc/terraform/ops2")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terrd, shell=True)
        elif args.ops3 :
            print "[!] Destroying OPS3!"
            os.chdir("/etc/terraform/ops3")
            print os.getcwd() #debug
            subprocess.call(["terraform", "init"])
            subprocess.call(terrd, shell=True)
        else :
            print "[!!!] Please specify the infrastructure to destroy!"
        print "[DEBUG] Infrastructure has been destroyed!"
    if args.output :
        if args.ops1 : 
            print "[!] Querying OPS1!"
            os.chdir("/etc/terraform/ops1")
            print os.getcwd() #debug
            subprocess.call(terro, shell=True)
        elif args.ops2 :
            print "[!] Querying OPS2!"
            os.chdir("/etc/terraform/ops2")
            print os.getcwd() #debug
            subprocess.call(terro, shell=True)
        elif args.ops3 :
            print "[!] Querying OPS3!"
            os.chdir("/etc/terraform/ops3")
            print os.getcwd() #debug
            subprocess.call(terro, shell=True)
        else :
            print "[!!!] Please specify the infrastructure to query!"

if __name__ == "__main__" :
    prog_parser()
