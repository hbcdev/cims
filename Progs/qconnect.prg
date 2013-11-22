FUNCTION QCONNECT (lcConnectString,llDSN)
IF PARAMETERS() = 0
	=MESSAGEBOX('Too few Arguments'+CHR(13)+'QCONNECT(cConnectionString,lLogical)',48,'Error')
	RETURN -999
ENDIF
IF PARAMETERS() = 1
	llDSN = .F.
ENDIF
IF !llDSN
	nSqlConn = SQLSTRINGCONNECT(lcConnectString)
ELSE
	nSqlConn = SQLCONNECT(lcConnectString)
ENDIF							
RETURN nSqlConn
