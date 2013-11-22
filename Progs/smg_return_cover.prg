

SET REPORTBEHAVIOR 90
*

		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, claim.client_name, claim.service_type, ;
			claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.snote, ;
			claim.indication_admit, claim.result, claim.diag_plan, claim.tr_acno, claim.tr_name, claim.paid_date, ;
			claim.lotno, claim.batchno, claim.insurepaydate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= gcFundCode AND claim.return_date Between gdStartDate AND gdEndDate AND claim.result= gcResult ;
		ORDER BY claim.paid_date ;
		INTO CURSOR curCredit	
		*
		IF _TALLY = 0
			=MESSAGEBOX("ไม่พบข้อมูลเคลมสำหรับส่งกลับในช่วงวันที่ "+DTOC(gdStartDate)+ " ถึง วันที่ " +DTOC(gdEndDate)), 0, "คำเตือน")		
		ELSE 		
			DO CASE 
			CASE gnOption = 1
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Reimb_Return") TO PRINTER PROMPT 
			CASE gnOption = 2
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Reimb_Return") PREVIEW
			CASE gnOption = 3
			ENDCASE 
		ENDIF 	
	ELSE 	
		SELECT fund.thainame AS fundname, claim.prov_name, claim.policy_no, claim.notify_no, claim.notify_date, claim.client_name, claim.service_type, ;
			claim.admis_date, claim.disc_date, claim.scharge, claim.sdiscount, claim.snopaid, claim.sbenfpaid, claim.snote, ;
			claim.indication_admit, claim.result, claim.diag_plan, claim.tr_acno, claim.tr_name, claim.paid_date, ;
			claim.lotno, claim.batchno, claim.insurepaydate ;		
		FROM cims!claim LEFT JOIN cims!fund ;
			ON claim.fundcode = fund.fundcode ;
		WHERE claim.fundcode= gcFundCode AND claim.return_date Between gdStartDate AND gdEndDate AND claim.result= gcResult ;
		ORDER BY claim.prov_name ;
		INTO CURSOR curCredit	
		*
		IF _TALLY = 0
			=MESSAGEBOX("ไม่พบข้อมูลเคลมสำหรับส่งกลับในช่วงวันที่ "+DTOC(gdStartDate)+ " ถึง วันที่ " +DTOC(gdEndDate)), 0, "คำเตือน")		
		ELSE 		
			DO CASE 
			CASE gnOption = 1
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Credit_Return") TO PRINTER PROMPT 
			CASE gnOption = 2
				REPORT FORM (ADDBS(gcReportPath)+"Claim_Credit_Return") PREVIEW
			CASE gnOption = 3
			ENDCASE 
		ENDIF 	
	ENDIF 	
ENDIF 
SET REPORTBEHAVIOR 80