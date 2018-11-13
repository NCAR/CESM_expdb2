#!/usr/bin/env python
"""
Insert the CMIP6 exps and requesting MIPs into the t2j_cmip6 table
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
        description='create the join records between DECK, MIPS, and CMIP6 exps in t2j_cmip6.')

    parser.add_argument('--backtrace', action='store_true', 
                        help='Show exception backtraces as extra debugging output')

    parser.add_argument('--debug', required=False, action='store_true',
                        help='Display debugging messages')

    options = parser.parse_args()

    return options

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
    if dq.inx.experiment.label[exp_name]:
        e_id = dq.inx.experiment.label[exp_name][0]
        mips.append(dq.inx.uid[e_id].mip)
        e_vars = dq.inx.iref_by_sect[e_id].a
        for ri in e_vars['requestItem']:
            dr = dq.inx.uid[ri]
            if dr.mip not in mips:
                mips.append(dr.mip)

    return mips

# ---------------------------------------------------------------------
# join_DECK_exps
# ---------------------------------------------------------------------
def join_DECK_exps(db, cursor, version):

    """
    Add the deck_id to exp_id in join table

    Args:
    db: database connection object
    cursor: database cursor object
    version: dreq version
    """
    # define a lookup data structures for DECK experiments with design_mip = 'DECK'
    deck_exps = { 'historical'   : ['historical', 'historical-WACCM'],
                  'abrupt-4xCO2' : ['4xCO2-CESM2-BGC','4xCO2-CESM2-WACCM'],
                  '1pctCO2'      : ['1pctCO2-CESM2-BGC','1pctCO2-CESM2-WACCM'],
                  'amip'         : ['AMIP-CESM2-BGC','AMIP-CESM2-WACCM'],
                  'piControl'    : ['Control','Control-WACCM','Control-high-res'] }

    # get the DECK MIP id from the t2_cmip6_MIP_types table
    count = 0
    #sql = "select count(id), id from t2_cmip6_MIP_types where name = 'DECK'";
    sql = "select count(id), id from t2_cmip6_MIP_types where name = 'CMIP'";
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
        (count, deck_id) = cursor.fetchone()
    except:
        print ("Error executing sql = {0}".format(sql))
        db.rollback()

    if count == 1:
        # iterate through the deck_exps dictionary and create join entries.
        for deck, exps in deck_exps.iteritems():

            # get the deck_type_id 
            sql = "select id from t2_cmip6_DECK_types where name = '{0}'".format(deck)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (deck_type_id) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()

            # get the uid for this deck
            sql = "select uid from t2_cmip6_exps where name = '{0}'".format(deck)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor.execute(sql)
                (uid) = cursor.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()

            # loop over the exps for this DECK exp
            for exp in exps:
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

                sql = "select id, description from t2_cmip6_DECK_exps where CMIP6_DECK_exp = '{0}' and CESM_exp = '{1}'".format(deck, exp)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    (deck_exp_id, description) = cursor.fetchone()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

                if not exists:
                    # insert a row into the t2_cmip6_exps
                    #sql = "insert into t2_cmip6_exps (name, description, uid, design_mip, dreq_version, DECK_id) value ('{0}','{1}','{2}','DECK','{3}',{4})".format(exp, description, uid[0], version, deck_type_id[0])
                    sql = "insert into t2_cmip6_exps (name, description, uid, design_mip, dreq_version, DECK_id) value ('{0}','{1}','{2}','CMIP','{3}',{4})".format(exp, description, uid[0], version, deck_type_id[0])
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
                count3 = 0
                sql = "select count(exp_id) from t2j_cmip6 where exp_id = {0}".format(exp_id)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor.execute(sql)
                    (count3) = cursor.fetchone()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()
                    
                if count3[0] == 0:
                    # insert a new join record
                    sql = "insert into t2j_cmip6 (exp_id, deck_id, design_mip_id) value ({0},{1},{2})".format(exp_id, deck_type_id[0], deck_id)
                    try:
                        print ("Executing sql = {0}".format(sql))
                        cursor.execute(sql)
                        db.commit()
                    except:
                        print ("Error executing sql = {0}".format(sql))
                        db.rollback()

                if count3[0] == 1:
                    # update record with deck_id
                    sql = "update t2j_cmip6 set deck_id = {0}, design_mip_id = {1} where exp_id = {2}".format(deck_type_id[0], deck_id, exp_id)
                    try:
                        print ("Executing sql = {0}".format(sql))
                        cursor.execute(sql)
                        db.commit()
                    except:
                        print ("Error executing sql = {0}".format(sql))
                        db.rollback()

    return

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
    cursor1 = db.cursor()

    # load a data request object
    dq = dreq.loadDreq()
    version = dq.version

    # loop through the list of experiments and get the associated requesting MIPs
    sql = "select id, name, design_mip from t2_cmip6_exps"
    try:
        print ("Executing sql = {0}".format(sql))
        cursor.execute(sql)
    except:
        print ("Error executing sql = {0}".format(sql))
        sys.exit(1)

    for row in cursor:
        # get the design_mip_id from the t2_cmip6_MIP_types
        count1 = 0
        sql = "select count(id), id from t2_cmip6_MIP_types where name = '{0}'".format(row[2])
        try:
            print ("Executing sql = {0}".format(sql))
            cursor1.execute(sql)
            (count1, design_mip_id) = cursor1.fetchone()
        except:
            print ("Error executing sql = {0}".format(sql))
            db.rollback()

        if count1 == 1:
            # update / insert into the t2j_cmip6 table
            sql = "select count(exp_id) from t2j_cmip6 where exp_id = {0}".format(row[0])
            try:
                print ("Executing sql = {0}".format(sql))
                cursor1.execute(sql)
                count2 = cursor1.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()

            if count2[0] == 0:
                sql = "insert into t2j_cmip6 (exp_id, design_mip_id) value ({0},{1})".format(row[0], design_mip_id)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor1.execute(sql)
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

            if count2[0] == 1:
                sql = "update t2j_cmip6 set design_mip_id = {0} where exp_id = {1}".format(design_mip_id, row[0])
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor1.execute(sql)
                    db.commit()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

        # loop through the list of requesting mips and update or insert in the join table
        reqMips = map_exp_to_request_mip(row[1], dq=dq)
        for rm in reqMips:
            count2 = 0
            sql = "select count(id), id from t2_cmip6_MIP_types where name = '{0}'".format(rm)
            try:
                print ("Executing sql = {0}".format(sql))
                cursor1.execute(sql)
                (count2, MIPid) = cursor1.fetchone()
            except:
                print ("Error executing sql = {0}".format(sql))
                db.rollback()

            if count2 == 1:
                # check if record already exists in join table
                count3 = 0
                sql = "select count(exp_id), exp_id from t2j_cmip6_exps_mips where exp_id = {0} and mip_id = {1}".format(row[0], MIPid)
                try:
                    print ("Executing sql = {0}".format(sql))
                    cursor1.execute(sql)
                    (count3, exp_id) = cursor1.fetchone()
                except:
                    print ("Error executing sql = {0}".format(sql))
                    db.rollback()

                if count3 == 0:
                    # insert a new record
                    sql = "insert into t2j_cmip6_exps_mips (exp_id, mip_id) value ({0}, {1})".format(row[0], MIPid)
                    try:
                        print ("Executing sql = {0}".format(sql))
                        cursor1.execute(sql)
                        db.commit()
                    except:
                        print ("Error executing sql = {0}".format(sql))
                        db.rollback()
                
            else:
                print("Error there are {0} MIPS matching name {1}".format(count2,rm))

    # add the CMIP DECK entries to the exps and join tables
    join_DECK_exps(db, cursor, version)

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
