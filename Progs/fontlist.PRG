* From home(1) + "ffc\foxpro_reporting.h"
#define FRX_OBJCOD_DETAIL                   4

CREATE CURSOR crsrFontList ( ;
	cFont char(32))
	
llGotFonts = AFONT(laFonts)
IF NOT llGotFonts
	? "Could not obtain font list: exiting."
	RETURN
ENDIF

FOR i = 1 TO ALEN(laFonts)
	INSERT INTO crsrFontList VALUES (laFonts(i))
ENDFOR
	
CREATE REPORT fontList FROM DBF("crsrFontList")
	
loListen = CREATEOBJECT("myFontListener")
	
REPORT FORM fontList PREVIEW OBJECT loListen 
	
DEFINE CLASS myFontListener as ReportListener
	ListenerType = 1
	lInDetail = .F.
	
	*!* Test that we're in the detail band so we
	*!* don't affect column headers, etc.
	PROCEDURE BeforeBand
		LPARAMETERS nBandObjCode, nFRXRecNo
		
		IF nBandObjCode = FRX_OBJCOD_DETAIL
			This.lInDetail = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE AfterBand
		LPARAMETERS nBandObjCode, nFRXRecNo
		
		IF This.lInDetail
			This.lInDetail = .F.
		ENDIF
	ENDPROC
		
	PROCEDURE EvaluateContents
		LPARAMETERS nFrxRecno, oObjProperties
		
		IF This.lInDetail
			oObjProperties.FontName = ALLTRIM(cFont)
			oObjProperties.Reload = .T.
		ENDIF
	ENDPROC
ENDDEFINE