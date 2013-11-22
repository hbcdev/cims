* DBF2XML.prg - Converts an cursor or table into an XML string.
* Author: Ken R. Levy
* Modified: 02/24/1999
*

*-- ASCII codes
#DEFINE TAB			CHR(9)
#DEFINE LF			CHR(10)
#DEFINE CR			CHR(13)
#DEFINE CR_LF		CR+LF


LPARAMETERS tcTable,tcScope,tnTabIndents,tlUpperCase,tlTrim,tcOutFile,tlShow,tlModify
LOCAL lcTable,lcAlias,lcScope,lcDBFName,lcDBF,lcRootName,lcItemName,lcXMLText,lcOutFile
LOCAL lcValue,lcField,lnFieldCount,lvField,lnCount,lnLastSelect,lnLastRecNo,lcIndentText
DIMENSION laFields[1]

IF NOT INLIST(VARTYPE(tcTable),"C","L") OR NOT INLIST(VARTYPE(tcScope),"C","L")
	RETURN ""
ENDIF
lcIndentText=IIF(VARTYPE(tnTabIndents)=="N",REPLICATE(TAB,tnTabIndents),TAB)
lcTable=LOWER(IIF(EMPTY(tcTable),ALIAS(),ALLTRIM(tcTable)))
lnLastSelect=SELECT()
IF "."$lcTable
	lcDBF=lcTable
	IF NOT FILE(lcDBF)
		RETURN ""
	ENDIF
	SELECT 0
	lcAlias=LOWER(SYS(2015))
	USE (lcDBF) ALIAS (lcAlias) AGAIN SHARED
	lcDBFName=LOWER(FORCEEXT(JUSTFNAME(DBF()),""))
ELSE
	lcDBF=""
	lcAlias=lcTable
	lcDBFName=lcAlias
ENDIF
IF NOT USED(lcAlias)
	SELECT (lnLastSelect)
	RETURN ""
ENDIF
lcScope=IIF(EMPTY(tcScope),"ALL",ALLTRIM(tcScope))
SELECT (lcAlias)
lnLastRecNo=IIF(EOF(),0,RECNO())
lnFieldCount=AFIELDS(laFields)
IF lnFieldCount=0
	RETURN ""
ENDIF
lcRootName=IIF(tlUpperCase,UPPER(lcDBFName),LOWER(lcDBFName))
DO WHILE TYPE(lcRootName)#"U"
	lcRootName=lcRootName+"1"
ENDDO
lcItemName="record"
DO WHILE TYPE(lcItemName)#"U"
	lcItemName=lcItemName+"1"
ENDDO
lcXMLText=[<?xml version="1.0"?>]
IF tlUpperCase
	lcXMLText=UPPER(lcXMLText)
	lcItemName=UPPER(lcItemName)
ENDIF
lcXMLText=lcXMLText+CR_LF+ ;
		"<"+lcRootName+">"+CR_LF
SCAN &lcScope
	lcXMLText=lcXMLText+lcIndentText+"<"+lcItemName+">"+CR_LF
	FOR lnCount = 1 TO lnFieldCount
		lcField=IIF(tlUpperCase,UPPER(laFields[lnCount,1]),LOWER(laFields[lnCount,1]))
		IF laFields[lnCount,2]=="G"
			LOOP
		ENDIF
		lvField=EVALUATE(lcField)
		IF ISNULL(lvField) OR EMPTY(lvField)
			lcXMLText=lcXMLText+lcIndentText+TAB+"<"+lcField+"/>"+CR_LF
			LOOP
		ENDIF
		IF tlTrim
			lcValue=TRIM(TRANSFORM(lvField))
		ELSE
			lcValue=TRANSFORM(lvField)
		ENDIF
		IF MEMLINES(lcValue)>=2 OR ">"$lcValue OR "<"$lcValue OR "&"$lcValue OR ;
				"#"$lcValue OR '"'$lcValue
			lcValue="<![CDATA["+lcValue+"]]>"
		ENDIF
		lcXMLText=lcXMLText+lcIndentText+TAB+"<"+lcField+">"+lcValue+"</"+lcField+">"+CR_LF
	ENDFOR
	lcXMLText=lcXMLText+lcIndentText+"</"+lcItemName+">"+CR_LF
ENDSCAN
lcXMLText=lcXMLText+"</"+lcRootName+">"+CR_LF
IF EMPTY(lcDBF)
	IF lnLastRecNo>0
		GO lnLastRecNo
	ENDIF
ELSE
	USE
ENDIF
SELECT (lnLastSelect)
lcOutFile=IIF(VARTYPE(tcOutFile)=="C",ALLTRIM(tcOutFile),"")
IF EMPTY(lcOutFile) AND (tlShow OR tlModify)
	lcOutFile=LOWER(SYS(2023)+"\"+SYS(2015)+".xml")
ENDIF
IF NOT EMPTY(lcOutFile)
	ERASE (lcOutFile)
	STRTOFILE(lcXMLText,lcOutFile)
ENDIF
IF tlShow
	DECLARE INTEGER ShellExecute ;
		    IN SHELL32.DLL ;
		    INTEGER nWinHandle,;
		    STRING cOperation,;   
		    STRING cFileName,;
		    STRING cParameters,;
		    STRING cDirectory,;
		    INTEGER nShowWindow
	ShellExecute(0,"Open",lcOutFile,"","",1)
ENDIF
IF tlModify
	MODIFY FILE (lcOutFile) NOWAIT
ENDIF
RETURN lcXMLText
