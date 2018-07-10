#!/usr/bin/env python
"""
Insert the CMIP6 experiments into the t2_cmip6_exps table
--------------------------
Created November, 2016

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

# these experiments are not required in the database because they will not be run by CESM
_exclude_exps = []

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='load experiments name and UID fields from the CMIP6 data request database into t2_cmip6_exps.')

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
    exps = get_exp_list(dq=dq)

    # create a db connection and cursor
    db = MySQLdb.connect(host="localhost", user="u_csegdb", passwd="c$3gdb", db="csegdb")
    cursor = db.cursor()

    # loop through the exps dictionary and load them into the database keying off the name
    for key, value in exps.iteritems():
        # check that the key (experiment name) isn't included in the _exclude_exps list
        if key not in _exclude_exps:
            count = 0
            sql = "select count(id), id, name, description, uid, design_mip, dreq_version from t2_cmip6_exps where name = '"+key+"'"
            dreq_description = db.escape_string(value[0])
            dreq_uid = db.escape_string(value[1])
            dreq_design_mip = db.escape_string(value[2])
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (count, id, name, description, uid, design_mip, dreq_version) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()
        
            if count == 1:
                sql = "update t2_cmip6_exps set description = '{0}', uid = '{1}', design_mip = '{2}', dreq_version = '{3}' where id = {4}".format(dreq_description, dreq_uid, dreq_design_mip, version, str(id))
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    db.commit()
                except:
                    print("Error executing sql = {0}".format(sql))
                    db.rollback()

            elif count == 0:
                sql = "insert into t2_cmip6_exps (name, description, uid, design_mip, dreq_version) value ('{0}','{1}','{2}','{3}','{4}')".format(key, dreq_description, dreq_uid, dreq_design_mip, version)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()
            else:
                print("Error in database {0} rows found matching experiment name '{1}'".format(count, name))

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
