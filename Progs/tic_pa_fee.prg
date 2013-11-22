CLEAR 
PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption

#INCLUDE "include\excel9.h"	
SET SAFETY OFF 	
SET PROCEDURE TO progs\utility
*******************************
WAIT WINDOW "กรุณารอสักครู่"
DO Mark_followup
*******************************
gcCaption = "TIC PA Fee"
gnAll = 1
gnCover = 1
gnData = 0
gnType = 1
gcStartDate = "Start Date"
gcEndDate = "End Date"
glMonth = .T.	
gcFundCode = "TIC"
gdStartDate = GOMONTH(DATE(),-1)
gdStartDate = DATE(YEAR(DATE()), MONTH(DATE()), 1)
gdEndDate = GOMONTH(gdStartDate, 1)-1
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
DO FORM form\Rollingentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF

SELECT notify_no, followup, app_no, policy_no, client_name, plan, effective, expried, service_type, ;
TTOD(acc_date) AS acc_date, prov_name, admis_date, disc_date, scharge, sbenfpaid, return_date, result ;
FROM cims!claim ;
ORDER BY policy_no, app_no, notify_no, result ;
WHERE fundcode = gcFundCode ;
	AND claim_with = "P" ;
	AND return_date between gdStartDate AND gdEndDate ;
INTO CURSOR curFee

SELECT curFee
COPY TO tic_fee 
IF _TALLY <= 0
	RETURN 
ENDIF 

oExcel = CREATEOBJECT("Excel.Application")
oBook = oExcel.workBooks.Add()
oSheet = oBook.Worksheets(1)
oSheet.name = "Claim"
WITH oSheet
	.Columns("A:B").ColumnWidth = 15
	.Columns("C:D").ColumnWidth = 30
	.Columns("E:I").ColumnWidth = 15
	.Columns("J:J").ColumnWidth = 30
	.Columns("K:L").ColumnWidth = 15
	.Columns("M:P").ColumnWidth = 12
	.Columns("Q:Q").ColumnWidth = 2
	.Columns("R:X").ColumnWidth = 12
	.Range("M:N").NumberFormat = '#,##0.00;[Red](#,##0.00);""'
	.Range("R:X").NumberFormat = '#,##0.00;[Red](#,##0.00);""'	
	.Range("S4:S4").NumberFormat = "0%"
	.PageSetup.Orientation = xlLandscape
	.PageSetup.Zoom = 70
ENDWITH 
*
lnRow = 4
WITH oSheet
	.Cells(1,1).Value = "TIC Claim Of "+CMONTH(gdStartDate)+" "+STR(YEAR(gdStartDate),4)
	.Rows("4:4").RowHeight = 30
	.Rows("4:4").HorizontalAlignment = xlCenter
	.Rows("4:4").VerticalAlignment = xlCenter
	.Rows("4:4").WrapText = .T.
	.Cells(lnRow,1).Value = "Follow Up(Refer to notify no)"	
	.Cells(lnRow,2).Value = "Notify No"          
	.Cells(lnRow,3).Value = "Policy No"
	.Cells(lnRow,4).Value = "Name"
	.Cells(lnRow,5).Value = "Plan"
	.Cells(lnRow,6).Value = "Effective"	
	.Cells(lnRow,7).Value = "Expried"
	.Cells(lnRow,8).Value = "Service Type"
	.Cells(lnRow,9).Value = "Accident Date"
	.Cells(lnRow,10).Value = "Hospital"
	.Cells(lnRow,11).Value = "Admit"
	.Cells(lnRow,12).Value = "Discharge"
	.Cells(lnRow,13).Value = "Charge"
	.Cells(lnRow,14).Value = "Benefit Paid"    && N
	.Cells(lnRow,15).Value = "Status"
	.Cells(lnRow,16).Value = "Return Date"
	.Cells(lnRow,18).Value = "Up to date Claim paid" && Q
	.Cells(lnRow,19).Value = "Fee rate 7%"     && R
	.Cells(lnRow,20).Value = "Last time fee"
	.Cells(lnRow,21).Value = "Already Billed"
	.Cells(lnRow,22).Value = "This time billing"
	.Cells(lnRow,23).Value = "Up to date Claim Denied" 
	.Cells(lnRow,24).Value = "Last Time Claim Denied"
ENDWITH 
*
lnRow = 5
SELECT curFee
GO TOP 
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z99,999") NOWAIT 
	IF EMPTY(app_no)
		* มีเคลมเดียว	
		=GetRowResult(.F.)
		SKIP 
	ELSE 	
		lnFollowRow = lnRow - 1	
		ldAccDate = curFee.acc_date
		lcPolicyNo = curFee.policy_no
		lcNotifyNo = IIF(EMPTY(app_no), notify_no, app_no)
		**********************************	
		* รวมยอดจ่ายของ Acc date ทั้งหมด ก่อนเดือนที่่รัน	
		SELECT app_no, SUM(sbenfpaid) AS paid, SUM(IIF(LEFT(result, 1) = "D", scharge, 0)) AS denied ;
		FROM cims!claim ;
		WHERE fundcode = gcFundCode ;
			AND claim.policy_no = lcPolicyNo ;
			AND claim.app_no = lcNotifyNo ;
			AND claim.return_date <= gdEndDate ;					
		GROUP BY app_no ;	
		INTO  CURSOR curAllAcc
		*************************	
		*รวมยอดจ่ายที่จ่ายก่อนเดือนนี้ 
		SELECT app_no, SUM(sbenfpaid) AS paid, SUM(IIF(LEFT(result, 1) = "D", scharge, 0)) AS denied ;
		FROM cims!claim ;
		WHERE claim.fundcode = gcFundCode ;
			AND claim.policy_no = lcPolicyNo ;		
			AND claim.app_no = lcNotifyNo ;
			AND claim.return_date  < gdStartDate ;			
		GROUP BY app_no ;	
		INTO CURSOR curLast
		*
		SELECT curFee
		=GetRowResult(.F.)
		lnMrow = lnRow
		*
		oSheet.Cells(lnRow,18).Value = curAllAcc.paid
		oSheet.Cells(lnRow,19).Value = "=R"+ALLTRIM(STR(lnRow))+"*7%"		
		oSheet.Cells(lnRow,20).Value = "="+STR(curLast.paid,6,2)+"*7%"
		oSheet.Cells(lnRow,21).Value = "=IF(T"+ALLTRIM(STR(lnRow))+"> 0, IF(T"+ALLTRIM(STR(lnRow))+"<=300, 300, IF(T"+ALLTRIM(STR(lnRow))+">=10000, 10000,T"+ALLTRIM(STR(lnRow))+")), 0)"
		IF curAllAcc.paid = 0 
			oSheet.Cells(lnRow,22).Value = "=IF(M"+ALLTRIM(STR(lnRow))+"<=10000, 700, 1000)"	
		ELSE 
			oSheet.Cells(lnRow,22).Value = "=IF(S"+ALLTRIM(STR(lnRow))+"<=300, 300, IF(S"+ALLTRIM(STR(lnRow))+">=10000, 10000,S"+ALLTRIM(STR(lnRow))+"))-U"+ALLTRIM(STR(lnRow))
		ENDIF 	
		oSheet.Cells(lnRow,23).Value = curAllAcc.denied
		oSheet.Cells(lnRow,24).Value = curLast.denied		
		DO WHILE policy_no = lcPolicyNo AND app_no = lcNotifyNo AND !EOF()
			=GetRowResult(.T.)		
			lnRow = lnRow + 1				
			SKIP 
		ENDDO 
		lnRow = lnRow - 1
		lcColExp = ["R] + ALLTRIM(STR(lnMrow)) + [:R] + ALLTRIM(STR(lnRow)) + ["]	
		oSheet.Range(&lcColExp).MergeCells = .T.	
		lcColExp = ["S] + ALLTRIM(STR(lnMrow)) + [:S] + ALLTRIM(STR(lnRow)) + ["]		
		oSheet.Range(&lcColExp).MergeCells = .T.	
		lcColExp = ["T] + ALLTRIM(STR(lnMrow)) + [:T] + ALLTRIM(STR(lnRow)) + ["]		
		oSheet.Range(&lcColExp).MergeCells = .T.	
		lcColExp = ["U] + ALLTRIM(STR(lnMrow)) + [:U] + ALLTRIM(STR(lnRow)) + ["]		
		oSheet.Range(&lcColExp).MergeCells = .T.	
		lcColExp = ["V] + ALLTRIM(STR(lnMrow)) + [:V] + ALLTRIM(STR(lnRow)) + ["]		
		oSheet.Range(&lcColExp).MergeCells = .T.	
	ENDIF 	
	lnRow = lnRow + 1
ENDDO 
oSheet.Cells(lnRow,22).Value = '=SUM(V5:V'+ALLTRIM(STR(lnRow-1))+")"
lcExcelCover = ADDBS(gcSaveTo)+ALLTRIM(STR(YEAR(gdStartDate)))+"-"+STRTRAN(STR(MONTH(gdStartDate),2), " ", "0")+" "+gcFundCode+"_PA_Fee_Cover_"+ALLTRIM(CMONTH(gdStartDate))+"_"+ALLTRIM(STR(YEAR(gdStartDate)))
oBook.SaveAs(lcExcelCover)
oExcel.Quit
*********************************************		
FUNCTION GetRowresult(llNoSum)

WITH oSheet
	.Cells(lnRow,1).Value = followup
	.Cells(lnRow,2).Value = notify_no
	.Cells(lnRow,3).Value = policy_no
	.Cells(lnRow,4).Value = ALLTRIM(client_name)
	.Cells(lnRow,5).Value = plan
	.Cells(lnRow,6).Value = effective	
	.Cells(lnRow,7).Value = expried
	.Cells(lnRow,8).Value = service_type
	.Cells(lnRow,9).Value = IIF(EMPTY(acc_date), "", acc_date)
	.Cells(lnRow,10).Value = ALLTRIM(prov_name)
	.Cells(lnRow,11).Value = admis_date
	.Cells(lnRow,12).Value = disc_date
	.Cells(lnRow,13).Value = scharge
	.Cells(lnRow,14).Value = sbenfpaid
	.Cells(lnRow,15).Value = result
	.Cells(lnRow,16).Value = return_date
ENDWITH 
IF !llNoSum
	oSheet.Cells(lnRow,18).Value = "=N"+ALLTRIM(STR(lnRow))	
	oSheet.Cells(lnRow,19).Value = "=R"+ALLTRIM(STR(lnRow))+"*7%"
	DO CASE 
	CASE LEFT(result,1) = "P"	
		oSheet.Cells(lnRow,22).Value = "=IF(S"+ALLTRIM(STR(lnRow))+"<=300, 300, IF(S"+ALLTRIM(STR(lnRow))+">=10000, 10000,S"+ALLTRIM(STR(lnRow))+"))"
	CASE LEFT(result,1) = "D"	
		oSheet.Cells(lnRow,22).Value = "=IF(M"+ALLTRIM(STR(lnRow))+"<=10000, 700, 1000)"	
	OTHERWISE 
		oSheet.Cells(lnRow,22).Value = 0
	ENDCASE 		
ENDIF
*********************************************
PROCEDURE Mark_Followup

SELECT DISTINCT followup ;
FROM cims!claim ;
WHERE fundcode = gcFundCode AND claim_with = "P" AND !EMPTY(followup) ;
INTO CURSOR curFWD
SELECT curFWD
SCAN 
	IF SEEK(followup, "claim","notify_no")
		REPLACE claim.app_no WITH followup
	ENDIF 	
ENDSCAN 	
USE IN curFWD
*******************************
SELECT claim
REPLACE ALL claim.app_no WITH followup FOR fundcode = gcFundCode AND !EMPTY(followup)
*******************************
