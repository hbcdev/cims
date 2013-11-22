*******************************************************************************
* Function 		SQL Create Cursor
* Written by 		Kasem Kamolchaipisit
* Written date  	27 Aug. 2003
* Example		=QCURSOR(nHandle,"TABLE","CURSOR")
*	or		 	=QCURSOR(nHandle,"TABLE")
*******************************************************************************
FUNCTION QCURSOR (pnHandle,pcTable,pcCursor)
IF PARAMETERS() < 2
	=MESSAGEBOX('Tool few Arguments'+CHR(13)+'QCURSOR(pnHandle,pcTable,pcCursor)',48,'Error')
	RETURN -999
ENDIF 
IF PARAMETERS() = 2
	pcCursor = pcTable 
ENDIF
LOCAL lnSuccess,lcSql
lcSql = [SELECT * FROM ] + LOWER(ALLTRIM(pcTable)) + [ WHERE 1 = 2]
lnSuccess = SQLEXEC(pnHandle,lcSql,[QCURSOR])
IF lnSuccess > 0
	SELECT * FROM QCURSOR INTO CURSOR (pcCursor) READWRITE
	USE IN QCURSOR
ENDIF
RETURN lnSuccess