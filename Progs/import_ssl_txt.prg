lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
llExp = AT("EXP", UPPER(lcDbf)) <> 0
llAdj = AT("ADJ", UPPER(lcDbf)) <> 0
ldDate = CTOD(LEFT(RIGHT(lcDbf, 12),2)+"/"+SUBSTR(RIGHT(lcDbf, 12),3,2)+"/"+SUBSTR(RIGHT(lcDbf, 12),5,4))
*************************************
SET HOURS TO 24
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 
*	
SELECT 0
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan_type C(1), Plan C(20), Cust_id C(20), Title C(20), Name C(40), Surname C(40), Sex C(1), Dob D, Age I, ;
	Discrict C(40), Province C(40), Country C(30), Postcode C(5), Telephone C(30), Pol_date T, Eff_date T, Exp_date T, Premium Y, Premium_I C(18), Premium_O C(18), ;
	Exclusion C(254), Agent C(20), Agency C(20), Pay_mode C(2), Renew N(1), Polstatus C(1),  Payer C(50), Medical Y, HB_limit Y, EndoNo C(30), EndDate D, EndType C(2), ;
	Paiddate D, ReinDate D, LapseDate D, Cancdate D, Adddate D, adjcancel D, adjlapse D, note V(100))
*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(",",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(",",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')
		laData[j] = IIF(laData[j] = "NULL", "", laData[j])
		DO CASE
		CASE INLIST(j ,9, 16, 17, 18)
			laData[j] = SUBSTR(laData[j], 9,2)+"/"+SUBSTR(laData[j], 6, 2)+"/"+LEFT(laData[j], 4)
			laData[j] = CTOD(laData[j])
			IF !EMPTY(laData[j])
				IF INLIST(j, 16, 17, 18)
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 00)
				ENDIF
			ENDIF
		CASE INLIST(j , 32, 34, 35, 36, 37)
			IF EMPTY(laData[j])
				laData[j] = {}
			ELSE 	
				laData[j] = SUBSTR(laData[j], 7, 2)+"/"+SUBSTR(laData[j], 5, 2)+"/"+LEFT(laData[j], 4)
				laData[j] = CTOD(laData[j])
			ENDIF 	
		ENDCASE
		*
		IF j = 38
			laData[j] = ldDate
		ENDIF
		*	
		IF llExp
			DO CASE 
			CASE laData[27] = "L"
				laData[18] = laData[36]
				laData[40] = ldDate				
			CASE laData[27] = "C"
				laData[18] = laData[37]
				laData[39] = ldDate
			ENDCASE 	
		ENDIF 	
		IF llAdj
			laData[17] = IIF(EMPTY(laData[35]), laData[17], laData[35])
			laData[40] = IIF(EMPTY(laData[35]), {}, ldDate)
			laData[41] = "กรุณาติดต่อสอบถามกับ SSL ก่อนทำจ่าย เนื่องจากเป็นกรมธรรม์ Reinstate ทาง SSL ยังไม่ยืนยัน Effective Date"
		ENDIF
		*
		IF AT(",",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(",",lcTemp)+1)
		ENDIF
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 