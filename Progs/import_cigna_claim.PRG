CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Cigna Claim data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")

CREATE DBF (lcDbf) FREE (claim_no C(30), policy_no C(30), prodcode C(20), covercode C(8), name C(60), client_rel C(60), paiddate D, claim_amt Y, pay_amt Y, delay_int Y, ;
	total_amt Y, summitted D, eventdate D, category C(16), class1 C(40), class2 C(68), class3 C(57), hospID C(13), hospname C(60), diagnosis C(60), clmstatus C(10), pay_type C(15), ;
	b_code C(3), b_branch C(20), payee C(60), rej_date D, sus_reason C(100), sup_comp_d D, remark C(200))

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
lnFieldCount = 29
lnRow = 2
DIMENSION laData[29]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		DO CASE 
		CASE INLIST(i, 7, 12, 13, 26, 28)
			IF EMPTY(laData[i])
				laData[i] = {}
			ELSE 	
				IF TYPE("laData[i]") = "C"
					laData[i] = CTOD(laData[i])
				ENDIF 	
			ENDIF 			
		CASE INLIST(i, 8, 9, 10, 11)
			IF TYPE("laData[i]") = "C"
				laData[i] = 0
			ENDIF  
		OTHERWISE 
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 				
		ENDCASE 		
	ENDFOR
	IF !EMPTY(laData[2])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 