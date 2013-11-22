lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 
*	
IF !FILE(ADDBS(DATAPATH)+"smg_endos.dbf")
	CREATE DBF (ADDBS(DATAPATH)+"smg_endos.dbf") FREE (Policy_no V(30), title V(20), name V(40), surname V(40), Eff_date T, Exp_date T, endorse V(50), reportdate D, effdate_ed T, expdate_ed T, ;
		Totalprem Y, refno V(50), personcode I, grptype C(1), lotno V(20), prodno I, locno I, itemno I, polstatus C(1), filename V(100))	
ENDIF 		
*
SELECT 0	
CREATE DBF (lcDbf) FREE (Policy_no C(30), title V(20), name V(40), surname V(40), Eff_date T, Exp_date T, endorse C(30), reportdate D, effdate_ed T, expdate_ed T, ;
	Totalprem Y, refno C(30), personcode I, grptype C(1), lotno C(20), prodno I, locno I, itemno I, polstatus C(1), filename v(50))	
*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()-2
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j ,5, 6, 8, 9, 10)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF EMPTY(laData[j])
				laData[j] = {}
			ELSE 
				IF j # 9	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 16, 00)
				ENDIF 	
			ENDIF 	
		CASE INLIST(j ,11,13,16,17,18)
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE  	
		*
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[19] = IIF(RIGHT(ALLTRIM(laData[7]),1)= "A", "A", "C")
	laData[20] = JUSTFNAME(lcSourceFile)
	*
	INSERT INTO (lcdbf) FROM ARRAY laData
	*
	INSERT INTO (ADDBS(DATAPATH)+"smg_endos.dbf")	 FROM ARRAY laData
ENDFOR 
BROWSE 
IF MESSAGEBOX("ต้องการให้นำเข้า SQL Server หรือไม่",4+32+256,"Info") = 6
	SCAN 
		IF update2Member() = 1
		
		ENDIF
ENDIF 
USE 
*****************************************************************
FUNCTION UpdateToMember

lcSql = "UPDATE [cimstest].[dbo].[member] SET [policy_no] = ?laData[1], [plan] = ?laData[2], [natid] = ?laData[3], "+;
	"[title] = ?laData[4], [name] = ?laData[5], [surname] = ?laData[6], [sex] = ?laData[7], [birth_date] = ?laData[8], "+;
	"[age] = ?laData[9], [h_addr1] = ?laData[10], [h_addr2] = ?laData[11], [h_city] = ?laData[12], [h_province] = ?laData[13], "+;
	"[h_country] = ?laData[14], [h_postcode] = ?laData[15], [h_phone] = ?laData[16], [policy_date] = ?laData[17], [effective] = ?laData[18], "+;
	"[expiry] = ?laData[19], [agent] = ?laData[20], [agency] = ?laData[21], [me_cover] = ?laData[22], [premium] = ?laData[23], "+ ;
	"[adddate] = ?laData[25], [customer_id] = ?lcCustID, [package] = ?laData[28], [branch_code] = ?laData[29], [l_submit] = ?laData[30], "+;
	"[no_of_pers] = ?laData[33], [policy_name] = ?laData[37], [polstatus] = ?laData[42], [old_policyno] = ?laData[43], [plan_id] = ?laData[44], "+;
	[cardno] = ?laData[45], [quotation] = ?laData[47], [l_update] = ?laData[48], [customer_type] = ?lcCustType, [effective_y] = ?laData[18], [expried_y] = ?ltExpY "+;
	"WHERE policy_no = ?laData[1] AND customer_id = ?lcCustType"

=SQLSETPROP(lnConn,"Transactions", 2) && Manual transaction	
lnSucess = SQLEXEC(lnConn, (lcSql))	
IF lnSucess < 0
	= SQLROLLBACK(lnConn) && Rollback insert record
ELSE
	= SQLCOMMIT(lnConn)  && Commit the changes
ENDIF
= SQLSETPROP(lnConn, 'Transactions', 1)  && Auto transactions

RETURN lnSucess	
*****************************************************************
