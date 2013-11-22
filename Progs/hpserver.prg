SET PROCEDURE TO wwFoxISAPI additive
SET PROCEDURE TO wwVFPSCript additive
SET PROCEDURE TO wwUTILS ADDITIVE
SET PROCEDURE TO wwEval ADDITIVE

o=CREATE("THpServer")
?o.Showmember()
*? o.HelloWorld()
*? o.LongRequest()
*? o.cErrorMsg
*? o.FirstQuery()

*? o.TestScript()

RETURN
*************************
#INCLUDE Include\WCONNECT.H
#DEFINE SHOWCODEFOOTER [<HR><a href="/foxisapi/foxisapi.dll/hpserver.TFirstserver.Process?Method=ShowCode&ShowMethod=]+Request.QueryString("Method")+[&PRG=hpServer.prg]+[&">Show Code</a>]
*************************************************************
DEFINE CLASS THpServer AS wwFoxISAPI  OLEPUBLIC
*************************************************************
lSaveRequestInfo = .T.
lUseMTS = .f.
nScriptMode = 2    && Compiled

FUNCTION Init
************************************************************************
* TFirstServer :: Init
********************************* 
***  Function: Any Environment overrides should go here
************************************************************************
DoDefault()

DO PATH WITH ".\DATA\"

ENDFUNC


FUNCTION HelloWorld
************************************************************************
* TFirstServer :: HelloWorld
*********************************
***  Function: Simple Hello World with FoxISAPI using String output
***    Assume:
***      Pass: lcFormVars   -  URLEncoded HTML Form Variables
***            lcIniFile    -  The INI file that contains server vars
***            lnReleaseFlag-  0 - keep loaded 1 - unload
***    Return: HTML + HTTP Header to send back to server
************************************************************************
LPARAMETER lcFormVars, lcIniFile, lnReload

lnReload = 0  && Keep server loaded

lcHeader = "HTTP/1.0 200 OK"+CHR(13) + CHR(10) +;
           "Content-type: text/html" + CHR(13) + CHR(10) + CHR(13) + CHR(10) 
           
lcOutput = "<HTML><BODY>" + ;
           "<h1>Hello World From Visual FoxPro!</H1><HR>" + CHR(13)+CHR(10) +;
           "<b>Version: </b>" + Version() + "<BR>"+;
           "<b>Time:    </b>" + Time() + ;
           "</BODY></HTML>"

RETURN lcHeader + lcOutput 


FUNCTION ShowMember
************************************************************************
* FirstServer :: FirstQuery
*********************************
***  Function: Very basic data query that builds the output by hand
***            using a string parameter.
************************************************************************
LPARAMETER lcFormVars, lcIniFile, lnReleaseFlag

lcIniFile=IIF(type("lcIniFile")="C",lcIniFile,"")

*** Don't release the server
lnReleaseFlag=0

lcOutput="HTTP/1.0 200 OK"+CR+;
         "Content-type: text/html"+CR+CR

SELECT  fund_id, policy_no, name, surname, effective, expiry, product ;
   FROM (".\data\customer") ;
   ORDER BY fund_id ;
   WHERE fund_id=2; 
   INTO Cursor TQuery

lcOutput = lcOutput + ;
  [<HTML><BODY BGCOLOR="#FFFFFF">] + ;
  [<H1>Customer Lookup</H1><HR>] + ;
  [Matching found: ]+STR(_Tally)+[<p>]

lcOutput = lcOutput + ;
   [<TABLE BGCOLOR=#EEEEEE CELLPADDING=4 BORDER=1 WIDTH=100%>]+CR+;
   [<TR BGCOLOR=#FFFFCC><TH>Fund</TH><TH>กรมธรรม์ เลชที่</TH><TH>ชื่อ</TH><TH>เริ่มคุ้มครอง</TH><TH>หมดอายุ</TH><TH>แผน</TH></TR>]+CR

SCAN
   *** Build the table row - note the second column is hotlinked by CustId for display
   lcOutput = lcOutput + [<TR><TD>]+STR(TQuery.fund_id,4)+[</TD><TD>]+TQuery.policy_no+[</TD><TD>]+;
   		ALLT(TQuery.name)+Space(1)+ALLT(TQuery.surname)+[</TD><TD>]+;
   		DTOC(TQuery.effective)+[</TD><TD>]+DTOC(TQuery.expiry)+[</TD><TD>]+TQuery.product+[</TD></TR>]+CR
ENDSCAN          

lcOutput = lcOutput  + [</TABLE><HR>] + ;
                       [</BODY></HTML>]

USE IN Tquery
USE IN Customer

RETURN lcOutput
ENDFUNC
* ShowMember
*
FUNCTION FirstQueryx
************************************************************************
* FirstServer :: FirstQuery2
*********************************
***  Function: Step 2 - Using the basic wwFoxISAPI functionality in 
***                     query.
***    Assume: Uses wwFoxISAPI class methods. 
***            to preconfigure Request and Response and output.
************************************************************************
LPARAMETER lcFormVars, lcIniFile, lnRelease
LOCAL lcCustno

THIS.StartRequest(lcFormVars, lcIniFile, lnRelease)

Request=THIS.oRequest
Response=THIS.oResponse

lcCustno = Request.QueryString("CustNo")

*** If no custno was passed let's show all custs
IF !EMPTY(lcCustNo)
   lcCustno = PADL(lcCustNo,8)
ENDIF   

*** NOTE THE USE OF THE PATH!
SELECT [<A HREF="/scripts/foxisapi.dll/HpServer.THpServer.Process?Method=LookupCustomer&Custno=]+ALLTRIM(Custno)+[">]+policy_no+[</a>] as policy,;
       CareOf, phone, custno ;
 FROM .\Data\Customer ;
 WHERE Policy_no = lcCustNo ;
 ORDER BY 1 ;
 INTO Cursor TQuery

IF _TALLY = 0
   THIS.ErrorMsg("No customers match the customer number.",;
                 "Please retry your request or omit the customer number for a list of all customers.<p>"+;
                 [<A HREF="]+THIS.oRequest.GetPreviousUrl()+[">Return to the previous page</a>])
   RETURN Response.GetOutput()
ENDIF 

*** Creates ContentTypeHeader and HTML header
Response.HTMLHeader("Simple Customer List")

Response.Write([<TABLE Border=1 CellPadding=3 width="98%">] + ;
 [<TR BGCOLOR="#CCCC88" ><TH>Company</TH><TH>Name</TH><TH>Phone</TH></TR>])

SCAN
  Response.Write("<TR><TD>" + Company + "</TD><TD>" + Careof + ;
                 "</TD><TD>"+ STRTRAN(Phone,CHR(13),"<BR>") + "</TD></TR>")
                 
ENDSCAN
             
Response.Write("</TABLE>")

RETURN Response.GetOutput()
ENDFUNC

FUNCTION FirstQuery2
************************************************************************
* FirstServer :: FirstQuery2
*********************************
***  Function: Step 3 - Using the basic wwFoxISAPI functionality in 
***                     query.
***    Assume: Uses wwFoxISAPI class methods. Uses the Process method
***            to preconfigure Request and Response and output.
************************************************************************
LOCAL lcCustno

lcCustno = Request.QueryString("CustNo")

*** If no custno was passed let's show all custs
IF !EMPTY(lcCustNo)
   lcCustno = PADL(lcCustNo,8)
ENDIF   

*** NOTE THE USE OF THE PATH!
SELECT [<A HREF="/foxisapi/foxisapi.dll/FirstServer.TFirstServer.Process?Method=LookupCustomer&Custno=]+ALLTRIM(Custno)+[">]+Company+[</a>] as COMPANY,;
       CareOf, phone, custno ;
 FROM .\Data\TT_Cust ;
 WHERE CustNo = lcCustNo ;
 ORDER BY 1 ;
 INTO Cursor TQuery

IF _TALLY = 0
   THIS.ErrorMsg("No customers match the customer number.",;
                 "Please retry your request or omit the customer number for a list of all customers.<p>"+;
                 [<A HREF="]+THIS.oRequest.GetPreviousUrl()+[">Return to the previous page</a>])
   RETURN
ENDIF 

*** Creates ContentTypeHeader and HTML header
Response.HTMLHeader("Simple Customer List")

Response.Write([<TABLE Border=1 CellPadding=3 width="98%">] + ;
 [<TR BGCOLOR="#CCCC88" ><TH>Company</TH><TH>Name</TH><TH>Phone</TH></TR>])

SCAN
  Response.Write("<TR><TD>" + Company + "</TD><TD>" + Careof + ;
                 "</TD><TD>"+ STRTRAN(Phone,CHR(13),"<BR>") + "</TD></TR>")
                 
ENDSCAN
             
Response.Write("</TABLE>")

Response.HTMLFooter(SHOWCODEFOOTER)

RETURN 
ENDFUNC

FUNCTION LookupCustomer
************************************************************************
* FirstServer :: LookupCustomer
*********************************
***  Function: Looks up a customer by Customer Number.
***    Assume: Uses wwFoxISAPI with the Process method call
************************************************************************
lcCustId = Request.QueryString("Custno")
lcCustId = PADL(lcCustId,8)

IF !USED("TT_Cust")			
   USE .\Data\TT_Cust IN 0
ENDIF
SELE TT_Cust

LOCATE FOR CustNo = lcCustId
IF !FOUND()
   THIS.ErrorMsg("Customer does not exist","["+lcCustId+"] Please select a valid customer.")
   RETURN Response.GetOutput()
ENDIF

Response.HTMLHeader(Company)

Response.Write([<TABLE BORDER="1" CELLSPACING="3" width="300">])
Response.Write("<TR><TD>Company:</td><TD>"+Company + "</TD></TR>")
Response.Write("<TR><TD>Name:</td><TD>"+Careof + "</TD></TR>")
Response.Write("<TR><TD>Phone:</td><TD>"+Phone + "</TD></TR>")
Response.Write("<TR><TD>Address:</TD><TD>"+STRTRAN(Address,CHR(13),"<BR>") + "</TD></TR>")
Response.Write("</TABLE>")

Response.HTMLFooter(SHOWCODEFOOTER)

RETURN
ENDFUNC

FUNCTION Authenticate
************************************************************************
* TFirstServer :: Authenticate
*********************************
***  Function: Shows how User Authentication work over the Web.
***            1)  Check if user is Authenticated
***            2)  If not request Authentication
***            2.1 After entering dialog server re-runs request
************************************************************************

lcUserName=Request.ServerVariables("Authenticated Username")

IF EMPTY(lcUserName)   
    *** Send Password Dialog
    Response.Authenticate(Request.GetServerName(),;
                          "<h2>Get out and stay out!</h2>")
    RETURN 
ENDIF

*** Go on processing - user has been authenticated
THIS.StandardPage("You're Authenticated",;
                  "Welcome <b>"+lcUsername+"</b>. You may proceed to wreak havoc on the system now..." +;
                  SHOWCODEFOOTER)

RETURN
ENDFUNC
* Authenticate


************************************************************************
* HTTPDemo :: DownloadQuery
*********************************
***  Function: Demonstrates sending a binary response to the client.
***    Assume: 
***********************************************************************
FUNCTION DownLoadQuery

lcName = UPPER(Request.QueryString("Name"))

*** Create a DBF file
SELECT company,careof, custno ;
  FROM .\data\TT_CUST ;
  WHERE UPPER(Company) = lcName ;
    ORDER BY company ;
    INTO DBF TExport

USE IN TExport

*** Send the file directly over the HTTP link
Response.Write(File2Var("TExport.dbf"))

ERASE TExport.dbf

ENDFUNC
* GetCustomer

************************************************************************
* HTTPDemo :: DownloadQuery
*********************************
***  Function: Demonstrates sending a binary response to the client.
***    Assume: 
***********************************************************************
FUNCTION DownLoadQuery2

lcName = UPPER(Request.QueryString("Name"))

*** Create a DBF file
SELECT company,careof, company.custno, ;
       timebill.datein, timebill.timein, timebill.descript ;
  FROM .\data\TT_CUST, .data\TimeBill ;
  WHERE UPPER(Company) = lcName AND ;
        tt_cust.custno = timebill.custno ;
    ORDER BY company ;
    INTO DBF TExport

USE IN TExport

loIP=CREATE("wwIPSTuff")
lcFileBuffer = loIp.EncodeDbf("TExport.dbf",.t.)
IF EMPTY(lcFileBuffer)
   Response.Write("Error - File couldn't be encoded")
ENDIF   

*** Send the file directly over the HTTP link
Response.Write(lcFileBuffer)

ERASE TExport.dbf
ERASE TExport.fpt

ENDFUNC
* GetCustomer

FUNCTION LongRequest
************************************************************************
* TFirstServer :: LongRequest
*********************************
LPARAMETER lcFormVars, lcIniFile, lnRelease

THIS.StartRequest(lcFormVars,lcIniFile,lnRelease)
lnSecs = SECONDS()

DECLARE Sleep IN WIN32API INTEGER

FOR x=1 to 200
    select * from data\TT_CUST INTO CURSOR TQuery
    Sleep(30)
ENDFOR && x=1 to 200

THIS.StandardPage("Waited for "+STR(SECONDS() - lnSecs) + " secs","")

RETURN THIS.oResponse.GetOutput()

* Test a binary response
FUNCTION BinaryResponse
Response = THIS.oResponse
Response.Write("This is a test"+Chr(0)+". This is more text...")
EndFunc





ENDDEFINE