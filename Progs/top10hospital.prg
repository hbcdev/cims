#INCLUDE "include\excel9.h"

gdStartDate = {^2005-01-01}
gdEndDate = {^2007-12-31}
*
SELECT claim.illness1, ;
COUNT(*) AS ipdCnt, ;
SUM(IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)) AS ipdPaid, ;
COUNT(DISTINCT client_name) AS claimant ;
FROM cims!claim ;
WHERE 	 claim.fundcode = gcFundCode ;
	AND claim.policy_no = gcPolicyNo ;
	AND claim.service_type # "IPD" ;
	AND return_date BETWEEN gdStartDate AND gdEndDate ;
	AND claim.result LIKE "P%" ;		
GROUP BY  claim.illness1 ;
ORDER BY 3 DESC ;
INTO CURSOR curDisease


PROCEDURE icd2hosp
*
SELECT curDisease
SCAN 
	SELECT TOP 10 claim.prov_name, ;
	COUNT(*) AS ipdCnt, ;
	SUM(IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)) AS ipdPaid ;
	FROM cims!claim ;
	WHERE 	 claim.service_type = "IPD" ;
		AND return_date BETWEEN gdStartDate AND gdEndDate ;
		AND claim.result LIKE "P%" ;		
		AND illness1 = curDisease.illness1 ;
	GROUP BY  claim.prov_name ;
	ORDER BY 2 DESC ;
	INTO CURSOR ("curIPD"+ALLTRIM(STR(RECNO())))
ENDSCAN 	
*
SELECT TOP 10 claim.illness1, ;
COUNT(*) AS ipdCnt, ;
SUM(IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)) AS ipdPaid ;
FROM cims!claim ;
WHERE 	 claim.service_type = "OPD" ;
	AND return_date BETWEEN gdStartDate AND gdEndDate ;
	AND claim.result LIKE "P%" ;		
GROUP BY  claim.illness1 ;
ORDER BY 2 DESC ;
INTO CURSOR curOPDDisease
*
SELECT curOPDDisease
SCAN 
	SELECT TOP 10 claim.prov_name, ;
	COUNT(*) AS ipdCnt, ;
	SUM(IIF(EMPTY(claim.fax_by), claim.sbenfpaid, claim.fbenfpaid)) AS ipdPaid ;
	FROM cims!claim ;
	WHERE 	 claim.service_type = "OPD" ;
		AND return_date BETWEEN gdStartDate AND gdEndDate ;
		AND illness1 = curOPDDisease.illness1 ;
		AND claim.result LIKE "P%" ;		
	GROUP BY  claim.prov_name ;
	ORDER BY 2 DESC ;
	INTO CURSOR ("curOPD"+ALLTRIM(STR(RECNO())))
ENDSCAN 	



PROCEDURE BuildXls

IF !USED("icd10th")
	USE f:\hips\data\icd10th IN 0
ENDIF 	

oExcel = CREATEOBJECT("Excel.Application")
oBook = oExcel.WorkBooks.Add()
oSheet = oBook.WorkSheets(1)
oSheet.name = "Top 10"
osheet.Cells(1,1).Value = "สรุป 10 อันดับของโรค ตั้งแต่ปี 2005-2007"
lnRow = 4
SELECT curDisease
GO TOP 
DO WHILE !EOF()
	IF SEEK(illness1, "icd10th", "code")
		lcICD10 = ALLTRIM(icd10th.thainame)+"("+ALLTRIM(illness1)+")"
	ELSE 
		lcICD10 = illness1
	ENDIF 
			
	lcAlias = "curIPD"+ALLTRIM(STR(RECNO()))
	
	WITH oSheet
		.Cells(lnRow,2).Value = 	lcICD10
		.Cells(lnRow,3).Value = 	ipdcnt
		.Cells(lnRow,4).Value = 	ipdpaid
		
		lnRow = lnRow + 2
		.Cells(lnRow,2).Value = 	"โรงพยาบาล"
		.Cells(lnRow,3).Value = 	"ความถี่"
		.Cells(lnRow,4).Value = 	"จำนวนเงิน"		
		lnRow = lnRow + 1		
		SELECT (lcAlias)	
		SCAN 
			.Cells(lnRow,2).Value = prov_name
			.Cells(lnRow,3).Value = ipdcnt
			.Cells(lnRow,4).Value = ipdpaid
			lnRow = lnRow + 1
		ENDSCAN 	
	ENDWITH 
	lnRow = lnRow + 3	
	SELECT curDisease
	SKIP 			
ENDDO 
*
lnRow = 4
SELECT curOPDDisease
GO TOP 
DO WHILE !EOF()
	IF SEEK(illness1, "icd10th", "code")
		lcICD10 = ALLTRIM(icd10th.thainame)+"("+ALLTRIM(illness1)+")"
	ELSE 
		lcICD10 = illness1
	ENDIF 		
	lcAlias = "curOPD"+ALLTRIM(STR(RECNO()))
	
	WITH oSheet
		.Cells(lnRow,9).Value = 	lcICD10
		.Cells(lnRow,10).Value = 	ipdcnt
		.Cells(lnRow,11).Value = 	ipdpaid
		
		lnRow = lnRow + 2
		.Cells(lnRow,9).Value = 	"โรงพยาบาล"
		.Cells(lnRow,10).Value = 	"ความถี่"
		.Cells(lnRow,11).Value = 	"จำนวนเงิน"		
		lnRow = lnRow + 1		
		SELECT (lcAlias)	
		SCAN 
			.Cells(lnRow,9).Value = prov_name
			.Cells(lnRow,10).Value = ipdcnt
			.Cells(lnRow,11).Value = ipdpaid
			lnRow = lnRow + 1
		ENDSCAN 	
	ENDWITH 
	lnRow = lnRow + 3	
	SELECT curOPDDisease
	SKIP 			
ENDDO 

lcPath = GETDIR("F:\Report\")
lcXlsFile = ALLTRIM(lcPath)+"Top10_Claim_Analysis_Report_"+STRTRAN(DTOC(gdStartDate), "/", "")+"-"+STRTRAN(DTOC(gdEndDate), "/", "")+".xls"
oBook.Saveas(lcXlsFile)
oExcel.Quit



