#!/usr/bin/python2.7

"""
### AUTHOR: 0xreno
### LICENSE: GNU-GPL v3.0
"""

#Below are all of the module imports
import argparse
import os

def prog_parser() :
    parser = argparse.ArgumentParser()
    parser.add_argument("op_name", help="Gives a name to the machines that are spun up in Digital Ocean.")
    parser.add_argument("-a", "--apply", help="Applies the infrastructure and spins up the machines.", action="store_true")
    parser.add_argument("-d", "--destroy", help="Destroys any current infrastructure that is spun up.", action="store_true")
    parser.add_argument("--ops1", help="Uses OPS1 as target infrasture.", action="store_true")
    parser.add_argument("--ops2", help="Uses OPS2 as target infrasture.", action="store_true")
    parser.add_argument("--ops3", help="Uses OPS3 as target infrasture.", action="store_true")
    args = parser.parse_args()
    if args.apply :
        if args.op1 :
            print "[!] Spinning up OPS1"
            os.chdir("/etc/terraform/ops1")
            print os.getcwd()
        elif args.op2 :
            print "[!] Spinning up OPS2!"
            os.chdir("/etc/terraform/ops2")
            print os.getcwd()
        elif args.op3 :
            print "[!] Spinning up OPS3!"
            os.chdir("/etc/terraform/ops3")
            print os.getcwd()
        else :
            print "[!!!] Please specify the infrastructure to apply!"
        print "[DEBUG] Infrastructure {} applied!".format(args.op_name)
    if args.destroy :
        if args.op1 : 
            print "[!] Destroying OPS1!"
            os.chdir("/etc/terraform/ops1")
            print os.getcwd()
        elif args.op2 :
            print "[!] Destroying OPS2!"
            os.chdir("/etc/terraform/ops2")
            print os.getcwd()
        elif args.op3 :
            print "[!] Destroying OPS3!"
            os.chdir("/etc/terraform/ops3")
            print os.getcwd()
        else :
            print "[!!!] Please specify the infrastructure to destroy!"
        print "[DEBUG] Infrastructure {} destroyed!".format(args.op_name)

if __name__ == "__main__" :
    prog_parser()
