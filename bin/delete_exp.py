#!/usr/bin/env python
"""
Delete and experiment by name
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

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='CAUTION! Removing case metadata cannot be easily undone.' \
        'Remove a CESM experiment case and all metadata from the database.')

    parser.add_argument('-casename', '--casename', nargs=1, required=True,
                        help='Unique casename to be deleted. ')

    parser.add_argument('-removeSVN', '--removeSVN', action='store_true',
                        help='Remove the SVN caseroot directory and all tags. Default is false.')

    options = parser.parse_args()

    return options


# ---------------------------------------------------------------------
# main
# ---------------------------------------------------------------------

def main(options):
    """ main

    Arguments:
        options (list) - input options from command line
    """
    casename = options.casename[0]
    removeSVN = options.removeSVN
    
    # create a db connection and cursor
    db = MySQLdb.connect(host="localhost", user="u_csegdb", passwd="c$3gdb", db="csegdb")
    cursor = db.cursor()

    sql = "select count(id), id from t2_cases where casename = '"+casename+"'"
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
        (count, case_id) = cursor.fetchone()
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()

    if count == 0:
        print ("casename = {0} does not exist. Exiting...".format(casename))
        # disconnect from server
        db.close()
        return 0

    # delete from t2_cases
    sql = "delete from t2_cases where id = "+str(case_id)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
        db.close()
        return 1

    # update from t2j_cmip6
    sql = "update t2j_cmip6 set case_id = NULL, parentExp_id = NULL, real_num = NULL, " \
          "ensemble_num = NULL, ensemble_size = NULL, assign_id = NULL, science_id = NULL, " \
          "request_date = NULL where case_id = "+str(case_id)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
        db.close()
        return 1

    # delete from t2j_status
    sql = "delete from t2j_status where case_id = "+str(case_id)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
        db.close()
        return 1

    # delete from t2e_notes
    sql = "delete from t2e_notes where case_id = "+str(case_id)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
        db.close()
        return 1

    # delete from t2e_fields
    sql = "delete from t2e_fields where case_id = "+str(case_id)
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()
        db.close()
        return 1

    # TODO remove SVN trunk and all trunk_tags

    # disconnect from server
    db.close()
    return 0

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
