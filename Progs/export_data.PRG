SELECT tpacode as fundcode, policy_no as policyno, name, surname, ;
product as plan, effective as effdate, expiry as expdate, pay_fr as paymode, ;
overall_limit as medical, hb_limit as hbcover, plan_id as planid, lastpaid, reindate, ;
end_serial as mtcode, status, TTOD(effective)+30 as waiting, TTOD(expiry)+31 As grace, ;
TTOD(effective)+120 As exclwait, exclusion, policy_date as poldate, l_update as lastupdate ;
FROM cims!member ;
WHERE tpacode = "ACE"
COPY TO f:\report\ace_member.txt TYPE DELIMITED WITH CHARACTER ";"