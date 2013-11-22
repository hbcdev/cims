CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG Cancel data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
IF AT("CANCEL", UPPER(lcDataFile)) = 0
	=MESSAGEBOX("àÅ×Í¡ä¿Åì·ÕèãªéÍÑ¾à´·¼Ô´", 0)
	RETURN 
ENDIF 


lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")

IF !FILE(lcDbf)

	CREATE DBF (lcDbf) FREE (canceldate D, cardno C(30), cardexp D, adjcancel D, saledate D, remark C(80), polstatus C(1))


	oExcel = CREATEOBJECT("Excel.Application")
	oWorkBook = oExcel.workbooks.open(lcDataFile)

	oexcel.ActiveWindow.Activate
	oexcel.ActiveWindow.FreezePanes = .F.
		*
	oSheet = oWorkBook.worksheets(1)
		
	?DBF()
	lcDate = RIGHT(JUSTFNAME(DBF()),12)
	ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
	***************************************************
	lnFieldCount = 6
	lnRow = 2
	DIMENSION laData[7]
	DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
		WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
		FOR i = 1 TO lnFieldCount
			laData[i] = oSheet.Cells(lnRow,i).Value
			DO CASE 
			CASE INLIST(i, 1, 3, 4, 5)
				laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
				IF EMPTY(laData[i])
					laData[i] = {}
				ENDIF 	
				IF TYPE("laData[i]") = "C"
					laData[i] = CTOD(laData[i])
				ENDIF 	
			OTHERWISE 		
				laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
				IF TYPE("laData[i]") = "N"
					laData[i] = LTRIM(STR(laData[i]))
				ENDIF 	
			ENDCASE 
		ENDFOR
		laData[7] = "C"
		IF !EMPTY(laData[2])
			INSERT INTO (lcDbf) FROM ARRAY laData
		ENDIF
		lnRow = lnRow + 1
	ENDDO
	BROWSE 
	USE 
	=MESSAGEBOX("Finished.....")
	oExcel.quit 
	*
ENDIF 	
************************************************
*
* Update To Member Table
*
USE (lcDbf) IN 0 ALIAS smgcancel
IF !USED("members")
	USE cims!members IN 0
ENDIF 

SELECT smgcancel
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	IF SEEK("SMG"+cardno, "members", "policy_no")
		?cardno 
		REPLACE members.canceldate WITH canceldate, ;
			members.expried_y WITH members.expiry, ;
			members.expiry WITH DATETIME(YEAR(canceldate), MONTH(canceldate), DAY(canceldate), 12, 00), ;
			members.adjcancel WITH adjcancel, ;
			members.polstatus WITH polstatus, ;
			members.status WITH polstatus
	ENDIF 
ENDSCAN
USE IN smgcancel