#DEFINE CRLF CHR(13)+CHR(10)

SET SAFETY OFF 
SET DELETED ON 

IF !USED("uat")
	USE ? IN 0 ALIAS uat
ENDIF 	
lcPath = ADDBS(JUSTPATH(DBF("uat")))
lcDate = ChangeDateFormat(DATE())
lcTime = ChangeTimeFormat(DATETIME())
STORE 0 TO lnNew, lnP1, lnP5, lnD
*
DO genTypeNew
DO genText
*
=MESSAGEBOX("Claim Upload is:"+CHR(13) +;
		"P1 = "+TRANSFORM(lnP1, "@Z 9,999")+CHR(13)+;
		"P5 = "+TRANSFORM(lnP5, "@Z 9,999")+CHR(13)+;
		"D = "+TRANSFORM(lnD, "@Z 9,999")+CHR(13)+;
		"Total = "+TRANSFORM(lnNew, "@Z 9,999")+CHR(13),0+64,"Infomation")
*USE IN curUat
******************************
*
PROCEDURE genText

SELECT uat
lcFileName = ADDBS(lcPath) + "Claim_Payment.txt"
lcFileName1 = "CLAIM_PAYMENT.TXT"
*Start
=STRTOFILE("01" + ReplaceBlank(lcFileName1, 20) + ReplaceBlank(lcDate, 10) +ReplaceBlank(lcTime, 10) + CRLF, lcFileName, 0)
*
STORE 0 TO lnReccount, lnTransation
*
SELECT uat
SCAN
	DO CASE 
	CASE clmstatus = "Payment"
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)				
		lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF		
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + SPACE(23) + ReplaceBlank(total_amt, 17) + CRLF
		lcStr7 = "04" + ReplaceBlank(payee, 60) + ReplaceBlank(natid, 30) + ;
			ReplaceBlank(payee_addr, 200) + ReplaceBlank(payee_post, 10) + ReplaceBlank(pay_type, 15) + ;
			ReplaceBlank(b_code, 40) + ReplaceBlank(b_branch, 200) + ReplaceBlank(total_amt, 17) + ReplaceBlank(b_accno, 15) + ;
			ReplaceBlank(payee_t, 2) + CRLF
		lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + CRLF
		*
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr7 + lcStr8, lcFileName, 1)
		* 		
		lnTransation = lnTransation + 4
	OTHERWISE 
		lcStr1 = "02" + ReplaceBlank(clmstatus, 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
		lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
		lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
		lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
		DO CASE 
		CASE clmstatus = "Reject"
			lcStr5 = ChangeDateFormat(rej_date) + LEFT(sus_reason,4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		CASE clmstatus = "Suspend"
			lcStr5 = SPACE(10) + SPACE(4) + "01" + LEFT(sus_reason,6) + SPACE(10) + ReplaceBlank("HBC", 200)		
		ENDCASE 
		lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF
		lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + CRLF
		lcStr8 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
		=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr8 , lcFileName, 1)		
		* 		
		lnTransation = lnTransation + 3
	ENDCASE 
	lnP1 = lnP1 + IIF(result = "P1", 1, 0)
	lnP5 = lnP5 + IIF(result = "P5", 1, 0)
	lnD = lnD + IIF(result = "D", 1, 0)	
ENDSCAN 
=STRTOFILE("09" + ReplaceBlank(lnTransation, 20, 0) + ReplaceBlank(RECCOUNT("uat"), 20, 0), lcFileName, 1)
=MESSAGEBOX("Transfer Claim Payment Data Finish")
***************************************************
PROCEDURE genTypeNew


lcFileName1 = "CLAIM_NEW.TXT"
lcFileName = ADDBS(lcPath) + "CLAIM_NEW.TXT"
=STRTOFILE("01" + ReplaceBlank(lcFileName1, 20) + ReplaceBlank(lcDate, 10) +ReplaceBlank(lcTime, 10) + CRLF, lcFileName, 0)
STORE 0 TO lnReccount, lnTransation
SELECT uat
GO TOP 
SCAN
	lcStr1 = "02" + ReplaceBlank("New", 10) + ReplaceBlank(claim_no, 30) + LEFT(policy_no, 17) + ReplaceBlank(ALLTRIM(LEFT(name,AT(" ",name))), 60)		
	lcStr2 = ReplaceBlank(ALLTRIM(SUBSTR(name,AT(" ",name))),60) + ReplaceBlank(natid, 20) + ReplaceBlank("Self", 60) 
	lcStr3 = ChangeDateFormat(summitted) + ChangeDateFormat(eventdate) + category + class1 + class2 + class3
	lcStr4 = ReplaceBlank(hospid, 32) + ReplaceBlank(hospname, 100) + ReplaceBlank(diagnosis, 60) + ReplaceBlank(remark, 510) + ReplaceBlank(total_amt, 17) + ReplaceBlank(delay_int, 17)
	lcStr5 = SPACE(10) + SPACE(4) + SPACE(2) + SPACE(6) + SPACE(10) + ReplaceBlank("HBC", 200)		
	lcStr026 = ReplaceBlank(diags2, 20) + ReplaceBlank(diags2, 10) + ReplaceBlank(proc1, 10)+ ReplaceBlank(proc2, 10)+ ReplaceBlank(proc3, 10) + CRLF
	*
	lcStr6 = "03" + ReplaceBlank(prodcode, 16) + ReplaceBlank(covercode, 30) + ReplaceBlank(natid, 30) + ReplaceBlank(claim_amt, 17) + ;
		ReplaceBlank(" ", 10) + ReplaceBlank(" ", 10) + ReplaceBlank(" ", 3) + CRLF
	lcStr7 = "08" + ReplaceBlank("1", 20) + ReplaceBlank("1", 20) + ReplaceBlank("0", 20) + CRLF
	*
	=STRTOFILE(lcStr1 + lcStr2 + lcStr3 + lcStr4 + lcStr5 + lcStr026 + lcStr6 + lcStr7 , lcFileName, 1)
	*		
	lnNew = lnNew + 1
	lnTransation = lnTransation + 3	
ENDSCAN 
=STRTOFILE("09" + ReplaceBlank(lnTransation, 20, 0) + ReplaceBlank(RECCOUNT("uat"), 20, 0), lcFileName, 1)
=MESSAGEBOX("Transfer Claim New Data Finished")
ENDPROC 
********************************************************
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