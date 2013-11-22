CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS;XLSX", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDate = SUBSTR(JUSTFNAME(lcDataFile),8,8)
IF ISDIGIT(lcDate)
	ldDate = CTOD(RIGHT(lcDate,2)+"/"+SUBSTR(lcDate,5,2)+"/"+LEFT(lcDate,4))
ELSE 
	ldDate = DATE()
ENDIF 	
*
lnSelect = select()
lcDbf = forceext(lcDataFile, ".DBF")
if file(lcDbf)
	if messagebox("พบไฟล์ที่ Covert แล้ว ต้องกการ Convert ใหม่ ", 4+32+256,"Warning") = 6
		do convertData
	else
		select 0
		use (lcDbf)	
		lnSelect = select()		
		if reccount() = 0
			do convertData	 	
		endif 			
	endif
else 
	do convertData	 	
endif 	
*	
IF MESSAGEBOX("Update Data To Member Table",4+32+256,"Update Data") = 7
	RETURN 
ENDIF 

IF !USED("member")
	USE cims!member IN 0
	llClose = .T.
ENDIF 	

select member
scatter memo memvar blank

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
	m.customer_type = "P"
	m.family_no = val(m.quotation)	
	m.quotation = ALLTRIM(m.policy_no)+"-"+STRTRAN(ALLTRIM(m.quotation), "/", "-")
	m.effective_y = m.effective
	m.expiry = IIF(EMPTY(m.canceldate), m.expiry, m.canceldate)
	m.age = YEAR(m.effective)-YEAR(m.birth_date)+1
	m.policy_date = m.effective
	m.pay_fr = m.pay_mode
	m.l_user = gcUserName
	m.overall_limit = m.medical
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
	*	
	=updateMemberToSql()
	*
	select member
	scatter memo memvar blank
	*	
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
ENDIF
**********************************
procedure convertData
	
CREATE DBF (lcDbf) FREE (rectype C(1), fundname V(10), sponsor V(10), package V(20), plancode V(20), cover_op V(2), progress V(2), memberid V(30), policy_no V(30), polstatus C(1), ;
	title V(20), name V(50), surname V(50), natid V(20), birth_date D, sex C(1), h_addr1 V(70), h_addr2 V(70), h_city V(50), h_province C(50), h_postcode C(5), h_country V(50), ;
	h_phone V(30), mobile V(30), title_p C(20), name_p V(44), surname_p V(44), p_natid V(20), p_dob D, p_gender C(1), pcountry V(20), effective T, expiry T, canceldate T, pay_mode C(1), ;
	medical Y, premium Y, quotation V(50), polname C(50), polgroup V(20), product V(20), plan_id C(10),adddate D, filename V(100), l_update T)
	
lnSelect = SELECT()

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
oSheet = oWorkBook.worksheets(1)
	
?DBF()
***************************************************
lnFieldCount = 38
lnRow = 2
DIMENSION laData[45]
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
			*
			laData[i] = IIF(TYPE("laData[i]") = "N", ALLTRIM(STR(laData[i])), laData[i])
			IF TYPE("laData[i]") = "C"
				IF AT("/", laData[i]) = 0
					laData[i] = SUBSTR(laData[i],7,2)+"/"+SUBSTR(laData[i],5,2)+"/"+LEFT(laData[i],4)
				ENDIF 
				laData[i] = CTOD(laData[i])
			ENDIF
			*
			IF INLIST(i, 32, 33)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
			ENDIF 
			IF i = 33
				IF !EMPTY(laData[i])
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
			ENDIF 
		case i = 38
			laData[i] = alltrim(str(laData[i]))
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 
	ENDFOR
	***
	laData[39] = ALLTRIM(laData[12])+" "+ALLTRIM(laData[13])
	laData[40] = laData[9]
	laData[41] = ALLTRIM(laData[5])
	laData[42] = ICASE(laData[36] = 100000, "FAL1900",laData[36]= 10000, "FAL1901",laData[36]= 20000, "FAL1857",laData[36]= 30000, "FAL1858","")
	laData[43] = ldDate	
	laData[44] = JUSTFNAME(lcDataFile)	
	laData[45] = DATETIME()
	IF !EMPTY(laData[38])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
oExcel.quit 
*****************************
BROWSE 
