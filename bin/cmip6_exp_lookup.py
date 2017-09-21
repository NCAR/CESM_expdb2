#!/usr/bin/env python
"""
Query the CMIP6 experiments tables and return corresponding CMIP6 tables and variables
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

    options = parser.parse_args()

    return options

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
        mip = map_exp_to_design_mip(e.label, dq)
        exp[e.label] = [e.description, e.uid, mip]
            
    return exp

# ---------------------------------------------------------------------
# main
# ---------------------------------------------------------------------

def main(options):
    """ main

    Arguments:
        options (list) - input options from command line
    """
    debug = options.debug

    # Load in the request
    dq = dreq.loadDreq()

    # load up the experiments name into a list
    exps = get_exp_list(dq=dq)

    for exp, value in exps.iteritems():
        # Dictionary to hold the variables 
        # Stored as [mip_table] = [variable names]
        variables = {}

        # Get the experiment id
        e_id = dq.inx.experiment.label[exp]
    
        if e_id:
            # Store info about exp in e_vars
            e_vars = dq.inx.iref_by_sect[e_id[0]].a
    
            # Query e_vars to get the 'requestItem's and loop over each item
            for ri in e_vars['requestItem']:

                # Get more info about this request item
                dr = dq.inx.uid[ri]
                rl = dq.inx.requestLink.uid[dr.rlid]
                # Now we can get these vars that are within this request item
                vars = dq.inx.iref_by_sect[rl.refid].a
                var_list = vars['requestVar'] 

                # Go through each requested var and get its name
                for rv in var_list:
                    v_id = dq.inx.uid[rv].vid
                    c_var = dq.inx.uid[v_id]
                    if c_var.mipTable not in variables.keys():
                        variables[c_var.mipTable] = []
                    if c_var.label not in variables[c_var.mipTable]:
                        variables[c_var.mipTable].append(c_var.label)

            print ('EXPERIMENT: {0}'.format(exp))
            for mt,var_s in sorted(variables.iteritems()):
                print ('____________________')
                print ('TABLE     : {0}'.format(mt))
                print (sorted(var_s))

        else:
            print ('EXPERIMENT: {0}'.format(exp))
            print ('No variables found')
            print ('____________________')

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
