#INCLUDE "INCLUDE\cims.h"
SET SAFE OFF
SET DELETED ON 
SET PROCEDURE TO progs\utility

PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 3
gcSaveTo = "D:\Report\Outstanding\" &&gcTemp
*
*DO FORM form\dateentry
*IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
*	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ด้วย ", MB_OK,"Outstanding Report")
*	RETURN
*ENDIF	
*
SELECT fundcode FROM cims!fund WHERE EMPTY(date_off) INTO CURSOR curFund
IF _TALLY > 0
	SELECT curFund
	DO WHILE !EOF()
		gcFundCode = curFund.fundcode
		*
		?gcFundCode
		DO GenReport
		*
		SELECT curFund
		SKIP 
	ENDDO  	
ENDIF 
*************************************
*
PROCEDURE genReport

STORE .F. TO llLogBook, llClaim
*
lcFile = ADDBS(gcSaveTo)+STR(YEAR(DATE()),4)+"-"+ALLTRIM(STRTRAN(STR(MONTH(DATE()), 2), " ", "0"))+"_"+gcFundCode+"_Outstanding as at "+ STRTRAN(DTOC(DATE()), "/", "-")
*************************************************************
WAIT WINDOW "Query Outstanding data " NOWAIT 
cFundCode = gcFundCode
************
SELECT notify_no, summit, ref_date, policy_no, client_name, plan, effective, expried, ;
	prov_name, admis_date, charge, status ;
FROM cims!notify_log ;
WHERE fundcode = gcFundCode ;
	AND EMPTY(claim_result) ;
	AND !EMPTY(notify_no) ;
ORDER BY ref_date ;
INTO CURSOR curLogBook	
IF _TALLY > 0
	llLogbook = .T.
ENDIF 
*
SELECT Claim.notify_no, Claim.notify_date, Claim.ref_date, ;
  Claim.policy_no, Claim.client_name, Claim.plan, Claim.effective, Claim.expried, Claim.service_type, ;
  Claim.prov_name, Claim.admis_date, Claim.disc_date, Claim.scharge, Claim.sbenfpaid, ;
  Claim.sremain, Claim.result, Claim.assessor_date, Claim.audit_date ;
 FROM cims!claim ;
 WHERE Claim.fundcode = gcFundCode ;
 	AND (Claim.result LIKE "W%" OR Claim.result LIKE "A%") AND claim.Result # "W5" ;
 ORDER BY 3 ;
 INTO CURSOR curClaimOut
 IF _TALLY > 0
 	llClaim = .T.
 ENDIF 	
 *
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()	
*
IF llClaim
	SELECT curClaimOut
	GO TOP 
	oSheet = oWorkBook.WorkSheets(2)
	*
	DO Genexcel
ENDIF 	
*
IF llLogBook
	SELECT curLogBook
	GO TOP 
	oSheet = oWorkBook.WorkSheets(3)
	*
	DO genexcel
ENDIF 	
*
lnRows = 3
oSheet = oWorkBook.WorkSheets(1)
oSheet.Name = "Cover"
oSheet.Cells(1, 1).Value = gcFundCode + " Outstanding Cover as at "+STRTRAN(DTOC(DATE()), "/", "-")
oSheet.Range("B:D").NumberFormat = "#,##0.00"
oSheet.Range("A:A").ColumnWidth = 30
oSheet.Range("B:D").ColumnWidth = 15
*	
IF llClaim
	SELECT result, COUNT(*) AS noc, SUM(scharge) AS charge, SUM(sbenfpaid) AS paid ;
	FROM curClaimOut ;
	GROUP BY result ;
	ORDER BY result ;
	INTO CURSOR curSumWait
	*
	IF _TALLY > 0
		oSheet.Cells(lnRows, 1).Value = "Claim"
		oSheet.Cells(lnRows+2, 1).Value = "Result"
		oSheet.Cells(lnRows+2, 2).Value = "No. of Claim"
		oSheet.Cells(lnRows+2, 3).Value = "Incurr. Amount" 
		oSheet.Cells(lnRows+2, 4).Value = "Pay Amount"
		*
		lnRows = lnRows + 3
		SELECT curSumWait
		SCAN 
			oSheet.Cells(lnRows, 1).Value = result
			oSheet.Cells(lnRows, 2).Value = noc
			oSheet.Cells(lnRows, 3).Value = charge
			oSheet.Cells(lnRows, 4).Value = paid
			lnRows = lnRows + 1
		ENDSCAN
		*
		oSheet.Cells(lnRows, 1).HorizontalAlignment = xlRight
		oSheet.Cells(lnRows, 1).Value = "Total Claim"
		oSheet.Cells(lnRows, 2).Value = "=SUM(B6:B"+ALLTRIM(STR(lnRows-1))+")"
		oSheet.Cells(lnRows, 3).Value = "=SUM(C6:C"+ALLTRIM(STR(lnRows-1))+")"
		oSheet.Cells(lnRows, 4).Value = "=SUM(D6:D"+ALLTRIM(STR(lnRows-1))+")"
		*
	ENDIF 
ENDIF 		
*
IF llLogBook
	oSheet.Cells(lnRows+1, 1).Value = "Logbook"
	oSheet.Cells(lnRows+1, 2).Value = "=COUNT('Logbook'!M:M)"
	oSheet.Cells(lnRows+1, 3).Value = "=SUM('Logbook'!M:M)"
	oSheet.Cells(lnRows+1, 4).Value = 0
ENDIF 
oSheet.Cells(lnRows+2, 1).Value = "จำนวนเคลมที่ยังไม่ออก Logbook"
oSheet.Cells(lnRows+2, 2).Value = 0
oSheet.Cells(lnRows+2, 3).Value = 0
oSheet.Cells(lnRows+2, 4).Value = 0
*
oSheet.Cells(lnRows+3, 1).RowHeight = 20	
oSheet.Cells(lnRows+3, 2).Value = "=SUM(B6:B"+ALLTRIM(STR(lnRows+2))+")"
oSheet.Cells(lnRows+3, 3).Value = "=SUM(C6:C"+ALLTRIM(STR(lnRows+2))+")"
oSheet.Cells(lnRows+3, 4).Value = "=SUM(D6:D"+ALLTRIM(STR(lnRows+2))+")"
*
oWorkBook.SaveAs(lcFile)
oExcel.Quit
********
*
PROCEDURE GenExcel

WITH oSheet
	.PageSetup.Orientation = xlLandscape
	.PageSetup.LeftMargin = 1.5
	.PageSetup.RightMargin = 1.5
	.PageSetup.TopMargin = 1.3
	.PageSetup.BottomMargin = 1.3
	.PageSetup.Zoom = 60	
	.Range("A3:R3").RowHeight = 20	
	.Range("A4:R8").RowHeight = 30
	.Range("A4:R4").HorizontalAlignment = xlCenter	
	.Range("A1:E1").MergeCells = .T.
	.Range("A1:D1").Font.Size = 14
	.Range("A1:D1").Font.Bold = .T.	
	.Range("A2:D2").MergeCells = .T.
	.Range("A2:D2").Font.Size = 14
	.Range("A2:D2").Font.Bold = .T.
	.Range("A3:D3").Font.Size = 14	
ENDWITH 	
*
oSheet.Name = ICASE(UPPER(ALIAS()) = "CURCLAIM", "Claim", "Logbook")
oSheet.Cells(1, 1).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", "Claim Outstanding as at ", "Logbook Outstanding as at ")+DTOC(DATE())
oSheet.Cells(4, 1).Value = "Notify No"
oSheet.Cells(4, 2).Value = "Notify Date"
oSheet.Cells(4, 3).Value = "Receive Date"
oSheet.Cells(4, 4).Value = "Policy No"
oSheet.Cells(4, 5).Value = "Name"
oSheet.Cells(4, 6).Value = "Plan"
oSheet.Cells(4, 7).Value = "Effective"
oSheet.Cells(4, 8).Value = "Expiry"
oSheet.Cells(4, 9).Value = "Type of Service"
oSheet.Cells(4, 10).Value = "Hospital"
oSheet.Cells(4, 11).Value = "Admit"
oSheet.Cells(4, 12).Value = "Discharge"
oSheet.Cells(4, 13).Value = "Hospital Charge"
oSheet.Cells(4, 14).Value = "Paid"
oSheet.Cells(4, 15).Value = "Client Paid"
oSheet.Cells(4, 16).Value = "Result"
oSheet.Cells(4, 17).Value = "Assess Date"
oSheet.Cells(4, 18).Value = "Audit Date"
*		
oSheet.Range("A4:R4").HorizontalAlignment = xlCenter
oSheet.Range("M:O").NumberFormat = "#,##0.00"
oSheet.Range("A:R").ColumnWidth = 20
oSheet.Range("E:E").ColumnWidth = 30
oSheet.Range("J:J").ColumnWidth = 30
***************************
lnRows = 5
*
GO TOP
DO WHILE !EOF()
	WAIT WINDOW notify_no NOWAIT
	*
	oSheet.Cells(lnRows, 1).Value = notify_no
	oSheet.Cells(lnRows, 2).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", TTOC(notify_date), DTOC(summit))
	oSheet.Cells(lnRows, 3).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", TTOC(ref_date), DTOC(ref_date))
	oSheet.Cells(lnRows, 4).Value = ALLTRIM(policy_no)
	oSheet.Cells(lnRows, 5).Value = ALLTRIM(client_name)
	oSheet.Cells(lnRows, 6).Value = ALLTRIM(plan)
	oSheet.Cells(lnRows, 7).Value = TTOC(effective)
	oSheet.Cells(lnRows, 8).Value = TTOC(expried)
	oSheet.Cells(lnRows, 9).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", service_type, "")
	oSheet.Cells(lnRows, 10).Value = ALLTRIM(prov_name)
	oSheet.Cells(lnRows, 11).Value = TTOC(admis_date)
	oSheet.Cells(lnRows, 12).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", TTOC(disc_date), "")
	oSheet.Cells(lnRows, 13).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", scharge, charge)
	oSheet.Cells(lnRows, 14).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", sbenfpaid, 0)
	oSheet.Cells(lnRows, 15).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", sremain, 0)
	oSheet.Cells(lnRows, 16).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", result	, "")
	oSheet.Cells(lnRows, 17).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", TTOC(assessor_Date), "")
	oSheet.Cells(lnRows, 18).Value = ICASE(UPPER(ALIAS()) = "CURCLAIM", TTOC(audit_date), "")
	lnRows = lnRows + 1
	SKIP 
ENDDO 	
*
oSheet.Cells(lnRows+1, 1) = "จำนวนเคลมรวม: "
oSheet.Cells(lnRows+1, 2) = "=COUNT(M5:M"+ALLTRIM(STR(lnRows-1))
oSheet.Cells(lnRows+2, 1) = "ยอดจ่ายรวมทั้งสิ้น"
oSheet.Cells(lnRows+2, 2) = "=SUM(M5:M"+ALLTRIM(STR(lnRows-1))
*
lcRange = ["A4:R]+ALLTRIM(STR(lnRows-1))+["]
oSheet.Range(&lcRange).WrapText = .T.	
oSheet.Cells.EntireColumn.AutoFit
************************************
DO SetBorder WITH  lcRange
************************************
*

 	
