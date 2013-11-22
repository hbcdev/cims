#DEFINE CRLF CHR(13)+CHR(10)

SET SAFETY OFF 
SET DELETED ON 

IF !USED("uat")
	USE ? IN 0 ALIAS uat
ENDIF 	
*
SELECT result, COUNT(*) FROM uat GROUP BY 1 INTO CURSOR curUat
*
SELECT curUat
SCAN 
	DO genText WITH curUat.result
ENDSCAN
*USE IN curUat
******************************
*
PROCEDURE genText

PARAMETERS tcResult

IF EMPTY(tcResult)
	RETURN 
ENDIF 	

SELECT uat
tcResult = ALLTRIM(IIF(INLIST(LEFT(tcResult, 1), "D", "R"), LEFT(tcResult,1), tcResult))

lcPath = ADDBS(JUSTPATH(DBF("uat")))
lcFileName = STRTRAN(JUSTFNAME(DBF("uat")), "_", "")
lcNewFile = lcPath+STRTRAN(STRTRAN(STRTRAN(JUSTFNAME(DBF("uat")), "_", ""), "RETURN",tcResult), "DBF", "TXT")
lcFileName = ReplaceBlank(JUSTFNAME(lcNewFile), 20)
lcPayFileName = "hbcpaymentclaim.txt"
lcPayFileName = ReplaceBlank(lcPayFileName, 20)

lcDate = ChangeDateFormat(DATE())
lcTime = ChangeTimeFormat(DATETIME())

*Start
=STRTOFILE("01" + ReplaceBlank(lcFileName, 20) + ReplaceBlank(lcdate, 10) +ReplaceBlank(lctime, 10) + CRLF, lcNewFile, 0)
*
=STRTOFILE("01" + ReplaceBlank(lcPayFileName, 20) + ReplaceBlank(lcdate, 10) +ReplaceBlank(lctime, 10) + CRLF, lcPayFileName, 0)
*
STORE 0 TO lnReccount, lnTransation, lnPayRecCount, lnPayTransation
*
SELECT uat
SCAN FOR result = tcResult
	IF clmstatus <> "New"
		***********************************
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 20) + SPACE(17) + ReplaceBlank(delay_int, 17)
		*
		DO CASE 
		CASE clmstatus = "Reject"
			lcStr5 = ChangeDateFormat(rej_date) + LEFT(sus_reason,4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Suspend"
			lcStr5 = SPACE(10) + SPACE(4) + "01" + LEFT(sus_reason,6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Payment"
			lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		ENDCASE 
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + CRLF, lcPayFileName, 1)
		*		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		*
		IF clmstatus = "Payment"
			lcStr7 = "04" + ReplaceBlank(payee, 60) + ReplaceBlank(natid, 30) + SPACE(200) + SPACE(10) + ReplaceBlank(pay_type, 15) + ;
				ReplaceBlank(b_code, 40) + ReplaceBlank(b_branch, 200) + ReplaceBlank(total_amt, 17) + ReplaceBlank(b_accno, 15) + CRLF
			lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + CRLF
			=STRTOFILE(lcStr6 + lcStr7 + lcStr8, lcPayFileName, 1)		
		ELSE 
			lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF				
			=STRTOFILE(lcStr6 + lcStr8, lcPayFileName, 1)			
		ENDIF
		* 		
		lnPayTransation = lnPayTransation + 1
		lnPayRecCount = lnPayRecCount + 1	
	ELSE 
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 20) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		lcStr5 = ChangeDateFormat(rej_date) + SPACE(4) + SPACE(2) + LEFT(sus_reason,6) + ChangeDateFormat(sup_comp_d) + ReplaceBlank("HBC", 200)
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + CRLF, lcNewFile, 1)
		*		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		lcStr7 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
		*
		=STRTOFILE(lcStr6 + lcStr7, lcNewFile, 1)
		*		
		lnTransation = lnTransation + 1
		lnReccount = lnReccount + 1
	ENDIF 
ENDSCAN 
lnReccount = (lnReccount * 3) + 2
=STRTOFILE("09" + ReplaceBlank(lnReccount, 20, 0) + ReplaceBlank(lnTransation, 20, 0), lcNewFile, 1)
*
lnPayReccount = (lnPayReccount * 3) + 2
=STRTOFILE("09" + ReplaceBlank(lnPayReccount, 20, 0) + ReplaceBlank(lnPayTransation, 20, 0), lcPayFileName, 1)
=MESSAGEBOX("Transfer Result <"+tcResult+">Data Finish")
***************************************************
FUNCTION ChangeDateFormat(tdDate)
	IF EMPTY(tdDate)
		RETURN SPACE(10)
	ELSE 	
		RETURN  STR(YEAR(tdDate),4)+"-"+STRTRAN(STR(MONTH(tdDate),2), " ", "0")+"-"+STRTRAN(STR(DAY(tdDate),2), " ", "0")
	ENDIF 	
ENDFUNC 
*
FUNCTION ChangeTimeFormat(tdDateTime)
	IF EMPTY(tdDateTime)
		RETURN SPACE(10)
	ELSE 	
		RETURN STRTRAN(STR(HOUR(tdDateTime),2)," ","0")+"-"+STRTRAN(STR(MINUTE(tdDateTime),2)," ","0")+"-"+STRTRAN(STR(SEC(tdDateTime),2)," ","0")
	ENDIF 	
ENDFUNC 
*
FUNCTION ReplaceBlank(tcText, tnSize, tnDecimal)
	IF PARAMETERS() = 2
		tnDecimal = 2
	ENDIF 	
	lcRetValue = SPACE(tnSize)
	DO CASE 
	CASE TYPE("tcText") $ "NYI"	
		lcRetValue = ALLTRIM(STR(tcText, tnSize, tnDecimal))
		lcRetValue = lcRetValue + REPLICATE(" ", tnSize-LEN(lcRetValue))
	CASE TYPE("tcText") = "C"
		lcRetValue = ALLTRIM(tcText)
		IF LEN(lcRetValue) > tnSize
			lcRetValue = LEFT(lcRetValue, tnSize)
		ELSE 			
			lcRetValue = lcRetValue + REPLICATE(" ", tnSize-LEN(lcRetValue))
		ENDIF 	
	ENDCASE 
	RETURN lcRetValue
ENDFUNC 