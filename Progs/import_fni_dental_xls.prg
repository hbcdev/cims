CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDate = LEFT(RIGHT(JUSTFNAME(lcDataFile),12),8)
IF ISDIGIT(lcDate)
	ldDate = CTOD(RIGHT(lcDate,2)+"/"+SUBSTR(lcDate,5,2)+"/"+LEFT(lcDate,4))
ELSE 
	ldDate = DATE()
ENDIF 	
*
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
CREATE DBF (lcDbf) FREE (rectype C(1), fundname V(10), sponsor V(10), package V(10), plancode V(10), cover_op V(2), progress V(2), memberid V(30), policy_no V(30), polstatus C(1), title V(20), name V(50), surname V(50), ;
	natid V(20), birth_date D, sex C(1), h_addr1 V(70), h_addr2 V(70), h_city V(50), h_province C(50), h_postcode C(5), h_country V(50), h_phone V(30), mobile V(30), title_p C(20), name_p V(44), surname_p V(44), p_natid V(20), p_dob D, ;
	p_gender C(1), pcountry V(20), effective T, expiry T, canceldate T, pay_mode C(1), premium Y, quotation V(50), polname C(50), polgroup V(20), product V(20), plan_id C(10),adddate D, filename V(100), l_update T)
	
lnSelect = SELECT()

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
oSheet = oWorkBook.worksheets(1)
	
?DBF()
***************************************************
lnFieldCount = 37
lnRow = 2
DIMENSION laData[44]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 37).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 15, 29, 32, 33, 34)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 				
			IF INLIST(i, 32, 33)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 00, 00)
				ENDIF 	
			ENDIF 
			IF i = 34 
				IF !EMPTY(laData[i])
					laData[i] = laData[i]-1
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 23, 59)
				ENDIF 	
			ENDIF 					
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	***
	IF EMPTY(laData[35])
		DO CASE 
		CASE laData[10] = "A" &&  มีผลบังคับ
			laData[35] = GOMONTH(laData[33], 1)
		CASE laData[10] = "S" &&  รอชำระเบี้ย
			laData[35] = GOMONTH(laData[33], 1)		
		CASE laData[10] = "T" &&  ยกเลิกกรมธรรม์ ไม่ชำระเบี้ย
			laData[35] = laData[33]
		ENDCASE 
	ENDIF 
	***
	laData[38] = ALLTRIM(laData[12])+" "+ALLTRIM(laData[13])
	laData[39] = laData[9]
	laData[40] = ALLTRIM(laData[5])
	laData[41] = ICASE(SUBSTR(laData[5],6,4) = "A 01", "FAL1704",SUBSTR(laData[5],6,4) = "A 02", "FAL1708",;
		SUBSTR(laData[5],6,4) = "B 01", "FAL1712",SUBSTR(laData[5],6,4) = "B 02", "FAL1716",;
		SUBSTR(laData[5],6,4) = "C 01", "FAL1720",SUBSTR(laData[5],6,4) = "C 02", "FAL1724",;
		SUBSTR(laData[5],6,4) = "D 01", "FAL1728",SUBSTR(laData[5],6,4) = "D 02", "FAL1732",;
		SUBSTR(laData[5],6,4) = "E 01", "FAL1736",SUBSTR(laData[5],6,4) = "E 02", "FAL1740","")
	laData[42] = ldDate	
	laData[43] = JUSTFNAME(lcDataFile)	
	laData[44] = DATETIME()
	IF !EMPTY(laData[37])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit 
BROWSE 
*
IF MESSAGEBOX("Update Data To Member Table",4+32+256,"Update Data") = 7
	RETURN 
ENDIF 

IF !USED("member")
	USE cims!member IN 0
	llClose = .T.
ENDIF 	

STORE "" TO lcError
STORE 0 TO lnNew, lnUpdate, lnError
SELECT (lnSelect)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	m.fund_id = 19
	m.tpacode = "FAL"
	m.policy_group = m.polgroup
	m.policy_name = m.polname
	m.customer_id = m.natid
	m.customer_type = "D"
	m.effective_y = m.effective
	m.age = YEAR(m.effective)-YEAR(m.birth_date)+1
	m.policy_date = m.effective
	m.pay_fr = ICASE(m.pay_mode = "M", "M", m.pay_mode = "Q", "3M", m.pay_mode = "S", "6M", m.pay_mode = "A", "Y", m.pay_mode)
	m.l_user = gcUserName
	m.expiry = IIF(m.polstatus = "C", m.canceldate, m.expiry)
	m.adjcancel = IIF(EMPTY(m.canceldate), {}, m.adddate)
	*
	lcQuoNo = m.tpacode+m.quotation+REPLICATE(" ",50-LEN(m.quotation))+ALLTRIM(m.name)+ALLTRIM(m.surname)
	SELECT member	
	IF !SEEK(lcQuoNo, "member", "quo_name")	
		lnNew = lnNew + 1
		APPEND BLANK 
	ELSE 
		lnUpdate = lnUpdate + 1
	ENDIF
	GATHER MEMVAR 
	SELECT (lnSelect)
ENDSCAN 	 
lcMessage = "Update: "+TRANSFORM(lnUpdate, "@Z 999,999") +CHR(13)+;
		"New: "+TRANSFORM(lnNew, "@Z 999,9999") +CHR(13)+;
		"Error: "+TRANSFORM(lnError, "@Z 999,9999") +CHR(13)+;		
		"Total: "+TRANSFORM(RECCOUNT(lnSelect), "@Z 999,999") +CHR(13)	
=MESSAGEBOX(lcMessage,0,"FCI Upload Data")
*
IF llClose
	USE IN member
ENDIF 	