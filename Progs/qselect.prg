*******************************************************************************
* Function 		SQL Select Data into Cursor
* Written by 		Kasem Kamolchaipisit
* Written date  	27 Aug. 2003
* Example		=QSELECT(nHandle,[TABLE],[FIELD = ?ThisForm.Text1.Value AND ...],[CURSOR])
*	or		 	=QSELECT(nHandle,[TABLE],[FIELD = ?ThisForm.Text1.Value AND ...])
*******************************************************************************
FUNCTION QSELECT(pnHandle,pcTable,pcWhere,pcCursor)
IF PARAMETERS() < 2 
	=MESSAGEBOX('Tool few Arguments'+CHR(13)+'QSELECT(pnHandle,pcTable,pcWhere,pcCursor)',48,'Error')
	RETURN -999
ENDIF 
IF PARAMETERS() <= 3
	pcCursor = pcTable 
ENDIF
IF PARAMETERS() = 2
	pcWhere = []
ENDIF
IF EMPTY(pcWhere)
	pcWhere = [] 
ELSE
	pcWhere = [ WHERE ] + ALLTRIM(pcWhere)
ENDIF
LOCAL lnSuccess,lcSql
lcSql = [SELECT * FROM ] + LOWER(ALLTRIM(pcTable)) + (pcWhere)
lnSuccess = SQLEXEC(pnHandle,lcSql,[QSELECT])
IF lnSuccess > 0
	SELECT * FROM QSELECT INTO CURSOR &pcCursor READWRITE
	USE IN QSELECT
ENDIF
RETURN lnSuccess