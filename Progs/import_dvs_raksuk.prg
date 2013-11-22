CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Deves Raksuk data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")

CREATE DBF (lcDbf) FREE (refno I, payor C(20), company C(30), staffno C(30), join_date D, fullname C(50), sex C(1), relations C(10), principal C(20), ic C(20), ;
	dob D, add1 C(50), add2 C(50), add3 C(50), pcode C(5), town C(50), state C(50), contactno C(20), phone C(20), chanel C(10), email C(30), policy_no C(30), ;
	plan C(20), eff_date T, exp_date T, remark C(80), exclusion C(80), premium Y, mco C(10), members C(10), o_member C(10), centre C(10), clinic1 C(20), ;
	clinic2 C(20), pol_year I, cert_no C(20), card_no C(20), title C(20), c_accno C(20), cover_l C(20), bankcode C(5), accno C(20), pol_date D, tranno C(3), startdate D, ;
	numscb C(20), name C(40), surname C(40), orgplan C(20), planid C(8),polstatus C(1), cardno C(25))

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
	*
oSheet = oWorkBook.worksheets(1)
	
?DBF()
lcStatus = IIF(AT("END", DBF()) = 0, "I", "C")
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 46
lnRow = 6
DIMENSION laData[52]

DO WHILE !ISNULL(oSheet.Cells(lnRow, 6).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 		
		CASE i = 23
			laData[49] = UPPER(laData[i])
			laData[50] = ICASE(AT("Platinum", laData[23]) <> 0, "DVS1437", AT("Gold", laData[23]) <> 0, "DVS1438", AT("Silver", laData[23]) <> 0, "DVS1439", "")
			IF EMPTY(laData[50])
				laData[50] = ICASE(AT("แผน1", laData[23]) <> 0, "DVS1437", AT("แผน2", laData[23]) <> 0, "DVS1438", AT("แผน3", laData[23]) <> 0, "DVS1439", "")
			ENDIF 
		CASE INLIST(i, 11, 24, 25, 43, 45)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 				
			IF INLIST(i, 24, 25, 43)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
			ENDIF 
		CASE INLIST(i, 28, 35)
			IF TYPE("laData[i]") = "C"
				laData[i] = VAL(laData[i])
			ENDIF 			
		CASE i = 37
			IF ISNULL(laData[i])
				laData[i] = STRTRAN(STRTRAN(laData[22], "/", ""), "-", "")		
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 				
			laData[i] = ALLTRIM(STRTRAN(laData[i], CHR(160), ""))
		ENDCASE 
	ENDFOR
	laData[47] = ALLTRIM(LEFT(laData[6], AT(" ", laData[6])))
	laData[48] = ALLTRIM(SUBSTR(laData[6], AT(" ", laData[6])))
	laData[51] = lcStatus
	laData[52] = IIF(EMPTY(laData[46]), STRTRAN(STRTRAN(laData[22], "/", ""), "-", ""), laData[46])
	IF "แผนใหม่" $ laData[26]
		laData[50] = ICASE(AT("Platinum", laData[23]) <> 0, "DVS1698", AT("Silver", laData[23]) <> 0, "DVS1697", "")
	ENDIF 
	*
	IF !EMPTY(laData[6])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 