lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
?lcSourceFile
lnSelect = SELECT()
IF FILE(ADDBS(DATAPATH)+"smg_endos.dbf")
	USE (ADDBS(DATAPATH)+"smg_endos.dbf") IN 0
ELSE 	
	CREATE DBF (ADDBS(DATAPATH)+"smg_endos.dbf") FREE (Policy_no V(30), Title V(20), Name V(40), Surname V(40), ;
	Effdate T, Expdate T, endosno V(30), reportdate D, edeffdate T, edexpdate T, premium Y, ;
	refno V(30), personcode I, grptype V(20), lotno V(20), polstatus V(1), l_update T, filename V(100))		
ENDIF 
*	
CREATE CURSOR curEndos (Policy_no C(30), Title C(20), Name C(40), Surname C(40), ;
	Effdate T, Expdate T, endosno C(30), reportdate D, edeffdate T, edexpdate T, premium Y, ;
	refno C(30), personcode I, grptype C(20), lotno C(20), polstatus C(1), l_update T, filename V(100))
*	
SELECT curEndos
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 5, 6, 8, 9, 10)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 5, 6, 9, 10)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE j = 11
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[16] = RIGHT(ALLTRIM(laData[7]), 1)
	laData[17] = DATETIME()
	laData[18] = JUSTFNAME(lcSourceFile)
	INSERT INTO curEndos FROM ARRAY laData
	INSERT INTO (ADDBS(DATAPATH)+"smg_endos.dbf") FROM ARRAY laData
ENDFOR 
BROWSE
************************
IF MESSAGEBOX("ต้องการอัพเดทข้อมูลเข้าระบบ หรือไม่",4+32+256,"Comfrim") = 7
	RETURN 
ENDIF 
*	
lnConn = gnConn &&SQLCONNECT("CimsDB")
IF lnConn <=0
	=MESSAGEBOX("Cannot connect to SQL Server Please Contact Database Administrator",0)
	RETURN 
ENDIF
*
lnUpdate = 0
IF FILE("smg_endos_error.txt")
	DELETE FILE "smg_endos_error.txt"
ENDIF 	
SELECT curEndos
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR 
	IF updateToMember() = 1
		lnUpdate = lnUpdate + 1
	ELSE 
		lcError = ALLTRIM(m.policy_no)+" "+ALLTRIM(m.name)+" "+ALLTRIM(m.surname)+" "+ALLTRIM(STR(m.personcode))+CHR(13)
		=STRTOFILE(lcError, "smg_endos_error.txt", .T.)		
	ENDIF 
ENDSCAN
lcError = "Update: "+TRANSFORM(lnUpdate, "@Z 99,999")+"/"+TRANSFORM(RECCOUNT(), "@Z 999,999")+" Records"
=MESSAGEBOX(lcError, 0, "SMG Endos")
MODIFY FILE "smg_endos_error.txt" NOEDIT  
=SQLDISCONNECT(lnConn)
*****************************************************************
FUNCTION UpdateToMember

lcCustId = ALLTRIM(STR(m.personcode))
ldUpdate = DATETIME()
lcSql = "UPDATE [cimstest].[dbo].[member] SET " +;
	"[polstatus] = 'C', [expiry] = ?m.edeffdate, [oldeffective] = ?m.effdate, "+;
	"[oldexpiry] = ?m.expdate, [adjcancel] = ?m.reportdate, "+;
	"[canceldate] = ?m.edeffdate, [l_users] = ?gcUserName, [l_update] = ?ldUpdate "+;
	"WHERE [fundcode] = 'SMG' "+;
	"AND [policy_no] = ?m.policy_no AND [customer_id] = ?lcCustID "
		
=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions
RETURN lnSucess	
**************************************************