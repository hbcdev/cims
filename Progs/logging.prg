*!***********************************************************************************
*! Function Name: WriteLog()
*! Description	: Write to a Log File or Foxpro free table or to WIN NT/WIN 2K Events
*! Parameters	: tcAction	->	Action that has/will be taken. (Character)
*!				  tnResult	->	Result of Action. (Numeric - See Logging Code below)
*!				  tcOther	->	Any other information that should be noted. (String)
*! Returns		: Nothing
*! Logging Code	: 0	 ->  Successful
*!				  1  ->  Failed
*!				  2  ->  Warning
*!				  4  ->  Information
*!				  8  ->  Audit Success
*!				  16 ->  Audit Failure
*! Notes		: Any Items marked optional with [braces] need to have a
*!				  blank string passed into the function.
*!				  For more Information email me (vreboton@hotmail.com)
*!***********************************************************************************

*-- You should declare this constant somewhere in your application
*-- before calling this function. Or you can also allow your user
*-- to select for the type of logging s/he wants.
*-- The value of the this constant are:
*-- 1	->	No Logging
*-- 2	->	Text File
*-- 3	->	Foxpro Free Table
*-- 4	->	Event Logging (WIN NT and WIN 2K only)

#DEFINE CRLF 				CHR(13) + CHR(10)
#DEFINE LOGGINGTYPE_LOC		4  && Type Of Logging
#DEFINE LOGFILEDIR			"C:\MyLogs\"  && Log file directory

FUNCTION WriteLog(tcAction, tnResult, tcOther)
  LOCAL lcOldError, llError, lcLogFileName, lcLogInfo
  LOCAL lcTimeStamp, lcUserID, lcStatus
  LOCAL WSHShell, lcTableName, lnEvent

  *-- Get Time Stamp (hh:mm:ss DOW MDY)
  lcTimeStamp = TTOC(DATETIME())

  *-- Get Currently log User
  lcUserID = "current user" && You can call a function here that gets the
							&& Currently log USERID in your application

  lcOldError = ON('ERROR')
  ON ERROR llError = .T.

  *-- Get Event type
  lnEvent = IIF(EMPTY(tnResult),4,tnResult)

  *-- Check to See what type of logging was selected
  DO CASE
    CASE LOGGINGTYPE_LOC = 1 && No Logging

    CASE LOGGINGTYPE_LOC = 2 && Text File Logging

      *-- Create the Log file Name that will be used
      lcLogFileName = LOGFILEDIR + "AppName" + STRTRAN(DTOC(DATE()),"/","-") + ".txt"

      *-- Create New Log information
      lcLogInfo = lcTimeStamp + ", "
      lcLogInfo = lcLogInfo + " " + lcUserID + ", "
      lcLogInfo = lcLogInfo + " " + ALLTRIM(tcAction) + ", "
      lcLogInfo = lcLogInfo + " " + ALLTRIM(STR(tnResult)) + ", "
      lcLogInfo = lcLogInfo + " " + ALLTRIM(tcOther) 

      *-- Write new entry to text file
      =STRTOFILE(lcLogInfo + CRLF, lcLogFileName, .T.)

    CASE LOGGINGTYPE_LOC = 3 && Foxpro free table Logging

      *-- Create the Log file Name that will be used
      lcTableName = "LogFileTable"
      lcLogFileName = LOGFILEDIR + lcTableName + ".dbf"

      *-- Check to see if table exist if not create it then open
      IF !FILE(lcLogFileName) Then

        CREATE TABLE (lcLogFileName) FREE (cTimeStamp C(40), ;
          cUserID C(10), cAction C(30), nResult N(10), cOther C(30))

      ENDIF

      IF !USED(lcTableName) Then
        USE (lcLogFileName) IN 0 SHARED
      ENDIF

      IF !llError Then
        *-- add new record to table
        SELECT (lcTableName)
        APPEND BLANK
        REPLACE cTimeStamp WITH lcTimeStamp,;
          cUserID WITH lcUserID,;
          cAction WITH tcAction,;
          nResult WITH tnResult,;
          cOther WITH tcOther
        FLUSH
        USE IN (lcTableName)
      ENDIF

    CASE LOGGINGTYPE_LOC = 4 && Event Log Logging

      *-- Build New Log information Line
      lcLogInfo = lcTimeStamp + ", "
      lcLogInfo = lcLogInfo + " " + lcUserID + ", "
      lcLogInfo = lcLogInfo + " " + tcAction + ", "
      lcLogInfo = lcLogInfo + " " + ALLTRIM(STR(tnResult)) + ", "
      lcLogInfo = lcLogInfo + " " + tcOther

      *-- Create Window scripting host object
      WSHShell = CREATEOBJECT("WScript.Shell")

      *-- Write Log Information
      IF !llError Then
        WSHShell.LogEvent(lnEvent, lcLogInfo)
      ENDIF
	
	  *-- Destroy Object
	  WSHShell = NULL

  ENDCASE

  ON ERROR &lcOldError

ENDFUNC

