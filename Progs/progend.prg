IF HOUR(DATETIME()) >= 17
	lcMess = "�س " + gcUserName + " ��ͧ��þ���� ��§ҹ��ػ����͡����ͧ�ѹ��� �������?"
	IF MESSAGEBOX(lcMess,4+64+256, "����͹") = 6
		gtStartDate = DATETIME(YEAR(DATE()), MONTH(DATE()), DAY(DATE()), 00,00)
		gtEndDate = DATETIME(YEAR(DATE()), MONTH(DATE()), DAY(DATE()), 23,59)
		REPORT FORM (ADDBS(gcReportPath)+"claim_report_users") PREVIEW
	ENDIF 	
ENDIF 
*
IF USED("tracking")
	SELECT tracking
	SET ORDER TO logintime
	IF SEEK(gcUserName+TTOC(oApp.dLoginTime))
		REPLACE dateout WITH DATETIME(),;
			action WITH "Logout"
	ENDIF
ENDIF	