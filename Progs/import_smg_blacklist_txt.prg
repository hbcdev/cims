*#DEFINE DATAPATH "d:\hips\data\"
lcBlackListDbf = ADDBS(DATAPATH)+"smg_blacklist.dbf"
*!*	IF !FILE(lcBlackListDbf)
*!*		=MESSAGEBOX("ไม่พบแฟ้มเก็บข้อมูล Blacklist กรุณาแจ้งให้ผู้ดูแลระบบ",0,"Error")
*!*		RETURN 
*!*	ENDIF 	

*!*	SET DEFAULT TO ?
*!*	lnAmountFiles = ADIR(laSmg, "*.TXT")
*!*	FOR lnFile = 1 TO lnAmountFiles
*!*		DO insertData WITH laSmg[lnFile, 1]
*!*	ENDFOR 		
DO insertData
***************************************
PROCEDURE InsertData
LPARAMETERS lcSourceFile

IF EMPTY(lcSourceFile)
	lcSourceFile = GETFILE("TXT")
ENDIF 
	
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
SELECT 0	
lnSelect = SELECT()
CREATE DBF (lcDbf) FREE (Entityid C(6), Brcode C(3), firstname C(40), name C(40), Surname C(40), idcardno C(20), class C(20), ;
	subclass C(20), level C(20), active C(1), updatedate T, adddate D) 
*
*--cardno = idno	
?DBF()
lcDate = JUSTFNAME(DBF())
ldDate = CTOD(SUBSTR(lcDate, 17, 2)+"/"+SUBSTR(lcDate,15,2)+"/"+SUBSTR(lcDate, 11, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts - 1
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE j = 11
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ELSE 	
				laData[j] = CTOT(laData[j])
			ENDIF 	
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[12] = ldDate
	INSERT INTO (lcBlackListDbf) FROM ARRAY laData
	INSERT INTO (lcDbf) FROM ARRAY laData	
ENDFOR 
DO Update2Members
*
*
PROCEDURE Update2Members

SELECT idcardno, name, surname, COUNT(*) FROM (lcDbf) GROUP BY 1, 2, 3 INTO CURSOR bl

lcError = "กรมธรรม์นี้ ได้ถูก Blacklist โดยบริษัทประกัน กรุณาตรวจสอบกับบริษัทฯ ก่อนทำจ่าย"
SELECT bl
SCAN 
	SCATTER MEMVAR 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	UPDATE cims!members SET polstatus = "C", ;
		members.infonote = lcError ;
	WHERE natid = m.idcardno ;
		AND name = m.name ;
		AND surname = m.surname
ENDSCAN 		

