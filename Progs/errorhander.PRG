PROCEDURE errhandler( nerror,cmethod,nline )

* PURPOSE : Provides an Error Handling mechanism (Basic
*           implementation).

LOCAL cmsg
LOCAL oerrorform
LOCAL nanswer

#DEFINE yes          6
#DEFINE error_msg    "Error in <First Steps>"

cmsg = "Error number : " + ALLTRIM(STR(nerror)) + CHR(13) + ;
	"originator : "   + cmethod              + CHR(13) + ;
	"description : "  + MESSAGE()            + CHR(13) + ;
	"line number : "  + ALLTRIM(STR(nline))

	&& If the Application/Program object is known
IF ( TYPE( "oApp" ) == "O" .AND. ! ISNULL( oapp ) )
	&& Here there are some cases that we trap immediately
	DO CASE
	CASE ( nerror == 1958 )          && Error loading
		&& printer driver
		&& Originator : FRMMAIN.CONBUTTONS.CMDPRINT.CLICK
		oapp.MESSAGE( "Cannot load printer driver. " + ;
			"check that a printer has been " + ;
			"defined is on-line.", ;
			16,"Error in «" + oapp.applname + " " + ;
			oapp.VERSION.stringify() + "»" )
		&& Immediate return
		RETURN
	CASE ( nerror == 1705 )          && File access denied
		nanswer = oapp.MESSAGE( "File access denied. " + ;
			"would you like to retry the " + ;
			"operation?", ;
			52,"Error in «" + ;
			oapp.applname + " " + ;
			oapp.VERSION.stringify() + "»" )
		IF ( nanswer == yes )
			RETRY
		ENDIF
	CASE ( nerror == 1001 )          && Feature not available
		&& Maybe there is a line of code that remains in
		&& the source code such as SUSPEND or something
		&& like that. SUSPEND for example is not
		&& supported in a real EXE (feature not available).
		&& We simply trap the error in here and we
		&& return immediately
		RETURN
	ENDCASE
	&& Check if we can use the ErrorForm class ...
	IF ( "FOCUS.VCX"       $ UPPER( SET( "CLASSLIB" ) ) .AND. ;
			"focusfrms.vcx"   $ UPPER( SET( "CLASSLIB" ) ) .AND. ;
			"focusvisual.vcx" $ UPPER( SET( "CLASSLIB" ) ) .AND. ;
			"focusbiz.vcx"    $ UPPER( SET( "CLASSLIB" ) ) .AND. ;
			"focus.fll"       $ UPPER( SET( "LIBRARY"  ) ) .AND. ;
			oapp.errorlevel == 2                                 ;
			)
	&& Create an ErrorForm object
		oerrorform = CREATEOBJECT( "ErrorForm"                    , ;
			oapp                           , ;
			"error in «" + oapp.applname   + ;
			" " + oapp.VERSION.stringify() + ;
			"»"                            , ;
			cmsg )
		&& Show the form
		oerrorform.SHOW()
	ELSE
		oapp.MESSAGE( cmsg,16,"Error in «" + ;
			oapp.applname + " " + ;
			oapp.VERSION.stringify() + "»" )
	ENDIF
ELSE
	MESSAGEBOX( cmsg,16,error_msg )
ENDIF
RETURN
************************************
*
DEFINE CLASS errorform AS dvlmodalform

	HEIGHT      = 249
	WIDTH       = 462
	DOCREATE    = .T.
	AUTOCENTER  = .T.
	BORDERSTYLE = 2
	CAPTION     = ""
	NAME        = "errorform"
	HIDDEN WINDOWTYPE

	ADD OBJECT edterrormessage AS dvleditbox WITH        ;
		ENABLED           = .F.                        , ;
		HEIGHT            = 165                        , ;
		LEFT              = 143                        , ;
		TOP               = 13                         , ;
		WIDTH             = 310                        , ;
		DISABLEDBACKCOLOR = RGB(255,255,255)           , ;
		DISABLEDFORECOLOR = RGB(0,0,0)                 , ;
		NAME              = "edtErrorMessage"

	ADD OBJECT cmdok AS dvlbutton WITH                   ;
		TOP               = 220                        , ;
		LEFT              = 393                        , ;
		HEIGHT            = 21                         , ;
		WIDTH             = 60                         , ;
		CAPTION           = "OK"                       , ;
		DEFAULT           = .T.                        , ;
		NAME              = "cmdOK"

	ADD OBJECT chkincludeinbugs AS dvlcheckbox WITH      ;
		TOP               = 188                        , ;
		LEFT              = 143                        , ;
		HEIGHT            = 15                         , ;
		WIDTH             = 142                        , ;
		CAPTION           = "Insert error in BUGS.DBF?", ;
		VALUE             = .T.                        , ;
		NAME              = "chkIncludeInBugs"

	ADD OBJECT banister AS banister WITH                 ;
		TOP               = 208                        , ;
		LEFT              = 143                        , ;
		WIDTH             = 310                        , ;
		HEIGHT            = 7                          , ;
		NAME              = "Banister"                 , ;
		line1.NAME        = "Line1"                    , ;
		line2.NAME        = "Line2"                    , ;
		line3.NAME        = "Line3"                    , ;
		line4.NAME        = "Line4"

	ADD OBJECT edit1 AS dvleditbox WITH                  ;
		ENABLED           = .F.                        , ;
		HEIGHT            = 200                        , ;
		LEFT              = 6                          , ;
		SCROLLBARS        = 0                          , ;
		TOP               = 13                         , ;
		WIDTH             = 129                        , ;
		NAME              = "Edit1"

	ADD OBJECT imgerror AS dvlimage WITH                 ;
		HEIGHT           = 196                         , ;
		LEFT             = 8                           , ;
		TOP              = 15                          , ;
		WIDTH            = 125                         , ;
		NAME             = "imgError"

	PROCEDURE INIT( o__app,ccaption,cmsg )

	LOCAL ores

	WITH THISFORM

		.APPL        = o__app

		ores         = CREATEOBJECT( "resource" )
		ores.storage = "focus.dbf"

		ores.OPEN()

		.imgerror.PICTURE = ores.loadbitmap( "ERRORLOGO" )

		RELEASE ores

		.CAPTION               = ccaption
		.edterrormessage.VALUE = cmsg

		DODEFAULT()

	ENDWITH
ENDPROC

	PROCEDURE cmdok.CLICK()
	LOCAL cmsg

	WITH THISFORM

		IF ( .chkincludeinbugs.VALUE )

			IF ( FILE( .APPL.runpath + "\BUGS.DBF" ) )

				IF ( dbf_isexclusive( SELECT( "BUGS" ) ) )
					.APPL.MESSAGE( "BUGS.DBF is currently in use. " + ;
						"cannot save bug." )
					RELEASE THISFORM
				ENDIF

				cmsg = STRTRAN( .edterrormessage.VALUE, ;
					CHR(13) + CHR(10)," " )
				cmsg = STRTRAN( cmsg,CHR(13)," " )
				cmsg = STRTRAN( cmsg,CHR(10)," " )

				INSERT INTO bugs ( applname                   , ;
					VERSION                    , ;
					problem                    , ;
					DATETIME                   , ;
					priority                   , ;
					remauthor                  , ;
					category                   , ;
					BUILD                      , ;
					TYPE  )                      ;
					VALUES ( .APPL.applname             , ;
					.APPL.VERSION.stringify()  , ;
					cmsg                       , ;
					DATETIME()                 , ;
					1                          , ;
					.APPL.USER.username        , ;
					"code"                     , ;
					.APPL.VERSION.BUILDDATETIME, ;
					1 )

			ENDIF
		ENDIF

	ENDWITH

	RELEASE THISFORM
ENDPROC

ENDDEFINE
