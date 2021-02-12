#!/usr/bin/env python
"""
Map the one to many MIP experiments
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

# -------------------------------------------------------------------------------
# commandline_options - parse any command line options
# -------------------------------------------------------------------------------
def commandline_options():
    """Process the command line arguments.

    """
    parser = argparse.ArgumentParser(
        description='Add the CESM exps to t2j_cmip6.')

    parser.add_argument('--backtrace', action='store_true', 
                        help='Show exception backtraces as extra debugging output')

    parser.add_argument('--debug', required=False, action='store_true',
                        help='Display debugging messages')

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
    debug = options.debug

    # create a db connection and cursor
    db = MySQLdb.connect(host="localhost", user="u_csegdb", passwd="c$3gdb", db="csegdb")
    cursor = db.cursor()

    # load a data request object
    dq = dreq.loadDreq()
    version = dq.version

    # define a lookup data structures for MIP experiments that are CESM specific
##    mip_exps = { 'DAMIP'         : ['hist-nat-WACCM', 'hist-GHG-WACCM'],
##                 'ScenarioMIP'   : ['ssp585-WACCM', 'ssp370-WACCM', 'ssp245-WACCM', 'ssp126-WACCM', 'ssp534-over-WACCM'],
##                 'RFMIP'         : ['piClim-control-WACCM'] }

    mip_exps = { 'ScenarioMIP'   : ['ssp126-ext-WACCM', 'ssp585-ext-WACCM', 'ssp534-over-ext-WACCM'] }

    for mip, exps in mip_exps.iteritems():
        # get the design_mip_id from the t2_cmip6_MIP_types
        sql = "select id from t2_cmip6_MIP_types where name = '{0}'".format(mip)
        try:
            print ("Executing sql = {0}".format(sql))
            cursor.execute(sql)
            (design_mip_id) = cursor.fetchone()
        except:
            print ("Error executing sql = {0}".format(sql))
            db.rollback()

        # loop over the exps for this MIP
        for exp in exps:
            # get the CMIP6 exp UID which will be the same for these new experiments
            exp_tmp = exp.replace('-ext-WACCM','')
            exp_tmp = exp_tmp.replace('-over-ext-WACCM','')
            sql = "select uid, description from t2_cmip6_exps where name = '{0}'".format(exp_tmp)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (uid, description) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()
            
            # check if this exp is already in the t2_cmip6_exps table
            exp_id = 0
            sql = "select count(id), id from t2_cmip6_exps where name = '{0}'".format(exp)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (exists, exp_id) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()

            if not exists:
                # insert a row into the t2_cmip6_exps
                sql = "insert into t2_cmip6_exps (name, description, uid, design_mip, dreq_version) value ('{0}','{1}','{2}','{3}','{4}')".format(exp, description, uid, mip, version)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

                # get the id for the exp just inserted
                sql = "select id from t2_cmip6_exps where name = '{0}'".format(exp)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    (id) = cursor.fetchone()
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

                # reset the exp_id to this new experiment
                exp_id = id[0]

                # check if record already exists in join table
                sql = "select count(exp_id) from t2j_cmip6 where exp_id = {0}".format(exp_id)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    (count) = cursor.fetchone()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()
                    
                if count[0] == 0:
                    # insert a new join record
                    sql = "insert into t2j_cmip6 (exp_id, design_mip_id) value ({0},{1})".format(exp_id, design_mip_id[0])
                    try:
                        print ("Executing sql = {0}".format(sql))
                        cursor.execute(sql)
                        db.commit()
                    except:
                        print ("Error executing sql = {0}".format(sql))
                        db.rollback()

                if count[0] == 1:
                    # update record with deck_id
                    sql = "update t2j_cmip6 set design_mip_id = {0} where exp_id = {1}".format(design_mip_id[0], exp_id)
                    try:
                        print ("Executing sql = {0}".format(sql))
                        cursor.execute(sql)
                        db.commit()
                    except:
                        print ("Error executing sql = {0}".format(sql))
                        db.rollback()



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
