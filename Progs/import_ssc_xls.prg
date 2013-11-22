CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")


lcPolStatus = IIF("EXP" $ UPPER(lcDbf), "C", "A")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no C(30), poltype C(10), Plan C(20), Cust_id C(20), Title C(20), Name C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, Address3 C(40), Address4 C(40), Country C(40), Postcode C(5), Telephone C(30), ;
	Pol_date T, Eff_date T, Exp_date T, Premium Y, Exclusion C(100), Agent C(20), Agency C(20), Pay_mode C(1), Renew I, PolStatus C(1), ;
	Payer C(40), Medical Y, HB_Limit Y, endosno C(20), end_date D, end_type C(20), paiddate D, reindate D, lapsedate D, canceldate D, adddate D, pol_name C(120))
***************************************************
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
*
lnFieldCount = FCOUNT()
lnRow = 2
DIMENSION laData[lnFieldCount+2]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 3).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 9, 16, 17, 18, 30, 32, 33, 34, 35)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			laData[i] = CovertDate(laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF
			IF i = 18 AND EMPTY(laData[i])
				laData[i] = GOMONTH(laData[17], 12)
			ENDIF 	
			*
			IF INLIST(i, 16, 17, 18) AND  !EMPTY(laData[i])
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 00, 01)
			ENDIF 
		CASE i = 25
			IF lcPolStatus = "C"
				laData[i] = "C"
			ENDIF 		
		CASE i = 28
			DO CASE 
			CASE INLIST(laData[3], "AS", "BS", "CS")
				laData[i] = 300
			CASE INLIST(laData[3], "AG", "BG", "CG")
				laData[i] = 400
			CASE INLIST(laData[3], "AD", "BD", "CD")
				laData[i] = 500
			OTHERWISE 
				laData[i] = 0				
			ENDCASE 
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ELSE 
				laData[i] = ALLTRIM(laData[i])
			ENDIF 				
		ENDCASE 
	ENDFOR 
	IF !EMPTY(laData[3])
		laData[36] = ldDate
		laData[37] = ALLTRIM(laData[6])+" "+ALLTRIM(laData[7])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit
*
****************************
PROCEDURE ColumnLetter                                                          
   PARAMETER lnColumnNumber                                                     
      lnFirstValue = INT(lnColumnNumber/27)                                     
      lcFirstLetter = IIF(lnFirstValue=0,"",CHR(64+lnFirstValue))               
      lnMod =  MOD(lnColumnNumber,26)                           
      lcSecondLetter = CHR(64+IIF(lnMod=0, 26, lnMod))
                                                                                
RETURN lcFirstLetter + lcSecondLetter


FUNCTION CovertDate(tcDate)

IF EMPTY(tcDate)
	ldDate = {}	
ELSE 
	lcDay = LEFT(tcDate,2)
	lcMonth = SUBSTR(tcDate, 4, 3)
	lcYear = RIGHT(ALLTRIM(tcDate), 2)
	*
	lcCMonth = ICASE(UPPER(lcMonth) = "JAN", "01", UPPER(lcMonth) = "FEB", "02", UPPER(lcMonth) = "MAR", "03", UPPER(lcMonth) = "APR", "04", UPPER(lcMonth) = "MAY", "05", UPPER(lcMonth) = "JUN", "06", UPPER(lcMonth) = "JUL", "07", UPPER(lcMonth) = "AUG", "08", UPPER(lcMonth) = "SEP", "09", UPPER(lcMonth) = "OCT", "10", UPPER(lcMonth) = "NOV", "11", UPPER(lcMonth) = "DEC", "12", "")
	IF EMPTY(lcCMonth)
		ldDate = {}
	ELSE 
		ldDate = CTOD(lcDay + "/" + lcCMonth + "/" + lcYear)
	ENDIF 
ENDIF 
RETURN ldDate			
