llClosePlan = .F.

IF !USED("plan")
	USE cims!plan IN 0
	llClosePlan = .T.
ENDIF 	

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
SELECT 0	
lnSelect = SELECT()
CREATE DBF (lcDbf) FREE (group_no C(20), acc_name C(50), employee C(50), nric C(20), ins_dob D, sex C(1), ;
	staff_num C(20), dep_cost C(50), Eff_date T, term_date T, reserved C(20), dep_name C(50), dep_rela C(20), ;
	dep_nric C(20), dep_dob D, plan_code C(15), bankcode C(4), bank_br C(3), bank_acc C(20), emp_new C(50), ;
	dep_new C(50), deductible Y, insure C(50), policy_no C(30), cardno C(25), dob D, plan_id C(8), exp_date T, ;
	firstname C(50), surname C(50))
	*
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))-1
lnFieldCounts = FCOUNT()-6
*
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(CHR(9),lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(CHR(9),lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 5, 9, 10, 15)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			laData[j] = ConvertDate(laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 9, 10, 28)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 00)					
				ENDIF 	
				IF j = 10
					IF EMPTY(laData[j])					
						laData[28] = {}
					ELSE 
						laData[28] = laData[j]
					ENDIF 	
				ENDIF 				
			ENDIF 	
		CASE j = 16
			laData[j] = UPPER(laData[j])	
		CASE j = 22
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(CHR(9),lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(CHR(9),lcTemp)+1)
		ENDIF 	
	ENDFOR 
	************************************
	IF EMPTY(laData[12]	)
		laData[23] = laData[3]
		laData[24] = laData[4]
		laData[26] = laData[5]		
	ELSE 
		laData[23] = laData[12]
		laData[24] = laData[14]
		laData[26] = laData[15]		
	ENDIF 				
	************************************
	IF !EMPTY(laData[20]) && Employee New ID
		laData[24] = laData[20]
	ENDIF 
	*
	IF !EMPTY(laData[21]) && Dependants New ID
		laData[24] = laData[21]	
	ENDIF 	
	laData[25] = ALLTRIM(laData[1]) + SUBSTR(laData[24], 3, 1) + RIGHT(ALLTRIM(laData[24]), 4)
	laData[25] = laData[25] + GenLuhn(laData[25])
	laData[28] = IIF(EMPTY(laData[28]), GOMONTH(DATETIME(VAL("25"+RIGHT(LEFT(laData[24],6),2))-543, MONTH(laData[9]), DAY(laData[9])),12)-1, laData[28])		
	laData[29] = ALLTRIM(SUBSTR(laData[23], AT(" ", laData[23])))
	laData[30] = LEFT(ALLTRIM(laData[23]), AT(" ", ALLTRIM(laData[23])))	
	*
	IF SEEK(LEFT(laData[16],20), "plan", "title")
		laData[27] = plan.plan_id
	ENDIF 	
	*
	IF !checkLuhn(laData[25]) 
		laData[25] = ""
	ENDIF 	
	*		
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE
**********************
FUNCTION ConvertDate(tcDate)

IF EMPTY(tcDate)
	RETURN {}
ENDIF 


lcDay = LEFT(tcDate,2)
lcMonth = ICASE(SUBSTR(tcDate,4,3) = "JAN", "01", SUBSTR(tcDate,4,3) = "FEB", "02", SUBSTR(tcDate,4,3) = "MAR", "03", ;
	SUBSTR(tcDate,4,3) = "APR", "04", SUBSTR(tcDate,4,3) = "MAY", "05", SUBSTR(tcDate,4,3) = "JUN", "06", ;
	SUBSTR(tcDate,4,3) = "JUL", "07", SUBSTR(tcDate,4,3) = "AUG", "08", SUBSTR(tcDate,4,3) = "SEP", "09", ;
	SUBSTR(tcDate,4,3) = "OCT", "10", SUBSTR(tcDate,4,3) = "NOV", "11", SUBSTR(tcDate,4,3) = "DEC", "12", "00") 
lcYear = RIGHT(tcDate,4)

ldDate = CTOD(lcDay+"/"+lcMonth+"/"+lcYear	)

RETURN ldDate

**********************************
FUNCTION GenLuhn(tcCardNo)

LOCAL i 

IF EMPTY(tcCardNo)
	RETURN ""
ENDIF 	
lnLuhn = 0
lnCheckDigit = ""
FOR i = 1 TO 15
	STORE 0 TO lnDigit1, lnDigit2
	IF INLIST(i, 1, 3, 5, 7, 9, 11, 13, 15)
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1)) * 2
		IF lnDigit > 9
			lnDigit1 = lnDigit - 9
		ELSE 
			lnDigit1 = lnDigit	
		ENDIF 	
	ELSE 
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1))
		lnDigit2 = lnDigit	
	ENDIF 
	lnLuhn = lnLuhn + (lnDigit1 + lnDigit2)
ENDFOR
lnCheckDigit = MOD(10 - MOD(lnLuhn, 10), 10)
RETURN ALLTRIM(STR(lnCheckDigit))
****
*
FUNCTION CheckLuhn(tcCardNo)

LOCAL i

IF EMPTY(tcCardNo)
	RETURN .F.
ENDIF 	
lnLuhn = 0
lnCheckDigit = ""
FOR i = 16 TO 1 STEP -1
	STORE 0 TO lnDigit1, lnDigit2
	IF INLIST(i, 1, 3, 5, 7, 9, 11, 13, 15)
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1)) * 2
		IF lnDigit > 9
			lnDigit1 = lnDigit - 9
		ELSE 
			lnDigit1 = lnDigit	
		ENDIF 	
	ELSE 
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1))
		lnDigit2 = lnDigit	
	ENDIF 
	lnLuhn = lnLuhn + (lnDigit1 + lnDigit2)
ENDFOR
RETURN MOD(lnLuhn, 10) = 0