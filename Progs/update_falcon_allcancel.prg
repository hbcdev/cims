CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
IF EMPTY(lcDataFile) AND !USED("eff") AND !USED("exp")
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")


IF FILE(lcDbf)
	IF MESSAGEBOX(lcDbf + "has exist you want convert new file",4+32+256, "Confirm ") = -6
		DO ConvertData
	ELSE 
		SELECT 0
		USE (lcDbf)	
		USE cims!member IN 0
	ENDIF 	 
ELSE 
	DO Convert Data
ENDIF 		
*
DO UpdateData
*
************************************	
PROCEDURE ConvertData

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (quotation C(50), policy_no C(30), firstname C(40), Surname C(40), canceldate D, polstatus C(1), expdate T, reason C(100))
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 8
lnRow = 2
DIMENSION laData[8]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 5, 7)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 				
			
			lnYear = YEAR(laData[i])
			IF lnYear > YEAR(DATE())
				laData[i] = DATE(YEAR(laData[i])-543, MONTH(laData[i]), DAY(laData[i]))			
			ENDIF 
			IF i = 7
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
			ENDIF 
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Convert Finished.....")
oExcel.quit 
*****************************************************

PROCEDURE UpdateData

IF MESSAGEBOX("Do you want update this data into member table now",4+32+256, "Confirm ") = -7
	RETURN 
ENDIF 	 
*
CLEAR 
? "Start Checking and Update Member Table" 

SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	m.fullname = ALLTRIM(m.firstname)+ALLTRIM(m.surname)
	lcQuoName = "FAL" + m.quotation + m.fullname
	IF SEEK(lcQuoName, "member", "quo_name")
		DO CASE 
		CASE m.polstatus = "C"	
			REPLACE member.adjcancel WITH m.canceldate, ;
				member.canceldate WITH m.canceldate, ;
				member.cancelexp WITH member.expiry, ;
				member.expiry WITH IIF(EMPTY(m.expdate), member.expiry, m.expdate), ;
				member.polstatus WITH m.polstatus, ;
				member.status WITH "C", ;
				member.infonote WITH ALLTRIM(m.reason)
		CASE m.polstatus = "R"	
			REPLACE member.adjrefund WITH m.canceldate, ;
				member.refunddate WITH m.canceldate, ;
				member.cancelexp WITH member.expiry, ;
				member.expiry WITH IIF(EMPTY(m.expdate), member.expiry, m.expdate), ;
				member.polstatus WITH m.polstatus, ;
				member.status WITH "C", ;
				member.infonote WITH ALLTRIM(m.reason)
		ENDCASE 				
	ELSE
		? quotation
	ENDIF 	
ENDSCAN 
? "Update Cancel & Refund  Finished...."
USE 
