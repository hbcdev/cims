*********************************************************
** Project  : APPLICATION starter. **
** PROG NAME: gsStart.PRG          **
*********************************************************
** Make sure only one instance started.
=myInstance("csstart")
*********************************************************
** Set the initial environment values
DO set_environment
*********************************************************
ON ERROR DO errhand WITH ;
   ERROR( ), MESSAGE( ), MESSAGE(1), PROGRAM( ), LINENO(1)
*********************************************************
** Set the default directory as this directory.
PUBLIC gcHomeDirectory, gcAppName, gcAppPath
LOCAL lcName, lnCopy, lnSource, llDoCopy

gcAppName = "\\hbcsrv01\shareprogram\aims2013.exe"
gcHomeDirectory = JUSTPATH(SYS(16,0))
SET DEFAULT TO (gcHomeDirectory)
*********************************************************
** IF application not set .. then select the Application
** gsStart.MEM stores the Application name along with fill Path
*gcAppName = "\\hbcnt\apps\shareprogram\cims20050601v9.exe"
** If application not yet set, QUIT
IF EMPTY(gcAppName)
   =MESSAGEBOX("Source Application files not set. ")" ;
   +CHR(13)+"Contact system administrator", ;
   0+16,"Application not available")
   QUIT
ENDIF

** find the application path and find the application
gcAppPath = ADDBS(JUSTPATH(gcAppName))
lcName = JUSTFNAME(gcAppName)
lnCopy =ADIR(aApp1,lcName)     && DEFAULT DIRECTORY
lnSource =ADIR(aApp2,gcAppName) && SOURCE DIRECTORY

** If source directory not available, QUIT
IF lnSource = 0
   =MESSAGEBOX("Source Application files not available." ;
      +CHR(13)+"Contact system administrator", ;
      0+16,"Application not available")
   QUIT
ENDIF
*********************************************************
** If newer version available, copy it from source
llDoCopy = .f.
IF lnCopy = 0
   llDoCopy = .t.
ELSE
   IF aApp2(1,3) # aApp1(1,3) OR aApp2(1,4) # aApp1(1,4)
      llDoCopy = .t.
   ENDIF
ENDIF
IF llDoCopy
   WAIT WINDOW "Copying a newer version of the application... please wait" NOWAIT NOCLEAR
   COPY FILE &gcAppName TO &lcName
   WAIT CLEAR
ENDIF
*********************************************************
** To avoid new users from starting application *
IF FILE(gcAppPath+"DoShut.txt")
   _screen.Visible = .f.
   =MESSAGEBOX("System maintenance in progress"+CHR(13) ;
     + "Try after some time",0+16, ;
     "Application cannot start !")
   QUIT
ENDIF
*********************************************************
** Call the Application
DO (lcName)
RETURN
*********************************************************
** COMMON PROCEDURES and FUNCTIONS
*********************************************************
** My default environment settings
PROCEDURE set_environment
   SET ANSI ON
   SET CENTURY ON
   SET CONFIRM ON
   SET CURRENCY TO "ß"
   SET DATE DMY
   SET DELETED ON
   SET EXACT OFF
   SET EXCLUSIVE OFF
   SET MESSAGE TO
   SET MULTILOCKS ON
   SET NEAR ON
   SET NOTIFY OFF
   SET REPROCESS TO AUTOMATIC
   SET SAFETY OFF
   SET STATUS BAR OFF
   SET SYSMENU OFF
   SET TALK OFF
ENDPROC
*********************************************************
** My error handler
PROCEDURE errhand
PARAMETER merror, mess1, mess2, mprog, mlineno
   LOCAL myMessage
   myMessage='Error number: ' + LTRIM(STR(merror)) ;
      + CHR(13) + 'Error message: ' + mess1 + CHR(13) ;
      + 'Line of code with error: ' + mess2 + CHR(13) ;
      + 'Line number of error: ' + LTRIM(STR(mlineno)) ;
      + CHR(13) + 'Program with error: ' + mprog
   =MESSAGEBOX(myMessage,"ERROR !!!",16)
RETURN
*********************************************************
** Procedure to allow only one instance of this application
PROCEDURE myInstance
** How run =myInstance("A name for your Application")
PARAMETERS myApp
    =ddesetoption("SAFETY",.F.)
    ichannel = DDEINITIATE(myapp,"ZOOM")
    IF ichannel =>0
        =DDETERMINATE(ichannel)
        QUIT
    ENDIF
    =DDESETSERVICE(myapp,"define")
    =DDESETSERVICE(myapp,"execute")
    =DDESETTOPIC(myapp,"","ddezoom")
    RETURN
*********************************************************
PROCEDURE ddezoom
    PARAMETER ichannel,saction,sitem,sdata,sformat,istatus
    ZOOM WINDOW SCREEN MAX
    RETURN
*********************************************************
** EOF
*********************************************************