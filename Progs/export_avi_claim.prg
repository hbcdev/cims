PARAMETERS tcFundCode, tdStartDate, tdEndDate, tnClaimBy, tcSaveTo

IF EMPTY(tcFundCode) AND EMPTY(tdStartDate) AND EMPTY(tdEndDate) AND EMPTY(tnClaimBy)
	RETURN 
ENDIF 	

lcOrder = IIF(tnClaimBy = 2, "7", "4")+", claim.notify_no"

SET PROCEDURE TO progs\utility
SELECT claim.notify_no, member.policy_group, IIF(LEFT(claim.policy_no, 2) <> "DW", member.customer_id, claim.policy_no) AS policy_no, claim.policy_holder, ;
	claim.client_name, claim.service_type, claim.cause_type, claim.prov_id, claim.prov_name, claim.admis_date, claim.paid_to, claim.indication_admit, ;
	claim.disc_date, claim.scharge, claim.sdiscount, claim.sbenfpaid, claim.deduc, claim.deduc_paid + claim.snopaid + claim.sremain AS deduc_paid, claim.snote, ;
	claim.currency_rate, claim.refno, claim.sday, claim.icd9_1, claim.illness1, claim.illness2, claim.currency_type, claim.policy_no AS policy, ;
	LEFT(member.policy_group,6) AS groupno, claim.result, claim.return_date, STRTRAN(STRTRAN(IIF(LEFT(claim.policy_no, 2) <> "DW", member.customer_id, ;
	claim.policy_no), "P",""), "DW", "P") AS claimantid, claim.policy_no AS pol_no, claim.copayment ;
FROM cims!claim LEFT JOIN cims!member ;
	ON claim.fundcode+claim.policy_no = member.tpacode+member.policy_no ;
WHERE claim.fundcode = tcFundCode ;
	AND claim.inv_page = tnClaimBy ;	
	AND claim.result <> "C" ;
	AND claim.return_date BETWEEN tdStartDate AND tdEndDate ;
ORDER BY &lcOrder ;	
INTO CURSOR curAviClaim

IF _TALLY = 0
	=MESSAGEBOX("No data found for this period", 0, "Warning")
	RETURN 
ENDIF 
*
USE (ADDBS(DATAPATH)+"avi_hospital_code") IN 0 ALIAS aviHospital
*
lcSaveTo = tcSaveTo
lcFile = tcFundCode+"_Claim_"+IIF(tnClaimBy = 1, "Client", "Hospital")+"_Return_"+DTOS(tdStartDate)+"_"+DTOS(tdEndDate)
SELECT 0
CREATE DBF (lcSaveTo+lcFile) FREE (groupno C(30), empid C(30), claimantid C(30), hospname C(40), hospid C(10), assigncode C(1), benftype C(3), admit C(8), discharge C(8), ;
	charge Y, paid Y, deduc Y, bankcharge Y, totalpaid Y, comments C(250), patientno C(20), invoiceno C(20), copayment Y, claimtype C(2), mcdays I, diagcode C(30), diagscode C(30), ;
	currencyc C(3), clientname C(40), policy C(30), paid_to C(50), fxrate Y, indicator C(200), provid C(20), notify_no C(15), result C(3), insurename C(50))
lcAlias = ALIAS()
	
SELECT curAviClaim
GO TOP 
SCAN 
	IF SEEK(prov_id, "avihospital", "prov_id")
		m.hospid = IIF(tnClaimBy = 1, "30"+substr(avihospital.clinicid,3,2), avihospital.clinicid)
		m.hospname = avihospital.name
	ELSE 
		m.hospid = ""
		m.hospname = UPPER(ALLTRIM(curAviClaim.prov_name))
	ENDIF 	
	APPEND BLANK IN (lcAlias)
	REPLACE groupno WITH LEFT(curAviClaim.policy_group, 7), ;
		claimantid WITH IIF(ISNULL(curAviClaim.claimantid), "", curAviClaim.claimantid), ;
		hospname WITH m.hospname, ;
		hospid WITH m.hospid, ;
		assigncode WITH "Y", ;
		benftype WITH 	IIF(curAviClaim.result = "D", "NP", curAviClaim.cause_type), ;
		admit WITH DTOS(TTOD(curAviClaim.admis_date)), ;
		discharge WITH DTOS(TTOD(curAviClaim.disc_date)), ;
		charge WITH curAviClaim.scharge-curAviClaim.sdiscount, ;
		paid WITH curAviClaim.sbenfpaid, ;
		deduc WITH curAviClaim.deduc_paid, ;
		comments WITH ALLTRIM(curAviClaim.notify_no)+LEFT(curAviClaim.service_type,1)+" "+ALLTRIM(curAviClaim.snote), ;
		patientno WITH ALLTRIM(curAviClaim.illness1)+IIF(EMPTY(ALLTRIM(curAviClaim.illness2)), "", ","+ALLTRIM(curAviClaim.illness2)), ;
		invoiceno WITH curAviClaim.refno, ;
		copayment WITH curAviClaim.copayment, ;
		claimtype WITH "N", ;
		diagcode WITH curAviClaim.icd9_1, ;
		currencyc WITH curAviClaim.currency_type, ;
		clientname WITH ALLTRIM(curAviClaim.client_name), ;
		fxrate WITH curAviClaim.currency_rate, ;
		indicator WITH ALLTRIM(curAviClaim.indication_admit), ;
		provid WITH curAviClaim.prov_id, ;
		notify_no WITH curAviClaim.notify_no, ;
		result WITH curAviClaim.result, ;
		policy with curAviClaim.policy, ;
		insurename WITH curAviClaim.policy_holder  IN (lcAlias)
ENDSCAN
USE IN curAviClaim
USE IN aviHospital
***********************
SELECT (lcAlias)
GO TOP 

loExcel = CREATEOBJECT("Excel.Application")
DO CASE 
CASE tnClaimBy = 1
	lcFile = 	"Claim_Client_of_"+DTOS(tdStartDate)+"_"+DTOS(tdEndDate)
	loWorkBook = loExcel.Workbooks.ADD()
	loWorkSheet = loWorkBook.WorkSheets(1)
	WITH loWorkSheet
		.Cells(1,1).Value = "Group No"	
		.Cells(1,2).Value = "Employee PID"
		.Cells(1,3).Value = "Claimant PID"
		.Cells(1,4).Value = "Hospital Name"
		.Cells(1,5).Value = "Provider Tax ID"
		.Cells(1,6).Value = "Assigned Code"
		.Cells(1,7).Value = "Benefit Type"
		.Cells(1,8).Value = "Service From Date"
		.Cells(1,9).Value = "Service Thru Date"
		.Cells(1,10).Value = "Total Submitted charges"
		.Cells(1,11).Value = "Bank Charges"
		.Cells(1,12).Value = "Total Submitted charges (incl of Bank charge)"
		.Cells(1,13).Value = "Deductible/Non Payable/Co-Payment"
		.Cells(1,14).Value = "Total Amount Payable"
		.Cells(1,15).Value = "Comments"
		.Cells(1,16).Value = "Patient No"
		.Cells(1,17).Value = "Invoice no"
		.Cells(1,18).Value = "Claim Type"
		.Cells(1,19).Value = "MC days"
		.Cells(1,20).Value = "Diagnosis code"
		.Cells(1,21).Value = "Aviva Diagnosis Code"
		.Cells(1,22).Value = "Currency code"
		.Cells(1,23).Value = "Pateint Name"
		.Cells(1,24).Value = "(THB) Total Amount Payable"
		.Cells(1,25).Value = "FX Rate"
		.Cells(1,26).Value = "Insure Name"		
	 	.Columns("J:N").NumberFormat = "#,##0.00"
	 	.Columns("S:S").NumberFormat = "#,##0.00"
	 	.Columns("X:Y").NumberFormat = "#,##0.0000"
	ENDWITH 	
	*
	lnRows = 2
	DO WHILE !EOF()
		WITH loWorkSheet
			.Cells(lnRows,1).Value = groupno
			.Cells(lnRows,2).Value = claimantid
			.Cells(lnRows,3).Value = ""
			.Cells(lnRows,4).Value = hospname
			.Cells(lnRows,5).Value = hospid
			.Cells(lnRows,6).Value = assigncode
			.Cells(lnRows,7).Value = benftype
			.Cells(lnRows,8).Value = admit
			.Cells(lnRows,9).Value = discharge
			.Cells(lnRows,10).Value = charge
			.Cells(lnRows,11).Value = 0
			.Cells(lnRows,12).Value = "=SUM(J"+ALLTRIM(STR(lnRows))+":K"+ALLTRIM(STR(lnRows))+")"
			.Cells(lnRows,13).Value = deduc
			.Cells(lnRows,14).Value = paid
			.Cells(lnRows,15).Value = comments
			.Cells(lnRows,16).Value = patientno
			.Cells(lnRows,17).Value = invoiceno
			.Cells(lnRows,18).Value = claimtype
			.Cells(lnRows,19).Value = mcdays
			.Cells(lnRows,20).Value = ALLTRIM(indicator)
			.Cells(lnRows,21).Value = diagcode
			.Cells(lnRows,22).Value = currencyc
			.Cells(lnRows,23).Value = clientname
			.Cells(lnRows,24).Value = IIF(fxrate = 0 AND (EMPTY(currencyc) OR currencyc ="THB"), paid, CEILING(paid*fxrate))
			.Cells(lnRows,25).Value = fxrate
			.Cells(lnRows,26).Value = insurename			
		ENDWITH 	
		lnRows = lnRows+1
		SKIP 
	ENDDO 
	lcXlsFile = lcSaveTo+lcFile
	loWorkBook.SaveAS(lcXlsFile)
CASE tnClaimBy = 2
	DO WHILE !EOF()
		loWorkBook = loExcel.Workbooks.ADD()
		loWorkSheet = loWorkBook.WorkSheets(1)
		WITH loWorkSheet
			.Cells(1,1).Value = "Group No"	
			.Cells(1,2).Value = "Employee PID"
			.Cells(1,3).Value = "Claimant PID"
			.Cells(1,4).Value = "Hospital Name"
			.Cells(1,5).Value = "Provider Tax ID"
			.Cells(1,6).Value = "Assigned Code"
			.Cells(1,7).Value = "Benefit Type"
			.Cells(1,8).Value = "Service From Date"
			.Cells(1,9).Value = "Service Thru Date"
			.Cells(1,10).Value = "Total Submitted charges"
			.Cells(1,11).Value = "Bank Charges"
			.Cells(1,12).Value = "Total Submitted charges (incl of Bank charge)"
			.Cells(1,13).Value = "Deductible/Non Payable/Co-Payment"
			.Cells(1,14).Value = "Total Amount Payable"
			.Cells(1,15).Value = "Comments"
			.Cells(1,16).Value = "Patient No"
			.Cells(1,17).Value = "Invoice no"
			.Cells(1,18).Value = "Claim Type"
			.Cells(1,19).Value = "MC days"
			.Cells(1,20).Value = "Diagnosis code"
			.Cells(1,21).Value = "Aviva Diagnosis Code"
			.Cells(1,22).Value = "Currency code"
			.Cells(1,23).Value = "Pateint Name"
			.Cells(1,24).Value = "(THB) Total Amount Payable"
			.Cells(1,25).Value = "FX Rate"
			.Cells(1,26).Value = "Insure Name"			
		 	.Columns("J:N").NumberFormat = "#,##0.00"
		 	.Columns("S:S").NumberFormat = "#,##0.00"
	 		.Columns("X:Y").NumberFormat = "#,##0.0000"
		ENDWITH 	
		*
		lnRows = 2
		lcHospId = provid
		lcFile = 	"Claim_of_"+ALLTRIM(hospname)+"_of_"+DTOS(tdStartDate)+"_"+DTOS(tdEndDate)	
		DO WHILE provid = lcHospId AND !EOF()
			WITH loWorkSheet
				.Cells(lnRows,1).Value = groupno
				.Cells(lnRows,2).Value = claimantid
				.Cells(lnRows,3).Value = ""
				.Cells(lnRows,4).Value = hospname
				.Cells(lnRows,5).Value = hospid
				.Cells(lnRows,6).Value = assigncode
				.Cells(lnRows,7).Value = benftype
				.Cells(lnRows,8).Value = admit
				.Cells(lnRows,9).Value = discharge
				.Cells(lnRows,10).Value = charge
				.Cells(lnRows,11).Value = 0
				.Cells(lnRows,12).Value = "=SUM(J"+ALLTRIM(STR(lnRows))+":K"+ALLTRIM(STR(lnRows))+")"
				.Cells(lnRows,13).Value = deduc
				.Cells(lnRows,14).Value = paid
				.Cells(lnRows,15).Value = comments
				.Cells(lnRows,16).Value = patientno
				.Cells(lnRows,17).Value = invoiceno
				.Cells(lnRows,18).Value = claimtype
				.Cells(lnRows,19).Value = mcdays
				.Cells(lnRows,20).Value = ALLTRIM(indicator)
				.Cells(lnRows,21).Value = diagcode				
				.Cells(lnRows,22).Value = currencyc
				.Cells(lnRows,23).Value = clientname
				.Cells(lnRows,24).Value = CEILING(paid)
				.Cells(lnRows,25).Value = fxrate				
				.Cells(lnRows,26).Value = insurename							
			ENDWITH 	
			lnRows = lnRows+1
			SKIP 
		ENDDO 
		lcXlsFile = lcSaveTo+lcFile
		loWorkBook.SaveAS(lcXlsFile)
	ENDDO 	
ENDCASE 	
loExcel.quit


