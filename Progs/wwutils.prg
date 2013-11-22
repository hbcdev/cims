
************************************************************************
* FUNCTION Utils
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995-98
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 12/22/97
***  Function: A set of utility classes and functions used by 
***            the various classes and processing code.
*************************************************************************
#INCLUDE FOXPRO.H
#INCLUDE Include\WCONNECT.H


*************************************************************
DEFINE CLASS Settings AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
***  Modified: 01/20/96
***  Function: Object that contains app wide settings
***            Defined as a Global so it's accessible
***            in all the sub procedures.
*************************************************************

*** Custom Properties
oAPI=.NULL.            && Need to use GetProfileString

cPath=""
cTemplate="wc_"
nPriority=1
lDebugMode=.F.
lLogToFile=.T.
lShowStatus=.T.
nTimerInterval=250
lSaveRequestFiles=.F.


************************************************************************
* Settings :: Init
*********************************
***  Function: Reads values from the INI file specified.
***    Assume: Note INI file name must be fully qualified. The current
***            directory needs to be identified with ".\CGIMAIN.INI"
***            for example.
***      Pass: lcINIFile   -   Path of INI file
***    Return: If the function fails either as a whole, or on
***            on individual options from the INI file, the default
***            assignments are used.
************************************************************************
FUNCTION Init
LPARAMETERS lcIniFile
LOCAL lcRetval,loAPI

lcIniFile=IIF(type("lcIniFile")="C",lcIniFile,"")

IF FILE(lcIniFile) 
   THIS.oAPI=CREATE("wwAPI")
   loAPI=THIS.oAPI
   IF TYPE("THIS.oAPI")="L"
      RETURN .F.
   ENDIF

   lcRetval=loAPI.GetProfileString(lcIniFile,"Main","Path")
   IF !ISNULL(lcRetval)
       THIS.cPath=lcRetVal
   ENDIF
     
   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","Template")
   IF !ISNULL(lcRetval)
       THIS.cTemplate=lcRetval
   ENDIF

   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","Priority")
   IF !ISNULL(lcRetval) 
       THIS.nPriority=val(lcRetVal)
   ENDIF

   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","TimerInterval")
   IF !ISNULL(lcRetval) 
       THIS.nTimerInterval=val(lcRetVal)
   ENDIF
     
   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","LogToFile")
   IF !ISNULL(lcRetval)
      lcRetVal=UPPER(lcRetVal)
      DO CASE
         CASE lcRetVal = "ON" or lcRetval="YES"
            THIS.lLogToFile=.T.
         CASE lcRetVal = "OFF" or lcRetVal="NO"
            THIS.lLogToFile=.F.
      ENDCASE
   ENDIF
   
   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","ShowStatus")
   IF !ISNULL(lcRetval)
      lcRetVal=UPPER(lcRetVal)
      DO CASE
         CASE lcRetVal = "ON" or lcRetval="YES"
            THIS.lShowStatus=.T.
         CASE lcRetVal = "OFF" or lcRetVal="NO"
            THIS.lShowStatus=.F.
      ENDCASE
   ENDIF
   
   lcRetVal=loAPI.GetProfileString(lcIniFile,"Main","SaveRequestFiles")
   IF !ISNULL(lcRetval)
      lcRetVal=UPPER(lcRetVal)
      DO CASE
         CASE lcRetVal = "ON" or lcRetval="YES"
            THIS.lSaveRequestFiles=.T.
         CASE lcRetVal = "OFF" or lcRetVal="NO"
            THIS.lSaveRequestFiles=.F.
      ENDCASE
   ENDIF
   
ENDIF

ENDFUNC
* Init


ENDDEFINE
*EOC Settings


*************************************************************
DEFINE CLASS wwEnv AS Custom
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
***  Modified: 10/31/95
***  Function: Saves environment settings.
***
***      Note: VERY PRELIMINARY HACK FOR NOW!!!
***            USE WITH CAUTION!!!
*************************************************************

*** Custom Properties
PROTECTED cSetting,vOldValue


************************************************************************
* wwEnv :: Init
*********************************
***  Function: Saves and restores environment settings
***    Assume: Limited to simple ON/OFF settings
***            Very limited!!! Test carefully.
***      Pass: tcSetting  -   SET value to set
***            tvNewValue -   Value to set to
***    Return:
*** ??? Set TO and ON support
************************************************************************
FUNCTION Init
LPARAMETERS tcSetting,tvNewValue
THIS.Set(tcSetting, tvNewValue)
ENDFUNC
* Init

************************************************************************
* wwEnv :: Set
*********************************
***  Function: 
***    Assume:
***      Pass: tcSetting  -   SET value to set
***            tvNewValue -   Value to set to
***    Return:
************************************************************************
FUNCTION Set
LPARAMETERS tcSetting,tvNewValue
THIS.cSetting=tcSetting

THIS.vOldValue=SET( tcSetting )

IF TYPE("tvNewValue")="C" AND ;
   INLIST(UPPER(tvNewValue),"ON","OFF") 
   SET &tcSetting &tvNewValue
ELSE
   SET &tcSetting TO (tvNewValue)   
ENDIF

ENDFUNC
* Set
************************************************************************
* wwEnv :: Destroy
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION Destroy
LOCAL lcSetting,lvValue

lcSetting=THIS.cSetting
lvValue=THIS.vOldValue

IF TYPE("lvValue")="C" AND ;
   INLIST(UPPER(lvValue),"ON","OFF") 
   SET &lcSetting &lvValue
ELSE
   SET &lcSetting TO (lvValue)   
ENDIF

ENDFUNC
* Destroy

ENDDEFINE
*EOC wwEnv


*************************************************************************
****
**** STANDALONE FUNCTIONS
****
*************************************************************************

************************************************************************
FUNCTION OpenExclusive
**********************
***  Modified: 01/27/96
***  Function: Tries to open a table exclusively
***    Assume: Table name can't contain a file name.
***            Returns .F. for other reasons like file !found etc.
***            USES wwEVAL object to test for success
***            Parameters MUST NOT BE LPARAMETERS!!!
***      Pass: lcTable   -  Name of table to open exclusively
***    Return: .T. or .F.
************************************************************************
PARAMETERS lcTable, lcAlias
LOCAL lcOldError, llRetVal, loEval

lcTable=IIF(EMPTY(lcTable),"",lcTable)
lcAlias=IIF(EMPTY(lcAlias),JustStem(lcTable),lcAlias)

IF EMPTY(lcTable)
   RETURN .F.
ENDIF

loEval=CREATE("wwEval")

*** Use Exclusively to reindex and pack
IF !USED(lcAlias)
   loEval.Execute("USE (lcTable) EXCLUSIVE IN 0 ALIAS (lcAlias)")
ELSE
   SELE (lcAlias)
   loEval.Execute("USE (lcTable) EXCLUSIVE  ALIAS (lcAlias)")
ENDIF

llRetVal=!loEval.lError

*** Now try to re-open table as shared
IF !llRetVal
   USE (lcTable) IN 0
ENDIF   

RETURN llRetVal
*EOP OpenExclusive


************************************************************************
FUNCTION File2Var
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***  Modified: 01/28/95
***  Function: Takes a file and returns the contents as a string or
***            Takes a string and stores it in a file if a second
***            string parameter is specified.
***      Pass: tcFilename  -  Name of the file
***            tcString    -  If specified the string is stored
***                           in the file specified in tcFileName
***    Return: file contents as a string
************************************************************************
LPARAMETERS tcFileName, tcString
LOCAL lcRetVal, lnHandle, lnSize

tcFileName=IIF(EMPTY(tcFileName),"",tcFileName)

IF EMPTY(tcString)
   *** File to Text
   lcRetVal=""
   
   *** Make sure file exists and can be opened for READ operation
   lnHandle=FOPEN(tcFileName,0)
   IF lnHandle#-1
     lnSize = FSEEK(lnHandle,0,2)
     FSEEK(lnHandle,0,0)
     lcRetVal=FREAD(lnHandle,lnSize)
     =FCLOSE(lnHandle)
   ENDIF
ELSE
   tcString=IIF(EMPTY(tcString),"",tcString)
   
   *** Text to File
   lnHandle=FCREATE(tcFileName)
   IF lnHandle=-1
      RETURN .F.
   ENDIF
   =FWRITE(lnHandle,tcString)
   =FCLOSE(lnHandle)
   RETURN .T.
ENDIF

RETURN lcRetVal
*EOP File2Var

************************************************************************
FUNCTION WrCursor
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1995
***   Contact: (503) 386-2087  / 76427,2363@compuserve.com
***  Modified: 06/05/95
***  Function: Creates a Writable cursor from a SELECTed cursor.
***            The original cursor is closed after completion.
***
***    Assume: No checks for valid cursor are performed! Make sure
***            you have a cursor and not a buffered table image!
***            CURSOR MUST BE CURRENTLY SELECTED!
***
***      Pass: pcNewName  -  New Alias name for the cursor
***
***    Return: nothing
************************************************************************
PARAMETER pcNewName
PRIVATE lcOldAlias

*** work with the current Cursor
lcOldAlias=ALIAS()

*** Select the cursor an
SELE (lcOldAlias)
lcDBF=DBF(lcOldAlias)

IF USED(pcNewName)
   USE IN (pcNewName)
ENDIF

USE (lcDBF) AGAIN ALIAS (pcNewName) IN 0
USE IN (lcOldAlias)
SELE (pcNewName)

RETURN 

************************************************************************
FUNCTION NewId
******************
***    Author: (c) Rick Strahl, 1994
***  Modified: 05/31/96
***  Function: This FUNCTION creates a new ID number based on a
***            numeric field in a database (default/system table).
***            The counter field is updated by locking the counter
***            record, updating the counter, then checking the master
***            file for existance of this Id. If it exists already the
***            counter is incremented again until no match is found.
***            Once no match is found the record is unlocked.
***
***    Assume: The table that is to receive the new ID value is open
***            and selected and the index order is set to the ID index
***            (used to check if the key exists).
***
***            The ID table is open and located on the record that
***            contains the ID. Remember all IDs are in one record (row)
***
***            Works best with SET REPROCESS TO 1 SECONDS or higher to allow
***            for lock conflicts.
***
***      Pass: pcCntField   -  The field in the defaults/system table
***                            used as a counter for the Id.
***                            MUST USE ALIAS: "defaults.custno"
***            pcIdSize     -  The Length of the ID field (* 8) the
***                            number returned is left padded with
***                            spaces.
***            pcStartChar  -  Starting ID Character - prepended to #
***            pcPadChar    -  Character used to pad the string with
***            plNoLookup   -  Don't do a SEEK() after value is added
***
***    Return: ID value. Number in Character format left padded with
***            spaces. EMPTY() if operation failed.
***
***   Example: SELE custno
***            SET ORDER TO custno
***            lcNewId = NewId("defaults.custno",7)
***
***            IF !empty(lcNewId)
***               APPEND BLANK
***               replace custno with lcNewId
***            ELSE
***               wait window "Unable to create new customer ID..."
***               RETURN
***            ENDIF
*************************************************************************
LPARAMETER pccntfield, pcidsize, pcStartChar, pcPadChar, plNoLookup

pcStartChar=IIF(type("pcStartChar")="C",pcStartChar,"")
pcPadChar=IIF(type("pcPadChar")="C",pcPadChar,"0")

PRIVATE lcoldalias,lnoldrecno,lcnewid,lncounterval,pccntfield,pcidsize,;
   lnmaxval,lcsysalias

*** In case size is omitted default to 8
pcidsize = IIF(TYPE("pcIdSize")#"N",8,pcidsize)
lcsysalias = LEFT(pccntfield,AT(".",pccntfield)-1)

*** Save Stats
lcoldalias = ALIAS()				       && keep current work area
lnoldrecno = IIF(!EOF(),RECNO(),0)       && save record number
lnmaxval = (10^pcidsize)-1			   && wrap around after this val

lcnewid = ""							   && our return result - NULL if failed

*** lock counter table and update counter
IF rlock(lcsysalias)
   *** Avoid use of Macros - Convert to mem var & update it
   lncounterval = EVALUATE(pccntfield)

   *** VERIFY ID NUMBER - search 'til no match
   DO WHILE .T.
      *** increase the counter - update field and var
      lncounterval = lncounterval+1

      *** check for wraparound
      IF lncounterval > lnmaxval
         lncounterval = 1
      ENDIF

      *** convert to char String
      lcnewid = pcStartChar+PADL(lncounterval,pcidsize,pcPadChar)

      IF !plNoLookup
        *** now see if it exists
        IF !SEEK(lcnewid)
           *** No match - DONE
           EXIT
        ENDIF
      ELSE
         EXIT
      ENDIF
   ENDDO								&& done

   SELE (lcsysalias)
   REPLACE (pccntfield) WITH lncounterval

   UNLOCK IN (lcsysalias)
ENDIF									&& reclock()

*** Reset record number on original file
SELE (lcOldAlias)
IF lnoldrecno#0
   GOTO lnoldrecno
ENDIF

RETURN lcnewid



************************************************************************
FUNCTION Extract
******************
***  Function: Extracts a text value between two delimiters
***    Assume: Delimiters are not checked for case!
***            The first instance only is retrieved. Idea is
***            to translate the delims as you go...
***      Pass: lcString   -  Entire string
***			   lcDelim1   -  The starting delimiter
***            lcDelim2	  -  Ending delimiter
***            lcDelim3	  -  Alternate ending delimiter
***            llEndOk	  -  End of line is OK
***    Return: Text between delimiters or ""
*************************************************************************
PARAMETERS lcString,lcDelim1,lcDelim2,lcDelim3, llEndOk
PRIVATE x,lnLocation,lcRetVal,lcChar,lnNewString,lnEnd

lcDelim1=IIF(EMPTY(lcDelim1),",",lcDelim1)
lcDelim2=IIF(EMPTY(lcDelim2),"z!x",lcDelim2)
lcDelim3=IIF(EMPTY(lcDelim3),"z!x",lcDelim3)

lnLocation=ATC(lcDelim1,lcString)
IF lnLocation=0
   RETURN ""
ENDIF

lnLocation=lnlocation+len(lcDelim1)

*** Crate a new string of remaining text
lcNewString=SUBSTR(lcString,lnLocation)

lnEnd=ATC(lcDelim2,lcNewString)-1
IF lnEnd>0 
   RETURN SUBSTR(lcNewString,1,lnEnd)
ENDIF   
IF lnEnd = 0
   *** Empty Delimited string
   RETURN ""
ENDIF
   
lnEnd=ATC(lcDelim3,lcNewString)-1
IF lnEnd>0 
   RETURN SUBSTR(lcNewString,1,lnEnd)
ENDIF   

IF llEndOk
  *** Return to the end of the line
  RETURN SUBSTR(lcNewString,1)
ENDIF

RETURN ""
*EOP RetValue

************************************************************************
Function CreateZip
*********************************
***  Function: Creates a ZIP file from a cursor passed into the routine
***    Assume: Uses PKZIP
***            Short Filenames required
***            PKZIP has problems with network drives
***      Pass: lcZipPath - Path where to create the Zip File
***    Return: Returns the name of the ZIP file that was created
************************************************************************
LPARAMETER lcZipPath

*** First of all check the temp path
lnFiles=ADIR(laFiles, lcZipPath + "*.zip" )
FOR x=1 to lnFiles
   IF ctot(DTOC(laFiles[x,3])+" "+laFiles[x,4]) < datetime() - 1800 
      ERASE (lcZipPath + laFiles[x,1])
   ENDIF
ENDFOR && x=1 to lnFiles

lcFile=SUBSTR(SYS(2015),3)
lcTempFilePath=SYS(2023)+"\"+lcFile
lcZipFile=lcZipPath+lcFile+".zip"
COPY ALL TO (lcTempFilePath ) 

lcRun="RUN pkZIP "+lcZipFile+" "+lcTempFilePath+".*"
&lcRun

ERASE (lcTempFilePath+".dbf")
ERASE (lcTempFilePath+".fpt")


IF !FILE(lcZipFile)
  RETURN ""
ENDIF
 
RETURN lcZipFile
* CreateZip


************************************************************************
FUNCTION Path
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
PARAMETERS pcPath,pcMethod
PRIVATE aPath,lcOldPath
pcMethod=IIF(type("pcMethod")="C",upper(pcMethod),"ADD")

IF parameters()<1 
   * WAIT WINDOW "No path passed..." NOWAIT
   RETURN
ENDIF
   
pcPath=ADDBS(UPPER(TRIM(pcPath)))
lcOldPath=UPPER(SET("PATH"))

IF pcMethod="ADD"
    IF EMPTY(pcPath) .OR. ;
      ADIR(aPath,pcPath,"D")<1
      * WAIT WINDOW "Path does not exist..." NOWAIT
      RETURN ""
   ENDIF
   IF AT(pcPath,lcOldPath)>0
      * WAIT WINDOW "Path is already included..." NOWAIT
      RETURN ""
   ENDIF
   lcOldPath=lcOldPath+";"+pcPath
ELSE
   IF AT(pcPath,lcOldPath)<1
      * WAIT WINDOW "Path is not part of path string..." NOWAIT
      RETURN ""
   ENDIF
   lcOldPath=STRTRAN(lcOldPath,";"+pcPath)
   lcOldPath=STRTRAN(lcOldPath,pcPath)
ENDIF   

SET PATH TO &lcOldPath
* WAIT WINDOW NOWAIT "New Path: "+lcOldPath

RETURN lcOldPath
*EOP PATH


************************************************************************
FUNCTION DomainName
*******************
***  Modified: 04/13/96
***  Function: Retrieves a Domain name from an URL
***    Assume: URL starts with http:// - // required!
***      Pass: lcUrl         -  URL to retrieve name from
***            llNoStripWWW  -  Don't strip www.
***    Return: Domain Name or ""
*************************************************************************
LPARAMETER lcUrl, llNoStripWWW
lcText=STRTRAN(EXTRACT(lower(lcUrl),"//","/"," "),"/","")
IF !llNoStripWWW
  lcText=STRTRAN(lcText,"www.","")
ENDIF
RETURN PADR(lcText,50)


****************************************************
FUNCTION GoUrl
******************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: rstrahl@west-wind.com
***  Modified: 03/14/96
***  Function: Starts associated Web Browser
***            and goes to the specified URL.
***            If Browser is already open it
***            reloads the page.
***    Assume: Works only on Win95 and NT 4.0
***      Pass: tcUrl  - The URL of the site or
***                     HTML page to bring up
***                     in the Browser
***    Return: 2  - Bad Association (invalid URL)
***            31 - No application association
***            29 - Failure to load application
***            30 - Application is busy 
***
***            Values over 32 indicate success
***            and return an instance handle for
***            the application started (the browser) 
****************************************************
LPARAMETERS tcUrl, tcAction

tcUrl=IIF(type("tcUrl")="C",tcUrl,;
          "http://www.west-wind.com/")
          
tcAction=IIF(type("tcAction")="C",tcAction,"OPEN")

DECLARE INTEGER ShellExecute ;
    IN SHELL32.dll ;
    INTEGER nWinHandle,;
    STRING cOperation,;
    STRING cFileName,;
    STRING cParameters,;
    STRING cDirectory,;
    INTEGER nShowWindow

DECLARE INTEGER FindWindow ;
   IN WIN32API ;
   STRING cNull,STRING cWinName

RETURN ShellExecute(FindWindow(0,_SCREEN.caption),;
                    tcAction,tcUrl,;
                    "",SYS(2023),1)

************************************************************************
FUNCTION RegisterOleServer
**************************
***    Author: Rick Strahl, West Wind Technologies
***            http://www.west-wind.com/
***  Function: Registers an OLE server or OCX control
***      Pass: lcServerPath  -  Full path and filename of OCX/OLE Server
***            llUnregister  -  .T. to unregister
***            lcClassId     -  (optional) check for class Id - if 
***                                        exist don't reregister 
***    Return: .T. or .F.
*************************************************************************
LPARAMETER lcServerPath, llUnRegister, llSilent
LOCAL llRetVal

IF !FILE(lcServerPath)
    RETURN .f.
ENDIF

llRetVal=.F.
IF !llUnregister
   DECLARE INTEGER DllRegisterServer ;
      IN (lcServerPath)

   IF DllRegisterServer() = 0
      If !llSilent
         wait window nowait lcServerPath + " has been registered..."
      endif
      llRetVal=.T.
   ELSE
*!*	      DECLARE INTEGER GETLASTERROR IN WIN32API
*!*	      lnError = GetLastError()
*!*	      wait window STR(lnError)
   ENDIF
   
ELSE
   DECLARE INTEGER DllUnregisterServer ;
      IN (lcServerPath)

   IF DllUnregisterServer() = 0
      if !llSilent
        wait window nowait lcServerPath + " has been unregistered..."
      ENDIF
      llRetVal=.T.
   ENDIF
ENDIF      

RETURN llRetVal

************************************************************************
PROCEDURE DCOMCnfgServer
***********************
***  Function: Sets the security attributes of an Automation server
***            to Interactive User
***    Assume: Only works for Interactive user for now
***      Pass: lcProgId  -  Program ID for the server (wcdemo.wcdemoserver)
***            lcRunAs   -  User Account (Default: Interactive User)
***    Return: nothing
*************************************************************************
LPARAMETER lcProgId, lcRunAs
LOCAL lcProgId, loAPI, lcClassId, lcServerName

lcRunAs=IIF(type("lcRunAs")="C",lcRunAs,"Interactive User")
lcProgId=IIF(type("lcProgId")="C",lcProgId,"")
loAPI = CREATE("wwAPI")

*** Retrieve ClassId and Server Name
lcClassId = loAPI.ReadRegistryString(HKEY_CLASSES_ROOT,;
                                     lcProgId + "\CLSID",;
                                     "")
lcServerName = loAPI.ReadRegistryString(HKEY_CLASSES_ROOT,;
                                        lcProgId + "","")

IF ISNULL(lcClassId) or ISNULL(lcServerName)
  wait window nowait "Invalid Class Id..."
  RETURN
ENDIF
  
wait window "Configuring server security for "+CR+;
             lcProgId + CR + lcServerName  nowait

*** Now add AppId key to the ClsID entry
if !loAPI.WriteRegistryString(HKEY_LOCAL_MACHINE,;
        "SOFTWARE\Classes\CLSID\"+lcClassId,"AppId",lcClassID,.t.)
   wait window "Unable to write AppID value..."  nowait
   RETURN
ENDIF                                     


*** Create a AppID Entry if it doesn't exist
if !loAPI.WriteRegistryString(HKEY_CLASSES_ROOT,;
        "AppID\"+lcClassId,CHR(0),CHR(0),.t.)
   wait window "Unable to write AppID key..."  nowait
   RETURN
ENDIF                                     

*** Write the Server Name into the Default key
loAPI.WriteRegistryString(HKEY_CLASSES_ROOT,;
                          "AppID\"+lcClassId,"",;
                          lcServerName,;
                          .t.)

*** Write Interactive User (or user Accounts)                          
loAPI.WriteRegistryString(HKEY_CLASSES_ROOT,;
                          "AppID\"+lcClassId,"RunAs",;
                          lcRunAS,;
                          .t.)

wait window "DCOM security context set to: " + lcRunAs nowait                          
RETURN 


************************************************************************
FUNCTION HTMLColor
*********************************
***  Function: Converts a FoxPro Color to an HTML Hex color value
***      Pass: lnRGBColor   -  FoxPro RGB color number - RGB(255,255,255)
***            llNoOutput
***    Return: Hex HTML Color String "#FFFFFF"
************************************************************************
LPARAMETER lnRGBColor

lcColor=RIGHT(TRANSFORM(lnRGBColor,"@0"),6)

*** Fox color is BBGGRR, HTML is RRGGBB

RETURN "#" + SUBSTR(lcColor,5,2) + SUBSTR(lcColor,3,2) + LEFT(lcColor,2)
* HTMLColor


************************************************************************
PROCEDURE DateToC
******************
***  Function: Converts a date to string displaying empty dates as blanks
***            rather than displaying the empty date format
***      Pass: ldDate  - Date to display
***    Return: Date String or "" if invalid date
*************************************************************************
LPARAMETER ldDate

IF EMPTY(ldDate)
   RETURN ""
ENDIF

RETURN  DTOC(ldDate)
* DateTOC

************************************************************************
PROCEDURE TimeToC
******************
***  Function: Converts a time to string displaying empty  as blanks
***            and formatting the time string properly
***      Pass: ltTime  - Date to display (Pass Time, Date or Char)
***    Return: Time String or "" if invalid date (Year is not returned)
*************************************************************************
LPARAMETER ltTime

IF EMPTY(ltTime)
   RETURN ""
ENDIF

IF TYPE("ltTime") $ "DT"
  lcTimestamp = TTOC(ltTime)
ELSE
  lcTimeStamp = ltTime  
ENDIF  

RETURN  Substr(lcTimeStamp,1,5)+Substr(lcTimeStamp,9,6)+lower(Substr(lcTimeStamp,19,2))
* DateTOC

************************************************************************
FUNCTION GetAppStartPath
*********************************
***  Function: Returns the FoxPro start path
***            of the *APPLICATION*
***            under all startmodes supported by VFP.
***            Returns the path of the starting EXE, 
***            DLL, APP, PRG/FXP
***    Return: Path as a string with trailing "\"
************************************************************************
DO CASE 
   #IF wwVFPVersion = 03
   CASE .T.
       lcPath = JustPath(SYS(16,0))
   #ENDIF
   *** Active Document
   CASE ATC(".VFD",SYS(16,0)) > 0
       lcPath = HOME() 
   *** OutOfProcess EXE Server
   CASE Application.StartMode = 2
       DECLARE integer GetModuleFileName ;
             IN WIN32API ;
             integer hinst,;
             string @lpszFilename,;
             integer @cbFileName
   
       lcFilename=space(256)
       lnBytes=255   
       =GetModuleFileName(0,@lcFileName,@lnBytes)

       lnBytes=AT(CHR(0),lcFileName)
       IF lnBytes > 1
          lcFileName=SUBSTR(lcFileName,1,lnBytes-1)
       ELSE
          lcFileName=""
       ENDIF       
       
       lcPath = JustPath(lcFileName)

   *** InProcess DLL Server
   CASE Application.StartMode = 3
      lcPath = HOME()

  *** Standalone EXE or VFP Development
  OTHERWISE
       lcPath = JustPath(SYS(16,0))
ENDCASE

RETURN AddBs(lcPath)
* EOF GetAppStartPath      

#IF wwVFPVersion < 06

************************************************************************
FUNCTION JustFname
******************
***  Function: Returns just the filename portion of a path spec
***      Pass: lcFullPath
***    Return: Filename
*************************************************************************
LPARAMETER lcFilePath

IF EMPTY(lcFilePath)
   RETURN ""
ENDIF

lcFilePath=STRTRAN(TRIM(lcFilePath),"/","\")
lcFilePath=STRTRAN(lcFilePath,"\\","\")

lnLastSlash=RAT("\",lcFilePath)
If lnLastSlash=0
  *** Now check for Drive only
  lnLastSlash=RAT(":",lcFilePath)
ENDIF

*** No slashes - return full file name
IF lnLastSlash=0
   RETURN lcFilePath
ENDIF

*** No Filename in path if spec ends in slash
IF RIGHT(lcFilePath,1)="\"
   RETURN ""
ENDIF
   
RETURN SUBSTR(lcFilePath,lnLastSlash+1)

************************************************************************
FUNCTION JustStem
*****************
***  Function: Returns just the Filename without extension.
***      Pass: lcFile  -  File name or filename and path
***    Return: file stem
*************************************************************************
LPARAMETER lcFile
lcFile=JustFname(lcFile)
lnDot=AT(".",lcFile)
IF lnDot < 2
   RETURN lcFile
ENDIF   
RETURN LEFT(lcFile,lnDot-1)


************************************************************************
FUNCTION JustExt
******************
***  Function: Returns just a file extension
***      Pass: lcFile - Name of the file or full path + file
***    Return: Extension or ""
*************************************************************************
LPARAMETER lcFile
lcFile=JustFname(lcFile)
lnDot=AT(".",lcFile)
IF lnDot < 2 OR LEN(lcFile) < lnDot+1
   RETURN ""
ENDIF   
RETURN SUBSTR(lcFile,lnDot+1)


************************************************************************
FUNCTION JustPath
******************
***  Function: Returns just the path portion of a path spec
***    Assume: Path is returned with a trailing slash
***      Pass: lcFullPath
***    Return: Filename
*************************************************************************
LPARAMETER lcFilePath

IF EMPTY(lcFilePath)
   RETURN ""
ENDIF

IF lcFilePath = "\\"
   lcFilePath="\" + STRTRAN(lcFilePath,"\\","\")
ELSE
   lcFilePath=STRTRAN(lcFilePath,"\\","\")
ENDIF   

lnLastSlash=RAT("\",lcFilePath)
If lnLastSlash=0
  *** Now check for Drive only
  lnLastSlash=RAT(":",lcFilePath)
ENDIF

*** No slashes - no path specified
IF lnLastSlash=0
   RETURN ""
ENDIF

*** No Filename in path if spec ends in slash
IF RIGHT(lcFilePath,1)="\"
   RETURN lcFilePath
ENDIF

RETURN SUBSTR(lcFilePath,1,lnLastSlash)

************************************************************************
FUNCTION AddBS
******************
***  Modified: 07/21/96
***  Function: Add BackSlash to path.
***      Pass: lcPath -  Path to append Backslash to
***    Return:
*************************************************************************
LPARAMETER lcPath
lcPath=LTRIM(lcPath)
RETURN IIF(RIGHT(lcPath,1)#"\",lcPath+"\",lcPath)
* EOP AddBs



************************************************************************
FUNCTION ForcePath
*********************************
***  Function: Forces a path expression to the drive specified by
***            cPathOverride to allow mapping for network drives
***            to the INI and output files. 
***      Pass: lcPath    -  Path to work with
***            lcNewPath -  Path to override with
***     Notes: Does not guarantee valid path name!!!
***    Return: changed path or same path if no drive was specified
***            in the path string.
************************************************************************
LPARAMETERS lcFilename, lcNewPath
LOCAL lcNewPath, lnSlash
lcFileName=justfname(lcFileName)

*** Use the current path and replace drive
RETURN LOWER(AddBs(lcNewPath)+lcFilename)
* ForcePath   


************************************************************************
FUNCTION ForceExt
******************
***  Function: Converts or adds an extension to a filename
***      Pass: lcFileName
***            lcExtension
***    Return: Filename with new extension
************************************************************************
LPARAMETERS lcFilename, lcExtension
#IF wwVFPVERSION >= 06
   RETURN ForceExt(lcFileName,lcExtension)
#ENDIF
LOCAL lcNewPath, lnSlash
lndot = RAT(".",lcFileName)
IF lnDot > 1
   RETURN lower(SUBSTR(lcFilename,1,lnDot)+lcExtension)
ELSE
   RETURN lower(lcFileName+"."+lcExtension)
ENDIF

ENDFUNC
*EOP ForceExt

#ENDIF
 


************************************************************************
FUNCTION IsDir
******************
***  Modified: 10/09/97
***  Function: Checks to see whether a directory exists
***      Pass: lcPath   -  Path to check
***    Return: .T. or .F.
*************************************************************************
LPARAMETER lcPath
DIMENSION laTemp[1]
IF ADIR(laTemp,lcPath,"D") < 1
   RETURN .F.
ENDIF
RETURN .T.


************************************************************************
FUNCTION Slash
******************
***  Function: Converts slashes from DOS -> Web and vice versa
***      Pass: lcPath   -  Path to convert
***            lcStyle  -  "WEB" or "DOS"
***    Return: update path
************************************************************************
LPARAMETER lcPath, lcStyle
lcStyle=IIF(type("lcStyle")="C",UPPER(lcStyle),"")
IF lcStyle="WEB"
   lcPath=CHRTRAN(lcPath,"\","/")
ELSE
   lcPath=CHRTRAN(lcPath,"/","\")
ENDIF
RETURN lcPath
*EOP LPARAMETER


************************************************************************
FUNCTION PEMSTATUS
******************
***  Modified: 06/11/96
***  Function: Simulates PEMSTATUS for VFP 3.0 * 
***            Native PEMSTATUS() overrides in 3.0b and later
***            Note: Only PEMSTATUS(object, method, 5) is implemented
***      Pass: loObject -  Object parameter to check PEMs for
***            lcMethod -  Method or Property to check for
***            lnValue  -  Not used - like PEMSTATUS(o,m,5)
***    Return: .T. or .F. if object exists
*************************************************************************
LPARAMETER loObject,lcMethod, lnValue
LOCAL lnMembers, x, lcOldExact, llReturn

lcOldExact=SET("EXACT")
SET EXACT ON

lnMembers=AMEMBERS(laPEMs,loObject,1)
IF ASCAN( laPEMS, UPPER(lcMethod) ) > 0
   llReturn=.T.
ELSE
   llReturn=.F.   
ENDIF   

SET EXACT &lcOldExact

RETURN llReturn
* PEMSTATUS


************************************************************************
PROCEDURE ProgLevel
******************
***  Function: Returns the current Calling Stack level. Used to check
***            recursive Error calls in Error methods.
*************************************************************************

FOR x=1 to 128
   IF EMPTY(SYS(16,x))
      exit
   ENDIF
ENDFOR && x=1 to 128

*** -1 for x count - -1 for ProgLevel Call
RETURN x - 2


************************************************************************
PROCEDURE AParseString
**********************
***  Modified: 07/03/97
***  Function: Parses a delimited string into an array
***      Pass: laResult    -   Array containing the result strings (@)
***            lcString    -   The full string
***            lcDelimiter -   The delimiter string
***    Return: Count of strings or 0 if null string is passed
*************************************************************************
LPARAMETER laResult, lcString, lcDelimiter
LOCAL lnLastPos, lnItemCount, i

lnItemCount = OCCURS(lcDelimiter,lcString) + 1
DIMENSION laResult[lnItemCount]
lnLastPos=1

FOR i=1 to lnItemCount
   IF i < lnItemCount
     laResult[i] = SUBSTR(lcString,lnLastPos, ;
                          ATC(lcDelimiter,lcString,i) - lnLastPos )
   ELSE
     laResult[i] = SUBSTR(lcString,lnLastPos)
   ENDIF
   lnLastPos = ATC(lcDelimiter,lcString,i) + 1
ENDFOR

RETURN lnItemCount
* EOF AParseString

************************************************************************
FUNCTION URLDecode
******************
***  Function: URLDecodes a text string to normal text.
***    Assume: Uses wwIPStuff.dll
***      Pass: lcText    -   Text string to decode
***    Return: Decoded string or ""
************************************************************************
LPARAMETERS lcText
LOCAL lnSize

*** Use wwIPStuff for large buffers
IF LEN(lcText) > 1024
   DECLARE INTEGER URLDecode ;
      IN WWIPSTUFF AS API_URLDecode ;
      STRING @cText

   lnSize=API_URLDecode(@lcText)

   IF lnSize > 0
      lcText = SUBSTR(lcText,1,lnSize)
   ELSE
      lcText = ""
   ENDIF

   RETURN lcText
ENDIF

*** First convert + to spaces
lcText=STRTRAN(lcText,"+"," ")

*** Handle Hex Encoded Control chars

lcRetval = ""
DO WHILE .T.
   *** Format: %0A  ( CHR(10) )
   lnLoc = AT('%',lcText)

   *** No Hex chars
   IF lnLoc > LEN(lcText) - 2 OR lnLoc < 1
      lcRetval = lcRetval + lcText
      EXIT
   ENDIF

   *** Now read the next 2 characters
   *** Check for digits - at this point we must have hex pair!
   lcHex=SUBSTR(lcText,lnLoc+1,2)

   *** Now concat the string plus the evaled hex code
   lcRetval = lcRetval + LEFT(lcText,lnLoc-1) + ;
      CHR( EVAL("0x"+lcHex) )

   *** Trim out the input string
   IF LEN(lcText) > lnLoc + 2
      lcText = SUBSTR(lcText,lnLoc+3)
   ELSE
      EXIT
   ENDIF
ENDDO

RETURN lcRetval
ENDFUNC
* EOF URLDecode

************************************************************************
FUNCTION GetURLEncodedKey
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
LPARAMETERS lcURLString, lcKey
LOCAL lnLoc,c2, cStr

lcURLString=IIF(EMPTY(lcURLString),"",lcURLString)
lcKey=IIF(EMPTY(lcKey),"  ",lcKey)
lcKey=STRTRAN(lcKey," ","+")

*** First try locating the key with & in front
lnloc=ATC("&"+lcKey+"=",lcURLString)
*!*	IF EMPTY(lnLoc)
*!*	   *** Not found - now try without
*!*	   lnloc=ATC(lcKey+"=",lcURLString)
*!*	   IF lnLoc = 0
*!*	      *** No match
*!*	      RETURN ""
*!*	   ENDIF
*!*	ENDIF   

lcRetval=Extract(lcUrlString,"&"+lcKey+"=","&",,.T.)
*!*	IF EMPTY(lcRetval)
*!*	   lcRetval=Extract(lcUrlString,lcKey+"=","&",,.T.)
*!*	ENDIF

RETURN URLDecode(lcRetval)
ENDFUNC


********************************************************
PROCEDURE URLEncode
*******************
***  Function: Encodes a string in URL encoded format
***            for use on URL strings or when passing a
***            POST buffer to wwIPStuff::HTTPGetEx
***      Pass: tcValue  -   String to encode
***    Return: URLEncoded string or ""
********************************************************
LPARAMETER tcValue
LOCAL lcResult, lcChar, lnSize, x

*** Large Buffers use the wwIPStuff function 
*** for quicker response
if LEN(tcValue) > 80
   lnSize=LEN(tcValue)
   tcValue=PADR(tcValue,lnSize * 3)

   DECLARE INTEGER VFPURLEncode ;
      IN WWIPSTUFF ;
      STRING @cText,;
      INTEGER cInputTextSize
   
   lnSize=VFPUrlEncode(@tcValue,lnSize)
   
   IF lnSize > 0
      RETURN SUBSTR(TRIM(tcValue),1,lnSize)
   ENDIF
   RETURN ""
ENDIF   
   
*** Do it in VFP Code
lcResult=""

FOR x=1 to len(tcValue)
   lcChar = SUBSTR(tcValue,x,1)
   IF ATC(lcChar,"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789") > 0
      lcResult=lcResult + lcChar
      LOOP
   ENDIF
   IF lcChar=" "
      lcResult = lcResult + "+"
      LOOP
   ENDIF
   *** Convert others to Hex equivalents
   lcResult = lcResult + "%" + RIGHT(transform(ASC(lcChar),"@0"),2)
ENDFOR && x=1 to len(tcValue)

RETURN lcResult
* EOF URLEncode


************************************************************************
PROCEDURE WCSCompile
********************
***  Modified: 12/31/97
***  Function: Compiles WCS script files
***    Assume: Requires Runtime version
***            Called by wwMaint using VisualFoxpro.Application
***            Automation object if Runtime is installed.
***      Pass: lcFileSpec    -   Filespec of files to compile
***            llSilent      -   No error display
***    Return: "" on success or Error String
*************************************************************************
LPARAMETER lcFileSpec, llSilent, llKeepCode
lcFileSpec=IIF(type("lcFileSpec")="C",lcFileSpec,CURDIR() + "*.wcs")

lcPath = justpath(lcFileSpec)
lcFile = justfname(lcFileSpec)

IF EMPTY(lcPath)
  lcPath = CURDIR()
ENDIF
IF EMPTY(lcFile)
  lcFile = "*.WCS"
ENDIF
lcPath = ADDBS(lcPath)

lcFileSpec = lcPath + lcFile


DIMENSION laFiles[1]
lnFiles = ADIR(laFiles,lcFileSpec)
IF lnFiles < 1
   RETURN "No files to compile..."
ENDIF
oScript = CREATE("wwVFPScript",laFiles[1])
IF TYPE("oScript") <> "O"
  Return "Error: Couldn't create wwVFPScriptObject"
ENDIF
IF !llKeepCode
  oScript.lDeleteGeneratedCode = .T.   && Erase WCT files
ENDIF  

FOR x = 1 to lnFiles
         lcFileName = lcPath+laFiles[x,1]
         wait window nowait "Compiling "+lcFileName
         
         *** WCS - Script Text   WCX - Compiled   WCT - Intermediate
         oScript.cFileName = lcFileName
         oScript.ConvertPage()
         oScript.CompilePage() 
ENDFOR

wait window nowait LTRIM(STR(lnFiles))+ " Web Connection Script file(s) compiled."

lcErrors = ""
IF !EMPTY(oScript.cCompileErrors)
   File2Var(lcPath + "WCS_Script.err",oScript.cCompileErrors)
   IF !llSilent
      MODI COMM (lcPath + "WCS_Script.err")
   ENDIF
   lcErrors = File2Var(lcPath + "WCS_Script.err")
ENDIF

RETURN lcErrors
* EOF WCSCompile


************************************************************************
FUNCTION MergeText
******************
***  Function: This function provides an evaluation engine for FoxPro
***            expressions and Codeblocks that is tuned for Active
***            Server syntax. It works with any delimiters however. This
***            parsing engine is faster than TEXTMERGE and provides
***            extensive error checking and the ability to run
***            dynamically in the VFP runtime (ie uncompiled). Embed any
***            valid FoxPro expressions using
***            
***               <%= Expression%>
***            
***            and any FoxPro code with
***            
***               <% CodeBlock %>
***            
***            Expressions ideally should be character for optimal
***            speed, but other values are converted to string
***            automatically. Although optimized for the delimiters
***            above you may specify your own. Make sure to set the
***            llNoAspSyntax parameter to .t. to disallow the = check
***            for expressions vs code. If you use your own parameters
***            you can only evaluate expressions OR you must use ASP
***            syntax and follow your deleimiters with an = for
***            expressions.
***   Assume:  Delimiter is not used in regular text of the text.
***     Uses:  wwEval class (wwEval.prg)
***            Codeblock Class (wwEval.prg)         
***     Pass:  tcString    -    String to Merge
***            tcDelimeter -    Delimiter used to embed expressions
***                             Default is "<%"
***            tcDelimeter2-    Delimiter used to embed expressions
***                             Default is "%>"
***            llNoAspSytnax    Don't interpret = following first
***                             parm as expression. Everything is 
***                             evaluated as expressions.
***
***  Example:  loHTML.MergeText(HTMLDocs.MemField,"##")
*************************************************************************
LPARAMETER tcString,tcDelimiter, tcDelimiter2, llNoASPSyntax

*__loEval=CREATE("MergeText")
*RETURN __loEval.MergeText(@tcString)

LOCAL lnLoc1,lnLoc2,lnIndex, lcEvalText, lcExtractText, lcOldError, ;
	lnErrCount, lcType
PRIVATE plEvalError

plEvalError=.F.   && Debug Error Variable

tcDelimiter=IIF(EMPTY(tcDelimiter),"<%",tcDelimiter)
tcDelimiter2=IIF(EMPTY(tcDelimiter2),"%>",tcDelimiter2)

*** Occurance flag for second delim AT()
IF tcDelimiter # tcDelimiter2
	lnDifferent = 1
ELSE
	lnDifferent = 2
ENDIF

lnLoc1=1
lnLoc2=1
lnIndex=0

*** Create Evaluate Object (for error trappign)
loEval=CREATE([WWC_wwEval])  && 'wwEval'  defined in WCONNECT.H
loEval.SetResultType("C")
loEval.SetErrorResult("")

*** DEBUGMODE - Set up Error Handler
***             Otherwise Eval object handles errors
***             You can disable this here to find any script bugs
#IF DEBUGMODE
	lcOldError=ON("ERROR")
	ON ERROR plEvalError=.T.
#ENDIF

lnErrCount=0

*** Loop through all occurances of embedding
DO WHILE lnLoc1 > 0 AND lnLoc2>0
	*** Find instance
	lnLoc1=AT(tcDelimiter,tcString,1)

	IF lnLoc1>0
		*** Now check for the ending delimiter
		lnLoc2=AT(tcDelimiter2,tcString,lnDifferent)

		IF lnLoc2>lnLoc1
			*** Strip out the delimiter to get embedded expression
			lcExtractText=SUBSTR(tcString,lnLoc1+LEN(tcDelimiter),;
				lnLoc2-lnLoc1-LEN(tcDelimiter)  )


			IF llNoASPSyntax
				loEval.Evaluate(lcExtractText)
		#IF wwVFPVersion > 5		
				IF VARTYPE(loEval.Result) # "C"
					loEval.Result = TRANSFORM(loEval.Result)
				ENDIF
        #ELSE
				IF TYPE("loEval.Result") # "C"
					loEval.Result = TRANSFORM(loEval.Result,"")
				ENDIF
        #ENDIF				
			ELSE
			    *** ASP Syntax allows for <%= Expression %> <% CodeBlock %>
				IF  lcExtractText = "="
					loEval.Evaluate(SUBSTR(lcExtractText,2))
		          #IF wwVFPVersion > 5		
					IF VARTYPE(loEval.Result) # "C"
						loEval.Result = TRANSFORM(loEval.Result)
					ENDIF
		          #ELSE
					IF TYPE("loEval.Result") # "C"
						loEval.Result = TRANSFORM(loEval.Result,"")
					ENDIF
		          #ENDIF				
				ELSE
			 		loEval.Execute(lcExtractText)
                 #IF wwVFPVersion > 5		
					IF VARTYPE(loEval.Result) # "C"
				 #ELSE	
					IF TYPE("loEval.Result") # "C"
			     #ENDIF
					loEval.Result = ""
					ENDIF
				ENDIF
			ENDIF

			IF !loEval.lError AND !plEvalError
				*** Now translate and evaluate the expression
				*** NOTE: Any delimiters contained in the evaluated
				***       string are discarded!!! Otherwise we could end
				***       up in an endless loop...
				tcString= STRTRAN(tcString,tcDelimiter+lcExtractText+tcDelimiter2,;
					TRIM(loEval.Result))
			ELSE

			*** Check for EVAL error
*			IF loEval.lError or plEvalError
				plEvalError=.F.

				*** Bail-Out Hack in case invalid bracket code
				*** causes recursive lockup
				lnErrCount=lnErrCount+1
				IF lnErrCount>150
					EXIT
				ENDIF

				*** Error - embed an error string instead
				tcString=STRTRAN(tcString,;
					tcDelimiter+lcExtractText+tcDelimiter2,;
					"< % ERROR: "+STRTRAN(STRTRAN(lcExtractText,tcDelimiter,""),tcDelimiter2,"")+ " % >")
			ENDIF

		ELSE
			tcString = STUFF(tcString,lnLoc2,LEN(tcDelimiter2),SPACE(LEN(tcDelimiter2)) )
			LOOP
		ENDIF  && lnLoc2>=lnLoc1
	ENDIF     && lnLoc2>0
ENDDO

*** DEBUGMODE - Turn off the error handler
#IF DEBUGMODE
	ON ERROR &lcOldError
#ENDIF

RETURN tcString
*EOF MergeText