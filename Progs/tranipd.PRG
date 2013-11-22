SET TALK OFF
SET MULTI ON
LOCAL lnCharge,;
	lnThisClaim,;
	lnCover,;
	lnAdmit
******************************
OPEN DATA E:\hips\data\cims
IF !USED("claim")
	USE cims!claim IN 0 
ENDIF	
IF !USED("claim_line")
	USE cims!claim_line IN 0
ENDIF	
=CURSORSETPROP("Buffering",5,"claim_line")
*******************
SELECT claim
GO TOP
DO WHILE !EOF()
	IF claim_type = 1		
		IF ! SEEK(claim.claim_id, "claim_line", "claim_id")
			DO Create_Benf
		ENDIF	
	ENDIF
	SELECT claim
	IF !EOF()
		SKIP
	ENDIF	
ENDDO
**************************
PROC Create_Benf
**
cPlanID = claim.plan_id
nType = claim.claim_type
ntreatment = claim.type_claim
IF !USED("benefit")
	USE cims!benefit IN 0
ELSE
	=REQUERY("benefit")
ENDIF
SELECT benefit
IF !EOF()
	WAIT WINDOW "Add New Category in claim ID "+claim.claim_id NOWAIT
	SCAN
		APPEND BLANK IN claim_line
		REPLACE claim_line.claim_id WITH  claim.claim_id,;
			claim_line.cat_id WITH benefit.cat_id,;
			claim_line.cat_code WITH benefit.cat_code,;
			claim_line.description WITH benefit.description,;
			claim_line.benf_cover WITH benefit.benefit,;
			claim_line.serv_cover WITH IIF(benefit.type = 1,benefit.lm_code_7+benefit.lm_code_8, benefit.lm_code_4),;
			claim_line.service_type WITH benefit.per,;
			claim_line.group WITH benefit.cat_group,;
			claim_line.fee WITH benefit.fee,;
			claim_line.item_grp WITH benefit.item_grp,;
			claim_line.l_user WITH "Admin",;
			claim_line.l_update WITH DateTime(),;
			claim_line.dueperiod WITH TTOD(claim.disc_date)+benefit.period,;
			claim_line.duefollowup WITH IIF(EMPTY(benefit.followup), {}, TTOD(claim.disc_date)+benefit.followup),;
			claim_line.fadmis WITH IIF(benefit.type = claim.claim_type, 1, 0),;
			claim_line.fcharge WITH IIF(benefit.type = claim.claim_type, claim.fcharge, 0),;
			claim_line.fpaid WITH IIF(benefit.type = claim.claim_type, claim.fbenfpaid, 0),;
			claim_line.fremain WITH IIF(benefit.type = claim.claim_type, claim.fremain, 0)
	ENDSCAN
ENDIF