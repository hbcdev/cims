#define GDIPLUS_Unit_Point      3
#define GDIPLUS_FontStyle_Regular     0
#DEFINE FRX_OBJCOD_DETAIL 4

CREATE CURSOR crsrRLStringTrim (cField C(240))
FOR i = 1 TO 5
	*!* http://www.baen.com/library/1011250002/1011250002.htm
	INSERT INTO crsrRLStringTrim VALUES ;
		("Peace to you, small lady, he thought to Raina. " + ;
		 "You've won a twisted poor modern knight, to wear your " + ;
		 "favor on his sleeve.")
ENDFOR

*!* Passing oListener to the REPORT FORM command below will cause the
*!* report to display with 9.0 behavior regardless of the setting here:
*!* CREATE REPORT, though, doesn't know about the listener, so we need
*!* to change SET REPORTBEHAVIOR.
SET REPORTBEHAVIOR 90	
CREATE REPORT RLStringTrim FROM crsrRLStringTrim
MODIFY REPORT RLStringTrim NOWAIT 
WAIT WINDOW "Remove the 'Stretch with overflow' setting on cField, then save and resume." NOCLEAR
SUSPEND	
*!* While you're suspended here, change the field in the report so that it 
*!* doesn't stretch with overflow. Then close the report and resume.
WAIT CLEAR

oListener = CREATEOBJECT("RLStringTrim")

REPORT FORM RLStringTrim OBJECT oListener


DEFINE CLASS RLStringTrim as ReportListener
	oGraphics = .NULL.
	oFont = .NULL.
	oFormat = .NULL.
	oFillColor = .NULL.
	oBrush = .NULL.
	
	lDetail = .F.
	
	ListenerType = 1
	
	PROCEDURE Init
		*!* Unfortunately, StringTrimming isn't just a property we can flip.
		*!* It's part of the formatting we use to draw a string. Hence, to
		*!* change this, we need to do all the work needed to actually
		*!* draw the string.
		*!*
		*!* Note, of course, that there's a setting you can change within the
		*!* Report Designer to change the behavior of StringTrimming. This 
		*!* code just shows how to do it with a ReportListener.
		
		*!* gpGraphics gives us a surface to draw on.
		This.oGraphics = NEWOBJECT("gpGraphics", HOME(1) + "ffc\_gdiplus.vcx")

		*!* gpFont allows us to create a font object.
		This.oFont = NEWOBJECT("gpFont", HOME(1) + "ffc\_gdiplus.vcx")
		This.oFont.Create("Courier New", 10, GDIPLUS_FontStyle_Regular, GDIPLUS_Unit_Point)
		
		*!* gpStringFormat gives us finer control over the display of the strings
		This.oFormat = NEWOBJECT("gpStringFormat", HOME(1) + "ffc\_gdiplus.vcx")
		This.oFormat.Create()

		*!* gpColor gives us a color (here, black) to fill in the text.
		This.oFillColor = NEWOBJECT("gpColor", HOME(1) + "ffc\_gdiplus.vcx")
		This.oFillColor.Set(0, 0, 0, 255)	&& RGB + Alpha (transparency)
		
		*!* gpSolidBrush is what we draw the text with.
		This.oBrush = NEWOBJECT("gpSolidBrush", HOME(1) + "ffc\_gdiplus.vcx")
		This.oBrush.Create(This.oFillColor)
	ENDPROC
	
	PROCEDURE Destroy
		This.oGraphics = .NULL.
		This.oFont = .NULL.
		This.oFormat = .NULL.
		This.oFillColor = .NULL.
		This.oBrush = .NULL.
	ENDPROC
	
	*!* In here, we only want to change the text in the detail lines. So,
	*!* on the way into the detail band, we set a property to tell us
	*!* that we're in that band. On the way out, we turn it back off.
	PROCEDURE BeforeBand
		LPARAMETERS nBandObjCode, nFRXRecNo
		
		IF nBandObjCode = FRX_OBJCOD_DETAIL
			This.lDetail = .T.
		ENDIF
	ENDPROC
	
	PROCEDURE AfterBand
		LPARAMETERS nBandObjCode, nFRXRecNo
		
		IF nBandObjCode = FRX_OBJCOD_DETAIL
			This.lDetail = .F.
		ENDIF
		DODEFAULT(nBandObjCode, nFRXRecNo)
	ENDPROC
	
	
	PROCEDURE Render
		LPARAMETERS nFRXRecNo,;
					nLeft, nTop, nWidth, nHeight,;
					nObjectContinuationType, ;
					cContentsToBeRendered, GDIPlusImage
					
		IF This.lDetail
			*!* Tell the graphics class what we're drawing on
			This.oGraphics.SetHandle(This.GDIPlusGraphics)
			
			*!* Set the string trimming feature to one of the 5
			*!* non-default values. Each record should be set
			*!* differently, so using RECNO() is a quick-and-
			*!* dirty way to get the values.
			This.oFormat.Trimming = RECNO()
			
			*!* Create a GDI+ Rectangle which specifies where on the
			*!* surface we're drawing the text.
			loRect = This.oGraphics.MakeGdipRectF(nLeft, nTop, nWidth, nHeight)
			
			*!* cContentsToBeRendered, in a field object, contains a
			*!* Unicode string, instead of the ASCII we typically work
			*!* with. Therefore, we need to use DrawStringW instead of
			*!* DrawStringA to place it on the surface.
			This.oGraphics.DrawStringW(cContentsToBeRendered, This.oFont, ;
				loRect, This.oFormat, This.oBrush)
		ELSE
			*!* If we're not in the detail band, let Fox draw the text as
			*!* usual.
			DODEFAULT(nFRXRecNo, nLeft, nTop, nWidth, nHeight, ;
				nObjectContinuationType, cContentsToBeRendered, GDIPlusImage)
		ENDif	
		
		*!* Since we already drew the text, we don't want the default
		*!* behavior to occur.
		NODEFAULT
	ENDPROC
ENDDEFINE