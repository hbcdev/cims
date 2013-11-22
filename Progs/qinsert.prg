*******************************************************************************
* Function SQL Insert 
* Written by 		Kasem Kamolchaipisit
* Written date  	27 Aug. 2003
* Example		=QINSERT(nHandle,"CURSOR","TABLE")
*	or		 	=QINSERT(nHandle,"CURSOR")
* Note			Field name between Cursor and Table must same
* pcIgnorefield = field for increment (primary key)
*******************************************************************************
FUNCTION QINSERT (pnHandle,pcCursor, pcTable, pcIgnoreField)
IF PARAMETERS() < 2
	=MESSAGEBOX('Tool few Arguments'+CHR(13)+'QINSERT(pnHandle,pcCursor,pcTable)',48,'Error')
	RETURN -999
ENDIF 
IF PARAMETERS() = 2
	pcTable = pcCursor
ENDIF
IF PARAMETERS() <= 3
	pcIgnoreField = ''
ENDIF
LOCAL ARRAY aTmpStruct(1)
LOCAL lnFields, lcField
SELECT * FROM (pcCursor) INTO CURSOR INSCUR
lnSuccess = SQLCOLUMNS(pnHandle,pcTable,"NATIVE","SQLCUR")
IF lnSuccess < 0
	=MESSAGEBOX('Cannot Access Table ('+ALLTRIM(pcTable)+')',48,'Error')
	RETURN lnSuccess
ENDIF
lnFields = AFIELDS(aTmpStruct,pcCursor)
lcFieldSQL = [INSERT INTO ] + pcTable + [ (]
lcField = "" 
SELECT SQLCUR
FOR i = 1 TO lnFields
	LOCATE FOR UPPER(ALLTRIM(Column_name)) == UPPER(ALLTRIM(aTmpStruct(i,1))) 
	IF FOUND()
		IF !EMPTY(pcIgnoreField)
			IF !(UPPER(ALLTRIM(pcIgnoreField)) == UPPER(ALLTRIM(Column_name)))
				lcFieldSQL = lcFieldSQL + ALLTRIM(Column_name)	
				IF i < lnFields
					lcFieldSQL = lcFieldSQL + [,]
				ELSE
					lcFieldSQL = lcFieldSQL + [) VALUES (]
				ENDIF
			ENDIF
		ELSE
			lcFieldSQL = lcFieldSQL + ALLTRIM(Column_name)	
			IF i < lnFields
				lcFieldSQL = lcFieldSQL + [,]
			ELSE
				lcFieldSQL = lcFieldSQL + [) VALUES (]
			ENDIF
		ENDIF
*		lcSqlFieldName = ALLTRIM(Column_name)
*	ELSE
*		lcSqlFieldName = ''
	ENDIF
*	lcSqlFieldName = LOOKUP(Column_name),aTmpStruct(i,1),Column_name)
*	lcFieldSQL = lcFieldSQL + ALLTRIM(lcSQLFieldName)
ENDFOR
lcField = lcFieldSQL
FOR i = 1 TO lnFields
	IF !EMPTY(pcIgnoreField)
		IF !(UPPER(ALLTRIM(pcIgnoreField)) == UPPER(ALLTRIM(aTmpStruct(i,1))))
			lcField = lcField+[?]+ALLTRIM(pcCursor)+[.]+ALLTRIM(aTmpStruct(i,1))
			IF i < lnFields
				lcField = lcField + [,]
			ENDIF
		ENDIF
	ELSE
		lcField = lcField+[?]+ALLTRIM(pcCursor)+[.]+ALLTRIM(aTmpStruct(i,1))
		IF i < lnFields
			lcField = lcField + [,]
		ENDIF
	ENDIF
ENDFOR
lcField = lcField + [) ]
= SQLSETPROP(pnHandle, 'Transactions', 2)  && Manual transactions
SELECT (pcCursor)
lcSQLInsert = lcField && ALLTRIM(lcFieldSQL) + ALLTRIM(lcField)
SCAN
	lnSuccess = SQLEXEC(pnHandle, (lcSQLInsert) )
	IF lnSuccess < 0	
		=MESSAGEBOX(ALLTRIM(STR(lnSuccess))+' Cannot Insert data into Table ('+ALLTRIM(pcTable)+')',48,'Error')
		EXIT 
	ENDIF 
ENDSCAN
IF lnSuccess < 0
	= SQLROLLBACK(pnHandle) && Rollback insert record
ELSE
	= SQLCOMMIT(pnHandle)  && Commit the changes
ENDIF
= SQLSETPROP(pnHandle, 'Transactions', 1)  && Auto transactions
RETURN lnSuccess