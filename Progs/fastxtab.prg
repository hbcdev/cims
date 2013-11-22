***********************************************************************
*    File: FastXtab.prg
* Version: 1.0
*  Author: Alexander Golovlev
* Country: Russian Federation
*   Email: avg.kedr@overta.ru , golovlev@yandex.ru
***********************************************************************
***********************************************************************
*
* Notes: On entry, a table should be open in the current work area,
*        and it should contain at most one record for each cell in
*        a cross-tabulation. This table may NOT be in row order.
*
*        The rowfld field in each record becomes the y-axis (rows) for
*        a cross-tab and the colfld field becomes the x-axis (columns)
*        The actual cross-tab results are saved to the database name
*        specified by "cOutFile" property.
*
*        The basic strategy goes like this. Using select query get all
*        unique values of rows and columns and totaling values for each
*        row/column pair. Then determine the column headings in the
*        output cursor. Next produce an empty cursor with one column
*        for each unique value of input field colfld, plus one additional
*        column for input field rowfld values. Finally, scan the temporary
*        cursor and put the cell values for the row/column intersections
*        into the output cursor.
*
* Usage: oXtab = NewObject("FastXtab", "FastXtab.prg")
*        oXtab.lCursorOnly = .T.
*        oXtab.lBrowseAfter = .T.
*        oXtab.RunXtab
*
***********************************************************************

#include Include\FastXtabEn.h	&& English
*#include FastXtabRu.h	&& Russian

#define NullField 'NULL'
#define CharBlank 'C_BLANK'
#define DateBlank 'D_BLANK'

External Array aFldArray

Define Class FastXtab As Custom
cOutFile = ""			&& The name of the output file
lCursorOnly = .F.		&& Specifies whether the input datasource is cursor
lCloseTable = .T.		&& Specifies whether to close the source datasource after the cross tab is generated
nPageField = 0			&& Specifies the field position in the datasource of the cross tab pages
nRowField = 1			&& Specifies the field position in the datasource of the cross tab rows
nColField = 2			&& Specifies the field position in the datasource of the cross tab columns
nDataField = 3			&& Specifies the field position in the datasource of the cross tab data
lTotalRows = .F.		&& Specifies whether to total rows in the cross tab output
lDisplayNulls = .F.		&& Specifies whether to display null values in the cross tab output
lBrowseAfter = .F.		&& Specifies whether to open a Browse window on the cross tab output

Protected BadChars		&& String of symbols not allowed in field name
Protected RepChars		&& String of symbols to replace bad chars

Procedure Init			&& Constructor
	If Version(3) $ "81 82 86 88"
		This.BadChars = "/,-=:;!@#$%&*.<>()?[]\+"+Chr(34)+Chr(39)+" "
	Else
		This.BadChars = "ÅÇÉÑÖÜáàâäãåéèêëíìîïñóòôö†°¢£§•/\,-=:;{}[]!@#$%^&*.<>()?"+;
			"+|Äõúùûü|®c™--rØ∞±Ii'µ∑∏π∫ºΩæø¿¡¬√ƒ≈∆«»… ÀÃÕŒœ"+;
			"–—“”‘’÷◊ÿŸ⁄€‹›ﬁﬂ‡·‚„‰ÂÊÁËÈÍÎÏÌÓÔÒÚÛÙıˆ˜¯˘˙˚¸˝˛"+Chr(34)+Chr(39)+" "
	EndIf
	This.RepChars = Replicate("_", Len(This.BadChars) - 1)
EndProc

Procedure Destroy		&& Destructor
	If Used("COLUMNS")
	   Use In columns
	EndIf
	If Used("CELLS")
	   Use In cells
	EndIf
EndProc

Function RunXtab		&& Generates a cross tab
	Local cTalkStat		&& SET TALK status
	Local cNullStat		&& SET NULL status
	Local cOutStem		&& Output cursor name
	Local DbfName		&& Input table file name
	Local nGroupFields	&& Number of grouping fields

	Wait Window "Running Cross Tab Query" NoWait
	cTalkStat = Set("TALK")
	Set Talk Off
	cNullStat = Set("NULL")

	* Check object properties
	If Type("This.cOutFile") != "C"
		This.cOutFile = "xtabquery"
	EndIf
	If Type("This.lCursorOnly") != "L"
		This.lCursorOnly = .F.
	EndIf
	If Type("This.lCloseTable") != "L"
		This.lCloseTable = .T.
	EndIf
	If Type("This.nPageField") != "N"
		This.nPageField = 0
	EndIf
	If Type("This.nRowField") != "N"
		This.nRowField = 1
	EndIf
	If Type("This.nColField") != "N"
		This.nColField = 2
	EndIf
	If Type("This.nDataField") != "N"
		This.nDataField = 3
	EndIf
	If Type("This.lTotalRows") != "L"
		This.lTotalRows = .F.
	EndIf
	If Type("This.lDisplayNulls") != "L"
		This.lDisplayNulls = .F.
	EndIf
	If Type("This.lBrowseAfter") != "L"
		This.lBrowseAfter = .F.
	EndIf

	If This.lDisplayNulls
		Set Null On
	Else
		Set Null Off
	EndIf

	* Make sure that table is open in current work area
	If !Used()
		m.DbfName = GetFile('DBF',C_LOCATEDBF)
		If Empty(m.DbfName)
			* User canceled out of dialog
			Return .F.
		Else
			Use (m.DbfName)
		EndIf
	EndIf
	* Check for input table properties
	If FullPath(DefaultExt(Alias(),'DBF')) == FullPath(DefaultExt(THIS.cOutFile,'DBF'))
		This.Alert(C_OUTPUT)
		Return .F.
	EndIf
	If FCount() < 3
    	This.Alert(C_NEED3FLDS)
    	Return .F.
    EndIf
	If RecCount() = 0
	    This.Alert("Empty Data")
		Return .F.
	EndIf

	* Gather information on the currently selected database fields
	Dimension InpFields[FCOUNT(),4]
	m.numflds = AFields(InpFields)

	* None of these fields are allowed to be memo fields
	If This.nPageField > 0
		If InpFields[THIS.nRowField,2] $ 'MGP'
			This.Alert(C_BADPAGEFLD)
			Return .F.
		EndIf
	EndIf
	If InpFields[THIS.nRowField,2] $ 'MGP'
	   This.Alert(C_BADROWFLD)
	   Return .F.
	EndIf
	If InpFields[THIS.nColField,2] $ 'MGP'
	   This.Alert(C_BADCOLFLD)
	   Return .F.
	EndIf
	If InpFields[THIS.nDataField,2] $ 'MGP'
	   This.Alert(C_BADCELLFLD)
	   Return .F.
	EndIf

	If This.nPageField > 0
		m.pagefldname = InpFields[This.nPageField,1]
		nGroupFields = 2
	Else
		nGroupFields = 1
	EndIf
	m.rowfldname = InpFields[This.nRowField,1]
	m.colfldname  = InpFields[This.nColField,1]
	m.cellfldname = InpFields[This.nDataField,1]
	m.DbfName = Alias()

	* Calculate all cell values
  	If InpFields[THIS.nDataField,2] $ "NFYBI"
		* SUM for numeric data types
		If This.nPageField > 0
			Select &pagefldname as pagefld, &rowfldname as rowfld, &colfldname as colfld, ;
				SUM(&cellfldname) As cellfld;
				From (DbfName) Group by 1, 2, 3 Into Cursor cells
		Else
			Select &rowfldname as rowfld, &colfldname as colfld, ;
				SUM(&cellfldname) As cellfld;
				From (DbfName) Group by 1, 2 Into Cursor cells
		EndIf
	Else
		* Replace for non numeric data types
		If This.nPageField > 0
			Select &pagefldname as pagefld, &rowfldname as rowfld, &colfldname as colfld, ;
				&cellfldname as cellfld;
				From (DbfName) Group by 1, 2, 3 Into Cursor cells
		Else
			Select &rowfldname as rowfld, &colfldname as colfld, ;
				&cellfldname as cellfld;
				From (DbfName) Group by 1, 2 Into Cursor cells
		EndIf
	EndIf

	* Generate column names
	Select Distinct colfld as colvalue ;
		From cells Group by 1 Into Cursor columns
	Index On colvalue Tag colvalue
	Do Case
	Case _TALLY > 254
		This.Alert(C_XSVALUES)
		Return .F.
	Case _TALLY = 0
		This.Alert(C_NOCOLS)
		Return .F.
	EndCase

	* Create output table
	Dimension OutFields[nGroupFields+_TALLY,4]
	* Page and Row fields are the same as in input table
	If This.nPageField > 0
		OutFields[1,1] = InpFields[This.nPageField,1]
		OutFields[1,2] = InpFields[This.nPageField,2]
		OutFields[1,3] = InpFields[This.nPageField,3]
		OutFields[1,4] = InpFields[This.nPageField,4]
	EndIf
	OutFields[nGroupFields,1] = InpFields[This.nRowField,1]
	OutFields[nGroupFields,2] = InpFields[This.nRowField,2]
	OutFields[nGroupFields,3] = InpFields[This.nRowField,3]
	OutFields[nGroupFields,4] = InpFields[This.nRowField,4]
	Scan
		OutFields[nGroupFields+RECNO(),1] = This.GenName(columns.colvalue, InpFields[This.nColField,4])
		OutFields[nGroupFields+RECNO(),2] = InpFields[This.nDataField,2]
		OutFields[nGroupFields+RECNO(),3] = InpFields[This.nDataField,3]
		OutFields[nGroupFields+RECNO(),4] = InpFields[This.nDataField,4]
	EndScan
	
	This.CheckNames(@OutFields)

	* Make sure that the output file is not already in use somewhere
	cOutStem = JustStem(This.cOutFile)
	If Used(cOutStem)
		Use In (cOutStem)
	EndIf
	If !This.lCursorOnly
	   Create Table (This.cOutFile) FREE From Array OutFields 
	   cOutStem = Alias()
	Else
	   Create Cursor (cOutStem) From Array OutFields	   
	EndIf

	* Fill the output table
	Select cells
	If This.nPageField > 0
		pagefldvalue = cells.pagefld
		rowfldvalue = cells.rowfld
		Insert Into (cOutStem) (&pagefldname, &rowfldname) Values (pagefldvalue, rowfldvalue)
		Scan
			If (pagefldvalue != cells.pagefld) or (rowfldvalue != cells.rowfld)
				pagefldvalue = cells.pagefld
				rowfldvalue = cells.rowfld
				Insert Into (cOutStem) (&pagefldname, &rowfldname) Values (pagefldvalue, rowfldvalue)
			EndIf

			* Translate a field value of any type into a column field name
			Seek cells.colfld In columns
			replcolumn = Field(RecNo('columns') + nGroupFields, cOutStem)
			Replace (replcolumn) With cells.cellfld In (cOutStem)
		EndScan
	Else
		rowfldvalue = cells.rowfld
		Insert Into (cOutStem) (&rowfldname) Values (rowfldvalue)
		Scan
			If rowfldvalue != cells.rowfld
				rowfldvalue = cells.rowfld
				Insert Into (cOutStem) (&rowfldname) Values (rowfldvalue)
			EndIf

			* Translate a field value of any type into a column field name
			Seek cells.colfld In columns
			replcolumn = Field(RecNo('columns') + nGroupFields, cOutStem)
			Replace (replcolumn) With cells.cellfld In (cOutStem)
		EndScan
	EndIf

	Select (cOutStem)
	Go Top

	* Close the input database
	If This.lCloseTable
		Use In (m.DbfName)
	EndIf
	Use In columns
	Use In cells

	Set Talk &cTalkStat
	Set Null &cNullStat
	Wait Clear

	If This.lBrowseAfter
		Browse NoWait Normal
	EndIf
EndProc

Protected Function GenName(in_name, in_dec)
* Generate a valid field name from field value of any type
	Local RetVal, cFldType

	If Parameters() = 1
		m.in_dec = 0
	EndIf
	cFldType = Type("m.in_name")
	Do Case
	Case IsNull(m.in_name)
		m.RetVal = NullField
	Case cFldType $ 'CM'
		Do Case
		Case Empty(m.in_name)
			m.RetVal = CharBlank
		Otherwise
			m.RetVal = IIf(IsAlpha(m.in_name), m.in_name, 'C_'+m.in_name)
			* Now have to truncate to 10 bytes
			m.RetVal=Left(m.RetVal, 10)
			If Len(RightC(m.RetVal, 1)) = 1 AND IsLeadByte(RightC(m.RetVal,1))	&& last byte is Double byte
				m.RetVal = Left(m.RetVal,9)
			EndIf
		EndCase
	Case cFldType $ 'NFIYB'
		m.RetVal = 'N_'+AllTrim(Str(m.in_name, 8, Min(in_dec,7)))
	Case cFldType $ 'DT'
		m.RetVal = IIf(Empty(m.in_name), DateBlank, 'D_' + DToS(m.in_name))
	Case cFldType = 'L'
		m.RetVal = IIf(m.in_name, 'True', 'False')
	Otherwise
		* Should never happen
		This.Alert(C_UNKNOWNFLD)
		Return "Unknown"
	EndCase

	* We need to replace bad characters here with "_"
	m.RetVal = ChrTranC(m.RetVal, This.BadChars, This.RepChars)
	Return Upper(AllTrim(m.RetVal))
EndFunc

Protected Procedure CheckNames(aFldArray)
* Checks to see if field names are unique, else assigns a new one
	Local cExactStat, nTmpCnt, cTmpCntStr, cOldValue, i

	For i = 1 To ALen(aFldArray, 1)
		Store AllTrim(aFldArray[i,1]) To cOldvalue, cCheckValue
		nTmpCnt = 1
		Do While !This.FldUnique(@aFldArray, m.cCheckValue, i)
			cTmpCntStr = "_"+AllTrim(Str(m.nTmpCnt))
			cCheckValue = Left(m.cOldValue, 10 - Len(m.cTmpCntStr)) + m.cTmpCntStr
			nTmpCnt = m.nTmpCnt + 1
		EndDo
		aFldArray[i,1] = m.cCheckValue
	EndFor
EndProc

Protected Function FldUnique(aFldArray, cCheckValue, nPos)
* Checks to see if field name is unique
	Local i

	For i = 1 To nPos - 1
		If aFldArray[i,1] == cCheckValue
			Return .F.
		EndIf
	EndFor

	Return .T.
EndFunc

Procedure Error(nError, cMethod, nLine)
This.Alert("Line: "+AllTrim(Str(m.nLine))+Chr(13) ;
	   +"Program: "+m.cMethod+Chr(13) ;
	   +"Error: "+AllTrim(Str(nError))+Chr(13) ;
	   +"Message: "+Message()+Chr(13);
	   +"Code: "+Message(1))
   Return To RunXtab
ENDPROC

Protected Procedure Alert(strg)
	MessageBox(m.strg, 16, "FastXtab")
EndProc

EndDefine

* TODO:	Support for long field names
*		lTotalRows property
