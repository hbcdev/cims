PUBLIC gcFundCode,;
	gdStartDate,;
	gdEndDate,;
	gnGroupBy,;
	gnPrintTo
	
gcFundCode = ""
STORE 0 TO gnGroupBy, gnPrintTo
STORE DATE() TO gdStartDate, gdEnddate
DO FORM form\getdate
IF EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN
ENDIF
*************************
lcFileName = "\\HBCNT\REPORT\"+m.cFundcode+"ClaimByAgent_"+STR(m.nYear,4)+ALLTRIM(STR(m.nMonth,2))
IF _TALLY > 1
	DO CASE
	CASE gnPrintTo = 1
		REPORT FORM (gcReportPath+"claimbyagent.frx") PREVIEW NOCONSOLE
	CASE gnPrintTo = 2
		REPORT FORM (gcReportPath+"claimbyagent.frx") TO PRINTER PROMPT NOCONSOLE
	CASE gnPrintTo = 3
		DO progs\Agent2xls
	ENDCASE 		
ELSE
	=MESSAGEBOX("ไม่พบรายการเคลมของ "+M.cFundCode+" ในเดือน"+TMonth(M.nMonth)+" ปี "+M.nYear, 0, "Error")
ENDIF