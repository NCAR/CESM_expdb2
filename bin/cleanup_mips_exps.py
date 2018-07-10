#!/usr/bin/env python
"""
cleean-up the CMIP6 experiments and mips based on most current dreqpy
--------------------------
Created March, 2018

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
    print('ERROR - unable to import dreq library')
    print('Please install or update to the latest dreqPy version in your local user directory as follows:')
    print('pip install -i https://testpypi.python.org/pypi --user  dreqPy==[latest_version]')
    print('The latest version can be found at https://www.earthsystemcog.org/projects/wip/CMIP6DataRequest')
    sys.exit(1)

from dreqPy.__init__ import version
drqVersion = version

try:
    import MySQLdb
except ImportError:
    print('ERROR - unable to import MySQLdb library')
    print('Please install or update to the latest MySQLdb version in your local user directory as follows:')
    print('pip install MySQL-Python --user')
    sys.exit(1)

#
# built-in modules
#
import argparse
import errno
import json
import pprint
import traceback


# these mips are not required in the database
_exclude_mips = []

# these experiments are not required in the database because they will not be run by CESM
_exclude_exps = []

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='Delete any experiments and MIPS that are no longer supported in the current dreqpy')

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

    dq = dreq.loadDreq()
    version = dq.version
    mips = get_mip_list(dq=dq)
    exps = get_exp_list(dq=dq)

    # create a db connection and cursor
    db = MySQLdb.connect(host="localhost", user="u_csegdb", passwd="c$3gdb", db="csegdb")
    cursor = db.cursor()

# sql statements that work... need to change the dreq_version <> 'version' for a script 
delete from t2j_cmip6_exps_mips where exp_id in (select id from t2_cmip6_exps where dreq_version = '01.00.21');
delete from t2j_cmip6 where exp_id in (select id from t2_cmip6_exps where dreq_version = '01.00.21') and case_id is NULL;
delete from t2_cmip6_exps where dreq_version = '01.00.21';

    # remove experiments that are not in this dreqpy version
    # CAUTION - this could be dangerous if there's already a casename assigned to the experiment
#    sql = "delete t2_cmip6_exps where dreq_version <> '{0}'".format(version)
#    try:
#        print ("Executing sql = {0}".format(sql))
#        cursor.execute(sql)
#        db.commit()
#    except:
#        print ("Error executing sql = {0}".format(sql))
#        db.rollback()

    # disconnect from server
    db.close()

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





    # remove experiments that are not in this dreqpy version
    # CAUTION - this could be dangerous if there's already a casename assigned to the experiment
    sql = "delete t2_cmip6_exps where dreq_version <> '{0}'".format(version)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
        db.commit()
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
