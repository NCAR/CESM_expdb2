#!/usr/bin/env python

from dreqPy import dreq

# Name of the experiment you want to find the variables for
exp = 'historical'

# Dictionary to hold the variables 
# Stored as [mip_table] = [variable names]
variables = {}

# Load in the request
dq = dreq.loadDreq()

# Get the experiment id
e_id = dq.inx.experiment.label[exp]

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

for mt,var_s in sorted(variables.iteritems()):
    print "---------------------------"
    print "TABLE: ",mt
    print sorted(var_s)
     
