*******************************************************************************
* Function SQL Update
* Written by 		Kasem Kamolchaipisit
* Written date  	27 Aug. 2003
* Example		=QUPDATE(nHandle,"CURSOR","PKField","TABLE")
*	or		 	=QUPDATE(nHandle,"CURSOR","PKField")
* Pk > 1                 =QUPDATE(nHandle,"CURSOR","field1 = ?var1 and field2 = ?var2 ...","TABLE",.T.,.F.)
* Note			Field name between Cursor and Table must same
*******************************************************************************
FUNCTION QUPDATE (pnHandle, pcCursor,pcPKField,pcTable,lWhere,lTransaction)
IF PARAMETERS() < 3
	=MESSAGEBOX('Tool few Arguments'+CHR(13)+'QINSERT(pnHandle,pcCursor,pcPKField,pcTable,lWhere,lTransaction)',48,'Error')
	RETURN -999
ENDIF
IF PARAMETERS() = 3
	pcTable = pcCursor
	lWhere = .F.
	lTransaction = .T.
ENDIF
IF PARAMETERS() = 4
	lWhere = .F.
	lTransaction = .T.
ENDIF
LOCAL ARRAY aTmpStruct(1)
LOCAL lnFields, lcField, nx
lnSuccess = SQLCOLUMNS(pnHandle,pcTable,"NATIVE","SQLCUR")
IF lnSuccess < 0
	=MESSAGEBOX('Cannot Access Table ('+ALLTRIM(pcTable)+')',48,'Error')
	RETURN lnSuccess
ENDIF
lnFields = AFIELDS(aTmpStruct,pcCursor)
lcFieldSQL = [UPDATE ] + ALLTRIM(pcTable) + " SET " 
SELECT SQLCUR
nx = 0
FOR i = 1 TO lnFields
	LOCATE FOR UPPER(ALLTRIM(Column_name)) == UPPER(ALLTRIM(aTmpStruct(i,1))) 
	IF FOUND()
		lcSqlFieldName = ALLTRIM(Column_name)
	ELSE
		lcSqlFieldName = ""
	ENDIF
*	lcSqlFieldName = LOOKUP(Column_name,ALLTRIM(aTmpStruct(i,1)),Column_name)
	IF !(UPPER(ALLTRIM(lcSqlFieldName)) == UPPER(ALLTRIM(pcPKField)))
		IF !EMPTY(lcSqlFieldName)
			IF nx > 0
				lcFieldSQL = lcFieldSQL + [,]
			ENDIF
			lcFieldSQL = lcFieldSQL + ALLTRIM(lcSQLFieldName) + [=?] + ALLTRIM(pcCursor)+[.]+ALLTRIM(aTmpStruct(i,1))
			nx = nx+1
		ENDIF
	ENDIF
	IF i = lnFields
		lcFieldSQL = lcFieldSQL + " WHERE "
	ENDIF
ENDFOR
IF lWhere = .T.
	lcFieldSQL = lcFieldSQL + " " + ALLTRIM(pcPKField) + " "
ELSE
	lcFieldSQL = lcFieldSQL + " " + ALLTRIM(pcPKField) + [=?] + ALLTRIM(pcCursor)+[.]+ALLTRIM(pcPKField) + " "
ENDIF
IF lTransaction
	= SQLSETPROP(pnHandle, 'Transactions', 2)  && Manual transactions
ENDIF 
SELECT (pcCursor)
SCAN
	lnSuccess = SQLEXEC(pnHandle,lcFieldSQL)
	IF lnSuccess < 0
		=MESSAGEBOX('Cannot Update data into Table ('+ALLTRIM(pcTable)+')',48,'Error'))
		EXIT 
	ENDIF 
ENDSCAN
IF lTransaction
	IF lnSuccess < 0
		= SQLROLLBACK(pnHandle) && Rollback Update record
	ELSE
		= SQLCOMMIT(pnHandle)  && Commit the changes
	ENDIF
	= SQLSETPROP(pnHandle, 'Transactions', 1)  && Auto transactions
ENDIF 
RETURN lnSuccess