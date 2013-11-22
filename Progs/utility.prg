*-- (c) Comway Softtech Inc. 1998

*-- General purpose utility functions independent of any classes
*-- for better performance and accessibility

#INCLUDE "INCLUDE\cims.h"
**********************************
*  RetUserFullName 
*  Pass : username
*  Return User full name (if found) OR "" 
**********************************
FUNCTION RetUserName(tcUserName)

LOCAL llClose,;
	lcFullName,;
	lnArea
IF PARAMETER() < 1
	RETURN ""
ENDIF

llClose = .F.
lnArea = SELECT(0)
IF !USED("users")
	USE cims!users IN 0
	llClose = .T.
ELSE
	SELECT users
ENDIF
IF SEEK(tcUserName,"users","userID")
	lcFullName = users.fullname
ELSE
	lcFullName = ""
ENDIF
IF llClose
	USE IN users
ENDIF
SELECT (lnArea)
RETURN lcFullName
***********************************
Function Path
	******************
	***    Author: Rick Strahl
	***            (c) West Wind Technologies, 1995
	***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
	***  Modified: 04/17/95
	***  Function: Adds or deletes items from the path string
	***      Pass: pcPathName   -   Filename
	***            pcMethod     -   *"ADD","DELETE"
	***
	***    Return: New Path or ""
	************************************************************************
	Parameters pcPath,pcMethod
	Private aPath,lcOldPath
	pcMethod=IIF(type("pcMethod")="C",upper(pcMethod),"ADD")

	If parameters()<1
		* WAIT WINDOW "No path passed..." NOWAIT
		Return
	Endif

	pcPath=ADDBS(UPPER(TRIM(pcPath)))
	lcOldPath=UPPER(SET("PATH"))

	If pcMethod="ADD"
		If EMPTY(pcPath) .OR. ADIR(aPath,pcPath,"D")<1
			* WAIT WINDOW "Path does not exist..." NOWAIT
			Return ""
		Endif
		If AT(pcPath,lcOldPath)>0
			* WAIT WINDOW "Path is already included..." NOWAIT
			Return ""
		Endif
		lcOldPath=lcOldPath+";"+pcPath
	Else
		If AT(pcPath,lcOldPath)<1
			* WAIT WINDOW "Path is not part of path string..." NOWAIT
			Return ""
		Endif
		lcOldPath=STRTRAN(lcOldPath,";"+pcPath)
		lcOldPath=STRTRAN(lcOldPath,pcPath)
	Endif

	Set PATH TO &lcOldPath
	 WAIT WINDOW NOWAIT "New Path: "+lcOldPath

	Return lcOldPath
	*EOP PATH
	************************************************************************
FUNCTION GetPath
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
***  Modified: 04/17/95
***  Function: Get Default Path
***    Return: Path name or ""
************************************************************************
Local lcPath,;
	lcCurrentPath
lcPath = ""	
lcCurrentPath = ADDBS(SYS(2003))	
IF FILE(lcCurrentPath+"HEALTHPAC.CFG")
	lcPath = FILETOSTR(lcCurrentPath+"HEALTHPAC.CFG")
ELSE	
	lcPath = GETENV("DATAPATH")
	IF EMPTY(lcPath)
		IF FILE("C:\WINDOWS\HEALTHPAC.CFG")
			lcPath = FILETOSTR("C:\WINDOWS\HEALTHPAC.CFG")
		ENDIF
	ENDIF	
ENDIF
lcPath = UPPER(ALLTRIM(lcPath))
IF !DIRECTORY(lcPath)
	lcPath = GETDIR(lcPath,"Select Default Directory")
	lcPath = ALLTRIM(lcPath)
ENDIF	
lcPath = ADDBS(lcPath)
RETURN lcPath
*EOF GetPath
******************************************
Function GetUserName
	******************
	***    Author: Rick Strahl
	***            (c) West Wind Technologies, 1995
	***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
	***  Modified: 04/17/95
	***  Function: Get user name from system
	***
	***    Return: username or ""
	************************************************************************
	Local lcUsername, lnLength

	*--DECLARE DLL statement for get username
	DECLARE INTEGER GetUserName ;
		IN WIN32API AS GUserName ;
		STRING @nBuffer, ;
		INTEGER  @nBufferSize

	lcUsername = Space(255)
	lnLength = LEN(lcUsername)
	lnError = GUserName(@lcUsername,@lnLength)
	*
	Return UPPER(ALLTRIM(SUBSTR(lcUsername, 1, lnLength - 1)))
	*
	**********************************************
Function IsTag (tcTagName, tcAlias)
	*-- Receives a tag name and an alias (which is optional) as
	*-- parameters and returns .T. if the tag name exists in the
	*-- alias. If no alias is passed, the current alias is assumed.
	Local llIsTag, ;
		lcTagFound

	If PARAMETERS() < 2
		tcAlias = ALIAS()
	Endif

	If EMPTY(tcAlias)
		Return .F.
	Endif

	llIsTag = .F.
	tcTagName = UPPER(ALLTRIM(tcTagName))

	lnTagNum = 1
	lcTagFound = TAG(lnTagNum, tcAlias)
	Do WHILE !EMPTY(lcTagFound)
		If UPPER(ALLTRIM(lcTagFound)) == tcTagName
			llIsTag = .T.
			Exit
		Endif
		lnTagNum = lnTagNum + 1
		lcTagFound = TAG(lnTagNum, tcAlias)
	Enddo

	Return llIsTag
Endfunc
*******************************************
Function NotYet()
	*-- Used during construction of Tastrade to indicate those
	*-- parts of the application that were not yet completed.
	=MESSAGEBOX(NOTYET_LOC, MB_ICONINFORMATION)
	Return
Endfunc
*****************************************************
Function FileSize(tcFileName)
	*-- Returns the size of a file. SET COMPATIBLE must be ON for
	*-- FSIZE() to return the size of a file. Otherwise, it returns
	*-- the size of a field.
	Local lcSetCompatible, lnFileSize

	lcSetCompatible = SET('COMPATIBLE')
	Set COMPATIBLE ON
	lnFileSize = FSIZE(tcFileName)
	Set COMPATIBLE &lcSetCompatible
	Return lnFileSize
Endfunc
*****************************************************
Function FormIsObject()
	*-- Return .T. if the active form is of type "O" and its baseclass
	*-- is "Form".
	Return (TYPE("_screen.activeform") == "O" AND ;
		UPPER(_screen.ActiveForm.BaseClass) = "FORM")
Endfunc
*****************************************************
Function ToolBarEnabled
	*- Return value of Toolbar object
	Parameter oObject
	Local oToolObj
	oToolObj = "oApp.oToolBar." + oObject + ".enabled"
	If TYPE(oToolObj) # "L"
		Return .F.
	Else
		Return EVAL(oToolObj)
	Endif
Endfunc
****************************************************************
Function OnShutdown()
	*-- Custom message called via the ON SHUTDOWN command to indicate
	*-- that the user must exit Tastrade before exiting Visual Foxpro.
	IF MESSAGEBOX(QUITFROMPROGRAM_LOC, MB_ICONEXCLAMATION+MB_YESNO,TITLE_LOC) = IDYES
		CLEAR EVENT
		CLOSE ALL
	ENDIF	
Endfunc
***************************************************************
PROCEDURE OnError
PARAMETERS tnErrorNo, tcMess, tcMess1, tcProgram, tnLineno

=AERROR(laErrorArray)

lcDate = TTOC(DATETIME())
lcErrorLog = ADDBS(gcProgDir)+"ERROR.LOG"
lcMessage =  "Error number: '"+ LTRIM(STR(laErrorArray[1]))+CR+ ;
		 'Error message: ' + laErrorArray[2]+CR+ ;
		 IIF(ISNULL(laErrorArray[3]), tcMess, laErrorArray[3])+ CR + ;
		 IIF(ISNULL(laErrorArray[4]), tcMess1, laErrorArray[4])+ CR + ;
 		 IIF(ISNULL(laErrorArray[5]), "", laErrorArray[5])+ " "+ ;
		 IIF(ISNULL(laErrorArray[6]), "", laErrorArray[6])+ " "+ ;
		 IIF(ISNULL(laErrorArray[7]), "", laErrorArray[7])+ " "+ ;
		 'Line number of error: ' + LTRIM(STR(tnLineno))+CR+ ;
		 'Program with error: ' + tcProgram
			 
=MESSAGEBOX(lcMessage, MB_ICONSTOP+MB_OK, ERRORTITLE_LOC)

lcMessage =  lcDate+' '+SYS(0)+' version '+PROGVER+ ;
			' Error number: '+ LTRIM(STR(laErrorArray[1]))+' '+ ;
			'Error message: ' + laErrorArray[2]+' ' + ;
			'Line number of error: ' + LTRIM(STR(tnLineno))+' '+;			
			IIF(ISNULL(laErrorArray[3]), "", laErrorArray[3])+ " "+;
			IIF(ISNULL(laErrorArray[4]), "", laErrorArray[4])+ " "+;
			IIF(ISNULL(laErrorArray[5]), "", laErrorArray[5])+ " "+;
			IIF(ISNULL(laErrorArray[6]), "", laErrorArray[6])+ " "+;
			IIF(ISNULL(laErrorArray[7]), "", laErrorArray[7])+ " "+;
			'Program with error: ' + tcProgram+CRLF
STRTOFILE(lcMessage,lcErrorLog, .T.)
*
***************************************************************
FUNCTION WarningBox(tcMessage)
	=MESSAGEBOX(tcMessage, MB_ICONINFORMATION,"Warning Message ...")
	Return
ENDFUNC
********************
Function LeapDay(tdFrom, tdTo)
If PARAMETER() = 0
	Return
Else
	If PARAMETER() = 1
		tdTo = DATE()
	Endif
Endif
*******************
lnYearFrom = YEAR(tdFrom)
lnYearTo = YEAR(tdTo)
lnTotalYear = (lnYearTo - lnYearFrom)
lnLeap = 0
For i = lnYearFrom To lnYearTo
	If MOD(i, 4) = 0
		IF i = lnYearTo
			ldDate = DATE(i, MONTH(tdTo), DAY(tdTo))
		ELSE 	
			ldDate = DATE(i, MONTH(tdFrom), DAY(tdFrom))
		ENDIF
		lnLeap = lnLeap + IIF(MONTH(ldDate) >= 2, 1, 0)
	Endif
Endfor
Return lnLeap
ENDFUNC
***************************************
FUNCTION GetStartRoll
LPARAMETER tdDate, tdRoll
IF PARAMETER() = 0
	RETURN 0
ELSE
	IF PARAMETER() < 2
		tdRoll = 12
	ENDIF
ENDIF
FOR i = tdRoll TO 1 STEP -1
	IF MONTH(tdDate) = 2
		IF MOD(YEAR(tdDate),4) = 0
			tdDate = tdDate - 29
		ELSE
			tdDate = tdDate - 28
		ENDIF	
	ELSE		
		IF INLIST(MONTH(tdDate), 1,3,5,7,8,10,12)
			tdDate = tdDate - 31
		ELSE
			tdDate = tdDate - 30
		ENDIF
	ENDIF		
ENDFOR
tdDate = tdDate + 1
RETURN tdDate	
************************************************
FUNCTION TLongDate(tdDate)
LOCAL ldDate,;
	laMonth[12,1],;
	lcRetVal
IF PARAMETER() = 0
	ldDate = DATE()
ELSE
	IF TYPE("tdDate") = "T"
		ldDate = TTOD(tdDate)
	ELSE
		ldDate = tdDate
	ENDIF
ENDIF
IF EMPTY(ldDate)
	RETURN ""
ENDIF	
laMonth[1] = "มกราคม"
laMonth[2] = "กุมภาพันธ์"
laMonth[3] = "มีนาคม"
laMonth[4] = "เมษายน"
laMonth[5] = "พฤษภาคม"
laMonth[6] = "มิถุนายน"
laMonth[7] = "กรกฎาคม"
laMonth[8] = "สิงหาคม"
laMonth[9] = "กันยายน"
laMonth[10] = "ตุลาคม"
laMonth[11] = "พฤศจิกายน"
laMonth[12] = "ธันวาคม"
***********************
lcRetVal = STR(DAY(ldDate),2)+" "+laMonth(MONTH(ldDate))+" "+STR(YEAR(ldDate)+543,4)
RETURN lcRetVal
ENDFUNC
************************************************
FUNCTION TShortDate(tdDate)
LOCAL ldDate,;
	laMonth[12,1],;
	lcRetVal
IF PARAMETER() = 0
	ldDate = DATE()
ELSE
	IF TYPE("tdDate") = "T"
		ldDate = TTOD(tdDate)
	ELSE
		ldDate = tdDate
	ENDIF
ENDIF
IF EMPTY(ldDate)
	RETURN ""
ENDIF	
laMonth[1] = "ม.ค"
laMonth[2] = "ก.พ"
laMonth[3] = "มี.ค"
laMonth[4] = "เม.ย"
laMonth[5] = "พ.ค"
laMonth[6] = "มิ.ย"
laMonth[7] = "ก.ค"
laMonth[8] = "ส.ค"
laMonth[9] = "ก.ย"
laMonth[10] = "ต.ค"
laMonth[11] = "พ.ย"
laMonth[12] = "ธ.ค"
***********************
lcRetVal = STR(DAY(ldDate),2)+" "+laMonth(MONTH(ldDate))+" "+STR(YEAR(ldDate)+543,4)
RETURN lcRetVal
ENDFUNC
************************************************
* แปลงเป็นเดือนไทย
FUNCTION TMonth(tdDate)
IF EMPTY(tdDate)
	RETURN ""
ENDIF 
	
LOCAL laMonth[12,1],;
	lnMonth,;
	lnYear,;
	lcRetVal
*************************
laMonth[1] = "มกราคม"
laMonth[2] = "กุมภาพันธ์"
laMonth[3] = "มีนาคม"
laMonth[4] = "เมษายน"
laMonth[5] = "พฤษภาคม"
laMonth[6] = "มิถุนายน"
laMonth[7] = "กรกฎาคม"
laMonth[8] = "สิงหาคม"
laMonth[9] = "กันยายน"
laMonth[10] = "ตุลาคม"
laMonth[11] = "พฤศจิกายน"
laMonth[12] = "ธันวาคม"
***********************
IF TYPE("tdDate") = "D"
	lnMonth = MONTH(tdDate)
	lnYear = YEAR(tdDate)
	lcRetVal = laMonth[lnMonth]+"  "+STR(lnYear+543,4)
ELSE 
	lnMonth = tdDate
	lcRetVal = laMonth[lnMonth]
ENDIF 	
RETURN lcRetVal
ENDFUNC
*************************
*
* แปลงตัวเลขเป็นตัวอักษรไทย
*
*************************
FUNCTION NumtoT(Vn)
IF PARAMETER() = 0
	RETURN ""
ENDIF	
Va = STRT(TRAN(Vn,'@R G9A9B9C9D9E9F9A9B9C9D9E9F9.9F9S'),' F0.','')
RETURN STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(;
STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(STRT(;
SUBS(Va,RAT(' ',Va)+2,35),'1','หนึ่ง'),'2','สอง'),'3','สาม'),'4','สี่'),;
'5','ห้า'),'6','หก'),'7','เจ็ด'),'8','แปด'),'9','เก้า'),'.0F0S','บาทถ้วน'),;
'0F',''),'0E',''),'0D',''),'0C',''),'0B',''),'0',''),'A','ล้าน'),;
'B','แสน'),'C','หมื่น'),'D','พัน'),'E','ร้อย'),'F','สิบ'),'.','บาท'),;
'หนึ่งสิบ','สิบ'),'สองสิบ','ยี่สิบ'),'สิบหนึ่ง','สิบเอ็ด'),'S','สตางค์')
ENDFUNC
*******************
* NumToWord Function
*******************
FUNCTION NumToE(numAmt)
  IF PARAMETER() = 0
  	RETURN ""
  ENDIF	
  PRIVATE numAmt, chrAmt, cDNums, wordAmt, cDvar

   *numAmt = Value to spell out
   *chrAmt = numAmt converted to char
   *wordAmt = spelled out version of numAmt

   *Covert amount to string, add leading zeros

   chrAmt=RIGHT('000000000'+LTRIM(STR(numAmt,12,2)),12)

   *Initialize literal string

   Dol1 = 'ONE'
   Dol2 = 'TWO'
   Dol3 = 'THREE'
   Dol4 = 'FOUR'
   Dol5 = 'FIVE'
   Dol6 = 'SIX'
   Dol7 = 'SEVEN'
   Dol8 = 'EIGHT'
   Dol9 = 'NINE'
   Dol10 = 'TEN'
   Dol11 = 'ELEVEN'
   Dol12 = 'TWELVE'
   Dol13 = 'THIRTEEN'
   Dol14 = 'FOURTEEN'
   Dol15 = 'FIFTEEN'
   Dol16 = 'SIXTEEN'
   Dol17 = 'SEVENTEEN'
   Dol18 = 'EIGHTEEN'
   Dol19 = 'NINETEEN'
   Dol20 = 'TWENTY'
   Dol30 = 'THIRTY'
   Dol40 = 'FORTY'
   Dol50 = 'FIFTY'
   Dol60 = 'SIXTY'
   Dol70 = 'SEVENTY'
   Dol80 = 'EIGHTY'
   Dol90 = 'NINETY'

   wordAmt=''
   IsHundred = .F.
   checkMillion =.T.

   FOR Counter = 1 TO 3

   * First time through the For loop to check for millions
   * Second time through the FOR loop to check for thousands
   * Third time through the FOR loop to check for hundreds, tens and ones


      DO CASE
        CASE Counter = 1
           cDNums = SUBSTR(chrAmt,1,3)
        CASE Counter = 2
           cDNums = SUBSTR(chrAmt,4,3)
        CASE Counter = 3
           cDnums = SUBSTR(chrAmt,7,3)
      ENDCASE


   * Check hundreds

      IF LEFT(cDNums, 1) > '0'
         cDvar = 'Dol'+LEFT(cDNums,1)
         wordAmt = wordAmt + EVAL(cDvar)+SPACE(1)+'HUNDRED'+SPACE(1)
         IsHundred = .T.
         IF Counter = 2
            CheckMillion = .T.
         ENDIF
      ENDIF

   * Check tens and ones

      Dtens = VAL(SUBSTR(cDNums,2,2))
      IF Dtens > 0
         IF Dtens > 20
            cDvar = 'Dol'+SUBSTR(cDNums,2,1)+'0'
            wordAmt = wordAmt + EVAL(cDvar)
            IF SUBSTR(cDNums,3,1) > '0'
               cDvar = 'Dol'+SUBSTR(cDNums,3,1)
               wordAmt = wordAmt + '-'+ EVAL(cDvar) + SPACE(1)
            ELSE
               wordAmt = wordAmt + SPACE(1)
            ENDIF
         ELSE
            cDvar = 'Dol'+LTRIM(STR(Dtens))
            wordAmt = wordAmt + EVAL(cDvar) + SPACE(1)
         ENDIF
         IsHundred = .F.
         IF Counter = 2
            CheckMillion = .T.
         ENDIF
      ENDIF

   * Add in Million, if needed
      IF numAmt > 999999.99 .AND. Counter = 1
         wordAmt = wordAmt + SPACE(1)+'MILLION'+SPACE(1)
         CheckMillion = .F.
      ENDIF


   * Add in Thousand, if needed
      IF CheckMillion
         IF numAmt > 999.99 .AND. Counter = 2
            IF Dtens > 0
               wordAmt = wordAmt + SPACE(1)+'THOUSAND'+SPACE(1)
            ENDIF
            IF IsHundred
               wordAmt = wordAmt + SPACE(1)+'THOUSAND'+SPACE(1)
            ENDIF
         ENDIF
      ENDIF
   ENDFOR
   * Construct the complete dollar amount in words
   wordAmt = IIF(numAmt<1, 'ONLY'+SPACE(1), wordAmt +IIF(RIGHT(chrAmt,2) <> "00", 'AND'+SPACE(1)+ ;
   RIGHT(chrAmt,2)+'/100 ', "") + 'BAHT')
   RETURN wordAmt 
ENDFUNC
******************************
FUNCTION GetCatCode(tcCatCode)
IF PARAMETER() = 0
	RETURN ""
ENDIF	
LOCAL lcRetCode
lcChr = ""
lcRetCode = ""
tcCatCode = IIF(ISNULL(tcCatcode), "", ALLTRIM(tcCatCode))
FOR i = 1 TO LEN(tcCatCode)
	lcChr = SUBSTR(tcCatCode,i,1)
	IF !INLIST(lcChr, "0", "1", "2", "3", "4", "5", "6", "7", "8", "9")
		lcRetCode = lcRetCode+lcChr
	ENDIF
ENDFOR
*
IF LEN(lcRetCode) > 5
	lcRetCode = STRTRAN(LEFT(cat_code,5), "_", "")
ENDIF 
*	
RETURN ALLTRIM(lcRetCode)		
*************************
FUNCTION TranDate(tcDate)
IF PARAMETER() = 0
	RETURN {}
ENDIF
LOCAL lcDate,lcYear

IF TYPE("tcDate") = "T"
	RETURN TTOD(tcDate)
ENDIF 	

IF TYPE("tcDate") = "N"
	tcDate =ALLTRIM(STR(tcDate))
ENDIF
 
tcDate = ALLTRIM(tcDate)
IF LEN(tcDate) < 8
	tcDate = "0"+tcDate
ENDIF
IF AT("/", tcDate) = 0
	ldDate = CTOD(LEFT(tcDate,2)+"/"+SUBSTR(tcDate,3,2)+"/"+SUBSTR(tcDate,5,4))
ELSE 
	ldDate = CTOD(ldDate)	
ENDIF 
RETURN ldDate
***************************************************
FUNCTION GetDateTime(tdDate, tnHour)
IF PARAMETER() = 1
	tnHour = 00
ENDIF	
IF EMPTY(tdDate)
	RETURN {}
ELSE	
	RETURN DATETIME(YEAR(tdDate), MONTH(tdDate), DAY(tdDate), tnHour, 00)
ENDIF	
************************************
FUNCTION ChkFunction(tcVar, tcAlias)
IF PARAMETER() = 0
	RETURN ""
ENDIF	
LOCAL lcVar,;
	lcFunction,;
	lcArg
lcArg = ""
IF AT("(",tcVar) <> 0
	lcVar = ALLTRIM(tcVar)
	lcFunction = LEFT(lcVar,AT("(", lcVar)-1)
	lcVar = SUBSTR(lcVar, AT("(", lcVar)+1)
	IF EMPTY(tcAlias)
		lcVar = LEFT(lcVar,LEN(lcVar)-1)
	ELSE
		lcVar = tcAlias+"."+LEFT(lcVar,LEN(lcVar)-1)
	ENDIF	
	lcVar = lcFunction+"("+lcVar+IIF(EMPTY(lcArg), "", ","+lcArg)+")"
ELSE
	lcVar = IIF(EMPTY(tcAlias), "", tcAlias+".")+ALLTRIM(tcVar)
ENDIF
RETURN lcVar
*******************************************
*ตรวจสอบ DATE ที่ป้อนว่าถูกต้องหรือไม่
*******************************************
FUNCTION CheckDate(tdDate)
IF EMPTY(tdDate)
	RETURN .T.
ENDIF
LOCAL lnDay,;
	lnMonth,;
	lnYear,;
	lnCurYear
	
lnDay = DAY(tdDate)
lnMonth = MONTH(tdDate)
lnYear = YEAR(tdDate)
lnCurYear = YEAR(DATE())
IF lnYear < 1980 AND lnYear > lnCurYear
	RETURN .F.
ENDIF
****
IF lnMonth < 1 AND lnMonth > 12
	RETURN .F.
ENDIF
*****
IF lnMonth = 2
	IF MOD(lnYear,4) = 0 
		IF lnDay > 28
			RETURN .F.
		ENDIF
	ELSE
		IF lnDay > 29
			RETURN .F.
		ENDIF
	ENDIF
ELSE
	IF INLIST(lnMonth, 1,3,5,7,8,10,12)
		IF lnDay > 31
			RETURN .F.
		ENDIF
	ELSE
		IF lnDay > 30
			RETURN .F.
		ENDIF
	ENDIF
ENDIF
RETURN .T.		
*****************************************************************
PROCEDURE WaitWindow
LPARAMETERS tcMessage, tnTimeOut
DO CASE 
CASE tnTimeOut = -1
	WAIT WINDOW tcMessage AT INT(WROWS()/2), INT((WCOLS()-LEN(tcMessage))/2)
CASE tnTimeOut = 0
	WAIT WINDOW tcMessage AT INT(WROWS()/2), INT((WCOLS()-LEN(tcMessage))/2) NOWAIT
OTHERWISE 
	WAIT WINDOW tcMessage AT INT(WROWS()/2), INT((WCOLS()-LEN(tcMessage))/2) TIMEOUT tnTimeOut
ENDCASE
*********************************************************************************			
PROCEDURE Gentab
PARAMETERS tcAlias, tcRow, tcColumn, tcData, tcOutFile
Local oXtab, res

SELECT(tcAlias)

starttime = Seconds()
oXtab = NewObject("FastXtab", "progs\FastXtab.prg")
oXtab.cOutFile = tcOutFile
oXtab.nPageField = 0
oXtab.nRowField = tcRow
oXtab.nColField = tcColumn
oXtab.nDataField = tcData

oXtab.lCursorOnly = .F.
oXtab.lDisplayNulls = .F.
oXtab.lBrowseAfter = .F.

oXtab.lCloseTable = .F.
oXtab.RunXtab()
*
***************************************
FUNCTION ChgToDate(tcDate)

IF TYPE("tcDate") # "C"
	RETURN 
ENDIF 

IF AT("/", tcDate) = 0
	ldDate = CTOD(LEFT(tcDate,2)+"/"+SUBSTR(tcDate,3,2)+"/"+SUBSTR(tcDate,5,4))
ELSE 
	ldDate = CTOD(ldDate)	
ENDIF 
RETURN ldDate
****************************
PROCEDURE SetBorder
PARAMETERS tcRange

IF EMPTY(tcRange)
	RETURN 
ENDIF 	

IF LEFT(tcRange, 1) <> ["]
	tcRange = ["]+tcRange+["]
ENDIF 	
*
WITH oSheet
	.Range(&tcRange).Borders(7).LineStyle = 1
	.Range(&tcRange).Borders(7).Weight = 2
	.Range(&tcRange).Borders(7).ColorIndex = -4105
	.Range(&tcRange).Borders(8).LineStyle = 1
	.Range(&tcRange).Borders(8).Weight = 2
	.Range(&tcRange).Borders(8).ColorIndex = -4105
	.Range(&tcRange).Borders(9).LineStyle = 1
	.Range(&tcRange).Borders(9).Weight = 2
	.Range(&tcRange).Borders(9).ColorIndex = -4105
	.Range(&tcRange).Borders(10).LineStyle = 1
	.Range(&tcRange).Borders(10).Weight = 2
	.Range(&tcRange).Borders(10).ColorIndex = -4105
	.Range(&tcRange).Borders(11).LineStyle = 1
	.Range(&tcRange).Borders(11).Weight = 2
	.Range(&tcRange).Borders(11).ColorIndex = -4105
	.Range(&tcRange).Borders(12).LineStyle = 1
	.Range(&tcRange).Borders(12).Weight = 2
	.Range(&tcRange).Borders(12).ColorIndex = -4105
ENDWITH 	
*
****************************************************************
FUNCTION GenPassword(tnLen)

char = "abcdefghijklmnopqrstuvwxyz0123456789"
upchar = "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
num = LEN(char)
retchar = SUBSTR(upchar, RAND()*num,1)

FOR i = 1 TO tnLen
	retchar = retchar + SUBSTR(char, RAND()*num,1)
ENDFOR 
RETURN retchar	
**********************************************************************
FUNCTION genLuhn(tcCard)

lnLuhn = 0
lnCheckDigit = ""
FOR i = 1 TO 15
	STORE 0 TO lnDigit1, lnDigit2
	? TRANSFORM(i, "99")+ "    "
	??SUBSTR(tcCardNo, i, 1) 
	IF INLIST(i, 1, 3, 5, 7, 9, 11, 13, 15)
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1)) * 2
		IF lnDigit > 9
			lnDigit1 = lnDigit - 9
		ELSE 
			lnDigit1 = lnDigit	
		ENDIF 	
		??lndigit
		??lnDigit1
	ELSE 
		lnDigit = VAL(SUBSTR(tcCardNo, i, 1))
		lnDigit2 = lnDigit	
		??lndigit		
		?? lnDigit2
	ENDIF 
	lnLuhn = lnLuhn + (lnDigit1 + lnDigit2)
ENDFOR
lnCheckDigit = 10 - MOD(lnLuhn, 10)
RETURN lnCheckDigit	
**************************************************
FUNCTION checkNatId(tcCardNo)

lnLuhn = 0
lnMin = 13
lnCheckDigit = ""
FOR i = 1 TO 12
	STORE 0 TO lnDigit1, lnDigit2
	? TRANSFORM(i, "99")+ "    "
	??SUBSTR(tcCardNo, i, 1) 
	lnDigit = lnMin*VAL(SUBSTR(tcCardNo, i, 1))
	lnLuhn  = lnLuhn + lnDigit
	lnMin = lnMin - 1
ENDFOR
lnMod = MOD(lnLuhn,11)
IF lnMod <= 1
	lnCheckDigit = 1 - lnMod
ELSE 
	lnCheckDigit = 11 - lnMod
ENDIF 
RETURN lnCheckDigit	
***************************************************
*Send Mail
***************************************************
FUNCTION sendMail(tcfrom, tcto, tcsubject, tcbody, tcAttach)

ON ERROR return(.f.)
local lcschema, loconfig, lomsg, loatt, lncountattachments
lcschema = "http://schemas.microsoft.com/cdo/configuration/"

loconfig = CREATEOBJECT("CDO.Configuration")

WITH  loconfig.fields
     .item(lcschema + "smtpserverport") = 465                        && SMTP Port
     .item(lcschema + "sendusing") = 2                                    && Send it using port
     .item(lcschema + "smtpserver") = "smtp.google.com"               &&"Your_Smtp.Server.com"
     .item(lcschema + "smtpauthenticate") = 1                          && Authenticate
     .item(lcschema + "sendusername") = "vacharaa@gmail.com"      && Username
     .item(lcschema + "sendpassword") = "vach0409"                     && Password
     .item(lcschema + "smtpusessl") = .t.
     .update
ENDWITH 

lomsg = CREATEOBJECT("CDO.Message")
lomsg.configuration = loconfig
WITH lomsg
     .to = tcto
     .from = tcfrom
     .subject = tcsubject
     .textbody = tcbody
     if pcount() > 4
          FOR lncountattachments = 1 to alen(tcAttach)
               loatt=.addattachment(tcAttach) &&,(lncountattachments)
          ENDFOR 
     endif
     .send()
ENDWITH 

STORE .null. TO loconfig, lomsg
RELEASE  loconfig, lomsg
RETURN .t.
ENDFUNC 