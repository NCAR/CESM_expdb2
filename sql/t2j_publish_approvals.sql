use csegdb;

drop table if exists t2j_publish_approvals;

create table t2j_publish_approvals(
       `case_id` INTEGER,
       `approver_id` INTEGER,
       `publishType_id` INTEGER);


