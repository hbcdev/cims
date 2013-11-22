LPARAMETER tcNotifyNo, tcFollowUp, tdDiscDate, ltEdit 
IF PARAMETERS() < 4
	tcEdit = .T.
ENDIF 
*************	
LOCAL lcClaimID,;
	lcNotifyNO,;
	lnArea,;
	llClosed
	
IF EMPTY(tcNotifyNo) AND EMPTY(tcFollowUp)
	RETURN
ENDIF
*************************
llClosed = .F.
lnArea = SELECT()	
lcNotifyNo = tcFollowUp
lcClaimID = tcNotifyNo
*************************
IF !USED("claim") AND  !USED("claim_line") AND  !USED("notify_period") AND !USED("notify_period_items") AND !USED("notify_period_lines")
	WAIT WINDOW "Cannot save period" NOWAIT
	RETURN
ENDIF
***************************************
IF !SEEK(lcClaimID,"claim","notify_no")
	RETURN
ENDIF
******************************	
cPlanID = claim.plan_id
nType = claim.claim_type
************************
IF !USED("prodbycode")
	USE cims!prodbycode IN 0
ELSE 
	=REQUERY("prodbycode")	
ENDIF 
*
IF !USED("benefit")
	USE cims!benefit IN 0
ELSE
	=REQUERY("benefit")
ENDIF
SELECT benefit
IF !IsTag("cat_id")
	INDEX ON cat_id TAG cat_id
ENDIF	
*****
IF EOF("benefit")
	RETURN
ENDIF
*******************************
IF !benefit.illness
	RETURN
ENDIF
**********************
lnPeriod = benefit.period
lnFollowup = benefit.followup
lnDuePeriod = IIF(prodbycode.period_type = "N", prodbycode.period, 0)
ldDue = IIF(lnPeriod = 0, claim.expried, TTOD(claim.disc_date) + lnPeriod)
ldFollowup = TTOD(claim.disc_date) + lnFollowUp
lcCustDue = claim.customer_id+DTOC(ldDue) 
********************************************
IF !SEEK(lcNotifyNo, "notify_period", "notify_no")
	DO Add_period IN saveperiod
ELSE
	IF SEEK(lcClaimID, "notify_period_lines", "not_no")
		DO RecallPeriod WITH lcNotifyNo
	ENDIF 	
	DO UpdatePeriod WITH lcNotifyNo, lnDuePeriod
ENDIF	
SELECT (lnArea)
***************************************
*
PROC Add_Period
***************************************
=WaitWindow("Add New disability Please wait ...", 0)
SELECT notify_period
APPEND BLANK
REPLACE notify_period.customer_id WITH claim.customer_id,;
notify_period.fundcode WITH Claim.fundcode,;
notify_period.type WITH claim.claim_type,;
notify_period.service_type WITH claim.service_type,;
notify_period.visit_no WITH claim.visit_no,;
notify_period.policy_no WITH claim.policy_no,;
notify_period.family_no WITH claim.family_no,;
notify_period.effective WITH claim.effective, ;
notify_period.expired WITH claim.expried, ;
notify_period.plan_id WITH Claim.plan_id,;
notify_period.plan WITH Claim.plan,;
notify_period.notify_no WITH claim.notify_no,;
notify_period.notify_dat WITH claim.notify_date,;
notify_period.acc_date WITH claim.acc_date,;
notify_period.admis_date WITH claim.admis_date,;
notify_period.disc_date WITH Claim.disc_date,;
notify_period.diags WITH claim.illness1,;
notify_period.due WITH ldDue,;
notify_period.endfollowup WITH ldFollowUp,;
notify_period.charge WITH IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge),;
notify_period.benefit WITH IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid),;
notify_period.over WITH IIF(EMPTY(claim.fax_by), claim.sremain, claim.fremain),;
notify_period.l_user WITH gcUserName,;
notify_period.l_update WITH DATETIME()
************************************
SELECT notify_period_lines
APPEND BLANK 
REPLACE notify_no WITH notify_period.notify_no,;
claim_id WITH claim.claim_id,;
not_no WITH claim.notify_no,;
admit WITH claim.admis_date,;
disc WITH claim.disc_date,;
icd10 WITH claim.illness1,;
icd9 WITH claim.icd9_1,;
prov_id WITH claim.prov_id,;
prov_name WITH claim.prov_name,;
fcharge WITH IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge),;
fpaid WITH IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)
**************************************
SELECT claim_line
SET ORDER TO NOTIFY_NO   && NOTIFY_NO 
DO WHILE notify_no = claim.notify_no AND !EOF()
	IF LEFT(claim_line.cat_id,4) <> "XXXX"
		IF EMPTY(claim.fax_by)
			lnCharge = claim_line.scharge
			lnPaid = claim_line.spaid
			IF notify_period_items.per = "D"	
				lnServiceDay =  IIF(claim_line.sservice = 0, claim_line.sadmis, claim_line.sservice)
			ELSE
				lnServiceDay =  claim_line.sadmis
			ENDIF				
		ELSE
			lnCharge = claim_line.fcharge
			lnPaid = claim_line.fpaid
			IF notify_period_items.per = "D"	
				lnServiceDay =  IIF(claim_line.sservice = 0, claim_line.sadmis, claim_line.sservice)
			ELSE
				lnServiceDay =  claim_line.fadmis
			ENDIF				
		ENDIF	
		*******************************	
		IF SEEK(cat_id, "benefit", "cat_id")
			lnOonCover = benefit.benefit2
		ELSE
			lnOonCover = benefit.benefit
		ENDIF
		******************************	
		APPEND BLANK IN notify_period_items
		REPLACE notify_period_items.notify_no WITH notify_period.notify_no,;
		notify_period_items.cat_id WITH claim_line.cat_id,;
		notify_period_items.cat_code WITH claim_line.cat_code,;
		notify_period_items.description WITH claim_line.description,;
		notify_period_items.item_grp WITH claim_line.item_grp,;
		notify_period_items.fee WITH claim_line.fee,;
		notify_period_items.fee_rate WITH claim_line.total_fee,;
		notify_period_items.group WITH claim_line.group,;
		notify_period_items.benf_cover WITH claim_line.benf_cover,;
		notify_period_items.oon_cover WITH lnOonCover,;
		notify_period_items.serv_cover WITH claim_line.serv_cover,;
		notify_period_items.per WITH claim_line.service_type,;
		notify_period_items.serv_used WITH lnServiceDay,;
		notify_period_items.charge WITH lnCharge,;
		notify_period_items.benefit WITH lnPaid,;
		notify_period_items.fee_rate WITH claim_line.total_fee, ;
		notify_period_items.subservice WITH claim_line.subservice, ;
		notify_period_items.subpaid WITH claim_line.subpaid, ;
		notify_period_items.l_user WITH gcusername, ;
		notify_period_items.l_update WITH DATETIME()
	ENDIF	
	SKIP IN claim_line
ENDDO
******************************
SELECT claim_item_icd9
SET ORDER TO notify_no
IF SEEK(claim.notify_no)
	DO WHILE claim.notify_no = notify_no AND !EOF()
		APPEND BLANK IN notify_period_fee
		REPLACE notify_period_fee.notify_no WITH claim.notify_no,;
		notify_period_fee.claim_id WITH claim.claim_id,;
		notify_period_fee.itemcode WITH item_code,;
		notify_period_fee.fee WITH fee,;
		notify_period_fee.use WITH use,;
		notify_period_fee.l_user WITH gcUserName,;
		notify_period_fee.l_update WITH DATETIME()
		SKIP
	ENDDO
ENDIF
WAIT CLEAR
********************************************************