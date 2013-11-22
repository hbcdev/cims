LOCAL lnSumCharge,;
	lnSumPaid,;
	lnSumDay,;
	lnCharge,;
	lnPaid,;
	lnServiceDay
****************
SELECT notify_period
REPLACE notify_period.charge WITH IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge),;
notify_period.benefit WITH IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid),;
notify_period.over WITH IIF(EMPTY(claim.fax_by), claim.sremain, claim.fremain),;
notify_period.l_user WITH gcUserName,;
notify_period.l_update WITH DATETIME()
************************************
SELECT claim_line
IF SEEK(claim.claim_id, "claim_line", "claim_id")
	DO WHILE claim_id = claim.claim_id AND !EOF()
		IF LEFT(claim_line.cat_id,4) <> "XXXX"
			IF EMPTY(claim.fax_by)
				IF notify_period_items.per = "D"	
					lnServiceDay =  IIF(claim_line.sservice <> 0, claim_line.sservice, claim_line.sadmis)
				ELSE
					lnServiceDay =  claim_line.sadmis
				ENDIF
				lnCharge = claim_line.scharge
				lnPaid = claim_line.spaid
			ELSE
				IF notify_period_items.per = "D"	
					lnServiceDay =  IIF(claim_line.fservice <> 0, claim_line.fservice, claim_line.fadmis)
				ELSE
					lnServiceDay =  claim_line.fadmis
				ENDIF
				lnCharge = claim_line.fcharge
				lnPaid = claim_line.fpaid				
			ENDIF	
			******************************************************************
			IF SEEK(notify_period.notify_no+cat_id,"notify_period_items","notify_cat")
				REPLACE notify_period_items.serv_used WITH notify_period_items.serv_used+lnServiceDay,;
				notify_period_items.charge WITH notify_period_items.charge+lnCharge,;
				notify_period_items.benefit WITH notify_period_items.benefit+lnPaid,;
				notify_period_items.fee_rate WITH notify_period_items.fee_rate+claim_line.total_fee
			ELSE
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
				notify_period_items.oon_cover WITH 0,;
				notify_period_items.serv_cover WITH claim_line.serv_cover,;
				notify_period_items.per WITH claim_line.service_type,;
				notify_period_items.serv_used WITH lnServiceDay,;
				notify_period_items.charge WITH lnCharge,;
				notify_period_items.benefit WITH lnPaid,;
				notify_period_items.fee_rate WITH claim_line.total_fee
			ENDIF
		ENDIF	
		SKIP IN claim_line
	ENDDO
ENDIF	
*****************
SELECT notify_period_lines
SET ORDER TO notify_clm
IF !SEEK(notify_period.notify_no+claim.claim_id)
	APPEND BLANK 
ENDIF
REPLACE notify_no WITH notify_period.notify_no,;
claim_id WITH claim.claim_id,;
not_no WITH claim.notify_no,;
admit WITH claim.admis_date,;
disc WITH claim.disc_date,;
icd10 WITH claim.illness1,;
icd9 WITH claim.icd9_1,;
prov_name WITH claim.prov_name,;
fcharge WITH IIF(EMPTY(claim.fax_by), claim.scharge, claim.fcharge),;
fpaid WITH IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)
*****************************************************