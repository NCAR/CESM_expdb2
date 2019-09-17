#!/usr/bin/env python
"""
Insert the CMIP6 MIP types into the t2_cmip6_mips table
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
    print('pip install -i https://testpypi.python.org/pypi --user  dreqPy==[latest-version]')
    print('The latest version can be found at https://www.earthsystemcog.org/projects/wip/CMIP6DataRequest')
    sys.exit(1)

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

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='load name and description fields from the CMIP6 data request database into t2_cmip6_mips.')

    parser.add_argument('--backtrace', action='store_true', 
                        help='Show exception backtraces as extra debugging output')

    parser.add_argument('--debug', required=False, action='store_true',
                        help='Display debugging messages')

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

    # create a db connection and cursor
    db = MySQLdb.connect(host="localhost", user="u_csegdb", passwd="c$3gdb", db="csegdb")
    cursor = db.cursor()

    # loop through the mips list and load them into the database
    for key, value in mips.iteritems():
        if key not in _exclude_mips:
            count = 0
            sql = "select count(id), id, name, description, dreq_version from t2_cmip6_MIP_types where name = '{0}'".format(key)
            mip_description = db.escape_string(value)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (count, id, name, description, dreq_version) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()
        
            if count == 1:
                sql = "update t2_cmip6_MIP_types set name = '{0}', description = '{1}', dreq_version = '{2}' where id = {3}".format(key, mip_description, version, id)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    db.commit()
                except:
                    print("Error executing sql = {0}".format(sql))
                    db.rollback()

            elif count == 0:
                sql = "insert into t2_cmip6_MIP_types (name, description, dreq_version) value ('{0}','{1}','{2}')".format(key, mip_description, version)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()
            else:
                print("Error in database {0} rows found matching MIP name '{1}'".format(count, name))

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
