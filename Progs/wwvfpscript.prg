#INCLUDE Include\WCONNECT.H

*************************************************************
DEFINE CLASS wwVFPScript AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1997
***
***            You are free to use this class inside of
***            this class framework, but it may not be
***            used to build a commercial framework.
***
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 11/18/97
***
***  Function:
*************************************************************

PROTECTED cTempFile

*** Custom Properties
oHTML = .NULL.
oCGI = .NULL.

cFileName = ""
cErrorMsg = ""
cCompileErrors = ""
*cVFPCode = ""

lSaveCode = .F.
lUseCodeBlock = .F.
lForceRuntime = .F.
lRuntime = .F.
lDeleteGeneratedCode = .F.

cTempFile = ""
lAlwaysUnloadScript = .F.
*lUseCodeBlock = .F.

*** Stock Properties

************************************************************************
* wwVFPScript :: Init
*********************************
***  Function:
***    Assume:
***      Pass: lcFile  -  File to Process
***            loHTML  -  An existing HTML object (Optional)
************************************************************************
FUNCTION Init
LPARAMETERS lcFile, loHTML, loCGI

IF !EMPTY(lcFile)
   THIS.cFilename = lcFile
ENDIF

IF TYPE("loHTML") # "O"
   THIS.oHTML = CREATE("wwResponse")
ELSE
   THIS.oHTML = loHTML
ENDIF
IF TYPE("loCGI") = "O"
  THIS.oCGI = loCGI
ENDIF

ENDFUNC
* Init

************************************************************************
* wwVFPScript :: Execute
*********************************
***  Function: Simple High level function that takes a piece of ASP
***            code and runs it using VFP Evaluation
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Execute
LPARAMETERS lcText, llRuntime
LOCAL lcFile

*** WCS - Script Text   WCX - Compiled   WCT - Intermediate
THIS.lAlwaysUnloadScript = .T.
 
IF !llRunTime
    THIS.cFileName = SYS(2023) + "\"+ SYS(2015) + ".WCS"
    THIS.lRuntime = .F.
    lcCode = THIS.ConvertPage(lcText)
    THIS.RenderPage()
ELSE
    THIS.lRuntime = .T.
    THIS.RenderPage(lcText)   && lcText is really the file name    
ENDIF

RETURN THIS.oHTML.GetOutput()
ENDFUNC
* wwVFPScript :: Execute

************************************************************************
* wwVFPScript :: cbExecute
**********************************
***  Function: Forces operation through CodeBlock
***      Pass: lcCode     -   Code to run as string
***            llVFPCode  -   ASP Scripting or VFP code
***    Return: Evaled output or ""
************************************************************************
FUNCTION cbExecute
LPARAMETER lcCode, llVFPCode
LOCAL lcVFPCode

IF !llVFPCode
   lcVFPCode = THIS.ConvertPage(@lcCode,.t.)
*   File2Var("Code.PRG",lcVFPCode)
ENDIF

IF llVFPCode
   THIS.RenderPageFromVar(@lcCode)
ELSE
   THIS.RenderPageFromVar(@lcVFPCode)
ENDIF   

RETURN THIS.oHTML.GetOutput()
ENDFUNC
* wwVFPScript :: ExecuteCodeBlock

************************************************************************
* wwVFPScript :: RenderPage
*******************************
***  Function: Actually creates the HTML from an input file (FXP or PRG
***            in the dev version)
***    Assume:
***      Pass: lcFile     -   File to render (.WCS, .WCT, .FXP)
***            llNoOutput - Result is returned as string but no output
***                         is sent to the wwHTML object.
***    Return: "" or rendered text if llOutput .T.
************************************************************************
FUNCTION RenderPage
LPARAMETER lcFile,llNoOutput
LOCAL lcOutput
PRIVATE poCGI, poHTML, Request,Response,lcFXPFile

lcFile=IIF(type("lcFile")="C",lcFile,THIS.cFileName )

IF THIS.lRuntime AND !THIS.lUseCodeBlock
   lcFile = ForceExt(lcFile,"FXP")
ELSE
*	IF ATC(".WCS",lcFile) > 0
    lcFile = ForceExt(lcFile,"WCT")   
*	ENDIF   
ENDIF	

poCGI = THIS.oCGI
poHTML = THIS.oHTML
Request = CREATEOBJECT("wwScriptRequest",THIS.oCGI)

lcOutFile = sys(2023)+"\WCS_"+Sys(3)+".TMP"

Response = CREATEOBJECT("wwScriptResponse",lcOutfile) 

*** Allow immediate unloading of script
IF THIS.lAlwaysUnloadScript
  lcOldDev = SET("DEVELOPMENT")
  SET DEVELOPMENT ON
  SET PROCEDURE TO (lcFile) ADDITIVE
  SET DEVELOPMENT &lcOldDev
ELSE
  SET PROCEDURE TO (lcFile) ADDITIVE  
ENDIF

*lcFXPFile = FORCEEXT(lcFile,"FXP")

*** Retrieve the Script and trim off __FUNCTION header
EVAL("__"+juststem(lcFile)+"()")

lcOutput = Response.GetOutput()
   
IF THIS.lAlwaysUnloadScript
  * wait window timeout 3 "Releasing: " + FORCEEXT(lcFile,"")
  RELEASE PROCEDURE (FORCEEXT(lcFile,""))  && (lcFxpFile)
ENDIF  

RETURN THIS.oHTML.Send(lcOutput,llNoOutput)
ENDFUNC
* RenderPage


************************************************************************
* wwVFPScript :: RenderPageFromVar
**********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION RenderPageFromVar
LPARAMETERS lcCode, llNoOutput
LOCAL lcOutput
PRIVATE poCGI, poHTML, Request,Response,lcFXPFile

poCGI = THIS.oCGI
poHTML = THIS.oHTML
Request = CREATEOBJECT("wwScriptRequest",THIS.oCGI)

lcOutFile = sys(2023)+"\WCS_"+Sys(3)+".TMP"

Response = CREATEOBJECT("wwScriptResponse",lcOutfile) 

IF THIS.lSaveCode 
   File2Var(SYS(2023) + "\TEMP_WCS.PRG",lcCode)
ENDIF

#IF .T.
loEval = CREATEOBJECT("wwEval")  
loEval.Execute(lcCode)
IF loEval.lError
   lcOutput = "<B>Scripting Error</B><BR>"+CR+;
              "Code: "+loEval.cErrorCode+"<BR>"+CR+;
              "Message: "+loEval.cErrorMessage+"<BR>"+CR+;
              "Script Line: " + STR(loEval.nErrorLine) + " (expanded code)" 
   lcOutput = lcOutput+ CR+Response.GetOutput()              
ELSE
   lcOutput = Response.GetOutput()
ENDIF
#ENDIF

RETURN THIS.oHTML.Send(lcOutput,llNoOutput)
ENDFUNC
* wwVFPScript :: RenderPageFromVar


************************************************************************
* wwVFPScript :: ConvertPage
*********************************
***  Function: Converts a script file from ASP syntax to VFP Syntax
***      Pass: lcFileText  -   (Optional) Text to parse
***                            If omitted data is loaded from WCT file
***            llReturnCode-   Returns the code as a string instead
***                            of writing it to file.
************************************************************************
FUNCTION ConvertPage
LPARAMETER lcFile, llReturnCode
LOCAL lcFile, lcVFPCode, lcEvalReplace, lcOutFile, llReturnCode, lcEvalCode

IF EMPTY(lcFile)
   lcFile = File2var(THIS.cFileName)
ENDIF
lcOutFile = ForceExt(THIS.cFileName,"WCT")

lcEvalCode = "x"
DO WHILE !EMPTY(lcEvalCode)
	lcEvalCode = Extract(lcFile,"<%=","%>")
	IF !EMPTY(lcEvalCode)
	   lcEvalReplace = "<%=" + lcEvalCode + "%>"
	   lcFile = STRTRAN(lcFile,lcEvalReplace,"<<" +ALLTRIM(lcEvalCode) + ">>")
	ENDIF
ENDDO

lcFile = STRTRAN(lcFile,"<%",CHR(13)+"ENDTEXT"+CHR(13))
lcVFPCode =;
 "TEXT" + CHR(13) +;
                STRTRAN(lcFile,"%>",CHR(13)+"TEXT"+CHR(13)) + ;
                CHR(13) + "ENDTEXT"  

IF llReturnCode
   RETURN lcVFPCode
ENDIF
   
File2Var(lcOutFile, "FUNCTION __"+JUSTSTEM(THIS.cFileName)+CR+;
                    lcVFPCode)
ENDFUNC
* ConvertFile

************************************************************************
* wwVFPScript :: CompilePage
*********************************
***  Function: Creates a compiled version that can be run by the
***            runtime version. 
***    Assume: File has a .FXP extension
***      Pass: llDelete    -   Delete intermediate file
************************************************************************
FUNCTION CompilePage

lcFileName = ForceExt(THIS.cFileName,"WCT")

COMPILE  (lcFileName)  && Create file with .FXP extension

*** Delete .WCT File?
IF THIS.lDeleteGeneratedCode
   ERASE (FORCEEXT(lcFileName,"wct"))
ENDIF

lcErrFile = ForceExt(THIS.cFileName,"ERR")
IF FILE(lcErrFile)
   THIS.cCompileErrors = THIS.cCompileErrors +;
                         "*********** " + THIS.cFileName + " Errors *************"+CR+;
                         File2Var(lcErrFile)+CR+CR
   ERASE (lcErrFile) 
ENDIF

IF !FILE(ForceExt(THIS.cFileName,"FXP"))
   RETURN .F.
ENDIF

RETURN .T.
ENDFUNC
* CompilePage



ENDDEFINE
*EOC wwVFPScript

*************************************************************
DEFINE CLASS wwScriptResponse AS Relation
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1997
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 11/18/97
***
***  Function:
*************************************************************

*** Custom Properties
oVFPScript = .NULL.
cFileName = ""

*** Stock Properties

************************************************************************
* wwResponse :: Init
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init
LPARAMETERS lcOutputFile, loVFPScript

SET TEXTMERGE ON
SET TEXTMERGE TO (lcOutputFile) NOSHOW
THIS.cFileName = lcOutputFile
THIS.oVFPScript = loVFPScript

ENDFUNC
* wwResponse :: Init

************************************************************************
* wwResponse :: Write
*********************************
***  Function: Basic Output Method for scripting. Used for direct
***            call or when using <%= <expression %> syntax.
************************************************************************
FUNCTION Write
LPARAMETER lvExpression

\\<<lvExpression>>

ENDFUNC
* Write

************************************************************************
* wwResponse :: Clear
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Clear

SET TEXTMERGE TO (THIS.cFileName)

ENDFUNC
* wwResponse :: Clear

************************************************************************
* wwResponse :: GetOutput
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION GetOutput

SET TEXTMERGE TO
lcOutput = file2Var(THIS.cFileName)
ERASE (THIS.cFileName)

RETURN lcOutput 
ENDFUNC
* wwResponse :: GetOutput


************************************************************************
* wwResponse :: Redirect
*********************************
***  Function: Redirects to another URL
***    Assume:
***      Pass: lcURL  -  New URL to redirect to
************************************************************************
FUNCTION Redirect
LPARAMETERS lcTarget

THIS.Clear()

THIS.Write(THIS.oVFPScript.oHTML.HTMLRedirect(lcTarget,.T.))

ENDFUNC
* wwResponse :: Redirect

************************************************************************
* wwResponse :: Cookies
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Cookies
LPARAMETERS lcCookie, lcValue, lcPath, lcExpires

THIS.oCGI.SetCookie(lcCookie,lcValue,lcPath,lcExpires)

ENDFUNC
* wwResponse :: Cookies
 
ENDDEFINE
*EOC wwResponse

*************************************************************
DEFINE CLASS wwScriptRequest AS Relation
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1997
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 11/18/97
***
***  Function:
*************************************************************

*** Custom Properties
oCGI = .NULL.
*** Stock Properties

************************************************************************
* wwScriptRequest :: Init
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Init
LPARAMETER loCGI
THIS.oCGI=loCGI
ENDFUNC
* Init

************************************************************************
* wwScriptRequest :: Form
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Form
LPARAMETER lcKey
RETURN THIS.oCGI.GetFormVar(lcKey)
ENDFUNC
* Form

************************************************************************
* wwScriptRequest :: QueryString
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION QueryString
LPARAMETERS lcKey
IF EMPTY(lcKey)
   RETURN THIS.oCGI.GetCGIParameter()
ENDIF
RETURN THIS.oCGI.QueryString(lcKey)
ENDFUNC
* QueryString

************************************************************************
* wwScriptRequest :: ServerVariables
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION ServerVariables
LPARAMETERS lcKey
IF EMPTY(lcKey)
   RETURN ""
ENDIF
lcResult = THIS.oCGI.GetCGIVar(lcKey)
IF EMPTY(lcResult) 
   lcResult = THIS.oCGI.GetCGIVar(lcKey,"Extra Headers")
ENDIF

RETURN lcResult
ENDFUNC
* wwScriptRequest :: ServerVariables

ENDDEFINE
*EOC wwScriptRequest
