#!/usr/bin/env python
"""
Query the CMIP6 data request database to return CMIP6 experiments options.
--------------------------
Created October, 2016

Author: CSEG <cseg@cgd.ucar.edu>
"""

from __future__ import print_function

import sys

# check the system python version and require 2.7.x or greater 
if sys.hexversion < 0x02070000:
    print(70 * "*")
    print("ERROR: {0} requires python >= 2.7.x. ".format(sys.argv[0]))
    print("It appears that you are running python {0}".format(
            ".".join(str(x) for x in sys.version_info[0:3])))
    print(70 * "*")
    sys.exit(1)

try:
    from dreqPy import dreq
except ImportError:
    print('ERROR cmip6_lookup in listCMIP6 - unable to import dreqPy package.')
    print('Please install or update to the latest dreqPy version in your local user directory as follows:')
    print('pip install -i https://testpypi.python.org/pypi --user  dreqPy==[01.beta.#]')
    print('The latest version can be found at https://www.earthsystemcog.org/projects/wip/CMIP6DataRequest')
    sys.exit(1)
#
# built-in modules
#
import argparse
import errno
import json
import pprint
import traceback

# define global variables
_pp = pprint.PrettyPrinter(indent=4)

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='Query and display information from the CMIP6 data request database.')

    parser.add_argument('--backtrace', action='store_true', 
                        help='Show exception backtraces as extra debugging output')

    parser.add_argument('--debug', required=False, action='store_true',
                        help='Display debugging messages')

    parser.add_argument('--expNames', action='store_true',
                        help='Display a list of valid CMIP6 experiment names.')

    parser.add_argument('--MIPS', action='store_true',
                        help='Display a list of valid MIPS.')

    parser.add_argument('--expMips', action='store_true',
                        help='Display a list of requesting and designing MIPs for each experiment name.')

    parser.add_argument('--vars', action='store_true',
                        help='Display a list of variables for each experiment name.')

    options = parser.parse_args()

    return options

# ---------------------------------------------------------------------
# get_mip_list
# ---------------------------------------------------------------------
def get_mip_list(dq=None):

    """ 
    Get a list of all MIPs within the CMIP6 data request 
    Return: 

    mips(dictionary): a dictionary containing the mip name as the key and 
          its values being the description of that mip
    """

    mips = {}
    if dq is None:
        dq = dreq.loadDreq()
    for m in dq.coll['mip'].items:
        mips[m.label] = m.title    

    return mips

# ---------------------------------------------------------------------
# get_exp_list
# ---------------------------------------------------------------------
def get_exp_list(dq=None):

    """ 
    Get a list of all experiments within the CMIP6 data request 

    Return: 
    exp(ditctionary): a dictionary containing the experiment name as the key and 
         its values being the description of that experiment
    """

    exp = {}
    if dq is None:
        dq = dreq.loadDreq()
    for e in dq.coll['experiment'].items:
        exp[e.label] = [e.description, e.uid]

    return exp


# ---------------------------------------------------------------------
# map_exp_to_design_mip
# ---------------------------------------------------------------------
def map_exp_to_design_mip(exp_name, dq=None):

    """
    Takes an experiment name and returns the designing mip name

    Args:
    exp_name: name of the experiment to look up

    Return:
    mip(string):  name of the designing mip
    """
    
    if dq is None:
        dq = dreq.loadDreq()
    e_id = dq.inx.experiment.label[exp_name][0]
    mip = dq.inx.uid[e_id].mip
    
    return mip

# ---------------------------------------------------------------------
# map_exp_to_request_mip
# ---------------------------------------------------------------------
def map_exp_to_request_mip(exp_name, dq=None):

    """
    Takes an experiment name and returns the mips requesting data from it

    Args:
    exp_name: name of the experiment to look up

    Return:
    mip (list):  name of the requesting mips
    """

    if dq is None:
        dq = dreq.loadDreq()

    mips = []
    e_id = dq.inx.experiment.label[exp_name][0]
    mips.append(dq.inx.uid[e_id].mip)
    e_vars = dq.inx.iref_by_sect[e_id].a
    for ri in e_vars['requestItem']:
        dr = dq.inx.uid[ri]
        if dr.mip not in mips:
            mips.append(dr.mip)

    return mips

# ---------------------------------------------------------------------
# main
# ---------------------------------------------------------------------

def main(options):
    """ main

    Arguments:
        options (list) - input options from command line
    """
    case_dict = dict()
    debug = options.debug

    dq = dreq.loadDreq()

    if options.MIPS:
        print('\n\n##################################################################')
        mips = get_mip_list(dq=dq)
        print('MIPS: ')
        _pp.pprint(mips)

    if options.expNames:
        print('\n\n##################################################################')
        exps = get_exp_list(dq=dq)
        print('Experiments:  ')
        _pp.pprint(exps)

    if options.expMips:
        print('\n\n##################################################################')
        for e in dq.coll['experiment'].items:
            print('Requesting: ',e.label, map_exp_to_request_mip(e.label, dq=dq))
            print('Designing: ',e.label, map_exp_to_design_mip(e.label, dq=dq),'\n')


#===================================                                                           
if __name__ == "__main__":
    options = commandline_options()
    try:
        status = main(options)
        sys.exit(status)
    except Exception as error:
        print(str(error))
        if options.backtrace:
            traceback.print_exc()
        sys.exit(1)
