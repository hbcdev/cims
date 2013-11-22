CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Select ALA member data file", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan C(20), Cust_id C(20), Title C(20), Name C(40), MidName C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, Address1 C(40), Address2 C(40), Address3 C(40), Address4 C(40), Country C(40), Postcode C(5), Telephone C(30), ContactPer C(40), ContactTel C(30), ;
	Pol_date T, Eff_date T, Exp_date T, Premium Y, Exclusion C(100), Agent C(20), Agency C(20), Pay_mode C(1), OccuCode C(20), OccuClass C(10), AdjDate D, Renew I, PolStatus C(1), ;
	Employee C(1), Payer C(40), HB_Limit Y, Medical Y)
***************************************************
lnFieldCount = 36
lnRow = 2
DIMENSION laData[lnFieldCount]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 2
			laData[i] = UPPER(laData[i])
		CASE INLIST(i, 10, 23, 31, 35, 36)
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])		
		CASE INLIST(i, 9, 20, 21, 22, 30)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			IF INLIST(i, 20, 21, 22)
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
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit