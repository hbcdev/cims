CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("TXT", "SMG Adj Data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
IF AT("ADJ", UPPER(lcDataFile)) = 0
	=MESSAGEBOX("เลือกไฟล์ที่ใช้อัพเดทผิด", 0)
	RETURN 
ENDIF 
*
lcDbf =  ADDBS(DATAPATH)+"Smg_Adj_Card.dbf"
*
IF FILE("error_adj_card.txt")
	DELETE FILE error_adj_card.txt
ENDIF 
*	
lnConn = gnConn
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF
*
IF !USED("card2natid")
	USE cims!card2natid IN 0
ENDIF 	
*
?lcDataFile
SELECT filename, COUNT(*) FROM (lcDbf) WHERE filename = lcDataFile AND !EMPTY(filename) GROUP BY filename INTO ARRAY laFileName
IF _TALLY > 0	
	=MESSAGEBOX("มีการอัพโหลดไฟล์นี้ เข้าระบบไปแล้ว จำนวน "+TRANSFORM(laFileName[2],"@Z 99,999")+" records "+CHR(13)+;
		"กรุณาตรวจสอบก่อนดำเนินการต่อไป",0+48,"Warnning")
	RETURN 
ENDIF 
*
lcDate = LEFT(RIGHT(ALLTRIM(lcDataFile),12),8)
ldDate = CTOD(SUBSTR(lcDate,1,2)+"/"+SUBSTR(lcDate,3,2)+"/"+RIGHT(lcDate,4))
***************************************************
lnUpdate = 0
lnFieldCounts = 5
DIMENSION laData[7]
lnLines = ALINES(laTextArray,FILETOSTR(lcDataFile))
FOR j = 2 TO lnLines
	WAIT WINDOW TRANSFORM(j-1, "@Z 999,999")+"/"+TRANSFORM(lnLines, "@Z 999,999") AT 25, 45 NOWAIT 
	STORE "" TO laData
	STORE {} to laData[1], ladata[4], ladata[5]
	lcTemp = laTextArray[j]
	FOR i = 1 TO lnFieldCounts
		laData[i] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[i] = STRTRAN(laData[i], '"','')		
		DO CASE 
		CASE INLIST(i, 1, 5)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF
	ENDFOR
	laData[5] = IIF(EMPTY(laData[5]), ldDate, ldDate)
	laData[6] = ""
	laData[7] = JUSTFNAME(lcDataFile)
	IF !EMPTY(laData[1]) OR !EMPTY(laData[2])
		SELECT oldcard FROM (lcDbf) WHERE adjdate = laData[1] AND oldcard = ALLTRIM(laData[2]) INTO ARRAY laCard
		IF _TALLY = 0	
			INSERT INTO (lcDbf) (fundcode, adjdate, oldcard, newcard, importd, natid, filename) ;
				VALUES ("SMG", laData[1], laData[2], laData[3], laData[5], laData[6], laData[7])
		ELSE 
			WAIT WINDOW "Update Data" NOWAIT 
			UPDATE (lcDbf) SET ;
				fundcode = "SMG", ;
				adjdate = laData[1], ;
				oldcard = laData[2], ;
				newcard = laData[3], ;
				importd = laData[5], ;
				filename = laData[7] ;
			WHERE adjdate = laData[1] ;
				AND oldcard = ALLTRIM(laData[2])
		ENDIF 	
		*
		lnRetVal = updateMember(laData[1], laData[2], laData[3])
		IF lnRetVal = 1
			lnUpdate = lnUpdate + 1
			WAIT WINDOW TRANSFORM(lnUpdate, "@Z 999,999") AT 25,30 NOWAIT 	
		ELSE 
			lcError = "M|"+m.oldcard+"|"+m.newcard+CHR(10)+CHR(13)
			=STRTOFILE(lcError, "error_adj_card.txt",1)
		ENDIF 	
	ENDIF
ENDFOR 
****************************************************************
FUNCTION updateMember(tdAdjDate, tcOldCard, tcNewCard)

IF EMPTY(tdAdjDate) AND EMPTY(tcOldCard) AND EMPTY(tcNewCard)
	RETURN 
ENDIF 	
*
lcSQL = "UPDATE [cimsdb].[dbo].[member] SET "+;
	"[member].[cardno] = ?tcNewCard, "+;	
	"[member].[oldcardno] = ?tcOldCard, "+;
	"[member].[adjcarddate] = ?tdAdjDate "+;		
"WHERE [member].[cardno] = ?tcOldCard "
*
=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
	*
	DO updateSmgMember WITH tdAdjDate, tcOldCard, tcNewCard
	DO updateCard2natid WITH tdAdjDate, tcOldCard, tcNewCard
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions
RETURN lnSucess
***********************************
PROCEDURE updateSmgMember
PARAMETERS tdAdjDate, tcOldCard, tcNewCard

lcSQL1 = "UPDATE [cimsdb].[dbo].[smg_member] SET "+;
	"[smg_member].[cardid] = ?tcNewCard "+;
"WHERE [smg_member].[cardid] = ?tcOldCard"
*	
=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql1))
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions
*
RETURN lnSucess
*********************************************
PROCEDURE updateCard2Natid
PARAMETERS tdAdjDate, tcOldCard, tcNewCard

IF SEEK(tcOldCard, "card2natid", "cardno")
	m.cardno = tcNewCard
	m.policy_no = card2natid.policy_no
	m.policyid = card2natid.policyid
	m.natid = card2natid.natid
	REPLACE card2natid.expdate WITH tdAdjDate
	*
	IF !SEEK(tcNewCard, "card2natid", "cardno")
		INSERT INTO cims!card2natid (fundcode, cardno, issuedate, policy_no, policyid, natid, l_update) ;
		VALUES ("SMG", m.cardno, tdAdjDate, m.policy_no, m.policyid, m.natid, DATETIME())
	ENDIF
ENDIF