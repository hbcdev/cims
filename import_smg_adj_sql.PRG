CLEAR 
*SET PROCEDURE TO progs\utility
SET DEFAULT TO ?
OPEN DATABASE ("D:\Database\Hips\Data\cims.dbc")

IF !USED("adj_card")
	USE "D:\Database\Hips\Data\Smg_Adj_Card.dbf" IN 0 ALIAS adj_card
ENDIF 	

lnConn = SQLCONNECT("CimsDb")
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF

lnAmountFiles = ADIR(laSmg, "*.TXT")
IF lnAmountFiles > 0
	IF FILE("error_adj_card.txt")
		DELETE FILE error_adj_card.txt
	ENDIF 
	*
	IF !USED("card2natid")
		USE cims!card2natid IN 0
	ENDIF 	
	
	*FOR lnFile = 1 TO lnAmountFiles
	*	DO ConvertData WITH laSmg[lnFile, 1]
	*ENDFOR
	
	lcFile = GETFILE("TXT")
	DO convertData WITH lcFile
	
	=SQLDISCONNECT(lnConn)
ENDIF 
*******************************
PROCEDURE ConvertData
PARAMETERS lcDataFile

IF AT("ADJ", UPPER(lcDataFile)) = 0
	=MESSAGEBOX("เลือกไฟล์ที่ใช้อัพเดทผิด", 0)
	RETURN 
ENDIF 
*
?lcDataFile
lcErrorFile = JUSTPATH(lcDataFile)+"\Error\"+STUFF(JUSTFNAME(lcDataFile),AT(".",JUSTFNAME(lcDataFile)),0,"_NO_NATID")
lcSqlErrorFile = JUSTPATH(lcDataFile)+"\Error\sql_error.txt"

SELECT filename, COUNT(*) FROM adj_card WHERE filename = lcDataFile AND !EMPTY(filename) GROUP BY filename INTO ARRAY laFileName
IF _TALLY > 0	
	lcMsg = lcDataFile+" มีการอัพโหลดเข้าระบบไปแล้ว จำนวน "+TRANSFORM(laFileName[2],"@Z 99,999")+" records "+CHR(13)
	=STRTOFILE(lcMsg, "error_update.txt",1)
	RETURN 
ENDIF 
*
SELECT adj_card
lcDate = LEFT(RIGHT(ALLTRIM(lcDataFile),12),8)
ldDate = CTOD(SUBSTR(lcDate,1,2)+"/"+SUBSTR(lcDate,3,2)+"/"+RIGHT(lcDate,4))
*****************************************************************
STORE 0 TO lnNew, lnUpdate, lnNoNat
lnFieldCounts = 6
DIMENSION laData[9]
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
				laData[i] = CTOT(laData[i])
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
		IF AT(";",lcTemp) = 0
			lcTemp = ""
		ELSE 	
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF
	ENDFOR
	*******************************************		
	laData[5] = IIF(EMPTY(laData[5]), ldDate, ldDate)
	laData[7] = JUSTFNAME(lcDataFile)
	laData[8] = DATETIME()
	laData[9] = laData[6]+SUBSTR(laData[3], 13, 4)

	SELECT adj_card	
	IF !EMPTY(laData[1]) OR !EMPTY(laData[2])
		IF EMPTY(laData[6])
			lnNoNat = lnNoNat + 1
			lcError = laTextArray[j]+"|ไม่พบเลขบัตรประชาชน"+CHR(13)
			=STRTOFILE(lcError, lcErrorFile, 1)
		ELSE 		
			lcCard = laData[6] +  SUBSTR(laData[2], 13, 4)		
			IF SEEK(laData[9], "adj_card", "nat4cardno")
				REPLACE adj_card.fundcode  WITH "SMG", adj_card.adjdate WITH  laData[1], ;
				adj_card.oldcard WITH laData[2], adj_card.newcard WITH laData[3], ;
				adj_card.importd WITH  laData[5], adj_card.filename WITH laData[7]
			ELSE 	
				INSERT INTO adj_card (fundcode, adjdate, oldcard, newcard, importd, natid, filename, nat4cardno) ;
					VALUES ("SMG", laData[1], laData[2], laData[3], laData[5], laData[6], laData[7], laData[9])					
			ENDIF 	
			*
			lnRetVal = updateMember(laData[1], laData[2], laData[3], laData[6])
			IF lnRetVal = 1
				lnUpdate = lnUpdate + 1
				WAIT WINDOW TRANSFORM(lnUpdate, "@Z 999,999") AT 25,30 NOWAIT 	
			ENDIF 	
		ENDIF 	
	ENDIF
ENDFOR 
lcMsg = lcDataFile + " Total Update : "+TRANSFORM(lnUpdate, "@Z 999,999")+" Total No Nat ID : "+TRANSFORM(lnNoNat, "@Z 999,999")+CHR(13) 	
=STRTOFILE(lcMsg, "update_log.txt",1)
****************************************************************
FUNCTION updateMember(tdAdjDate, tcOldCard, tcNewCard, tcNatId)

IF EMPTY(tdAdjDate) AND EMPTY(tcOldCard) AND EMPTY(tcNewCard)
	RETURN 
ENDIF 	
*
SELECT adj_card
tcNatId = IIF(ISNULL(tcNatId), '',tcNatid)
DO updateCard2natid WITH tdAdjDate, tcOldCard, tcNewCard, tcNatId

IF llDEBUG
	SUSPEND 	
ENDIF 	
	
lcCardx = STUFF(tcOldCard, 7, 6, "xxxxxx")
lcSQL = "UPDATE [cimsdb].[dbo].[member] SET "+;
	"[member].[cardno] = ?tcNewCard, "+;	
	"[member].[oldcardno] = ?tcOldCard, "+;
	"[member].[adjcarddate] = ?tdAdjDate "+;		
"WHERE ([member].[cardno] = ?lcCardx OR [member].[cardno] = ?tcOldCard) AND [member].[natid] = ?tcNatId"
*
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	=AERROR(laSqlError)
	=STRTOFILE("Member|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(10)+CHR(13),lcSqlErrorFile,1)
ELSE
	DO updateSmgMember WITH tdAdjDate, tcOldCard, tcNewCard, tcNatId
ENDIF
RETURN lnSucess
***********************************
PROCEDURE updateSmgMember
PARAMETERS tdAdjDate, tcOldCard, tcNewCard, tcNatId

lcSQL1 = "UPDATE [cimsdb].[dbo].[smg_member] SET "+;
	"[smg_member].[cardid] = ?tcNewCard "+;
"WHERE [smg_member].[cardid] = ?tcOldCard AND [smg_member].[cust_id] = ?tcNatId"
*	
lnSucess = SQLEXEC(lnConn, (lcSql1))
IF lnSucess < 1
	=AERROR(laSqlError)
	=STRTOFILE("SMG_Member|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(10)+CHR(13),lcSqlErrorFile,1)		
ENDIF
*
RETURN lnSucess
*********************************************
PROCEDURE updateCard2Natid
PARAMETERS tdAdjDate, tcOldCard, tcNewCard, tcNatId

* get amount change
lnSeqNo = 0
IF SEEK(tcNatId, "card2natid", "natid")
	DO WHILE natid = tcNatId AND !EOF()
		lnSeqNo = lnSeqNo + 1
		SKIP 
	ENDDO 
ELSE 
	lnSeqNo = 1	
ENDIF 		
********************************************
*find policy in member table
STORE '' TO lcPolicyNo, lcPolicyid
lnSelect = SELECT()
lcSql = "SELECT policy_no, policyid FROM cimsdb.dbo.member WHERE fundcode = 'SMG' AND natid = ?tcNatId AND cardno = ?tcOldCard AND effective <= ?tdAdjDate AND expiry >= ?tdAdjDate"
lnSuscess = SQLEXEC(lnConn, lcSql, "_curPol",laSql)
IF lnSuscess = 1
	IF laSql[2] >= 0
		lcPolicyNo = _curPol.policy_no
		lcPolicyId = _curPol.policyid
	ELSE 
		=AERROR(laSqlError)
		=STRTOFILE("Card2Natid|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(10)+CHR(13),lcSqlErrorFile,1)		
	ENDIF 	
ELSE 
	=AERROR(laSqlError)
	=STRTOFILE("Card2Natid|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(10)+CHR(13),lcSqlErrorFile,1)
ENDIF 	
IF USED("_curPol")
	USE IN _curPol
ENDIF 	
SELECT (lnSelect)
******************************************************************
lcCard = tcNatId + SUBSTR(tcOldCard,13,4)
IF SEEK(lcCard, "card2natid", "nat4cardno")
	REPLACE card2natid.expdate WITH tdAdjDate, card2natid.l_update WITH  DATETIME()
ELSE 	
	INSERT INTO cims!card2natid (fundcode, natid, seqno, cardno, issuedate, policy_no, policyid, l_update, nat4cardno) ;
		VALUES ("SMG", tcNatID, lnSeqNo, tcNewCard, tdAdjDate, lcPolicyNo, lcPolicyid, DATETIME(), lcCard)				
ENDIF 

* Insert or Update to SQL
lcSql = "UPDATE [cimsdb].[dbo].[card2natid] SET [expdate] = ?tdAdjDate, [l_update] = ?ldDate WHERE [natid] = ?tcNatId AND [cardno] = ?tcOldCard"
lnSuscess = SQLEXEC(lnConn, lcSql, laSql)
IF lnSuscess < 1
	=AERROR(laSqlError)
	=STRTOFILE("Card2Natid|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(13),lcSqlErrorFile,1)
ENDIF 	

*Add New card to table
ldDate = DATETIME()
STORE null TO lcPolicyNo, lcPolicyid
*lcSql = "{call sp_insert_card2natid('SMG', ?tcNatID, 1, ?tcNewCard, ?tdAdjDate, null, ?lcPolicyNo, ?lcPolicyid, ?ldDate)}"
lcSql = "INSERT INTO cimsdb.dbo.card2natid (fundcode, natid, seqno, cardno, issuedate, policy_no, policyid, l_update, nat4cardno) ;
		VALUES ('SMG', tcNatID, lnSeqNo, tcNewCard, tdAdjDate, lcPolicyNo, lcPolicyid, DATETIME(), lcCard)"				
lnSuscess = SQLEXEC(lnConn, lcSql)
IF lnSuscess < 1
	=AERROR(laSqlError)
	=STRTOFILE("Card2Natid|" + tcNewcard+"|"+tcNatid+"|"+laSqlError[3]+CHR(10)+CHR(13),lcSqlErrorFile,1)
ENDIF 	