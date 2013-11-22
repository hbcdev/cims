LPARAMETER tcFundCode
IF PARAMETER() = 0
	RETURN
ENDIF
***********************
SET MULTILOCK ON
OPEN DATA E:\Hips\data\cims
IF !USED("category")
	USE cims!category IN 0 ORDER cat_id
ENDIF	
IF !USED("notify_period")
	USE cims!notify_period IN 0 ORDER notify_no
ENDIF
IF !USED("notify_period_items")
	USE cims!notify_period_items IN 0 ORDER notify_no
ENDIF
IF !USED("notify_period_lines")
	USE cims!notify_period_lines IN 0 ORDER notify_no
ENDIF
IF !USED("notify")
	USE cims!notify IN 0 ORDER no
ENDIF
IF !USED("claim")
	USE cims!claim IN 0 ORDER customer_i
ENDIF
IF !USED("claim_line")
	USE cims!claim_line IN 0 ORDER claim_id
ENDIF
=CURSORSETPROP("Buffering",5,"notify_period")
=CURSORSETPROP("Buffering",5,"notify_period_items")
=CURSORSETPROP("Buffering",5,"notify_period_lines")
********************************************************
LOCAL lcNotifyNo

SELECT claim
SET RELATION TO claim_id INTO Claim_line ADDITIVE
SET RELATION TO Claim.notify_no INTO Notify ADDITIVE
=SEEK(tcFundCode, "claim", "customer_i")
DO WHILE LEFT(customer_id,3) = tcFundCode AND !EOF()
	IF claim.claim_type = 2  && IPD
		llAddNew = .T.
		WAIT claim.notify_no WINDOW NOWAIT
		IF SEEK(claim.claim_id,"notify_period_lines","claim_id")
			lcNotifyNo = notify_period_lines.notify_no
			IF SEEK(lcNotifyNo, "notify_period", "notify_no")
				llAddNew = .F.
			ENDIF			
		ENDIF		
		*****************************************
		IF SEEK(claim.claim_id,"claim_line","claim_id")
			ldPeriod = TTOD(claim.disc_date)
			IF SEEK(claim_line.cat_id, "category", "cat_id")
				ldPeriod = ldPeriod + category.period
			ELSE
				ldPeriod = ldPeriod + 90
			ENDIF
		ENDIF
		**************************************
		IF llAddNew
			WAIT WINDOW "Add New Period Claim " NOWAIT
			APPEND BLANK IN notify_period
			REPLACE notify_period.customer_id WITH claim.customer_id,;
			notify_period.policy_no WITH notify.policy_no,;
			notify_period.notify_no WITH claim.notify_no,;
			notify_period.notify_dat WITH claim.notify_date,;
			notify_period.type WITH claim.claim_type,;
			notify_period.diags WITH claim.illness1,;
			notify_period.due WITH ldPeriod
		ELSE	
			REPLACE notify_period.charge WITH notify_period.charge+claim.scharge,;
				notify_period.benefit WITH notify_period.benefit+claim.sbenfpaid,;
				notify_period.over WITH notify_period.over+claim.sremain,;
				notify_period.l_user WITH claim.l_user,;
				notify_period.l_update WITH claim.l_update
		ENDIF		
		*************	
		SELECT claim_line
		DO WHILE claim_id = claim.claim_id AND !EOF()
			IF !SEEK(notify_period.notify_no+cat_id,"notify_period_items","notify_cat")
				APPEND BLANK IN notify_period_items
				REPLACE notify_period_items.notify_no WITH notify_period.notify_no,;
					notify_period_items.cat_id WITH claim_line.cat_id,;
					notify_period_items.cat_code WITH claim_line.cat_code,;
					notify_period_items.description WITH claim_line.description,;
					notify_period_items.item_grp WITH claim_line.item_grp,;
					notify_period_items.fee WITH claim_line.fee,;
					notify_period_items.group WITH claim_line.group,;
					notify_period_items.benf_cover WITH claim_line.benf_cover,;
					notify_period_items.serv_cover WITH claim_line.serv_cover,;
					notify_period_items.per WITH claim_line.service_type
			ENDIF
			REPLACE notify_period_items.serv_used WITH IIF(notify_period_items.per = "D", notify_period_items.serv_used+claim_line.fadmis,0),;
				notify_period_items.charge WITH notify_period_items.charge+claim_line.fcharge,;
				notify_period_items.benefit WITH notify_period_items.benefit+claim_line.fpaid,;
				notify_period_items.fee_rate WITH notify_period_items.fee_rate+claim_line.total_fee
			SKIP IN claim_line
		ENDDO
		*****************
		IF !SEEK(notify_period.notify_no+claim.claim_id,"notify_period_lines","notify_clm")
			APPEND BLANK IN notify_period_lines
			REPLACE notify_period_lines.notify_no WITH notify_period.notify_no,;
				notify_period_lines.claim_id WITH claim.claim_id,;
				notify_period_lines.not_no WITH claim.notify_no,;
				notify_period_lines.icd10 WITH claim.illness1,;
				notify_period_lines.icd9 WITH claim.icd9_1,;
				notify_period_lines.admit WITH claim.admis_date,;
				notify_period_lines.disc WITH claim.disc_date
		ENDIF	
	ENDIF	
	SELECT claim
	SKIP
ENDDO