PARAMETERS tcNotifyNo

SELECT notify_period
IF SEEK(tcNotifyNo, "notify_period", "notify_no")
	REPLACE notify_period.customer_id WITH claim.customer_id, ;
	notify_period.fundcode WITH Claim.fundcode, ;
	notify_period.type WITH claim.claim_type, ;
	notify_period.service_type WITH claim.service_type, ;
	notify_period.visit_no WITH claim.visit_no, ;
	notify_period.policy_no WITH claim.policy_no, ;
	notify_period.family_no WITH claim.family_no, ;
	notify_period.plan_id WITH Claim.plan_id, ;
	notify_period.plan WITH Claim.plan, ;
	notify_period.notify_no WITH claim.notify_no, ;
	notify_period.notify_dat WITH claim.notify_date, ;
	notify_period.acc_date WITH claim.acc_date, ;
	notify_period.admis_date WITH claim.admis_date, ;
	notify_period.disc_date WITH Claim.disc_date, ;
	notify_period.diags WITH claim.illness1, ;
	notify_period.due WITH ldDue, ;
	notify_period.endfollowup WITH ldFollowUp, ;
	notify_period.l_user WITH gcUserName, ;
	notify_period.l_update WITH DATETIME()
ENDIF 	