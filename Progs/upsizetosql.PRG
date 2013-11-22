USE cims!members IN 0
*
conString =  "Driver={SQL Server};Server=(local);Database=Cims;Integrated Security=SSPI;Persist Security Info=False;"
oConn = SQLSTRINGCONNECT(conString)
=SQLPREPARE(oConn, 'SELECT * From member where policy_no =?cPolNo', "curMember")

SELECT members
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 	
	cPolNo = members.policy_no
	nResult = SQLEXEC(oConn)
	IF nResult = -1  && ไม่มีข้อมูลอยู่ใน SQL Server
		SCATTER MEMO MEMVAR 
		
	
	
	
	ENDIF 
ENDSCAN 	
