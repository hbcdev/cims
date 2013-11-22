CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XL*;XLSX", "Cigna CO File", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = FORCEEXT(lcDataFile, "DBF")
IF FILE(lcDbf)
	IF MESSAGEBOX("พบ "+lcDbf+" ต้องการให้สร้างใหม่หรือไม่?",4+32+256,"Confrim") = 6
		DO ConvertXls
	ENDIF 
ELSE 
	DO ConvertXls
ENDIF
*
IF MESSAGEBOX("ต้องการให้อัพโหลดเข้าฐานข้อมูลหรือไม่?",4+32+256,"Confrim") = 6
	DO Update2Items
ENDIF 	
*******************************
PROCEDURE ConvertXls

CREATE DBF (lcDbf) FREE (policy_no C(30), covercode C(10), covername C(50), effdate D, expdate D, benefit Y)

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
lnCount = oWorkBook.Sheets.Count()
*	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 6
DIMENSION laData[6]

FOR j = 1 TO lnCount
	oSheet = oWorkBook.Worksheets(j)
	lnRow = 2	
	DO WHILE !ISNULL(oSheet.Cells(lnRow, 1).Value)
		STORE "" TO laData[1], laData[2], laData[3]
		STORE {} TO laData[4], laData[5]
		STORE 0 TO laData[6]
		WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
		FOR i = 1 TO lnFieldCount
			laData[i] = oSheet.Cells(lnRow,i).Value
			DO CASE 
			CASE INLIST(i, 4, 5)
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
					IF i = 4
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 00, 00)
					ELSE 	
						laData[i] = laData[i]-1
						laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 23, 59)
					ENDIF 	
				ENDIF
			CASE INLIST(i, 6)
				laData[i] = VAL(laData[i])	
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
		IF lnRow = 65537
			EXIT
		ENDIF 	
	ENDDO
ENDFOR 	
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 
*
**************************************
PROCEDURE Update2items

USE (lcDbf) IN 0 ALIAS cig
IF !USED("policy2items")
	USE cims!policy2items IN 0
ENDIF 
IF !USED("member")	
	USE cims!member IN 0
ENDIF 
	
STORE 0 TO lnNew, lnUpdate
llError = .F.
lcErrFile = STRTRAN(lcDbf, "DBF", "TXT")
**********************************
IF FILE(lcErrFile)
	DELETE FILE (lcErrFile)
ENDIF 	
**********************************
SELECT cig
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	IF SEEK("CIG"+policy_no, "member", "policy_no")	
		m.fundcode = member.tpacode
		m.plan = member.product		
		m.policy_no = cig.policy_no
		m.effdate = cig.effdate
		m.expdate = cig.expdate
		m.itemcode = SUBSTR(cig.covercode,3,2)
		m.cat_id = ICASE(m.itemcode = "SF", "0000378", m.itemcode = "ET", "0000445", m.itemcode = "AC", "0000402", m.itemcode = "RC", "0000538", m.itemcode = "WR", "0000422",  m.itemcode = "SL", "0000436", "0000800")  
		m.catcode = cig.covercode
		m.catdesc = cig.covername
		m.benefit = cig.benefit
		*m.adddate = ldDate
		m.l_user = gcUserName
		m.l_update = DATETIME()		
		*****************************
		lcPolicyNo = m.fundcode + m.policy_no
		IF SEEK(lcPolicyNo, "policy2items", "policy")
			lnUpdate = lnUpdate + 1		
			IF m.effdate = member.effective
				SELECT policy2items
				GATHER MEMVAR 
			ENDIF 	
		ELSE 
			lnNew = lnNew + 1		
			INSERT INTO policy2items FROM MEMVAR
		ENDIF 			
	ELSE 
		llError = .T.
		lcError = policy_no	+" "+covercode+CHR(13)
		=STRTOFILE(lcError, lcErrFile, 1)		
	ENDIF 
	SELECT cig
ENDSCAN
IF llError
	MODIFY FILE (lcErrFile)
ENDIF 	
USE IN cig
=MESSAGEBOX("New Data: " + TRANSFORM(lnNew, "@Z 999,999"), 0)