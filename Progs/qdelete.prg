*******************************************************************************
* Function 		SQL Select Data into Cursor
* Written by 		Kasem Kamolchaipisit
* Written date  	27 Aug. 2003
* Example		=QDELETE(nHandle,[TABLE],[FIELD = ?ThisForm.Text1.Value AND ...])
* Delete all record 	=QDELETE(nHandle,[TABLE],[*ALL])
*******************************************************************************
FUNCTION QDELETE(pnHandle,pcTable,pcWhere)
IF PARAMETERS() < 3 
	=MESSAGEBOX('Tool few Arguments'+CHR(13)+'QDELETE(pnHandle,pcTable,pcWhere)',48,'Error')
	RETURN -999
ENDIF 
IF EMPTY(pcWhere)
	RETURN -999
ENDIF
IF UPPER(ALLTRIM(pcWhere)) == [*ALL]
	pcWhere = []
ELSE
	pcWhere = [ WHERE ] + ALLTRIM(pcWhere)	
ENDIF
LOCAL lnSuccess,lcSql
lcSql = [DELETE FROM ] + LOWER(ALLTRIM(pcTable)) + (pcWhere)
lnSuccess = SQLEXEC(pnHandle,lcSql)
RETURN lnSuccess