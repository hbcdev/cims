SELECT logbook.notify_no, logbook.policy_no, logbook.client_name, logbook.plan, logbook.policy_date, logbook.policy_exp, ;
	logbook.prov_name, logbook.admis_date, logbook.acc_date, logbook.age, member.renew ;
FROM cims!notify_log logbook INNER JOIN cims!member;
	ON logbook.policy_no = member.policy_no ;
WHERE fundcode = "KTA" ;
AND summit Between gdStartDate AND gdEndDate ;
ORDER BY plan ;
INTO CURSOR curLogBook

lcSourceFile = "F:\Hips\Template\HBC_CL_001.XLS"
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcSourceFile)

lnSheetNo = 0
SELECT curLogBook
DO WHILE !EOF()	
	IF INLIST(LEFT(plan,2), "HS", "HI")
		lnSheetNo = 1
	ELSE 
		IF LEFT(plan,3) = "MEA"
			IF TTOD(policy_date) > {^2007-08-01}			
				lnSheetNo = 5
			ELSE 
				lnSheetNo = 2
			ENDIF 		
		ELSE 
			IF LEFT(plan,3) = "HBC"
				lnSheetNo = 3			
			ELSE 
				lnSheetNo = 4				
			ENDIF 
		ENDIF 	
	ENDIF
	*
	osheet = oWorkbook.WorkSheets(lnSheetNo)
	oSheet.Cells(1, 08).Value = policy_date
	oSheet.Cells(1, 10).Value = policy_exp 
	oSheet.Cells(3, 09).Value = notify_no
	oSheet.Cells(4, 01).Value = "Hospital "+prov_name+" Province "
	oSheet.Cells(4, 07).Value = admis_date
	oSheet.Cells(5, 01).Value = "Policy No "+policy_no+" Plan "+plan+" Name "+ALLTRIM(client_name)+" Age "+TRANSFORM(age, "@Z 99")
	
	SUSPEND 
	
	SKIP 
ENDDO 	
	 