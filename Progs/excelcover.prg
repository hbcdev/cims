#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 3
gcSaveTo = ADDBS(gcTemp)
gcResult = ""

DO FORM form\dialyReportOption
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF	
SET SAFE OFF
************************************
*Query Claim
SELECT notify_no, claim_date, policy_no, client_name, plan, ;
  prov_name, acc_date, admis_date, disc_date, result AS clm_status, ;
  Claim.claim_with,  scharge, sdiscount, snopaid, sbenfpaid+over_respond AS sbenfpaid, sremain, abenfpaid AS exgratia, indication_admit, diag_plan, note2ins, snote, result  ;
FROM  cims!claim ;
WHERE Claim.fundcode = gcfundcode ;
   AND Claim.result = gcResult ;
   AND Claim.return_date BETWEEN gdstartdate AND gdEnddate ;
ORDER BY 10, 9, 2, 1 ;  
INTO CURSOR curCover

SELECT curCover
COPY TO oli_pa 
************************************ 
IF _TALLY > 0
	lnSheet = 0
	oExcel = CREATEOBJECT("Excel.Application")
	SELECT curCover	
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
		DO WHILE claim_with = lcType AND !EOF()
			WAIT WINDOW lcTypeMess+TRANSFORM(RECNO(),"@Z 9,999") NOWAIT 
			DO CASE 
			CASE clm_status = "D" 
				oSheet.Cells(lnRow, 1) = "สรุปเอกสารปฏิเสธการจ่ายค่าสินไหมส่งคืน"
			CASE clm_status = "P" 
				oSheet.Cells(lnRow, 1) = "สรุปการทำจ่ายผู้เอาประกัน"
			CASE clm_status = "I"
				oSheet.Cells(lnRow, 1) = "สรุปการทำจ่ายโรงพยาบาล"
			ENDCASE
			*************************************
			lnRow = lnRow + 1
			oSheet.Cells(lnRow,1) = "Notify No"
			oSheet.Cells(lnRow,2) = "กรมธรรม์"
			oSheet.Cells(lnRow,3) = "ชื่อ"
			oSheet.Cells(lnRow,4) = "แผน"
			oSheet.Cells(lnRow,5) = "โรงพยาบาล"
			oSheet.Cells(lnRow,6) = "Acc Date"			
			oSheet.Cells(lnRow,7) = "Admit"
			oSheet.Cells(lnRow,8) = "Discharged"
			IF clm_status # "D"
				oSheet.Cells(lnRow,9) = "เรียกเก็บ"
				oSheet.Cells(lnRow,10) = "ส่วนลด"
				oSheet.Cells(lnRow,11) = "ไม่คุ้มครอง"
				oSheet.Cells(lnRow,12) = "Exgratia"
				oSheet.Cells(lnRow,13) = "จ่าย"
				oSheet.Cells(lnRow,14) = "หมายเหตุ"
				oSheet.Cells(lnRow,15) = "สถานะ"	
			ELSE 
				oSheet.Cells(lnRow,9) = "หมายเหตุ"
				oSheet.Cells(lnRow,10) = "สถานะุ"						
			ENDIF 
			*************************************************
			lnRow = lnRow + 1
			lcStatus = clm_status
			DO WHILE claim_with = lcType AND clm_status = lcStatus AND !EOF()
				lcPol = policy_no
				lnPaid = 0
				lnCount = 0
				DO WHILE claim_with = lcType AND clm_status = lcStatus AND policy_no = lcPol AND !EOF()			
					oSheet.Cells(lnRow,1) = notify_no
					oSheet.Cells(lnRow,2) = ALLTRIM(policy_no)
					oSheet.Cells(lnRow,3) = ALLTRIM(client_name)
					oSheet.Cells(lnRow,4) = plan
					oSheet.Cells(lnRow,5) = ALLTRIM(prov_name)
					oSheet.Cells(lnRow,6) = IIF(EMPTY(acc_date), "", acc_date)				
					oSheet.Cells(lnRow,7) = admis_date
					oSheet.Cells(lnRow,8) = disc_date
					IF clm_status # "D"
						oSheet.Cells(lnRow,9) = scharge
						oSheet.Cells(lnRow,10) = sdiscount
						oSheet.Cells(lnRow,11) = snopaid
						oSheet.Cells(lnRow,12) = exgratia
						oSheet.Cells(lnRow,13) = sbenfpaid
						oSheet.Cells(lnRow,14) = ALLTRIM(note2ins)+" "+ALLTRIM(snote)
						oSheet.Cells(lnRow,15) = result
					ELSE 
						oSheet.Cells(lnRow,9) = ALLTRIM(note2ins)+" "+ALLTRIM(snote)
						oSheet.Cells(lnRow,10) = result				
					ENDIF 
					lnCount = lnCount + 1
					lnPaid = lnPaid + sbenfpaid
					lnRow = lnRow + 1
					SKIP
				ENDDO 
				oSheet.Cells(lnRow,5) = "รวม"
				oSheet.Cells(lnRow,13) = lnPaid
				lnRow = lnRow +1		
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

