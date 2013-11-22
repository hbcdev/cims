CLEAR 
lcDbf = ADDBS(DATAPATH)+"smg_renew.dbf"
IF !FILE(lcDbf)
	CREATE DBF (lcDbf) FREE (selldate D, oldeff T, entrydate D, cardno C(25), nextpaid T, nextfee D, neweff T, cutmonth I, ;
		importdate D, senddate D, effdate T, expdate T, filename V(100))
ENDIF 	

lcDataFile = GETFILE("XLS", "SMG Renew Data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
?lcDataFile
lcDataFile = ADDBS(SYS(5)+SYS(2003))+lcDataFile
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
oSheet = oWorkBook.worksheets(1)
***************************************************
lnFieldCount = 10
lnRow = 2
DIMENSION laData[13]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 4).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 2, 5, 7, 9, 10)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			IF EMPTY(laData[i])
				laData[i] = {}
			ELSE 	
				IF INLIST(i, 2, 5, 7)
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
			ENDIF 	
		CASE i = 8
			laData[i] = IIF(TYPE("laData[i]") = "C", VAL(laData[i]), IIF(ISNULL(laData[i]), 0, laData[i]))
		ENDCASE 
	ENDFOR
	IF !EMPTY(laData[4])
		ldDue = IIF(EMPTY(laData[2], {}, GOMONTH(DATE(YEAR(GOMONTH(GOMONTH(laData[2],12),1)), MONTH(GOMONTH(GOMONTH(laData[2],12),1)),1),1)-1)
		IF laData[6] > ldDue
			laData[11] = DATETIME(YEAR(laData[6]), MONTH(laData[6]), DAY(laData[6]), 12, 00)
			laData[12] = GOMONTH(laData[11],12)
			laData[12] = DATETIME(YEAR(laData[12]), MONTH(laData[12]), DAY(laData[12]), 12, 00)			
		ELSE 
			laData[11] = GOMONTH(laData[2],12)
			laData[11] = DATETIME(YEAR(laData[11]), MONTH(laData[11]), DAY(laData[11]), 12, 00)
			laData[12] = GOMONTH(laData[11],12)			
			laData[12] = DATETIME(YEAR(laData[12]), MONTH(laData[12]), DAY(laData[12]), 12, 00)
		ENDIF
		laData[3] = IIF(EMPTY(laData[3]) OR ISNULL(laData[3]), {}, laData[3])
		laData[5] = IIF(EMPTY(laData[5]) OR ISNULL(laData[5]), {}, DATETIME(YEAR(laData[5]), MONTH(laData[5]), DAY(laData[5]), 12, 00))
		laData[13] = JUSTFNAME(lcDataFile)
		*
		SELECT cardno, oldeff FROM (lcDbf) WHERE cardno = laData[4] AND oldeff = laData[2] INTO ARRAY laRenew 
		IF _TALLY = 0		
			INSERT INTO (lcDbf) FROM ARRAY laData
		ELSE 
			UPDATE  (lcDbf) SET ;
				selldate = laData[1], ;
				oldeff = laData[2], ;
				entrydate = laData[3], ;
				cardno = laData[4], ;
				nextpaid = laData[5], ;
				nextfee = laData[6], ;
				neweff = laData[7], ;
				cutmonth = laData[8], ;
				importdate = laData[9], ;
				senddate = laData[10], ;
				effdate = laData[11], ;
				expdate = laData[12], ;
				filename = laData[13] ;
			WHERE cardno = LEFT(laData[4],25) ;
				AND oldeff = laData[2]
		ENDIF
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit 