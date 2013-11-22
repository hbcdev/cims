CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
USE GETFILE("DBF", "Get Effective File") IN 0 ALIAS eff
USE ? IN 0 ALIAS exp

IF EMPTY(lcDataFile) AND !USED("eff") AND !USED("exp")
	RETURN 
ENDIF 

SELECT eff
IF EMPTY(TAG(1))
	INDEX on quotation+ALLTRIM(name)+" "+ALLTRIM(surname") tag quoname
ENDIF 	
********************

lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no C(30), sequence I, Plan C(20), Cust_id C(20), Title C(20), Name C(40), MidName C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, Address1 C(40), Address2 C(40), Address3 C(40), Address4 C(40), Country C(40), Postcode C(5), Telephone C(30), ContactPer C(40), ContactTel C(30), ;
	Pol_date T, Eff_date T, Exp_date T, Premium Y, Exclusion C(100), Agent C(20), Agency C(20), Pay_mode C(1), OccuCode C(20), OccuClass C(10), AdjDate D, Renew I, PolStatus C(1), ;
	Employee C(1), Payer C(40), HB_Limit Y, Medical Y, quotation C(30), pol_group C(20), pol_name C(60))
***************************************************
lnFieldCount = 38
lnRow = 2
DIMENSION laData[40]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 6).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 3
			laData[i] = UPPER(laData[i])
		CASE i = 4
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])				
			laData[i] = STRTRAN(IIF(AT(",", laData[i]) = 0, laData[i], LEFT(laData[i], AT(",", laData[i])-1)), "-", "")					
		CASE INLIST(i, 11, 24, 32, 36, 37)
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])		
		CASE INLIST(i, 10, 21, 22, 23, 31, 39)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			
			IF INLIST(i, 21, 22, 23) AND  !EMPTY(laData[i])
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR 	
	laData[40] = ALLTRIM(laData[6])+" "+ALLTRIM(laData[8])	
	IF !EMPTY(laData[6])
		IF SEEK(LEFT(laData[38], 30), "eff", "quoname")
			laData[1] = eff.policy_no
			IF SEEK(LEFT(laData[1], 30), "exp", "polname")
				laData[23] = exp.last_expir
			ELSE 
				laData[23] = {}
			ENDIF 	
		ENDIF 
		*********************
		laData[39] = laData[1]
		IF !EMPTY(laData[1])
			IF !EMPTY(laData[2]) AND LEFT(laData[3],6) # "I-CARE"
				laData[1] = ALLTRIM(laData[1])+"-"+IIF(LEN(laData[2])=1, "0", "")+laData[2]
			ENDIF 	
		ENDIF 	
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Finished.....")
oExcel.quit
CLOSE ALL 