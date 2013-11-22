#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 3
gcSaveTo = ADDBS(gcTemp)

DO FORM form\dateentry1

IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF	
SET SAFE OFF
*
*Query Claim
SELECT notify_no, policy_no, family_no, client_name, plan, ;
  prov_name, acc_date, admis_date, disc_date, IIF(result = "P5", "I", LEFT(result,1)) AS clm_status, ;
  IIF(Claim.fundcode = "OLI" AND RIGHT(ALLTRIM(Claim.plan),1) = "S", "S", Claim.claim_with) AS claim_with, ; 
  scharge, sdiscount, snopaid, sbenfpaid, sremain, IIF(EMPTY(fax_by), abenfpaid, exgratia) AS exgratia, ;
  note2ins, snote, result, indication_admit ;
FROM  cims!claim ;
WHERE Claim.fundcode = gcfundcode ;
   AND INLIST(LEFT(Claim.result,1), "D", "P") ;	
   AND Claim.return_date BETWEEN gdstartdate AND gdEnddate ;
ORDER BY claim_with, policy_no, family_no, acc_date ;  
INTO CURSOR curCover
SELECT curCover
IF _TALLY > 0
	CREATE CURSOR curPol2Xls (policy_no c(30), client_name C(120), plan C(20), ;
		hosp_name M, acc_date T, admit C(120), discharge C(120), ;
		cust_type C(1), charge Y, discount Y, nopaid Y, paid Y, over Y, exgratia Y, indi_admit M, notes M, ;
		total_claim I, p1 I, p5 I, d I, w I, claim_with C(1), notify M) 		
		*
	SELECT curCover
	GO TOP 
	DO WHILE !EOF()
		SCATTER FIELDS policy_no, family_no, client_name, plan, claim_with, acc_date MEMVAR 
		*
		STORE "" TO m.admit, m.discharge, m.indi_admit, m.notes, m.hosp_name, m.notify
		STORE 0 TO m.charge, m.discount, m.nopaid, m.paid, m.over, m.exgratia, m.total_claim, m.p1, m.p5, m.d, m.w
		DO WHILE m.claim_with = claim_with AND m.policy_no = policy_no AND m.family_no = family_no AND m.acc_date = acc_date AND !EOF()
			m.hosp_name = m.hosp_name + ALLTRIM(prov_name) + ", "
			m.admit = m.admit + TTOC(admis_date)+", "
			m.discharge = m.discharge + TTOC(disc_date)+", "
			m.indi_admit = m.indi_admit + ALLTRIM(indication_admit)+", "
			m.notify = m.notify+notify_no+", "
			m.notes = m.notes + ALLTRIM(note2ins)+" "+ALLTRIM(snote)
			m.charge = m.charge + scharge
			m.discount = m.discount + sdiscount
			m.nopaid = m.nopaid + snopaid
			m.paid = m.paid + sbenfpaid
			m.over = m.over + sremain
			m.exgratia = m.exgratia + exgratia
			m.total_claim = m.total_claim+1
			m.p1 = m.p1 + IIF(result # "P5", 1, 0)
			m.p5 = m.p5 + IIF(result = "P5", 1, 0)
			m.d = m.d + IIF(result = "D", 1, 0)
			m.w = m.w + IIF(result = "W", 1, 0)
			SKIP 
		ENDDO 
		INSERT INTO curPol2xls FROM MEMVAR 
	ENDDO 
ENDIF 			
SELECT curPol2Xls

IF RECCOUNT() > 0
	lnSheet = 0
	oExcel = CREATEOBJECT("Excel.Application")
	SELECT curPol2xls
	GO TOP
	DO WHILE !EOF()
		oWorkBook = oExcel.Workbooks.Add()
		lcType = claim_with
		lnRow = 1
		oSheet = oWorkBook.WorkSheets.Add
		oSheet.Name = "Cover sheet"
		***********************
		DO CASE 
		CASE lcType = "P"
			lcTypeMess = "PA"
		CASE lcType = "T"
			lcTypeMess = "Group"
		CASE lcType = "I"
			lcTypeMess = "HC"
		CASE lcType = "S"
			lcTypeMess = "PAS"			
		ENDCASE 	
		***********************
		lcExcelFile = ADDBS(gcSaveTo)+lcTypeMess+"_Dialy_Cover_"+STRTRAN(DTOC(gdStartDate), "/", "")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
		WAIT WINDOW lcTypeMess+TRANSFORM(RECNO(),"@Z 9,999") NOWAIT 
		oSheet.Cells(lnRow,1) = "กรมธรรม์"
		oSheet.Cells(lnRow,2) = "ชื่อ"
		oSheet.Cells(lnRow,3) = "แผน"
		oSheet.Cells(lnRow,4) = "โรงพยาบาล"
		oSheet.Cells(lnRow,5) = "Acc Date"			
		oSheet.Cells(lnRow,6) = "Admit"
		oSheet.Cells(lnRow,7) = "Discharged"
		oSheet.Cells(lnRow,8) = "เรียกเก็บ"
		oSheet.Cells(lnRow,9) = "ส่วนลด"
		oSheet.Cells(lnRow,10) = "ไม่คุ้มครอง"
		oSheet.Cells(lnRow,11) = "Exgratia"
		oSheet.Cells(lnRow,12) = "จ่าย"
		oSheet.Cells(lnRow,13) = "สาเหตุการรักษา"
		oSheet.Cells(lnRow,14) = "หมายเหตุ"	
		oSheet.Cells(lnRow,15) = "จำนวนเคลมรวม"
		oSheet.Cells(lnRow,16) = "จ่ายผู้เอาประกัน"
		oSheet.Cells(lnRow,17) = "จ่ายโรงพยาบาล"
		oSheet.Cells(lnRow,18) = "ปฏิเสธการจ่าย"
		oSheet.Cells(lnRow,19) = "รอข้อมูล"		
		*************************************************
		lnRow = lnRow + 1		
		DO WHILE claim_with = lcType AND !EOF()
			DO WHILE claim_with = lcType AND !EOF()
				oSheet.Cells(lnRow,1) = ALLTRIM(policy_no)
				oSheet.Cells(lnRow,2) = ALLTRIM(client_name)
				oSheet.Cells(lnRow,3) = plan
				oSheet.Cells(lnRow,4) = ALLTRIM(hosp_name)
				oSheet.Cells(lnRow,5) = IIF(EMPTY(acc_date), "", acc_date)				
				oSheet.Cells(lnRow,6) = admit
				oSheet.Cells(lnRow,7) = discharge
				oSheet.Cells(lnRow,8) = charge
				oSheet.Cells(lnRow,9) = discount
				oSheet.Cells(lnRow,10) = nopaid
				oSheet.Cells(lnRow,11) = exgratia
				oSheet.Cells(lnRow,12) = paid
				oSheet.Cells(lnRow,13) = indi_admit
				oSheet.Cells(lnRow,14) = notes
				oSheet.Cells(lnRow,15) = total_claim
				oSheet.Cells(lnRow,16) = p1
				oSheet.Cells(lnRow,17) = p5
				oSheet.Cells(lnRow,18) = d
				oSheet.Cells(lnRow,19) = w
				lnRow = lnRow + 1
				SKIP
			ENDDO 
			oSheet.Cells(lnRow,1).Select
			oSheet.HPageBreaks.Add(oExcel.ActiveCell)
			lnRow = lnRow + 1
		ENDDO 
		gcSaveTo = ALLTRIM(gcSaveTo)
		IF !DIRECTORY(gcSaveTo)
			MD &gcSaveTo
		ENDIF 	
		oWorkBook.SaveAs(lcExcelFile)
	ENDDO 	
	oExcel.Quit
ENDIF 	
COPY TO (gcSaveTo+"Cover")
USE IN curCover
USE IN curPol2xls 
=MESSAGEBOX("Generate Report sucess", 0, "Cover sheet")
*****************************************************
PROCEDURE SetFormat
lnFields = AFIELDS(laFields)
FOR iField1 = 1 TO lnFields
	oSheet.Cells(1,iField1) = FIELD(iField1)
	*********************
	lcColumn    = ColumnLetter(iField1)
	lcColumnExpression = ["] + lcColumn + [:] + lcColumn + ["]                                     
	oSheet.Columns(&lcColumnExpression.).Select                             
	*********************************************                                                                              
	DO CASE                                                                      
	CASE (laFields[iField1,2] $ "C.L")
		lcFmtExp = ["@"]
		lnWidth = laFields[iField1,3]
		lnWidth = IIF(lnWidth > 100, 100, lnWidth)
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "M")
		lcFmtExp = [""]
		lnWidth = 100
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = lnWidth
	CASE (laFields[iField1,2] $ "N.I.Y")		
           	IF laFields[iField1,4] = 0
			lcFmtExp = ["0"]
		ELSE
			lcFmtExp = ["0.] + REPLICATE("0", laFields[iField1,4]) + ["]
      	ENDIF
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 16
	CASE (laFields[iField1,2] $ "D.T")  
     		lcFmtExp = ["dd/mm/yyyy"]          
		oSheet.Columns(&lcColumnExpression.).ColumnWidth = 10
	ENDCASE
	IF lcFmtExp # [""]
		oSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.
	ENDIF 	
ENDFOR
*!****************************************************************************!*
*!* Beginning of PROCEDURE ColumnLetter                                      *!*
*!* This procedure derives a letter reference based on a numeric value.  It  *!*
*!* uses the basis of the ASCII Value of the upper case letters A to Z (65   *!*
*!* through 90) to return the proper letter (or letter combination) for a    *!*
*!* provided numeric value.                                                  *!*
*!****************************************************************************!*
                                                                                
PROCEDURE ColumnLetter                                                          
   PARAMETER lnColumnNumber                                                     
      lnFirstValue = INT(lnColumnNumber/27)                                     
      lcFirstLetter = IIF(lnFirstValue=0,"",CHR(64+lnFirstValue))               
      lnMod =  MOD(lnColumnNumber,26)                           
      lcSecondLetter = CHR(64+IIF(lnMod=0, 26, lnMod))
                                                                                
RETURN lcFirstLetter + lcSecondLetter
******************************************************************
PROCEDURE SetLine

osheet.Cells.Borders(7).LineStyle = 1
osheet.Cells.Borders(7).Weight = 2
osheet.Cells.Borders(7).ColorIndex = -4105
osheet.Cells.Borders(8).LineStyle = 1
osheet.Cells.Borders(8).Weight = 2
osheet.Cells.Borders(8).ColorIndex = -4105
osheet.Cells.Borders(9).LineStyle = 1
osheet.Cells.Borders(9).Weight = 2
osheet.Cells.Borders(9).ColorIndex = -4105
osheet.Cells.Borders(10).LineStyle = 1
osheet.Cells.Borders(10).Weight = 2
osheet.Cells.Borders(10).ColorIndex = -4105
osheet.Cells.Borders(11).LineStyle = 1
osheet.Cells.Borders(11).Weight = 2
osheet.Cells.Borders(11).ColorIndex = -4105
osheet.Cells.Borders(12).LineStyle = 1
osheet.Cells.Borders(12).Weight = 2
osheet.Cells.Borders(12).ColorIndex = -4105
oSheet.Cells.Select
oSheet.Cells.EntireColumn.AutoFit
oSheet.Range("A1").Select



