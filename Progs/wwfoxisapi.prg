SET PROCEDURE TO WWUTILS ADDITIVE
SET PROCEDURE TO WWVFPSCRIPT ADDITIVE
SET PROCEDURE TO wwEVal ADDITIVE

o=CREATE("wwFoxISAPI")
*? o.Process("&Rick=No+Good&Looser=Testing+me&","c:\temp\temp.ini")

? o.ExpandTemplate("","c:\temp\temp.ini")

RETURN

*** FoxISAPI base class


*** Some required #DEFINEs
#INCLUDE Include\WCONNECT.H

*************************************************************
DEFINE CLASS wwFoxISAPI AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: http://www.west-wind.com/
***  Modified: 04/15/98
***            Provided courtesy of West Wind Web Connection
***
***            You are free to use this class inside of
***            this class framework, but it may not be
***            used to build a commercial framework.
***
***  Function: This is a simplified FOXISAPI class that
***            provides basic utility functions required
***            to work with the FoxISAPI input and generate
***            the HTML output.
*************************************************************

*** Custom Properties

*** Worker Objects for Input (oRequest) and output (oResponse)
oRequest = .NULL.
oResponse = .NULL.

lError = .F.
cErrorMsg = ""

cDataPath = ""
lSaveRequestInfo = .F.

*** MTS methods
lUseMTS = .F.
oMTS = .NULL.
oMTSContext = .NULL.
lMTSCompleted = .F.

*** 1 - Codeblock   2 - VFP Compiled (fxp)
nScriptMode = 2

*** This is used only for editing the INI file in HTML mode
cFoxISAPIIniFile = "c:\westwind\foxisapi\foxisapi.ini"

************************************************************************
* wwFoxISAPI :: Init
*********************************
***  Function: Initialize the HTML output to be blank
************************************************************************
FUNCTION Init

*** Environment setup
SET SAFETY OFF
SET CPDIALOG OFF
SET EXCLUSIVE OFF
SET REPROCESS TO 2 SECONDS
SET EXACT OFF
SET DELETED ON

*** VERY IMPORTANT: You have to set the default path to force
***                 the server to start out of its server directory!
***                 If this code is not here the server runs in
***                 the SYSTEM path.
lcStartPath = GetAppStartPath()
SET DEFAULT TO (lcStartPath)

*** Create the worker objects
THIS.oRequest = CREATE("wwRequest")
THIS.oResponse = CREATE("wwResponse")

*wait window "Init..." + GetAppStartPath()

IF THIS.lUseMTS
   THIS.oMTS = CREATE("MTXaS.Appserver.1")
ENDIF   


ENDFUNC
* Init

************************************************************************
* wwFoxISAPI :: Process
*********************************
***  Function: Genereric Entry Point Method used for all requests.
***            This method requires that a ?Method=SomeMethod query
***            string is provided on the command line.
***            This method makes it possible to automatically load
***            the Request and Response objects automatically.
***    Assume: Always called from the Web server directly!
***      Pass: lcFormVars
***            lcIniFile
***            lnRelease
***    Return: HTML OUtput
************************************************************************
FUNCTION Process
LPARAMETERS lcFormVars, lcIniFile, lnRelease
LOCAL lcMethod
PRIVATE Response, Request

IF THIS.lUseMTS
   THIS.oMTSContext = THIS.oMTS.GetObjectContext()
   THIS.lMTSCompleted = .F.
ENDIF   

Response=THIS.oResponse
Request=THIS.oRequest

lnRelease = 0
THIS.StartRequest(lcFormVars, lcIniFile, lnRelease)
lcMethod = Request.QueryString("Method")
lcPhysicalPath = Request.GetPhysicalPath()

DO CASE
   *** Protect against illegal method calls - only fatal one is PROCESS really
   CASE INLIST(lcMethod,"PROCESS","LOAD","INIT","DESTROY")
      THIS.StandardPage("Invalid Method: " +lcParameter,"This method name is illegal...")

   *** Handle Template and Script Pages
   CASE ATC(".wcs",lcPhysicalPath) > 0
      THIS.ExpandScript(lcPhysicalPath)
   CASE ATC(".wc",lcPhysicalPath) > 0
      THIS.ExpandTemplate(lcPhysicalPath)
      
   *** Generic! Method names must the 1st parameter for the generic Method call to work.
   ***          If you use different method names or parameters a custom CASE statement
   ***          should be added *ABOVE* this line!
   ***
   *** Call methods that were specified on the command line's 1st parm
   ***  ie:   wwcgi.exe?Project~Method~MoreParameters
   CASE !EMPTY(lcMethod) AND PEMSTATUS(THIS,lcMethod,5)
      =EVALUATE("THIS."+lcMethod+"()")
   OTHERWISE
      THIS.StandardPage("Invalid Method call","This server does not support this method: " + lcMethod)
ENDCASE

IF THIS.lSaveRequestInfo
   File2Var(SYS(2023) + "\temp.htm",THIS.oResponse.GetOutput())
   COPY FILE (lcIniFile) TO (SYS(2023) + "\temp.ini")
ENDIF

IF THIS.lUseMTS AND !THIS.lMTSCompleted
   THIS.oMTSContext.SetAbort()
ENDIF   

RETURN THIS.oResponse.GetOutput()
ENDFUNC
* wwFoxISAPI :: Process


************************************************************************
* wwFoxISAPI :: ServerTest
*********************************
***  Function: Sample request that returns all server variables and
***            form variables.
***      Pass: FoxISAPI parameters or nothing
***    Return: 
************************************************************************
FUNCTION ServerTest
LPARAMETER lcFormVars, lcIniFile, lnUnload

IF !EMPTY(lcIniFile) AND EMPTY(lcFormVars)
   THIS.StartRequest(lcFormVars, lcIniFile)
ENDIF   

Response = THIS.oResponse

THIS.StandardPage("Server Test","")

Response.Write([<TABLE>])
Response.Write([<TR><TD BGCOLOR="#CCCCFF"><h3>Raw Form Variables</h3></td></TR>])
Response.Write([<TR><TD><PRE>]+THIS.oRequest.cFormVars+[<PRE><p> </td></TR>])

Response.Write([<TR><TD BGCOLOR="#CCCCFF"><h3>Parsed Form Variables (wwFoxISAPI::Form())</h3></td></TR>])

Response.Write([<TR><TD>])

DIMENSION laVars[1,2]

lnCount = THIS.oRequest.aFormVars(@laVars)
FOR x=1 to lnCount
  Response.Write("<b>"+laVars[x,1]+"</b>="+lavars[x,2]+"<BR>")
ENDFOR

Response.Write([<p> </td></TR>])
Response.Write([<TR><TD BGCOLOR="#CCCCFF"><h3>Server Variables (Ini File)</h3></td></TR>])
Response.Write([<TR><TD><PRE>]+FileToStr(THIS.oRequest.cContentFile)+[</PRE></td></TR>])

RETURN THIS.oResponse.Getoutput()
ENDFUNC
* wwFoxISAPI :: ServerTest



************************************************************************
* wwFoxISAPI :: StartRequest
*********************************
***  Function: This sets up the basics of the Request by assigning
***            various settings. Sets and decodes form variables,
***            and assigns the INI file to a class property
***    Assume: Should be called at the top of each request
***      Pass: lcFormVars   -   The form vars passed to the request
***                             by FOXISAPI.DLL.
***            lcIniFile    -   The INI file that contains the server
***                             vars.
***    Return: nothing
************************************************************************
PROTECTED FUNCTION StartRequest
LPARAMETERS lcFormVars, lcIniFile, lnUnload

lcFormVars=IIF(!EMPTY(lcFormVars),lcFormVars,"")
lcIniFile=IIF(!EMPTY(lcIniFile),lcIniFile,"")
lnUnload=IIF(EMPTY(lnUnload),0,lnUnload)

*** Set up the Request and Response objects
THIS.oRequest.LoadRequest(lcFormVars,lcIniFile)
THIS.oResponse.Rewind()

THIS.lError = .f.
THIS.cErrorMsg = ""

ENDFUNC
* StartRequest


************************************************************************
* wwFoxISAPI :: StandardPage
*********************************
***  Function: Simple routine to display a page with a header and
***            body.
***      Pass: lcHeader  -   Header Text
***            lcBody    -   Body of a document
***    Return: "" or 
************************************************************************
PROTECTED FUNCTION StandardPage
LPARAMETERS lcHeader, lcBody

THIS.lError = .f.
THIS.cErrorMsg = ""

*** Clear all output!
THIS.oResponse.Rewind()
THIS.oResponse.ContentTypeHeader()

lcOutput = ;
	[<font size="4" face="Verdana"><b>] + CR +;
	lcHeader + [</b></font><p>] + CR +;
	[<font face="Verdana" Size="-1">]+ CR +;
	lcBody+ [</font>] + CR 

THIS.oResponse.Write(lcOutput)	

RETURN
* StandardPage


************************************************************************
* wwFoxISAPI :: ExpandTemplate
*********************************
***  Function: Wrapper function that evaluates a scripted page and
***            adds a default content type header
***      Pass: lcFilename  -  Name of the page to expand
************************************************************************
FUNCTION ExpandTemplate
LPARAMETER lcFileName

*** Default Content Type 
Response.ContentTypeHeader()

*** And expand the actual template
Response.ExpandTemplate(lcFileName)

RETURN

************************************************************************
* wwFoxISAPI :: ExpandScript
*********************************
***  Function: Wrapper function that evaluates a scripted page and
***            adds a default content type header
***      Pass: lcFilename  -  Name of the page to expand
************************************************************************
FUNCTION ExpandScript
LPARAMETER lcFileName

Response.ContentTypeHeader()
Response.ExpandScript(lcFileName,THIS.nScriptMode)

RETURN
* wwFoxISAPI :: ExpandTemplate

************************************************************************
* wwFoxISAPI :: FlipScriptMode
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION SetScriptMode

lnMode = VAL(Request.QueryString("ScriptMode"))
IF lnMode = 0
   lnMode = 1
ENDIF

THIS.nScriptMode = lnMode
   
THIS.StandardPage("Script Mode Set","New value is: <b>" + ;
                  IIF(lnMode = 1,"Interpreted","Compiled")  + "</b>")
ENDFUNC
* wwFoxISAPI :: FlipScriptMode


************************************************************************
* wwFoxISAPI :: ErrorMsg
*********************************
***  Function: Just like StandardPage
************************************************************************
PROTECTED FUNCTION ErrorMsg
LPARAMETERS lcHeader, lcBody
THIS.StandardPage(lcHeader,lcBody)
ENDFUNC
* wwFoxISAPI :: ErrorMsg


************************************************************************
* wwFoxISAPI :: EditConfig
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
PROTECTED FUNCTION EditConfig

Response.HTMLHeader("FoxISAPI.ini Configuration")

lcLogicalPath = Request.ServerVariables("Logical Path")
lcAction = UPPER(Request.QueryString("Action"))

IF lcAction = "SAVE"
   lcIniFile = Request.Form("txtIniFile")
   IF !EMPTY(lcIniFile)
      File2Var(THIS.cFoxISAPIIniFile,lcIniFile)
   ENDIF
ENDIF

*** Always re-read the file
lcIniFile = File2Var(THIS.cFoxISAPIIniFile)
IF EMPTY(lcIniFile)
   THIS.ErrorMsg("Invalid File",;
                 "FoxISAPI.ini wasn't found or doesn't contain any data")
   RETURN 
ENDIF

Response.SendLn([<table border="1" width="502" cellspacing="0" height="459">])
Response.SendLn([  <tr>])
Response.SendLn([    <td width="100%" bgcolor="#FFFF00" height="23"><font face="Verdana" color="#000000"><big><strong>])
Response.SendLn([     FoxISAPI.ini Settings:</strong></big></font></td>])
Response.SendLn([  </tr>])
Response.SendLn([  <tr>])
Response.SendLn([    <td width="100%" height="448">])
Response.SendLn([    <form method="POST" action="/foxisapi/foxisapi.dll]+lcLogicalPath+[?Method=EditConfig&Action=Save">])
Response.SendLn([     <textarea rows="9" name="txtIniFile" cols="73" style="font-family: Courier New; font-size: 10pt; ; font-weight: bold; width=; Height=400">])
Response.SendLn(lcIniFile)
Response.SendLn([     </textarea>])
Response.Send([     <input type="submit" value="Save Changes" name="btnSubmit" style="font-family: Tahoma; font-size: 10pt; padding-left: 10; padding-right: 10">])
Response.SendLn([   </form></td>])
Response.SendLn([  </tr>])
Response.SendLn([</table>])
RETURN
ENDFUNC
* wwFoxISAPI :: EditConfig


FUNCTION ShowCode
************************************************************************
* wcDemoServer :: ShowCode
*********************************
***  Function: Routine displays code for a given routine
***    Assume: Url: ?ShowMethod=FirstQuery&PRG=Test.prg
************************************************************************

lcMethod=Request.QueryString("ShowMethod")
lcFile = Request.QueryString("PRG")

IF EMPTY(lcFile)
   lcFile = FORCEEXT(PROGRAM(),"PRG")
ENDIF   
lcProgram = File2Var(lcFile)

lcCode=Extract(lcProgram,"FUNCTION "+lcMethod,"FUNCTION ")

Response.ContentTypeHeader("text/plain")
Response.SendLn(lcCode)

ENDFUNC
* ShowCode


*#IF !DEBUGMODE

************************************************************************
* wwFoxISAPI :: Error
*********************************
***  Function: Limited Error handler. Not much we can do here other
***            than exit. Displays error page.
************************************************************************
FUNCTION Error
LPARAMETERS nError, cMethod, nLine
LOCAL lcOutput

THIS.lError = .T.
THIS.cErrorMsg = THIS.cErrorMsg + STR(nError) + " - " + Message() + " - " + Message(1) + " - " +cMethod + " @ " + STR(nLine) + CHR(13)

* lcOutput = THIS.oResponse.cOutput

THIS.StandardPage("Hold on... we've got a problem!",;
                  "The current request has caused an error in Visual FoxPro.<p>"+CR+;
                  "Error Number: "+STR(nError)+"<BR>"+CR+;
                  "Error: "+Message()+"<BR>"+CR+;
                  "Code: "+Message(1)+"<BR>"+CR+;
                  "Running Method: "+cMethod+"<BR>"+CR+;
                  "Current Code Line: "+STR(nLine) )
                  
THIS.oResponse.SendLn("<HR>")
                  
*** Stop further output
THIS.oResponse.lNoOutput=.T.

RETURN TO Process
ENDFUNC
* Error

* #ENDIF

ENDDEFINE
* FoxISAPI

*************************************************************
DEFINE CLASS wwRequest AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Function: FoxISAPI Request Handler class that retrieves
***            form info and Server/Browsers vars 
***            transparently
*************************************************************

#INCLUDE Include\WCONNECT.H

*** Custom Properties

*** Commonly accessed vars
cContentFile=""
cFormVars=""

cQueryString=""
cConfigFile=""   && wc.ini

*cPathOverride=""
DIMENSION aParms[1]
nParmCount=0
oApi=.NULL.

*** Parsed out OLE Class string
cOLEClassString=""      && Full Server Class name string
cOLEServer=""       && Server only
cOLEClass=""        && Class only
cOLEMethod=""       && Method Only


FUNCTION Init
************************************************************************
* wwRequest :: Init
*********************************
***  Function: Init loads receive the Form vars and Ini file
***            for configuration
***      Pass: lcFormVars  -   FoxISAPI form variables
***            lcIniFile   -   The name of the Ini file
************************************************************************
LPARAMETER lcFormVars, lcIniFile

DECLARE INTEGER GetPrivateProfileString ;
   IN WIN32API ;
   STRING cSection,;
   STRING cEntry,;
   STRING cDefault,;
   STRING @cRetVal,;
   INTEGER nSize,;
   STRING cFileName

THIS.LoadRequest(lcFormVars,lcIniFile)

ENDPROC
* Init


************************************************************************
* wwRequest :: LoadRequest
*********************************
***  Function: Populates the Request object with info from the
***            form var string and INI file
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION LoadRequest
LPARAMETERS lcFormVars, lcIniFile

lcFormVars=IIF(EMPTY(lcFormVars),"",lcFormVars)
lcIniFile=IIF(EMPTY(lcIniFile),"",lcIniFile)

THIS.cContentFile = lcIniFile
THIS.cFormVars = "&" + lcFormVars + "&"

*** Retrieve the query string for parsing
THIS.cQueryString = THIS.GetCGIVar("Query String")

ENDFUNC
* wwRequest :: LoadCgi

*** High Level ASP-like Access Methods: 
****     Form, ServerVariables and QueryString

************************************************************************
* wwRequest :: Form
*********************************
***  Function: Returns a form variable
***      Pass: lcFormVar  - Variable to return
***    Return: Form variable or "" on error
************************************************************************
FUNCTION Form
LPARAMETERS lcFormVar
RETURN THIS.GetFormVar(@lcFormVar)
ENDFUNC
* wwRequest :: Form

************************************************************************
* wwPostRequest :: aFormVars
*********************************
***  Function: Retrieves all form variables from the Form request
***            string.
***    Assume: String starts with &
***      Pass: @taVars     -     2D Array that will be filled with
***                              Key/Value pairs
***    Return: Number of rows
************************************************************************
FUNCTION aFormVars
LPARAMETERS taVars
LOCAL x,lcPointer, lnAt, lnEqual, lcKey, lcValue

x=0
lcPointer = THIS.cFormVars
lnAt = AT("&",lcPointer)
IF lnAt = 0
   RETURN 0
ENDIF
lcPointer = SUBSTR(lcPointer,lnAt+1)


DO WHILE lnAt > 0
  *** Find = sign then extract the value
  lnEqual = AT("=",lcPointer)

  *** No Equal Sign - Invalid key so skip it
  IF lnEqual = 0
     lnAt=AT("&",lcPointer)
     LOOP
  ENDIF
     
  lcKey = SUBSTR(lcPointer,1,lnEqual-1)
  
  lcPointer = SUBSTR(lcPointer,lnEqual+1)
  
  *** Find the & 
  lnAt = AT("&",lcPointer)
  IF lnAt = 0
     lcValue = lcPointer
  ELSE
     lcValue = LEFT(lcPointer,lnAt - 1)
  ENDIF
  
  lcValue = URLDecode(lcValue) 
  lcKey = URLDecode(lcKey)

  x=x+1
  DIMENSION taVars[x,2]
  taVars[x,1]=lcKey
  taVars[x,2]=lcValue
  
  lcPointer = SUBSTR(lcPointer,lnAt + 1 )
ENDDO  

RETURN x
ENDFUNC
* AFormVars

************************************************************************
* wwRequest :: ServerVariables
*********************************
***  Function: Returns a server variable
***      Pass: lcServerVar -  ServerVariable name
***            lcSection   -  Optional (default "CGI")
***    Return: Server Variable or "" if doesn't exist
************************************************************************
FUNCTION ServerVariables
LPARAMETERS lcServerVar, lcSection
RETURN THIS.GetCGIVar(@lcServerVar, @lcSection)
ENDFUNC
* wwRequest :: ServerVariables

************************************************************************
* wwRequest :: QueryString
*********************************
***  Function: Returns a URL Encoded parameter from the querystring
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION QueryString
LPARAMETERS lvParameter

#IF wwVFPVersion > 5
  IF VARTYPE(lvParameter) = "C"
#ELSE
  IF TYPE("lvParameter") = "C"
#ENDIF
   RETURN GetUrlEncodedKey("&"+THIS.cQueryString+"&",@lvParameter)
ELSE
   RETURN THIS.GetCGIParameter(lvParameter)
ENDIF

ENDFUNC
* wwRequest :: QueryString

*** Low Level Retrieval Methods

FUNCTION GetCGIVar
************************************************************************
* wwRequest :: GetCGIVar
*********************************
***  Function: Generic CGI access routine that allows retrieving a value
***            from the CGI INI ContentFile.
***      Pass: lcVariable  -   Variable to return value for
***            lcSection   -   Section in the INI file (default: 'CGI')
***            llForceNull -   When .T. returns .NULL. if the entry
***                            can't be found. Otherwise "" is returned.
***    Return: "" if not found or string otherwise
************************************************************************
LPARAMETERS lcVariable, lcSection 
LOCAL lcResult,lnResult

IF TYPE("lcSection") # "C"
  lcSection="FOXISAPI"
ENDIF   

*** Initialize buffer for result
lcResult=SPACE(512)

*** DECLARE LOADED IN INIT
lnResult=GetPrivateProfileString(lcSection,lcVariable,"*NONE*",;
                                 @lcResult,LEN(lcResult),THIS.cContentFile)
                         
*** Trim off the NULL
lcResult = SUBSTR(lcResult,1,lnResult)  

IF lcResult="*NONE*"
  lcResult=""
ENDIF

RETURN lcResult
ENDFUNC
* GetCGIVar


FUNCTION GetFormVar
************************************************************************
* wwRequest :: GetFormVar
*********************************
***  Function: Retrieves a 'parameter' from the query string that
***            is encoded with standard CGI/ISAPI URL encoding.
***            Typical URL encoding looks like this:
***
***    "User=Rick+Strahl&ID=0011&Address=400+Morton%0A%0DHood+River"
***
***      Pass: lcVal   -   Form Variable to retrieve
***    Return: Value or ""
************************************************************************
LPARAMETERS lcVarname
LOCAL lcRetVal,lcIniValue

IF EMPTY(lcVarname)
  RETURN ""
ENDIF

RETURN GetUrlEncodedKey(THIS.cFormVars,lcVarname)
ENDFUNC
* GetFormVar

************************************************************************
* wwRequest :: GetFormCheckBox
*********************************
***  Function: Retrieves an HTML Form variable for a checkbox and
***            returns .T. or .F. instead of ON or OFF
***      Pass: tcVarName  -  The name of the HTML Form Variable
***    Return: .T. or .F.
************************************************************************
FUNCTION GetFormCheckBox
LPARAMETERS tcVarName
LOCAL lcValue
lcValue=UPPER(THIS.GetFormVar(tcVarName))

IF lcValue="ON" OR lcValue="YES"
   RETURN .T.
ENDIF

RETURN .F. 
ENDFUNC
* GetFormCheckBox

FUNCTION GetFormMultiple
************************************************************************
* wwPostRequest :: GetFormMultiple
*********************************
***  Function: Returns a multiselection list in an array.
***      Pass: taVars  -  Array of selected values (pass by Reference!)
***    Return: count of selected values.
************************************************************************
LPARAMETERS taVars,tcVarname
LOCAL x, lcValue, lnAt, lcFind, lcPointer

x=0
lcPointer = THIS.cFormVars
lcFind = "&"+STRTRAN(tcVarname," ","+")+"="
lnAt = ATC(lcFind,lcPointer)
IF lnAt = 0
   RETURN 0
ENDIF

DO WHILE lnAt > 0
  lcValue = GetUrlEncodedKey(lcPointer,tcVarName) 

  x=x+1
  DIMENSION taVars[x]
  taVars[x]=lcValue
  
  lcPointer = SUBSTR(lcPointer,lnAt + LEN(lcFind))
  lnAt = ATC(lcFind,lcPointer)
ENDDO  

RETURN x
ENDFUNC
* GetFormMultiple

************************************************************************
* wwPostRequest:: SetKey
*********************************
***  Function: Updates a URLEncoded key in cFormVars. This is useful
***            to have AutoUpdate routines such as wwForm::SetValues()
***            override certain values.
***      Pass: lcKey      -   Key to update
***            lcValue    -   Value to set to 
***            lvReserved -   Compatibility
************************************************************************
FUNCTION SetKey
LPARAMETERS lcKey, lcValue, lvReserved

lcFullValue=WWC_NULLSTRING

lcFormVars = THIS.cFormVars
lcValue = URLEncode(lcValue)
lcKey = STRTRAN(lcKey," ","+")

lnLoc=ATC("&"+lcKey+"=",lcFormVars)

if lnLoc > 0
   lcRest = SUBSTR(lcFormvars,lnLoc)
   lnLength = ATC("&",lcRest,2) 
   IF lnLength=< 1 
      *** No & at end - full string size
      lnLength = LEN(lcRest) + 1 && One to long to match &
   ENDIF
   lcFullValue = LEFT(lcRest,lnLength-1)
   THIS.cFormvars = STRTRAN(lcFormvars,lcFullValue,"&"+lcKey+"="+lcValue)
ELSE
   THIS.cFormVars=THIS.cFormVars + "&" + lcKey +"="+lcValue
ENDIF

ENDFUNC
* SetKey


*****************  END OF BASE ACCESS FUNCTIONS *************************

*************** BEGIN  CUSTOM CONVENIENCE ACCESS FUNCTIONS **************

FUNCTION GetContentFile
************************************************************************
* wwRequest :: GetContentFile
*********************************
***  Function: Returns the name of the CGI Content file
************************************************************************
RETURN THIS.cContentFile
ENDFUNC
* GetContentFile

FUNCTION GetCGIParameter
************************************************************************
* wwRequest :: GetCGIParameter
*********************************
***  Function: Returns the optional numbered parameter returned on the
***            CGI command line (wwRequest?Optional_Parm)
***      Pass: Parameter Number (0 to pass full string)
************************************************************************
LPARAMETER tnParmNo

tnParmNo=IIF(type("tnParmNo")="N",tnParmNo,0)

IF tnParmNo>0
   IF tnParmNo>THIS.nParmCount
      RETURN ""
   ELSE
      IF THIS.aParms[1]=.f.
         THIS.aCGIParms()
      ENDIF
      RETURN THIS.aParms[tnParmNo]
   ENDIF
ENDIF

*** Return full parameter string
RETURN THIS.cQueryString
ENDFUNC
* GetCGIParameter

FUNCTION aCGIParms
************************************************************************
* wwRequest :: aCGIParms
*********************************
***  Function: Builds an array of parameters passed (following the ?).
***            Each parameter must be separated by a special character
***            (~ by default) seperator and a character used for 
***            spaces (+ by default).
***      Pass: tcSeparator  -  character that separates individual
***                            parameters. ('~')
***            tcSpace      -  Character that replaces spaces in
***                            the parameter string. ('+')
***    Return: parameter count  -  array is filled with parameters
***
***   Example: DIMENSION laParms[1]
***            lnParms=loCGI.aCGIParms(@laParms,loCGI.GetCGIParameter(),;
***                                    "~","+")
************************************************************************
LPARAMETERS tcSeparator, tcSpace
LOCAL x, taParms, lnSize

tcParmString = THIS.cQueryString

tcSeparator=IIF(type("tcSeparator")="C",tcSeparator,"~")
tcSpace=IIF(type("tcSpace")="C",tcSpace,"+")

*** Translate spaces first
tcParmString=CHRTRAN(tcParmString,tcSpace," ")

*** Now get parameters 

*** Convert parameters to indivdual lines of text
tcParmString=CHRTRAN(tcParmString,tcSeparator,CHR(13))
tcParmString=STRTRAN(tcParmString,"??",CHR(13)) && AOL browser doesn't do POST

*** Figure out size
lnSize=MEMLINES(tcParmString)
IF lnSize=0
   *** Array must be at least 1 element
   lnSize=1
ENDIF   

*** Resize the array
DIMENSION THIS.aParms[lnSize]
THIS.aParms=0  && Fix Memory Leak bug

FOR x=1 TO lnSize
   THIS.aParms[x]=MLINE(tcParmString,x)
ENDFOR && x=1 TO MEMLINES(tcParmString)

THIS.nParmCount=x-1
RETURN x-1
ENDFUNC
* aCGIParms


FUNCTION GetPhysicalPath
************************************************************************
* wwRequest :: GetPhysicalPath
*********************************
***  Function: Returns the physical path of the document that
***            created this CGI request if available.
************************************************************************
RETURN THIS.GetCGIVar("Physical Path")
ENDFUNC
* GetPhysicalPath

FUNCTION GetLogicalPath
************************************************************************
* wwRequest :: GetLogicalPath
*********************************
***  Function: Returns the logical path of the document that
***            created this CGI request if available. This path
***            is the one specified *AFTER* the script name:
************************************************************************
RETURN THIS.GetCGIVar("Logical Path")
ENDFUNC
* GetLogicalPath

FUNCTION SetOLEClass
************************************************************************
* wwRequest :: SetOLEClass
*********************************
***  Function: This function extracts an OLE server class string
***            that's passed on the Extra path of the URL and breaks
***            the string into its component pieces:
***            /cgi-win/wwRequest.dll/OLESERVER.OLECLASS.OLEMETHOD?Parm1
***
***            Populates the following public properties:
***                  cOLEClassString  -  the entire string
***                  cOLEServer   -  The server only
***                  cOLEClass 
***                  cOLEMethod
***
***    Return: .T. on success .F. on failure (not found)
************************************************************************
LPARAMETER lcOLEString

lcOleString=IIF(type("lcOleString")="C",lcOleString,THIS.GetLogicalPath())

IF EMPTY(lcOLEString)
   RETURN .F.
ENDIF   

*** Strip off leading slash
lcOLEString=chrtran(lcOLEString,"\/,","")
THIS.cOLEClassString=lcOLEString

*** OLE Server must contain two periods as separators
lnDot1=AT(".",lcOLEString,1)  
lnDot2=AT(".",lcOLEString,2)
IF lnDot1=0 or  lnDot2=0
   RETURN .F.
ENDIF   

THIS.cOLEServer=SUBSTR(lcOLEString,1,lnDot1-1)
THIS.cOLEClass=SUBSTR(lcOLEString,lnDot1+1,lnDot2-lnDot1-1)
THIS.cOLEMethod=SUBSTR(lcOLEString,lnDot2+1)

RETURN .T.
ENDFUNC
* SetOLEClass


FUNCTION GetPreviousUrl
************************************************************************
* wwRequest :: GetPreviousURL
*********************************
***  Function: Returns the URL of the referring document or request or
***            .NULL.
************************************************************************
LOCAL lcUrl
RETURN THIS.GetCGIVar("Referer")
ENDFUNC
* GetPreviousURL

FUNCTION GetAuthenticatedUser
************************************************************************
* wwRequest :: GetAuthenticatedUser
*********************************
***  Function: Returns the Authenticated user or "" if not logged on
***    Assume: Authentication is specific to a given directory and
***            down.
************************************************************************
RETURN THIS.GetCGIVar("Authenticated Username")
ENDFUNC
* GetAuthenticatedUser

FUNCTION GetServerAdmin
************************************************************************
* wwRequest :: GetServerAdmin
*********************************
***  Function: Returns the name of the server Administrator or .NULL.
************************************************************************
RETURN THIS.GetCGIVar("Server Admin")
ENDFUNC
* GetServerAdmin


FUNCTION GetBrowser
************************************************************************
* wwRequest :: GetBrowser
*********************************
***  Function: Returns the name of the Browser used to access server.
***            Returns "Mozilla" plus version for Netscape for example.
************************************************************************
RETURN THIS.GetCGIVar("HTTP_USER_AGENT","ALL_HTTP")
ENDFUNC
* GetBrowser


************************************************************************
* wwRequest :: IsLinkSecure
*********************************
***  Function: Returns whether the request was returned over a secure
***            link.
***    Assume: Default Secure port is 443.
***      Pass: lcSecurePort -  If your secure port is on a different
***                            port specify this parameter.
***    Return: .T. or .F.
************************************************************************
FUNCTION IsLinkSecure
LPARAMETER lcSecurePort
lcSecurePort=IIF(type("lcSecurePort")="C",lcSecurePort,"443")
RETURN IIF(THIS.GetCGIVar("Server Port") = lcSecurePort,.T.,.F.)
ENDFUNC
* IsLinkSecure


FUNCTION GetCookie
************************************************************************
* wwRequest :: GetCookie
*********************************
***  Function: Returns a HTTP Cookie previously set by Browser.
***    Assume: Cookies work only with Netscape, IE and other new
***            browsers. Cookies must be set with an HTTP header
***      Pass: lcCookie  -  Name of the cookie to return value for
***    Return: Cookie value or "" if not found
************************************************************************
LPARAMETERS lcCookie
LOCAL lcCookieString, lcValue

lcCookieString=THIS.GetCGIVar("HTTP_COOKIE","ALL_HTTP")
lcValue=EXTRACT(lcCookieString,;
                TRIM(lcCookie)+"=",";","",.T.)

RETURN lcValue
ENDFUNC
* GetCookie

FUNCTION GetRemoteAddress
************************************************************************
* wwRequest :: GetRemoteAddress
*********************************
***  Function: Returns the remote address that is requesting the CGI
***            operation. This is the remote's IP address or domain
***            name if IP Resolution is turned on on the server
***
***    Assume: Not supported by all browsers.
************************************************************************
RETURN THIS.GetCGIVar("Remote Address")
ENDFUNC
* GetRemoteAddress

FUNCTION GetRequestMethod
************************************************************************
* wwRequest :: GetRequestMethod
*********************************
***  Function: Returns the Request Method ("POST", "GET").
************************************************************************
RETURN THIS.GetCGIVar("Request Method")
ENDFUNC
* GetRequestMethod

FUNCTION GetRequestProtocol
************************************************************************
* wwRequest :: GetRequestProtocol
*********************************
***  Function: Returns the protocol requested by the Browser.
***            Example: 'HTTP/1.0'
************************************************************************
RETURN THIS.GetCGIVar("Request Protocol")
ENDFUNC
* GetRequestProtocol

FUNCTION GetServerName
************************************************************************
* wwRequest :: GetServerName
*********************************
***  Function: Returns the Server's domain name or IP address.
************************************************************************
RETURN THIS.GetCGIVar("Server Name")
ENDFUNC
* GetServerName


ENDDEFINE
*EOC wwRequest


*************************************************************
DEFINE CLASS wwResponse AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1998
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 03/15/98
***
***  Function:
*************************************************************

*** Custom Properties
cOutput = ""
lNoOutput = .F.

************************************************************************
* wwResponse :: Rewind
*********************************
***  Function: Use this if you need to reset the the wwResponse
***            object without creating a new object.
************************************************************************
FUNCTION Rewind

THIS.cOutput = ""
THIS.lNoOutput = .F.

ENDFUNC
* wwResponse :: Rewind

************************************************************************
* wwResponse :: Send
*********************************
***  Function: Creates and manages output
***      Pass: lcText      -   Text to output
***            llNooutput  -   Return text only - don't send to output
***    Return: "" or text if llNoOutput = .T.
************************************************************************
FUNCTION Send
LPARAMETERS lcText, llNoOutput

IF llNoOutput or THIS.lNoOutput
   RETURN lcText
ENDIF
   
THIS.cOutput = THIS.cOutput + lcText

RETURN ""
ENDFUNC
* wwResponse :: Send

************************************************************************
* wwResponse :: SendLn
*********************************
***  Function: Like Send but with CarriageReturn
************************************************************************
FUNCTION SendLn
LPARAMETERS lcText, llNoOutput
RETURN THIS.Send(lcText+CR,llNoOutput)
ENDFUNC
* wwResponse :: SendLn

************************************************************************
* wwRequest :: Write
*********************************
***  Function: Like Send - for ASP Compatibility
************************************************************************
FUNCTION Write
LPARAMETER lcText
THIS.cOutput = THIS.cOutput + lcText
ENDFUNC
* wwRequest :: Send


************************************************************************
* wwResponse :: Clear
*********************************
***  Function: Clears existing output
************************************************************************
FUNCTION Clear
THIS.cOutput = .F.
ENDFUNC
* wwResponse :: Clear

************************************************************************
* wwResponse :: GetOutput
*********************************
***  Function: Retrieves the current output.
***    Return: Output collected
************************************************************************
FUNCTION GetOutput
RETURN THIS.cOutput
ENDFUNC
* wwResponse :: GetOutput()

************************************************************************
* wwResponse :: ContentTypeHeader
*********************************
***  Function: Creates a content type header for standard HTML
***            document. Every HTML document requires this header.
***    Return:
************************************************************************
FUNCTION ContentTypeHeader
LPARAMETER lcContentType, llNoOutput

lcContentType=IIF(EMPTY(lcContentType),"text/html",lcContentType)

THIS.Rewind()
RETURN THIS.Send("HTTP/1.0 200 OK"+CR+;
                 "Content-type: "+lcContentType +;
                 CR+CR,llNoOutput)
ENDFUNC                            

************************************************************************
* wwHTML :: HTMLHeader
*********************************
***  Function: Writes out a basic HTML Header
***      Pass: tcHeader  -  Document Header Text.
***                         If this string contains < > tags
***                         the text is send as is, otherwise
***            			    it's formatted to the <H1> </H1> tag
***            tcDocName -  Browser Title String (displayed in caption)
***        tcContentType -  wwHTTPHeader Object  or
***                         Content Type
***                         others:
***                         "TEXT/PLAIN"
***                         "NONE"   (use when not generating plain
***                                   non-CGI requests)
***
***    Return: nothing
************************************************************************
FUNCTION HTMLHeader
LPARAMETERS tcHeader,tcDocName,tcBackground,tcContentType,tlNoOutput
LOCAL lcOutText

tcHeader=IIF(!EMPTY(tcHeader),tcHeader,"")
tcDocName=IIF(!EMPTY(tcDocName),tcDocName,tcHeader)
tcBackground=IIF(!EMPTY(tcBackground),tcBackground,"")

lcOutText=THIS.ContentTypeHeader(tcContentType,.T.)

IF !EMPTY(tcBackground)
   lcBackGround=IIF(AT("#",tcBackGround)>0,[BGCOLOR="],[BACKGROUND="])+;
                    lower(tcBackground)+["]
ELSE
   lcBackground=""   
ENDIF

lcOutText=lcOutText+;
   "<HTML>"+CR+"<HEAD><TITLE>"+;
   tcDocName+"</TITLE></HEAD>"+CR+"<BODY "+lcBackground+">"+CR

*** Print Header Text or Graphic
IF ATC("<",tcHeader)=1 AND ATC(">",tcHeader)=1
   lcOutText=lcOutText+THIS.sendln(tcHeader,.T.)
ELSE
   IF !EMPTY(tcHeader)
      lcOutText=lcOutText+[<FONT FACE="Verdana" Size="6"><b>]+tcHeader+[</b></FONT>]+CR+[<HR>]
   ENDIF
ENDIF

RETURN THIS.Send(lcOutText+CR,tlNoOutput)
ENDPROC
* HTMLHeader
************************************************************************
* wwResponse :: HTMLFooter
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION HTMLFooter
LPARAMETERS lcText, llNoOutput
THIS.Send(lcText + "</BODY></HTML>",llNoOutput)
ENDFUNC
* wwResponse :: HTMLFooter

************************************************************************
* wwResponse :: Authenticate
*********************************
***  Function: Asks for Authentication by sending a 401 request to
***            the browser. Brings up login dialog on browser.
***      Pass: tcRealm  -  Server realm. Typically the domain name or path
***    Return: nothing or output if tlNoOutput = .T.
************************************************************************
FUNCTION Authenticate
LPARAMETERS tcRealm, tcErrorText, tlNoOutput

tcRealm=IIF(type("tcRealm")="C",tcRealm,"/")
tcErrorText=IIF(type("tcErrorText")="C",tcErrorText,"<h2>Sorry pal! You need a password to get in...</h2>")

RETURN THIS.Send([HTTP/1.0 401 Not Authorized]+CR+;
                 [WWW-Authenticate: basic realm="]+ tcRealm + ["]+ CR+CR +;
                 [<HTML>]+tcErrorText+[</HTML>])
ENDFUNC


************************************************************************
* wwResponse :: ExpandScript
*********************************
***  Function: Takes a script page and 'runs' it as a TEXTMERGE 
***            document. 
***      Pass: lcPage  -  Physical Path to page to expand
***            lnMode  -  1 - Interpreted (CodeBlk)
***                       2 - Compiled FXP (default)
***    Return: Nothing
************************************************************************
FUNCTION ExpandScript
LPARAMETERS lcPage, lnMode

lnMode=IIF(EMPTY(lnMode),1,lnMode)

lcFileText = File2Var(lcPage)
IF EMPTY(lcFileText)
   RETURN THIS.Send("<h2>File " + lcPage + " not found or empty.</h2>",llNoOutput)
ENDIF

*** Add default content Type
THIS.ContentTypeHeader() 

*** Create Script Object and pass THIS HTML object to it
IF lnMode = 1   && CodeBlock
	loScript = CREATE("wwVFPScript",,THIS)
	loScript.oCgi = Request

	*** Outputs to script object
	loScript.cbExecute(lcFileText)
ELSE
    loScript = CREATE("wwVFPScript",lcPage,THIS)
	loScript.oCgi = Request
	loScript.lRuntime = .T.
	loScript.lAlwaysUnloadScript = .T.
	
	*** Converts the name to FXP and tries run the page
	loScript.RenderPage()
ENDIF	

ENDFUNC
* wwResponse :: ExpandScript

************************************************************************
* wwResponse :: ExpandTemplate
*********************************
***  Function: Evaluates embedded expressions inside of a page
***    Assume:
***      Pass: lcPage   -    Full physical path of page to merge
***    Return: "" or merged text if llNoOutput = .T.
************************************************************************
FUNCTION ExpandTemplate
LPARAMETERS lcPage,llNoOutput
LOCAL lcFileText

lcFileText = File2Var(lcPage)
IF EMPTY(lcFileText)
   RETURN THIS.Send("<h2>File " + lcPage + " not found or empty.</h2>",llNoOutput)
ENDIF
   
RETURN THIS.Send( MergeText(lcFileText),llNoOutput)
ENDFUNC
* wwResponse :: ExpandTemplate

ENDDEFINE
*EOC wwResponse
