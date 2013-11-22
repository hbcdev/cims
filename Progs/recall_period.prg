PARAMETER lcNotify_no
LOCAL lnOldCharge,;
	lnOldPaid,;
	lnOldOver
**************************
SELECT claim
IF !EMPTY(claim.fax_by)
	lnOldCharge = OLDVAL("fcharge")
	lnOldPaid = OLDVAL("fbenfpaid")
	lnOldOver = OLDVAL("fremain")
	***
	lnCharge = fcharge
	lnPaid = fbenfpaid
	lnOver = fremain
ELSE
	lnOldCharge = OLDVAL("scharge")
	lnOldPaid = OLDVAL("sbenfpaid")
	lnOldOver = OLDVAL("sremain")
	***
	lnCharge = scharge
	lnPaid = sbenfpaid
	lnOver = sremain
ENDIF	
IF SEEK(lcNotify_no, "notify_period", "notify_no")
	REPLACE notify_period.charge WITH (notify_period.charge - lnOldCharge)+lnCharge,;
	notify_period.benefit WITH (notify_period.benefit - lnOldPaid)+lnPaid,;
	notify_period.over WITH (notify_period.over- lnOldOver)+lnOver,;
	notify_period.l_user WITH gcUserName,;
	notify_period.l_update WITH DATETIME()
ELSE
	RETURN	
ENDIF	
***************
SELECT claim_line
DO WHILE claim_id = claim.claim_id AND !EOF()
	IF LEFT(claim_line.cat_id,4) <> "XXXX"
		IF SEEK(notify_period.notify_no+cat_id,"notify_period_items","notify_cat")
			IF EMPTY(claim.fax_by)
				IF notify_period_items.per = "D"	
					lnServiceDay =  notify_period_items.serv_used - IIF(OLDVAL("sservice") <> 0, OLDVAL("sservice"), OLDVAL("sadmis"))
				ELSE
					lnServiceDay =  notify_period_items.serv_used - OLDVAL("sadmis")
				ENDIF
				*******************************************************
				REPLACE notify_period_items.serv_used WITH lnServiceDay,;
				notify_period_items.charge WITH notify_period_items.charge - OLDVAL("scharge"),;
				notify_period_items.benefit WITH notify_period_items.benefit - OLDVAL("spaid"),;
				notify_period_items.fee_rate WITH notify_period_items.fee_rate - OLDVAL("total_fee")
			ELSE
				IF notify_period_items.per = "D"	
					lnServiceDay =  notify_period_items.serv_used - IIF(OLDVAL("fservice") <> 0, OLDVAL("fservice"), OLDVAL("fadmis"))
				ELSE
					lnServiceDay =  notify_period_items.serv_used - OLDVAL("fadmis")
				ENDIF
				*******************************************************
				REPLACE notify_period_items.serv_used WITH lnServiceDay,;
				notify_period_items.charge WITH notify_period_items.charge - OLDVAL("fcharge"),;
				notify_period_items.benefit WITH notify_period_items.benefit - OLDVAL("fpaid"),;
				notify_period_items.fee_rate WITH notify_period_items.fee_rate - OLDVAL("total_fee")
			ENDIF	
		ENDIF
	ENDIF	
	SKIP IN claim_line
ENDDO