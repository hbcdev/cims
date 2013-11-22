PARAMETERS lcAlias

LOCAL lnFileHandle, lnField, leFieldValue

SELECT (lcAlias)
lcOutput = STRTRAN(DBF(), "DBF", "TXT")

lnFileHandle = FCREATE (lcOutput)

FOR i = 1 TO FCOUNT()
	lcField = FIELD(i)
	IF i < FCOUNT()
		=FWRITE(lnFileHandle, lcField + ";")
	ELSE 
		=FPUTS(lnFileHandle, lcField)
	ENDIF 		
ENDFOR 	
*
SCAN ALL
	FOR lnField = 1 TO FCOUNT ()
		leFieldValue = EVALUATE (FIELD (lnField))
		IF VARTYPE (leFieldValue) <> "C"	
			leFieldValue = TRANSFORM (leFieldValue)	
		ENDIF
		IF lnField < FCOUNT ()	
			= FWRITE (lnFileHandle, leFieldValue + ";")
		ELSE
			= FPUTS (lnFileHandle, leFieldValue)
		ENDIF
	ENDFOR
ENDSCAN

= FCLOSE (lnFileHandle)