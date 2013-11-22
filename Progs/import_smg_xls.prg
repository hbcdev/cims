CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
IF FILE(ADDBS(DATAPATH)+"smg_blacklist.dbf")
	USE (ADDBS(DATAPATH)+"smg_blacklist") IN 0 
ENDIF 	

lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (title C(20), name C(40), surname C(40), saledate D, agent C(20), eff_date T, exp_date T, plan C(20), cardno C(25), ;
	quotation C(30), premium Y, 	policy_no C(30), polstatus C(1), adddate D, nattype C(2), natid C(13), accno C(20), poltype C(20), Medical Y, ;
	plan_id C(20), Pol_date T, pol_name C(60), cust_id C(20), remark C(50))

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
lnFieldCount = 18
lnRow = 2
DIMENSION laData[24]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 9).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 8
			DO CASE 
			CASE "PAH" $ DBF()
				laData[19] = ICASE(laData[i] = "A", 50000, laData[i] = "B", 100000, laData[i] = "C", 300000, laData[i] = "D", 300000, 0)
				laData[20] = ICASE(laData[i] = "A", "SMG1440", laData[i] = "B", "SMG1441", laData[i] = "C", "SMG1442", laData[i] = "D", "SMG1443", 0)
				laData[i] = ICASE(laData[i] = "A", "PaHappyPlus5แสน", laData[i] = "B", "PaHappyPlus1ล้าน", laData[i] = "C", "PaHappyPlus3ล้าน", laData[i] = "D", "PaHappyPlus5ล้าน", "PaHappyPlus")
			OTHERWISE 		
				laData[19] = ICASE(laData[i] = "S", 5000, laData[i] = "G", 25000, 0)		
				laData[20] = ICASE(laData[i] = "S", "SMG1050", laData[i] = "G", "SMG1051", "")					
				laData[i] = ICASE(laData[i] = "S", "Silver", laData[i] = "G", "Gold", laData[i])
			ENDCASE 	
		CASE INLIST(i, 4, 6, 7, 14)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			
			IF INLIST(i, 6, 7)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					IF "PAH" $ DBF()
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 16, 00)
					ELSE 
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
					ENDIF 	
				ENDIF 	
			ENDIF 	
			laData[21] = laData[6]
		CASE i = 11
			laData[i] = ICASE(laData[i] = 260, 258, laData[i] = 900, 896, laData[i])
		CASE i = 16
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])	
			laData[23] = laData[i]
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	laData[12] = IIF(ISNULL(laData[12]) OR EMPTY(laData[12]), laData[9], laData[12])	
	laData[13] = ""
	laData[24] = ""
	IF USED("smg_blacklist")
		SELECT subclass ;
		FROM smg_blacklist ;
		WHERE idcardno = ALLTRIM(laData[16]) ;
			AND name = ALLTRIM(laData[2]) ;
			AND surname = ALLTRIM(laData[3]) ;
		INTO ARRAY aBlackList
		IF _TALLY <> 0
			? laData[9]+" Blacklist" 
			laData[13] = "C"
			laData[24] = "SCSMG Blacklist"
		ENDIF
	ENDIF 	
	laData[22] = ALLTRIM(laData[2])+" "+ALLTRIM(laData[3])
	IF !EMPTY(laData[9])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 