PUBLIC gcFundCode, ;
	gdStartDate, ;
	gdEndDate, ;
	gcSaveTo, ;
	gnOption
********************	
gcFundCode = "BUI"
gdEndDate = DATE()
gdStartDate = DATE(YEAR(gdEndDate), MONTH(gdEndDate), 1)
gnOption = 1
gcSaveTo = ADDBS(gcTemp)
DO FORM form\dateentry1
IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	RETURN 
ENDIF
*****************************
DO CASE
CASE gnOption = 1
	lcOption = "TO PRINTER PROMPT NOCONSOLE"
CASE gnOption = 3
OTHERWISE 
	lcOption = "TO PRINTER PROMPT PREVIEW NOCONSOLE"
ENDCASE 
IF FILE(gcReportPath+"member_expried.frx")
	REPORT FORM (gcReportPath+"member_expried") &lcOption
ENDIF 	
