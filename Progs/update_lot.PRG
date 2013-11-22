USE ? IN 0 ALIAS lot
USE cims!claim IN 0 

SELECT lot
SCAN 
	lcNotNo = "20"+SUBSTR(dfclaimno, 3,8)
	IF SEEK(lcNotNo, "claim", "notify_no")
		IF claim.batchno <> lot.batchno
			?claim.notify_no
			REPLACE claim.batchno WITH batchNo, claim.lotno WITH lotno
		ENDIF 	
	ENDIF 
ENDSCAN 		
	
		
