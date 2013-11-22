#INCLUDE "include\excel9.h"

SET DELETED ON 

PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption

CLEAR 	
SET SAFETY OFF 	
gcTemp = "D:\"
llRun = .F.
********************	
gcFundCode = "FAL"
*******************************
lnFee = 0
gcStartDate = "From"
gcEndDate = "To"
glMonth = .T.
gdStartDate = DATE(YEAR(GOMONTH(DATE(),-1)), MONTH(GOMONTH(DATE(),-1)),1)
gdEndDate = GOMONTH(gdStartDate, 1) -1
gnOption = 1
gcSaveTo = LEFT(gcTemp,3)+"Fee\"
*
DO FORM form\dateentry
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
*************************
IF !DIRECTORY(gcSaveTo)
	MKDIR &gcSaveTo
ENDIF 	
*
*******************************
IF !USED("fund")
	USE cims!fund IN 0
ENDIF 
IF SEEK(gcFundCode, "fund", "fundcode")
	ldBeginDate = fund.date_on
	lnFee = fund.fee/100
ELSE 
	lnFee = 0.065
ENDIF 		
*****************************************
DO GenFee
*****************************************
PROCEDURE UpdateCancel

IF !USED("CancelDB")
	RETURN 
ENDIF 

SELECT * FROM CancelDB WHERE adjdate BETWEEN gdStartDate AND gdEndDate INTO CURSOR curCancel
IF _TALLY = 0
	RETURN 
ENDIF 	
SELECT curCancel
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	m.fullname = ALLTRIM(m.name)+" "+ALLTRIM(m.surname)
	lcQuoName = gcFundCode+m.quotation+m.fullname+m.plan
	IF SEEK(lcQuoName, "member", "quo_name_p")
		DO CASE 
		CASE m.types = "C"	
			REPLACE member.adjcancel WITH m.adjdate, ;
				member.canceldate WITH m.canceldate, ;
				member.cancelexp WITH member.expiry, ;
				member.expiry WITH m.exp_date, ;
				member.polstatus WITH m.types, ;
				member.status WITH "C", ;
				member.duty WITH ALLTRIM(m.reason)
		CASE m.types = "R"	
			REPLACE member.adjrefund WITH m.adjdate, ;
				member.refunddate WITH m.canceldate, ;
				member.cancelexp WITH member.expiry, ;
				member.expiry WITH m.exp_date, ;
				member.polstatus WITH m.types, ;
				member.status WITH "C", ;
				member.duty WITH ALLTRIM(m.reason)
		ENDCASE 				
	ELSE
		? quotation
	ENDIF 	
ENDSCAN 
? "Update Cancel & Refund of "+DTOC(gdEndDate) + " Finished"
*****************************************
*
PROCEDURE GenFee
*
? "Fee Report From "+DTOC(gdStartDate)+" To "+DTOC(gdEndDate) 
***********************
lcOldDir = SYS(5)+SYS(2003)
lnStartRow = 5
lcMonth = LEFT(CMONTH(gdEndDate),3)+"_"+STR(YEAR(gdEndDate),4)
lcExcelFile = ADDBS(gcSaveTo)+STR(YEAR(gdEndDate),4)+STRTRAN(STR(MONTH(gdEndDate),2), " ", "0") + "_"+gcFundCode + "_Fee_Cover_of " + lcMonth 
******************************************************
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.Workbooks.Add()
*
*DO onGoing
DO AddNew
DO Cancel_Refund

oWorkBook.SaveAs(lcExcelFile)
oExcel.Visible = .F.
oExcel.Quit
WAIT WINDOW " Create Fee Report Sucessful ......" NOWAIT 
*************************************************
PROCEDURE onGoing

WAIT WINDOW "Ongoing Member" NOWAIT 
SELECT quotation, name, surname, product As plan,  TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, IIF(canceldate > gdEndDate OR adjrefund > gdEndDate, "", polstatus) AS pol_status, adddate, polstatus ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND TTOD(effective) < gdStartDate ;
ORDER BY 5 ;	
INTO CURSOR curMemberData1	
*
SELECT quotation, name, surname, plan,  eff_date, exp_date, ;
premium, pol_status, adddate ;
FROM curMemberData1 ;
WHERE EMPTY(pol_status) ;
ORDER BY 5 ;	
INTO CURSOR curMemberData	
*************************************
oSheet = oWorkBook.WorkSheets.Add()
WITH oSheet
	.Name = "Member"
	.Cells(1, 1).Value = "On going Member"
ENDWITH 	
*
DO GenTitle
*
lnRows = lnStartRow
SELECT curMemberData
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adddate
		.Cells(lnRows, 2).Value = ALLTRIM(quotation)
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = ALLTRIM(name)
		.Cells(lnRows, 5).Value = ALLTRIM(surname)
		.Cells(lnRows, 6).Value = IIF(EMPTY(eff_date), "", eff_date) && F
		.Cells(lnRows, 7).Value = IIF(EMPTY(exp_date), "", exp_date)  && G
		.Cells(lnRows, 8).Value = premium  && H
		.Cells(lnRows, 9).Value = pol_status && I		
		.Cells(lnRows,10).Value = "=IF(A"+ALLTRIM(STR(lnRows))+" >= $F$1, F"+ALLTRIM(STR(lnRows))+", IF(F"+ALLTRIM(STR(lnRows))+" < $F$1, $F$1, F"+ALLTRIM(STR(lnRows))+"))"  && J
		.Cells(lnRows,11).Value = "=$G$1" &&"=IF(O"+ALLTRIM(STR(lnRows))+" > $G$1, $G$1, O"+ALLTRIM(STR(lnRows))+")"  && K
		.Cells(lnRows,12).Value = "=IF(F"+ALLTRIM(STR(lnRows))+" > $G$1, 0, 1)" &&"=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $G$1, O"+ALLTRIM(STR(lnRows))+" < $F$1), 0, 1)" && L
		.Cells(lnRows,13).Value = "=IF(F"+ALLTRIM(STR(lnRows))+" > $G$1, 0, K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"+1)" &&"=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $G$1, O"+ALLTRIM(STR(lnRows))+" < $F$1), 0, K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+")" && M
		.Cells(lnRows,14).Value = "=(H"+ALLTRIM(STR(lnRows))+"/365.25)*M"+ALLTRIM(STR(lnRows))
	ENDWITH 
	lnRows = lnRows + 1	
	SKIP 	
ENDDO 		
*********************************************
*Add New

PROCEDURE Addnew

WAIT WINDOW "This Month New Member" NOWAIT 
SELECT quotation, name, surname, product As plan, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
	premium, IIF(canceldate > gdEndDate OR adjrefund > gdEndDate, "", polstatus) AS pol_status, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND TTOD(effective) BETWEEN gdStartDate AND gdEndDate ;
ORDER BY 5 ;	
INTO CURSOR curAddNewData
*
	
oSheet = oWorkBook.WorkSheets(1)	
WITH oSheet
	.Name = "Add New"
	.Cells(1, 1).Value = "New Member"
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = lnStartRow
SELECT curAddNewData
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adddate
		.Cells(lnRows, 2).Value = ALLTRIM(quotation)
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = ALLTRIM(name)
		.Cells(lnRows, 5).Value = ALLTRIM(surname)
		.Cells(lnRows, 6).Value = IIF(EMPTY(eff_date), "", eff_date) && F
		.Cells(lnRows, 7).Value = IIF(EMPTY(exp_date), "", exp_date)  && G
		.Cells(lnRows, 8).Value = premium  && H
		.Cells(lnRows, 9).Value = pol_status && I
		.Cells(lnRows,10).Value = "=IF(F"+ALLTRIM(STR(lnRows))+"< $K$1, $K$1, IF(A"+ALLTRIM(STR(lnRows))+" >= $F$1, F"+ALLTRIM(STR(lnRows))+", IF(F"+ALLTRIM(STR(lnRows))+" < $F$1, $F$1, F"+ALLTRIM(STR(lnRows))+")))"  && J
		.Cells(lnRows,11).Value = "=$G$1" &&"=IF(O"+ALLTRIM(STR(lnRows))+" > $G$1, $G$1, O"+ALLTRIM(STR(lnRows))+")"  && K
		.Cells(lnRows,12).Value = 1 &&"=IF(OR(F"+ALLTRIM(STR(lnRows))+" > $G$1, G"+ALLTRIM(STR(lnRows))+" < $F$1), 0, 1)" && L
		.Cells(lnRows,13).Value = "=IF(L"+ALLTRIM(STR(lnRows))+" = 0, 0, K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"+1)" && M
		.Cells(lnRows,14).Value = "=IF(M"+ALLTRIM(STR(lnRows))+" >= 365, H"+ALLTRIM(STR(lnRows))+", (H"+ALLTRIM(STR(lnRows))+"/365.25)*M"+ALLTRIM(STR(lnRows))+")"
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
*
******************************
PROCEDURE Cancel_Refund

*Cancel
WAIT WINDOW "This Month Cancel Member" NOWAIT 
SELECT quotation, name, surname, product As plan,  TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adjcancel, canceldate, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND canceldate BETWEEN gdStartDate AND gdEndDate ;
	AND polstatus = "C" ;
ORDER BY 5 ;	
INTO CURSOR curCancelData

oSheet = oWorkBook.WorkSheets(2)
WITH oSheet
	.Name = "Cancel"
	.Cells(1, 1).Value = "Cancel Member"
	.Cells(3,15).Value = "ผอป. แจ้งยกเลิก วันที่"
	.Cells(4,15).Value = "Cancel Date"	
	.Cells(3,16).Value = "วันที่รับข้อมูล"
	.Cells(4,16).Value = "Receive Date"				
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = lnStartRow
SELECT curCancelData
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows,16).Value = adddate	
		.Cells(lnRows,17).Value = "=IF(AND(P"+ALLTRIM(STR(lnRows))+" >= $F$1, P"+ALLTRIM(STR(lnRows))+" <= $G$1), 1, 0)" 	
		.Cells(lnRows, 1).Value = adjcancel
		.Cells(lnRows, 2).Value = ALLTRIM(quotation)
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = ALLTRIM(name)
		.Cells(lnRows, 5).Value = ALLTRIM(surname)
		.Cells(lnRows, 6).Value = eff_date && F
		.Cells(lnRows, 7).Value = IIF(EMPTY(exp_date), "", exp_date)  && G
		.Cells(lnRows, 8).Value = premium  && H
		.Cells(lnRows, 9).Value = pol_status && I
		.Cells(lnRows,10).Value = "=IF(Q"+ALLTRIM(STR(lnRows))+"=1, F"+ALLTRIM(STR(lnRows))+", IF(F"+ALLTRIM(STR(lnRows))+ ;
									"< $F$1, IF(G"+ALLTRIM(STR(lnRows))+" < $F$1, G"+ALLTRIM(STR(lnRows))+", $F$1), F"+ALLTRIM(STR(lnRows))+"))" && J
		.Cells(lnRows,11).Value = "=IF(G"+ALLTRIM(STR(lnRows))+" = J"+ALLTRIM(STR(lnRows))+", $F$1-1, G"+ALLTRIM(STR(lnRows))+")" && K		
		.Cells(lnRows,12).Value = "=IF(P"+ALLTRIM(STR(lnRows))+" >= $F$1, 0, IF(A"+ALLTRIM(STR(lnRows))+" >= $F$1, 1, 0))"  && L
		.Cells(lnRows,13).Value = "=IF(L"+ALLTRIM(STR(lnRows))+" = 0, 0, IF(J"+ALLTRIM(STR(lnRows))+" < $F$1, -(K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"), K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"))" && M 
		.Cells(lnRows,14).Value = "=IF(L"+ALLTRIM(STR(lnRows))+" = 0, 0, IF(M"+ALLTRIM(STR(lnRows))+">=365, H4, (H"+ALLTRIM(STR(lnRows))+"/365.25)*M"+ALLTRIM(STR(lnRows))+"))" && N
		.Cells(lnRows,15).Value = IIF(EMPTY(canceldate), "", canceldate)
		.Cells(lnRows,16).Value = IIF(EMPTY(adddate), "", adddate)		
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
*
****************************************
*Refund
WAIT WINDOW "This Month Cancel Member" NOWAIT 
SELECT quotation, name, surname, product As plan,  TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, cancelexp, adjrefund, refunddate, adddate, adjcancel ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND refunddate BETWEEN gdStartDate AND gdEndDate ;
	AND polstatus = "R" ;
ORDER BY 5 ;	
INTO CURSOR curRefundData

oSheet = oWorkBook.WorkSheets(3)
WITH oSheet
	.Name = "Refund"
	.Cells(1, 1).Value = "Member Refund"
	.Cells(3,15).Value = "วันที่ขอคืนเบี้ย"
	.Cells(4,15).Value = "Refund Date"	
	.Cells(3,16).Value = "วันที่สิ้นสุด (Cancel)"
	.Cells(4,16).Value = "Expired Date (Cancel)"		
	.Cells(3,17).Value = "วันที่รับข้อมูล"
	.Cells(4,17).Value = "Receive Date"			
	.Cells(3,18).Value = "วันที่แจ้งยกเลิก"
	.Cells(4,18).Value = "Cancel Date"				
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = lnStartRow
SELECT curRefundData
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adjrefund
		.Cells(lnRows, 2).Value = ALLTRIM(quotation)
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = ALLTRIM(name)
		.Cells(lnRows, 5).Value = ALLTRIM(surname)
		.Cells(lnRows, 6).Value = eff_date && F
		.Cells(lnRows, 7).Value = IIF(EMPTY(exp_date), "", exp_date)  && G
		.Cells(lnRows, 8).Value = premium  && H
		.Cells(lnRows, 9).Value = pol_status && I
		.Cells(lnRows,15).Value = IIF(EMPTY(refunddate), "", refunddate)
		.Cells(lnRows,16).Value = IIF(EMPTY(cancelexp), "", cancelexp)
		.Cells(lnRows,17).Value = IIF(EMPTY(adddate), "", adddate)			
		.Cells(lnRows,18).Value = IIF(EMPTY(adjcancel), "", adjcancel)					
		****		
		.Cells(lnRows,10).Value = "=IF(AND(F"+ALLTRIM(STR(lnRows))+"< $F$1, G"+ALLTRIM(STR(lnRows))+" < $F$1), G"+ALLTRIM(STR(lnRows))+", $F$1)" && J		
		.Cells(lnRows,11).Value = "=IF(AND(F"+ALLTRIM(STR(lnRows))+"< $F$1, G"+ALLTRIM(STR(lnRows))+" > $F$1), G"+ALLTRIM(STR(lnRows))+", $F$1-1)" && K
		.Cells(lnRows,12).Value = "=IF(Q"+ALLTRIM(STR(lnRows))+" >= $F$1, 0, IF(A"+ALLTRIM(STR(lnRows))+" >= $F$1, 1, 0))"  && L
		.Cells(lnRows,13).Value = "=IF(L"+ALLTRIM(STR(lnRows))+" = 0, 0, IF(J"+ALLTRIM(STR(lnRows))+" < $F$1, -(K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"), K"+ALLTRIM(STR(lnRows))+"-J"+ALLTRIM(STR(lnRows))+"))" && M 
		.Cells(lnRows,14).Value = "=IF(L"+ALLTRIM(STR(lnRows))+" = 0, 0, IF(M"+ALLTRIM(STR(lnRows))+">=365, H4, (H"+ALLTRIM(STR(lnRows))+"/365.25)*M"+ALLTRIM(STR(lnRows))+"))" && N
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
*
****************************************
*Cover sheet
**
ldLastDate = GOMONTH(gdStartDate, -1)
oSheet = oWorkBook.WorkSheets.Add()
WITH oSheet
	.Name = "Cover"
	.Cells(1,1).Value = "Fee Cover of "+ALLTRIM(CMONTH(gdStartDate))+" "+STR(YEAR(gdStartDate),4)
	.Cells(3,2).Value = "Amount"
	.Cells(3,3).Value = "Gross Premium"
	.Cells(3,4).Value = "Earn Premium"
	.Cells(4,1).Value = "B/F From "+LEFT(CMONTH(ldLastDate), 3)+" "+ALLTRIM(STR(YEAR(ldLastDate)))
*!*		.Cells(4,2).Value = "=SUM(Member!L:L)+SUM(Refund!L:L)+SUM(Cancel!L:L)"	
*!*		.Cells(4,3).Value = '=SUM(Member!H:H)+SUMIF(Refund!L:L, "=1", Refund!H:H)+SUMIF(Cancel!L:L,"=1",Cancel!H:H)'
*!*		.Cells(4,4).Value = "=SUM(Member!N:N)"
	
	.Cells(5,1).Value = "Add New"
	.Cells(5,2).Value = "=SUM('Add New'!L:L)"
	.Cells(5,3).Value = "=SUM('Add New'!H:H)"
	.Cells(5,4).Value = "=SUM('Add New'!N:N)"
	
	.Cells(6,1).Value = "Refund"
	.Cells(6,2).Value = "=-SUM(Refund!L:L)"
	.Cells(6,3).Value = '=-SUMIF(Refund!L:L, "=1", Refund!H:H)'
	.Cells(6,4).Value = "=SUM(Refund!N:N)"
	
	.Cells(7,1).Value = "Cancel"
	.Cells(7,2).Value = "=-SUM(Cancel!L:L)"
	.Cells(7,3).Value = '=-SUMIF(Cancel!L:L,"=1",Cancel!H:H)'
	.Cells(7,4).Value = "=SUM(Cancel!N:N)"
	.Range("B7:D7").Borders(xlEdgeBottom).LineStyle = xlContinuous	
	
	.Cells(8,2).Value = "=SUM(B4:B7)"	
	.Cells(8,3).Value = "=SUM(C4:C7)"	
	.Cells(8,4).Value = "=SUM(D4:D7)"	
	.Range("B8:C8").Borders(xlEdgeBottom).LineStyle = xlDouble
	
	.Cells(9,1).Value = "Fee Rate"
	.Cells(9,4).Value = IIF(lnFee = 0, .07, lnFee)
	.Range("D9:D9").Borders(xlEdgeBottom).LineStyle = xlContinuous
	.Cells(10,1).Value = "Total Fee"
	.Cells(10,4).Value = "=D8*D9"
	.Range("D10:D10").Borders(xlEdgeBottom).LineStyle = xlDouble
	.Columns("A:A").ColumnWidth = 20	
	.Columns("B:D").ColumnWidth = 15
	.Columns("B:B").NumberFormat = '#,##0;[Red]-#,##0;"-"'	
	.Columns("C:D").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'
	.Cells(9,4).NumberFormat = "0.00%"
	.Rows("3:3").HorizontalAlignment = xlCenter
	.Rows("3:3").VerticalAlignment = xlBottom
	.Cells.RowHeight = 20	
ENDWITH 	
oWorkBook.SaveAs(lcExcelFile)
oExcel.Quit
WAIT WINDOW " Create Fee Report Sucessful ......" NOWAIT 
************************************************

*Expired
PROCEDURE GenExpiredSheet

ldOldStart = GOMONTH(gdStartDate, -1)
ldOldEnd = GOMONTH(ldOldStart, 1) - 1

WAIT WINDOW "This Month Cancel Member" NOWAIT 
SELECT policy_no, name, surname, product As plan, TTOD(effective) As eff_date, TTOD(expiry) AS exp_date, ;
premium, polstatus AS pol_status, adddate ;
FROM cims!member ;
WHERE tpacode = gcFundCode ;
	AND GOMONTH(effective, 12) BETWEEN ldOldStart AND ldOldEnd ;
	AND EMPTY(polstatus) ;
ORDER BY 5 ;	
INTO CURSOR curExpiredData

oSheet = oWorkBook.WorkSheets(4)
WITH oSheet
	.Name = "Expired"
	.Cells(1, 1).Value = "Expired Member"
	.Cells(1, 6).Value = ldOldStart
	.Cells(1, 7).Value = ldOldEnd
ENDWITH 	
***********
DO GenTitle	
***********
lnRows = lnStartRow
SELECT curExpiredData
DO WHILE !EOF()
	WITH oSheet
		.Cells(lnRows, 1).Value = adddate
		.Cells(lnRows, 2).Value = ALLTRIM(policy_no)
		.Cells(lnRows, 3).Value = plan
		.Cells(lnRows, 4).Value = ALLTRIM(name)
		.Cells(lnRows, 5).Value = ALLTRIM(surname)
		.Cells(lnRows, 6).Value = eff_date && F
		.Cells(lnRows, 7).Value = IIF(EMPTY(exp_date), "", exp_date)  && G
		.Cells(lnRows, 8).Value = GetPremium(plan, premium)  && H
		.Cells(lnRows, 9).Value = pol_status && I
		.Cells(lnRows,10).Value = "=F"+ALLTRIM(STR(lnRows))  && J
		.Cells(lnRows,11).Value = "=$F$1-1"  && K
		.Cells(lnRows,12).Value = "=IF(AND(A"+ALLTRIM(STR(lnRows))+" >= $F$1, A"+ALLTRIM(STR(lnRows))+" <= $G$1), 0, 1)" && L
		.Cells(lnRows,13).Value = 0
		.Cells(lnRows,14).Value = 0
	ENDWITH 
	lnRows = lnRows + 1
	SKIP 	
ENDDO
*
PROCEDURE Gentitle

WITH oSheet
	.Cells(1, 5).Value = "From"
	.Cells(1, 6).Value = gdStartDate
	.Cells(1, 7).Value = gdEndDate
	.Cells(1,11).Value = ldBeginDate
	.Cells(3, 1).Value = "วันที่รับ"
	.Cells(3, 2).Value = "เลขที่กรมธรรม์"
	.Cells(3, 3).Value = "แผน"
	.Cells(3, 4).Value = "ชื่อผู้เอาประกัน"
	.Cells(3, 5).Value = "นามสกุล"
	.Cells(3, 6).Value = "วันเริ่มคุ้มครอง"
	.Cells(3, 7).Value = "วันสิ้นสุด"
	.Cells(3, 8).Value = "เบี้ย/ต่อปี"
	.Cells(3, 9).Value = "สถานะ"
	.Cells(3,10).Value = "เริ่มคิดจาก วันที่"
	.Cells(3,11).Value = "คิดจนถึง วันที่"
	.Cells(3,12).Value = "จำนวน"	
	.Cells(3,13).Value = "จำนวนวันที่คิดได้"
	.Cells(3,14).Value = "เบี้ยรับ/ต่อเดือน"	
	
	.Cells(4, 1).Value = "Trans Date"
	.Cells(4, 2).Value = "Quotation No"
	.Cells(4, 3).Value = "Plan"
	.Cells(4, 4).Value = "Name"
	.Cells(4, 5).Value = "Surname"
	.Cells(4, 6).Value = "Eff Date"
	.Cells(4, 7).Value = "Exp Date"
	.Cells(4, 8).Value = "Premium"
	.Cells(4, 9).Value = "Pol Status"
	.Cells(4,10).Value = "Start Date"
	.Cells(4,11).Value = "End Date"
	.Cells(4,12).Value = "Counts"	
	.Cells(4,13).Value = "Days"
	.Cells(4,14).Value = "Earn Premium"
	.Columns("A:A").ColumnWidth = 10
	.Columns("B:C").ColumnWidth = 20
	.Columns("D:E").ColumnWidth = 30	
	.Columns("F:P").ColumnWidth = 12
	.Columns("M:N").ColumnWidth = 12
	.Range("F:G").NumberFormat = 'd/m/yyyy'	
	.Range("J:K").NumberFormat = 'd/m/yyyy'		
	.Range("H:H").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'
	.Range("L:M").NumberFormat = '#,##0;[Red]-#,##0;"-"'
	.Range("N:N").NumberFormat = '#,##0.00;[Red]-#,##0.00;"-"'		
	.Cells(1, 5).HorizontalAlignment = xlRight	
	.Rows("3:3").HorizontalAlignment = xlCenter
	.Rows("3:3").VerticalAlignment = xlBottom	
	.Cells.RowHeight = 20	
ENDWITH 	
	
	








