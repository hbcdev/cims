CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("CSV", "Cigna Coverage data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".CSV", ".DBF")

IF FILE(lcDbf)
	IF MESSAGEBOX("พบ "+lcDbf+" ต้องการให้สร้างใหม่หรือไม่?",4+32+256,"Confrim") = 6
		DO ConvertCsv
	ENDIF 
ELSE 
	DO ConvertCsv
ENDIF 		

IF MESSAGEBOX("ต้องการให้โอนเข้าฐานข้อมูล หรือไม่",4+32+256,"Confrim") = 6
	DO Update2Items
ENDIF 	
*******************************
PROCEDURE ConvertCsv


CREATE DBF (lcDbf) FREE (policy_no C(30), covercode C(10), covername C(50), effdate D, expdate D, benefit Y)

lnLines = ALINES(laTextArray,FILETOSTR(lcDataFile))
FOR j = 2 TO lnLines
	WAIT WINDOW TRANSFORM(j-1, "@Z 9,999,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[j]
	FOR i = 1 TO lnFieldCounts
		laData[i] = STRTRAN(IIF(AT(",",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(",",lcTemp)-1)),'"','')
		laData[i] = STRTRAN(laData[i], '"','')
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
		CASE i = 6
			laData[i] = laData[i]
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
		IF AT(",",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(",",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
*
**************************************
PROCEDURE Update2items

USE (lcDbf) IN 0 ALIAS cig
USE cims!policy2items IN 0
USE cims!member IN 0
lnNew = 0
llError = .F.
lcErrFile = STRTRAN(lcDbf, "DBF", "TXT")
**********************************
IF FILE(lcErrFile)
	DELETE FILE (lcErrFile)
ENDIF 	
**********************************
SELECT cig
STORE 0 TO lnNew, lnUpdate, lnDele
ldDate = CTOD(RIGHT(LEFT(RIGHT(DBF(),12),8),2)+"/"+SUBSTR(LEFT(RIGHT(DBF(),12),8),5,2)+"/"+LEFT(LEFT(RIGHT(DBF(),12),8),4))
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
		m.adddate = ldDate
		*
		llNew = .T.
		lcPolPlan = "CIG" + cig.policy_no + ALLTRIM(cig.covercode)
		IF SEEK(lcPolPlan, "policy2items", "pol_cat")
			lnUpdate = lnUpdate + 1
			*
			SELECT policy2items
			GATHER MEMVAR 
		ELSE 
			m.l_user = gcUserName
			m.l_update = DATETIME()
			*****************************
			lnNew = lnNew + 1			
			INSERT INTO cims!policy2items FROM MEMVAR
		ENDIF
		WAIT WINDOW "New: "+TRANSFORM(lnNew, "@Z 999,999")+CHR(13)+"Update: "+TRANSFORM(lnUpdate, "@Z 999,999") AT 25, 30 NOWAIT   			
	ELSE 
		llError = .T.
		lnDele = lnDele + 1
		lcError = policy_no	+" "+covercode+CHR(13)
		=STRTOFILE(lcError, lcErrFile, 1)		
	ENDIF 
	SELECT cig
ENDSCAN
IF llError
	MODIFY FILE (lcErrFile)
ENDIF 	
=MESSAGEBOX("New Data: " + TRANSFORM(lnNew, "@Z 999,999")+CHR(13)+;
	"Update: "+TRANSFORM(lnUpdate, "@Z 999,999")+CHR(13)+;
	"Not Found: "+TRANSFORM(lnDele, "@Z 999,999"), 0)