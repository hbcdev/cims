Define Class cHTML as Custom

*-- Array for HTML Page Lines
Protected aPageLines[1]
Protected cTitle
Protected cCRLF
Protected nLines

Function Init
This.cTitle = ""
This.cCRLF  = CHR(13) + CHR(10)
This.nLines = 0

EndFunc

Function ReturnHTMLPage
Lparameters plCGIPage

Local lcRetVal
lcRetVal = ""

If plCGIPage
  lcRetVal = This.CreateCGIHeader()
Endif

lcRetVal = lcRetVal + This.CreateHTMLHeader()

If This.nLines > 0
  Local lnKount
  For lnKount = 1 To This.nLines
    lcRetVal = lcRetVal + This.aPageLines[lnKount] + THIS.cCRLF
  EndFor
Endif

lcRetVal = lcRetVal + This.CreateHTMLFooter()

Return lcRetVal

EndFunc

*-- This method creates the title of th web page
Function CreateTitle
Lparameters pcTitle

*-- Return true or false sepending on input type
Local llRetVal
llRetVal = .f.

If Type("pcTitle") = "C"
  llRetVal = .t.
  This.cTitle = pcTitle
Endif  

Return llRetVal

*-- This function creates a text line for an HTML Page
Function CreateTextLine
LParameters pcTextLine, plIncludeBreak

LOCAL llRetVal 
llRetVal = .f.

If Type("pcTextLine") = "C"
  llRetVal = .t.
Endif

This.AddTextLine(pcTextLine,.t.)

Return llRetVal

EndFunc

*-- This function creates a hard return
Function CreateHardReturn

This.AddTextLine("<HR>",.t.)

Return 

EndFunc


Function CreateTable
Lparameters pcAlias, pcTableTitle

Local lcRetVal, llRetVal, lcTblString
lcRetVal = ""
llRetVal = .f.

If Used(pcAlias)
  llRetVal = .t.
  This.AddTextLine("<TABLE Border>")

  *-- If a table title was passed then create a table caption
  If Type("pcTableTitle") = "C"
    This.AddTextLine("<CAPTION>"+ pcTableTitle + "</CAPTION>")
  Endif


  Select (pcAlias)

  *- Create the column headers
  Local lnKount
  lcTblString = "<TR>"
  For lnKount = 1 To Fcount()
    lcTblString = lcTblString + "<TH>" + Field(lnKount)  
  Endfor
  lcTblString = lcTblString + "</TR>"
  This.AddTextLine(lcTblString)

  Go Top

  *-- Populate the fields with data
  Scan
    lcTblString = "<TR>"
    For lnKount = 1 To Fcount()
      lcTblString = lcTblString + "<TD>" + Eval(Field(lnKount)) 
    Endfor
    lcTblString = lcTblString + "</TR>" 
    This.AddTextLine(lcTblString)
  Endscan

    This.AddTextLine("</TABLE>")
Endif

Return llRetVal


Function CreateTextField
Lparameters pcCaption, pcVarName, pnSize, plIncludeBreak, pcValue,pcType

Local llRetVal
llRetVal = .f.

If Type("pcCaption") = "C" And Type("pcVarName") = "C" And Type("pnSize") = "N"
  llRetVal = .t.

  *-- Assign variable name
  lcStringToAdd = pcCaption + "" + [<INPUT NAME="] + pcVarName + [" SIZE=]

  *--- Assign size
  lcStringToAdd = lcStringToAdd + Alltrim(Str(pnSize,3,0))

  *-- If user handed in default value assign now
  If Type("pcValue") = "C"
    lcStringToAdd = lcStringToAdd + [ VALUE="] + pcValue + ["]
  Else
    lcStringToAdd = lcStringToAdd + [ VALUE=""] 
  Endif
  If Type("pcType") = "C"
  	If INLIST(pcType, "text","password","checkbox","radio","submit","reset","file","hidden","images","button")
  		lcStringToAdd = lcStringToAdd + [ TYPE= "] + pcType + ["]
  	Endif
  Endif	
  lcStringToAdd = lcStringToAdd + [>]
  lcStringToAdd = lcStringToAdd + IIF(plIncludeBreak,"<br>","")

  This.AddTextLine(lcStringToAdd)
Endif

Return llRetVal
EndFunc

*-- This method creates the combo box of the web page
Function CreateComBoBox
Lparameter pcAlias,pcField
Local llRetVal,;
	lcStringToAdd
llRetVal = .f.

IF TYPE("pcAlias") = "C" AND TYPE("pcField") = "C"
	IF USED(pcAlias)
		IF RECCOUNT(pcAlias) > 0
			llRetVal = .T.
		ENDIF
	ENDIF
ENDIF	
IF llRetVal		
	This.AddTextLine("<SELECT>")
	SELECT (pcAlias)
	SCAN
		lcStringToAdd = "<OPTION>"+&pcField+"</OPTION>"
		This.AddTextLine(lcStringToAdd)
	ENDSCAN		
	This.AddTextLine("</SELECT>")
ENDIF	
Endfunc

*-- This method creates the title of th web page
Function CreateHeaderLine
Lparameters pcHeaderText, pnHeaderNumber

*-- Return true or false sepending on input type
Local llRetVal
llRetVal = .f.

If Type("pcHeaderText") = "C" And Type("pnHeaderNumber") = "N"
 
  llRetVal = .t.

  *-- Create the header line to add
  LOCAL lcHeaderLine
  lcHeaderLine = "" 
  lcHeaderLine = lcHeaderLine + "<h" + Alltrim(Str(pnHeaderNumber,10,0)) + ">"
  lcHeaderLine = lcHeaderLine + pcHeaderText
  lcHeaderLine = lcHeaderLine + "</h" + Alltrim(Str(pnHeaderNumber,10,0)) + ">"

  *-- Add the line
  This.AddTextLine(lcHeaderLine,.f.)

Endif  

Return llRetVal

EndFunc

*-- This function returns creates the HTML Page header
Protected Function CreateCGIHeader

LOCAL lcRetVal
lcRetVal = ""
lcRetVal = lcRetVal + "Content-Type: text/html" + This.cCRLF + This.cCRLF

Return lcRetVal

Endfunc

*-- This function returns creates the HTML Page header
Protected Function CreateHTMLHeader
LOCAL lcRetVal

lcRetVal = ""

lcRetVal = lcRetVal + "<html>" + This.cCRLF
lcRetVal = lcRetVal + "<head>" + This.cCRLF
lcRetVal = lcRetVal + "<title>" + This.cTitle + "</title>" + This.cCRLF
lcRetVal = lcRetVal + "</head>" + THIS.cCRLF
lcRetVal = lcRetVal + "<body>" + THIS.cCRLF
*lcRetVal = lcRetVal + [<FORM ACTION="vfpcgi.exe?IDCFile=FOXTEACH.IDC" METHOD="POST">]

Return lcRetVal

Endfunc


*-- This function creates a text line for an HTML Page
Protected Function AddTextLine
LParameters pcTextLine, plIncludeBreak

LOCAL llRetVal 
llRetVal = .f.

If Type("pcTextLine") = "C"
  llRetVal = .t.
Endif


*-- Add a new line to the HTML Array
If This.nLines = 0
  This.nLines = This.nLines + 1
Else
  This.nLines = This.nLines + 1
  DECLARE THIS.aPageLines[This.nLines]
Endif

THIS.aPageLines[This.nLines] = pcTextLine + IIF(plIncludeBreak,"<br>","")

Return llRetVal

EndFunc

*-- This function returns creates the HTML Page footer
Protected Function CreateHTMLFooter
LOCAL lcRetVal
lcRetVal = "</body>" + THIS.cCRLF
lcRetVal = lcRetVal +  "</html>" + This.cCRLF

Return lcRetVal

Endfunc

Enddefine

