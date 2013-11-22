PARAMETERS tcFollowUp, tcNotifyNo

lnSelect = SELECT()
IF EMPTY(tcFollowUp) AND EMPTY(tcNotifyNo)
	RETURN 
ENDIF 
	
IF SEEK(tcFollowUp+tcNotifyNo, "notify_period_lines", "fw_no")
	DELETE IN notify_period_lines
	***************************************************
	SELECT claim_id, cat_id, cat_code, fadmis, fcharge, fpaid, fremain, ;
		sadmis, scharge, spaid, sremain ;
	FROM cims!claim_line ;
	WHERE notify_no = tcNotifyNo ;
	INTO CURSOR curLines 
	IF _TALLY = 0	
		RETURN 
	ENDIF 	
	SELECT curLines
	SCAN 
		IF SEEK(tcFollowUp+cat_id, "notifY_period_items", "notify_cat")
			REPLACE notify_period_items.serv_used WITH notify_period_items.serv_used - IIF(fadmis = 0, sadmis, fadmis), ;
				notify_period_items.charge WITH notify_period_items.charge - IIF(fcharge = 0, scharge, fcharge), ;
				notify_period_items.benefit WITH notify_period_items.benefit - IIF(fpaid = 0, spaid, fpaid)
		ENDIF 
	ENDSCAN 
	USE IN curLines
ENDIF			
				