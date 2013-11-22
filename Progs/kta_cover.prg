#INCLUDE "INCLUDE\cims.h"
PUBLIC gcFundCode, gdStartDate, gdEndDate, ;
	gnOption, gcSaveTo

STORE DATE() TO gdStartDate, gdEndDate
gcFundCode = ""
gnOption = 3
gcSaveTo = ADDBS(gcTemp)+"Cover\"

DO FORM form\dateentry1

IF EMPTY(gcFundCode) AND EMPTY(gdStartDate) AND EMPTY(gdEndDate)
	=MESSAGEBOX("กรุณาเลือก บริษัทประกันภัยที่ต้องการให้จัดทำรายงานประจำวันด้วย ", MB_OK,"Dialy Report")
	RETURN
ENDIF	
SET SAFE OFF
ltStartDate = gdStartDate - 1
ltEndDate = gdEndDate - 1

ltStartDate = DATETIME(YEAR(ltStartDate), MONTH(ltStartDate), DAY(ltStartDate), 00, 00, 00)
ltEndDate = DATETIME(YEAR(ltEndDate), MONTH(ltEndDate), DAY(ltEndDate), 23, 59, 00)
lcFile = ADDBS(gcSaveTo)+"Cover_"+STRTRAN(DTOC(gdStartDate),"/","")+"_"+STRTRAN(DTOC(gdEndDate), "/", "")
****************************************
SELECT notify_no, policy_no, client_name, cover AS remark ;
FROM cims!notify_log ;
WHERE fundcode = gcFundCode ;
	AND mail_date between gdStartDate AND gdEndDate ;
UNION ALL ;
SELECT notify_no, policy_no, client_name, cover AS remark ;
FROM cims!claim ;
WHERE fundcode = gcFundCode ;
	AND mail_date between gdStartDate AND gdEndDate ;
	OR (fax_date between ltStartDate AND ltEndDate) ;
	OR (result = "AI" AND return_date between gdStartDate AND gdEndDate) ;
HAVING fundcode = gcFundcode ;	
INTO CURSOR ktaCover	
SELECT ktaCover 
IF RECCOUNT() > 0
	EXPORT TO (lcFile) TYPE XL5 
ENDIF