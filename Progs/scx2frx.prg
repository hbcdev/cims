*
* This is a simple class that transform the running form
* to report style
*
* How to use:
*  Place the button to your form and put the following code
* to Click event button:
*  
*  DO form2report & create the class object oReport
*  oReport.Do(THISFORM)
*  RELEASE oReport
*  LOCAL lcReportName
*  lcReportName=THISFORM.Name
*  REPORT FORM &lcReportName PREVIEW
* 
* You can do the same the other way (when the form property Visible is set to .f.)
*
*  oForm=Createobject("myform")
*  Do form2report 
*  oReport.Do(oForm, "myreportname")
*  Release oReport
*  Report from "myreportname" Preview
*

#DEFINE REPORT_OBJTYPE 1
#DEFINE REPORT_OBJCODE 53
#DEFINE HDF_OBJTYPE 9

* How to use these set of PAGE_ defines:
*  If you want that your form object (textbox, checkbox and etc.) are placed
* on the one of following report part you must
* create new propery named 'objtype' to your object
* and assign it appropriate letter.
#DEFINE PAGE_TITLE "T"
#DEFINE PAGE_HEADER "H"
#DEFINE PAGE_GROUP  "G"
#DEFINE PAGE_DETAIL  "D"
#DEFINE PAGE_GROUPFOOTER "GF"
#DEFINE PAGE_FOOTER "F"
#DEFINE PAGE_SUMMARY "S"

#DEFINE TITLE_OBJCODE 0
#DEFINE HEADER_OBJCODE 1
#DEFINE GROUP_OBJCODE 3
#DEFINE DETAIL_OBJCODE 4
#DEFINE GROUPFOOTER_OBJCODE 5
#DEFINE FOOTER_OBJCODE 7
#DEFINE SUMMARY_OBJCODE 8

#DEFINE BOX_OBJTYPE 7
#DEFINE BOX_OBJCODE 4
#DEFINE FIELD_OBJTYPE 8
#DEFINE FIELD_OBJCODE 0
#DEFINE LABEL_OBJTYPE 5
#DEFINE LABEL_OBJCODE 0
#DEFINE LINE_OBJTYPE 6
#DEFINE LINE_OBJCODE 0

#DEFINE PICT_OBJTYPE 17
#DEFINE PICT_OBJCODE 0

#DEFINE PICT_CHECKBOXON "checkbx.bmp"
#DEFINE PICT_CHECKBOXOFF "checkbxoff.bmp"
#DEFINE PICT_RADIOBON "radiob.bmp"
#DEFINE PICT_RADIOBOFF "radioboff.bmp"



#DEFINE DEFAULT_OUTPUT "H"

#DEFINE REPORT_COEF (625/6)
#DEFINE REPORT_OFFSET 2083.333

#DEFINE DEFAULT_REPORT_NAME "TEST.FRX"

PUBLIC oReport

oReport=CREATEOBJECT("form2report")

DEFINE CLASS form2report AS Custom
	
	HofTitle=0
	HofHeader=0
	HofGroup=0
	HofGroupFooter=0
	HofDetail=0
	HofFooter=0
	HofSummary=0
	
	BofTitle=0
	BofHeader=0
	BofGroup=0
	BofGroupFooter=0
	BofDetail=0
	BofFooter=0
	BofSummary=0
	
	BofPlace=0
	HofPlace=0

	objFontName=""
	objFontStyle=""
	objFontSize=0
	
	objRef=""
	
	ReportName=""
	CursorName=""
	CurCursorName=ALIAS()
	
	PROCEDURE Init
	ENDPROC
	
	PROTECTED FUNCTION OpenDefaultReport
		
		IF FILE(DEFAULT_REPORT_NAME)
			=Use_Db( DEFAULT_REPORT_NAME + " IN 0 ALIAS default_report" )
		ENDIF
		IF USED("default_report")
			SELECT default_report
			RETURN .T.
		ENDIF
		RETURN .F.
	ENDFUNC

	FUNCTION CloseReport
	
	
		USE IN (THIS.ReportName)
		
		COMPILE REPORT (THIS.ReportName)
		RETURN .T.
	ENDFUNC

	FUNCTION GetObjectHeightInPixels
	PARAMETER m.height
		object_font_h=;
		FONTMETRIC(1, THIS.objFontName, THIS.objFontSize, THIS.objFontStyle )
		
	RETURN REPORT_COEF*INT(m.height/object_font_h)*(object_font_h+2)
	ENDFUNC
	
	FUNCTION GetObjectWidthInPixels
	PARAMETER nNumCharacters
	LOCAL reportwidth
		report_font_w=FONTMETRIC(6, THIS.objFontName, THIS.objFontSize, THIS.objFontStyle )
		reportwidth = REPORT_COEF * (report_font_w* nNumCharacters)
	RETURN reportwidth
	ENDFUNC
	
	FUNCTION GetObjectWidthInChars
	PARAMETER o
	LOCAL nCharacters
		nCharacters = o.Width/FONTMETRIC(6, THIS.ObjFontName, THIS.ObjFontSize, THIS.ObjFontStyle)
	RETURN nCharacters
	ENDFUNC

	FUNCTION GetProperty
	PARAMETER lcProperty, nObjType, nObjCode
	LOCAL lnAlias, lnRecNo, lvProperty
	lnAlias=SELECT()
	lnRecNo=RECNO()
	SELECT (THIS.ReportName)
 		LOCATE FOR ObjType=nObjType AND ObjCode= nObjCode
 		lvProperty=&lcProperty
 		SELECT (lnAlias)
		IF BETW(lnRecNo,1,RECC())
			GO lnRecNo
		ENDIF
	RETURN lvProperty
	ENDFUNC
	
	PROCEDURE SetProperty
	PARAMETER lcProperty, nObjType, nObjCode, NewValue
	LOCAL lnAlias, lnRecNo
		lnAlias=SELECT()
		lnRecNo=RECNO()
		SELECT (THIS.ReportName)
		LOCATE FOR ObjType=nObjType AND ObjCode= nObjCode
		REPLACE &lcProperty WITH NewValue
		
		=do_update(THIS.ReportName)

		SELECT (lnAlias)
		IF BETW(lnRecNo,1,RECC())
			GO lnRecNo
		ENDIF
	ENDPROC
	
	FUNCTION AddField
	SELECT (THIS.ReportName)
	LOCATE FOR uniqueid=reportobject.uniqueid
	IF NOT FOUND()

		INSERT INTO (THIS.ReportName);
		(platform,uniqueid,timestamp,objtype,objcode);
		VALUES ("WINDOWS", reportobject.uniqueid, 0, reportobject.objtype, reportobject.objcode)
	ENDIF

	
	REPLACE expr WITH reportobject.expr,;
		vpos WITH reportobject.vpos,;
		hpos WITH reportobject.hpos,;
		height WITH reportobject.height,;
		width WITH reportobject.width,;
		fillchar WITH reportobject.fillchar,;
		penred WITH -1,;
		pengreen WITH -1,;
		penblue WITH -1,;
		fillred WITH -1,;
		fillgreen WITH -1,;
		fillblue WITH -1,;
		fontface WITH reportobject.fontface,;
		fontstyle WITH reportobject.fontstyle,;
		fontsize WITH reportobject.fontsize,;
		mode WITH 1,;
		top WITH .t.,;
		norepeat WITH .f.,;
		spacing WITH 0,;
		offset WITH reportobject.offset,;
		totaltype WITH 0,;
		resettotal WITH 0,;
		supalways WITH .t.,;
		supovflow WITH .f.,;
		suprpcol WITH 3,;
		supgroup WITH 0,;
		supvalchng WITH .f.,;
		stretch WITH reportobject.stretch
		
		=do_update(THIS.ReportName)		

		
	RETURN
	ENDFUNC

	FUNCTION AddLabel
	SELECT (THIS.ReportName)
	LOCATE FOR uniqueid=reportobject.uniqueid
	IF NOT FOUND()

		INSERT INTO (THIS.ReportName);
		(platform,uniqueid,timestamp,objtype,objcode);
		VALUES ("WINDOWS", reportobject.uniqueid, 0, reportobject.objtype, reportobject.objcode)
	ENDIF
	
	
	REPLACE expr WITH STRTRAN(reportobject.expr,"\<", "");
		vpos WITH reportobject.vpos,;
		hpos WITH reportobject.hpos,;
		height WITH reportobject.height,;
		width WITH reportobject.width,;
		penred WITH -1,;
		pengreen WITH -1,;
		penblue WITH -1,;
		fillred WITH -1,;
		fillgreen WITH -1,;
		fillblue WITH -1,;
		fontface WITH reportobject.fontface,;
		fontstyle WITH reportobject.fontstyle,;
		fontsize WITH reportobject.fontsize,;
		mode WITH 0,;
		top WITH .t.,;
		norepeat WITH .f.,;
		spacing WITH 0,;
		supalways WITH .t.,;
		supovflow WITH .f.,;
		suprpcol WITH 3,;
		supgroup WITH 0,;
		supvalchng WITH .f.
		
		=do_update(THIS.ReportName)

	RETURN
	ENDFUNC


	PROTECTED PROCEDURE CreateReportObject
		
		lcReportName=THIS.ReportName
		
		SELECT 0
		CREATE CURSOR reportobject(;
				uniqueid C(10),;
				owner N(3),;
				bofowner N(9,3),;
				objtype N(2),;
				objcode N(3),;
				expr M,;
				vpos N(9,3),;
				hpos N(9,3),;
				height N(9,3),;
				width N(9,3),;
				fillchar C(1),;
				fontface M,;
				fontstyle N(3),;
				fontsize N(3),;
				stretch L(1),;
				offset N(3),;
				top L(1),;
				bottom L(1), Picture M)
			
		SELECT (lcReportName)
			
		SCAN FOR INLIST(objcode,;
				FIELD_OBJCODE, LABEL_OBJCODE, LINE_OBJCODE, BOX_OBJCODE) AND;
				INLIST(objtype, FIELD_OBJTYPE, LABEL_OBJTYPE, LINE_OBJTYPE, BOX_OBJTYPE)
				
				do case
				case betw(vpos,this.boftitle,this.boftitle+this.hoftitle)
					m.belongto=TITLE_OBJCODE
					m.bofowner=this.boftitle
				case betw(vpos,this.bofheader,this.bofheader+this.hofheader)
					m.belongto=HEADER_OBJCODE
					m.bofowner=this.bofheader
				case betw(vpos,this.bofgroup,this.bofgroup+this.hofgroup)
					m.belongto=GROUP_OBJCODE
					m.bofowner=this.bofgroup
				case betw(vpos,this.bofdetail,this.bofdetail+this.hofdetail)
					m.belongto=DETAIL_OBJCODE
					m.bofowner=this.bofdetail
				case betw(vpos,this.bofgroupfooter,this.bofgroupfooter+this.hofgroupfooter)
					m.belongto=GROUPFOOTER_OBJCODE
					m.bofowner=this.bofgroupfooter
				case betw(vpos,this.boffooter,this.boffooter+this.hoffooter)
					m.belongto=FOOTER_OBJCODE
					m.bofowner=this.boffooter
				case betw(vpos,this.bofsummary,this.bofsummary+this.hofsummary)
					m.belongto=SUMMARY_OBJCODE
					m.bofowner=this.bofsummary
				endcase
								
				INSERT INTO reportobject;
				VALUES(;
				&lcReportName..uniqueid,;
				m.belongto,;
				m.bofowner,;
				&lcReportName..objtype,;
				&lcReportName..objcode,;
				&lcReportName..expr,;
				&lcReportName..vpos-m.bofowner,;
				&lcReportName..hpos,;
				&lcReportName..height,;
				&lcReportName..width,;
				&lcReportName..fillchar,;
				&lcReportName..fontface,;
				&lcReportName..fontstyle,;
				&lcReportName..fontsize,;
				&lcReportName..stretch,;
				&lcReportName..offset,;
				&lcReportName..top,;
				&lcReportName..bottom,;
				&lcReportName..Picture)
		ENDSCAN

	ENDFUNC


	
	FUNCTION AddLine
	SELECT (THIS.ReportName)
	LOCATE FOR uniqueid=reportobject.uniqueid
	IF NOT FOUND()

		INSERT INTO (THIS.ReportName);
		(platform,uniqueid,timestamp,objtype,objcode);
		VALUES ("WINDOWS", reportobject.uniqueid, 0, ;
		reportobject.objtype, reportobject.objcode)
	ENDIF

	
	REPLACE vpos WITH reportobject.vpos,;
		hpos WITH reportobject.hpos,;
		height WITH reportobject.height,;
		width WITH reportobject.width,;
		penred WITH -1,;
		pengreen WITH -1,;
		penblue WITH -1,;
		fillred WITH -1,;
		fillgreen WITH -1,;
		fillblue WITH -1,;
		pensize WITH 1,;
		penpat WITH 8,;
		mode WITH 0,;
		top WITH reportobject.top,;
		bottom WITH reportobject.bottom,;
		norepeat WITH .f.,;
		offset WITH 1,;
		supalways WITH .t.,;
		supovflow WITH .f.,;
		suprpcol WITH 3,;
		supgroup WITH 0,;
		supvalchng WITH .f.,;
		stretch WITH reportobject.stretch

		=do_update(THIS.ReportName)

	RETURN
	ENDFUNC

	FUNCTION AddBox
	
	SELECT (THIS.ReportName)
	LOCATE FOR uniqueid=reportobject.uniqueid
	IF NOT FOUND()
		INSERT INTO (THIS.ReportName);
		(platform,uniqueid,timestamp,objtype,objcode);
		VALUES ("WINDOWS", reportobject.uniqueid, 0, reportobject.objtype, reportobject.objcode)
	ENDIF
		
	REPLACE vpos WITH reportobject.vpos,;
		hpos WITH reportobject.hpos,;
		height WITH reportobject.height,;
		width WITH reportobject.width,;
		penred WITH -1,;
		pengreen WITH -1,;
		penblue WITH -1,;
		fillred WITH -1,;
		fillgreen WITH -1,;
		fillblue WITH -1,;
		pensize WITH 1,;
		penpat WITH 8,;
		mode WITH 0,;
		top WITH .t.,;
		norepeat WITH .f.,;
		offset WITH 1,;
		supalways WITH .t.,;
		supovflow WITH .f.,;
		suprpcol WITH 3,;
		supgroup WITH 0,;
		supvalchng WITH .f.

		=do_update(THIS.ReportName)

	RETURN
	ENDFUNC

	FUNCTION AddPict
	SELECT (THIS.ReportName)
	LOCATE FOR uniqueid=reportobject.uniqueid
	IF NOT FOUND()

		INSERT INTO (THIS.ReportName);
		(platform,uniqueid,timestamp,objtype,objcode);
		VALUES ("WINDOWS", reportobject.uniqueid, 0, ;
		reportobject.objtype, reportobject.objcode)
	ENDIF

	
	REPLACE vpos WITH reportobject.vpos,;
		hpos WITH reportobject.hpos,;
		height WITH reportobject.height,;
		width WITH reportobject.width,;
		top WITH reportobject.top,;
		bottom WITH reportobject.bottom,;
		norepeat WITH .f.,;
		offset WITH 0,;
		supalways WITH .t.,;
		supovflow WITH .f.,;
		suprpcol WITH 3,;
		supgroup WITH 0,;
		supvalchng WITH .f.,;
		mode With 1,;
		top With .t.,;
		Picture With '"'+reportobject.Picture+'"'
		

		=do_update(THIS.ReportName)

	RETURN
	ENDFUNC
	
	PROTECTED FUNCTION ParseObject
	PARAMETER o
	LOCAL m.width, m.height, m.vpos, m.wpos
	LOCAL lcObjName, lcObjType, lnObjLen
	LOCAL cnt_control, oControl
	
	lnTop=IIF(TYPE('lnTop')='U',0,lnTop)
	lnLeft=IIF(TYPE('lnLeft')='U',0,lnLeft)
	
		Do Case
		Case o.BaseClass="Optiongroup"
			lnControlCount=o.ButtonCount
		Case o.BaseClass="Pageframe"
			lnControlCount=o.PageCount
		Other
			lnControlCount=o.ControlCount
		Endcase	
	
		FOR cnt_control=1 TO lnControlCount
			Do Case
			Case o.BaseClass="Optiongroup"
				oControl=o.Buttons(cnt_control)
			Case o.BaseClass="Pageframe"
				lnControlCount=o.Pages(cnt_control)
			Other
				oControl=o.Controls(cnt_control)
			Endcase	

			
			IF oControl.BaseClass="Container" Or;
				oControl.BaseClass="Optiongroup" Or;
				oControl.BaseClass="Pageframe" Or;
				oControl.BaseClass=="Page"
				
				lnLeft=lnLeft+oControl.Left
				lnTop=lnTop+oControl.Top
				
				THIS.ParseObject(oControl)
				
				lnLeft=lnLeft-oControl.Left
				lnTop=lnTop-oControl.Top

			ELSE
				DO CASE
					CASE oControl.BaseClass="Textbox"
					CASE oControl.BaseClass="Editbox"
					CASE oControl.BaseClass="Combobox"
					CASE oControl.BaseClass="Label"
					CASE oControl.BaseClass="Line"
					CASE oControl.BaseClass="Grid"
					CASE oControl.BaseClass="Checkbox"
					CASE oControl.BaseClass="Optionbutton"
					CASE oControl.BaseClass="Shape"
					OTHERW
						LOOP
				ENDCASE
	
			
				lcObjName= UPPER( oControl.Name )
				
			
				DO CASE
					CASE NOT oControl.Visible
						LOOP
										
					
						
					CASE oControl.BaseClass="Line"
						THIS.setobjectfont( oControl )
						m.width=IIF(oControl.Width=0,REPORT_COEF,oControl.Width*REPORT_COEF)
						m.height=IIF(oControl.Height=0,REPORT_COEF,oControl.Height*REPORT_COEF)
						m.vpos=REPORT_COEF*(lnTop+oControl.Top)
						m.wpos=REPORT_COEF*(lnLeft+oControl.Left)
					CASE oControl.BaseClass="Grid"
						m.wpos=0
						m.width=0
						THIS.CursorName=;
						IIF( INLIST(oControl.RecordSourceType,0,1),;
							oControl.RecordSource, "")
						FOR cntfg = 1 TO oControl.ColumnCount
							IF oControl.Columns(cntfg).Visible
								THIS.setobjectfont( oControl.Columns(cntfg) )
								WITH oControl.Columns(cntfg)
									lcLabel=.Header1.Caption
									lgField=.ControlSource
									lcObjType=TYPE('&lgField')
									m.height=THIS.GetObjectHeightInPixels( .parent.RowHeight )
									m.wpos=m.wpos+m.width+(REPORT_COEF* (lnLeft+.parent.Left))+REPORT_COEF
									m.wlabel=REPORT_COEF * .Width
									lnLabelLen=(.Width/FONTMETRIC(6, THIS.objFontName, THIS.objFontSize, THIS.objFontStyle ))
									m.wobj=REPORT_COEF * .Width
									m.width=MAX(m.wobj, m.wlabel)
								ENDWITH
								loObj=CREATEOBJECT("LableObject", REPORT_COEF*(lnTop+oControl.Top), m.wpos,  m.height, m.wlabel )
								loObj.expr=["]+LEFT(lcLabel,lnLabelLen)+["]
								loObj.Add( HEADER_OBJCODE )
								Release loObj
								loObj=CREATEOBJECT("LineObject", REPORT_COEF*(lnTop+oControl.Top), m.wpos,  m.height+REPORT_COEF, REPORT_COEF )
								loObj.Add( HEADER_OBJCODE )
								Release loObj
								IF cntfg=1
									
									loObj=CREATEOBJECT("BoxObject", REPORT_COEF*(lnTop+oControl.Top), m.wpos,  m.height+REPORT_COEF , REPORT_COEF * (3*oControl.Left+oControl.Width) )
									loObj.Add( HEADER_OBJCODE )
									Release loObj

									loObj=CREATEOBJECT("LineObject", -REPORT_COEF, m.wpos,  REPORT_COEF, REPORT_COEF * (3*oControl.Left+oControl.Width) )
									loObj.Add( DETAIL_OBJCODE )
									Release loObj
										
									loObj=CREATEOBJECT("LineObject", m.height+REPORT_COEF, m.wpos,  REPORT_COEF, REPORT_COEF * (3*oControl.Left+oControl.Width) )
									loObj.Add( DETAIL_OBJCODE )
									Release loObj
									
								ENDIF
						
								loObj=CREATEOBJECT("FieldObject",0, m.wpos,  m.height, m.wobj)
								loObj.expr=lgField
								loObj.offset=THIS.GetAlignment( oControl.Columns(cntfg).Text1 )
								loObj.fillchar=lcObjType
								loObj.stretch=IIF(lcObjType="M", .T., .F.)
								loObj.Add( DETAIL_OBJCODE )
								Release loObj
							

								loObj=CREATEOBJECT("LineObject", 0, m.wpos,  m.height+REPORT_COEF, REPORT_COEF )
								loObj.stretch=.T.
								loObj.Add( DETAIL_OBJCODE )
								Release loObj
								
									
							ENDIF
						ENDFOR

						
					OTHERW
						THIS.setobjectfont(oControl)
						
											
						lcObjType=TYPE('oControl.Value')
						lnObjLen=THIS.GetObjectWidthInChars(oControl)
						m.width=THIS.GetObjectWidthInPixels( lnObjLen )
						m.height=THIS.GetObjectHeightInPixels( oControl.Height)
						
						m.vpos=REPORT_COEF*(lnTop+oControl.Top)
						m.wpos=REPORT_COEF*(lnLeft+oControl.Left)
				ENDCASE
		
				DO CASE
					CASE;
						oControl.BaseClass="Textbox" OR;
						oControl.BaseClass="Editbox" OR;
						oControl.BaseClass="Combobox"
						
						
						IF TYPE('&lcObjName')="U"
							public &lcObjName
							
						ENDIF
						
						IF  TYPE('&lcObjName')=TYPE('oControl.Value') OR;
							TYPE('&lcObjName')="L"
							&lcObjName=IIF(oControl.BaseClass="Combobox",oControl.DisplayValue,oControl.Value)
						ENDIF
						
						
						loObj=CREATEOBJECT("FieldObject",m.vpos,m.wpos,m.height,m.width)
						loObj.expr=lcObjName
						loObj.offset=THIS.GetAlignment( oControl )
						loObj.fillchar=lcObjType
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
					CASE oControl.BaseClass="Label"
						
						loObj=CREATEOBJECT("LabelObject",m.vpos, m.wpos,  m.height, m.width)
						loObj.expr=["]+oControl.Caption+["]
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
					CASE oControl.BaseClass="Line"

						loObj=CREATEOBJECT("LineObject",m.vpos, m.wpos,  m.height, m.width)
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
					CASE oControl.BaseClass="Shape"
						
						loObj=CREATEOBJECT("LineObject",m.vpos, m.wpos,  REPORT_COEF, m.width)
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj

						loObj=CREATEOBJECT("LineObject",m.vpos, m.wpos,  m.height, REPORT_COEF)
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj

						loObj=CREATEOBJECT("LineObject",m.vpos+m.height, m.wpos,  REPORT_COEF, m.width)
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj

						loObj=CREATEOBJECT("LineObject",m.vpos, m.wpos+m.width,  m.height, REPORT_COEF)
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						

						
					CASE oControl.BaseClass="Checkbox"
					
						loObj=CREATEOBJECT("PictObject",m.vpos, m.wpos,  1562.5, 1562.5)

						loObj.Picture=IIF(Not EMPTY(oControl.Value),PICT_CHECKBOXON,PICT_CHECKBOXOFF)

						
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
						loObj=CREATEOBJECT("LabelObject",m.vpos, m.wpos+1562.5,  m.height, m.width)
						loObj.expr=["]+oControl.Caption+["]
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
					CASE oControl.BaseClass="Optionbutton"
					
						loObj=CREATEOBJECT("PictObject",m.vpos, m.wpos, 1562.5, 1562.5)

						loObj.Picture=IIF(Not EMPTY(oControl.Value),PICT_RADIOBON,PICT_RADIOBOFF)
						
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
						loObj=CREATEOBJECT("LabelObject",m.vpos, m.wpos+1562.5,  m.height, m.width)
						loObj.expr=["]+oControl.Caption+["]
						loObj.Add( THIS.getobjtype(oControl) )
						Release loObj
						
				ENDCASE
			ENDIF
			
		ENDFOR
	RETURN .T.
	ENDFUNC
	
	PROTECTED PROCEDURE setobjectfont
	PARAMETER o
	IF TYPE('o.FontName')<>"U"
		THIS.objFontName=o.FontName
		THIS.objFontStyle=IIF(o.FontBold,"B","N")
		THIS.objFontSize=o.FontSize
	ELSE
		THIS.objFontName=""
		THIS.objFontStyle=""
		THIS.objFontSize=0
	ENDIF
	ENDPROC

	FUNCTION Do
		PARAMETER o, tcReportName
		
		If TYPE("tcReportName")="C"
			THIS.ReportName=tcReportName
		Else
			THIS.ReportName=o.Name
		Endif
		
		IF THIS.MakeCopyDefaultReport( )
		
			THIS.CreateReportObject( )
			THIS.getoffsets( )
			THIS.ParseObject( o )
			THIS.MakeReport( )
			THIS.CloseReport( )
			
			
			DO CASE
				CASE NOT EMPTY(THIS.CursorName)
					SELECT (THIS.CursorName)
				CASE NOT EMPTY(THIS.CurCursorName)
					SELECT (THIS.CurCursorName)
			ENDCASE
			
			RETURN .T.
		ENDIF
	RETURN .F.
	ENDFUNC
	
	PROTECTED FUNCTION MakeCopyDefaultReport
		LOCAL lcSafe
		lcSafe=SET("SAFE")
		
		
		IF THIS.OpenDefaultReport( )
			SELECT default_report
			SET SAFE OFF
			COPY TO (THIS.ReportName + ".frx")
			SET SAFE &lcSafe
			=Use_Db( THIS.ReportName + ".frx IN 0" )
		
			USE IN default_report
			IF USED(THIS.ReportName)
				RETURN .T.
			ENDIF
		ENDIF
		RETURN .F.
	ENDFUNC
	
	PROTECTED PROCEDURE MakeReport
	
		SELECT owner, MAX(vpos+height) AS height FROM reportobject;
		INTO CURSOR reportviewport;
		GROUP BY owner;
		ORDER BY owner
	
		SCAN

			THIS.setproperty( 'Height', HDF_OBJTYPE, owner, ;
				IIF(reportviewport.height<REPORT_OFFSET,;
				REPORT_OFFSET,reportviewport.height))
		ENDSCAN
		
		THIS.getoffsets( )
				
		SCAN
			THIS.GetReportPort(owner)
			SELECT reportobject
			
				REPLACE vpos WITH THIS.BofPlace+vpos;
				FOR owner=reportviewport.owner
				
			SELECT reportviewport
		ENDSCAN
		
		USE IN reportviewport
		
		SELECT DISTI owner as objcode FROM reportobject;
		INTO CURS _objcode ORDER BY objcode
		
		SCAN
		
			m.objcode=objcode
			
			SELECT a.uniqueid, a.objcode, MIN(reportobject.vpos) AS vpos FROM (THIS.ReportName) a, reportobject ;
			WHERE a.objcode=m.objcode AND;
			INLIST(a.objcode,TITLE_OBJCODE,HEADER_OBJCODE,GROUP_OBJCODE,;
				DETAIL_OBJCODE,GROUPFOOTER_OBJCODE,FOOTER_OBJCODE,SUMMARY_OBJCODE) AND ;
			INLIST(a.objtype,HDF_OBJTYPE) AND a.objcode=reportobject.owner;
			INTO CURSOR minvpos

		

			=THIS.GetReportPort(minvpos.objcode)
			deltavpos=(minvpos.vpos-THIS.BofPlace)-REPORT_OFFSET
			IF deltavpos>0
				SELECT reportobject
				REPLACE ALL vpos WITH vpos-deltavpos;
				FOR vpos>=minvpos.vpos

				
				THIS.setproperty( 'Height', HDF_OBJTYPE, minvpos.objcode, ;
					IIF(THIS.HofPlace<REPORT_OFFSET,;
					REPORT_OFFSET,THIS.HofPlace-deltavpos))
			ENDIF
		USE IN minvpos
		SELECT _objcode
		ENDSCAN
		USE IN _objcode

		
		SELECT reportobject
		SCAN
			DO CASE
				CASE objtype=FIELD_OBJTYPE
					THIS.AddField(  )
				CASE objtype=LABEL_OBJTYPE
					THIS.AddLabel(  )
				CASE objtype=LINE_OBJTYPE
					THIS.AddLine(  )
				CASE objtype=BOX_OBJTYPE
					THIS.AddBox(  )
				CASE objtype=PICT_OBJTYPE
					THIS.AddPict(  )
			ENDCASE
			SELECT reportobject
		ENDSCAN
		
		USE IN reportobject
		
	ENDPROC
	
	PROTECTED PROCEDURE getoffsets
	
		THIS.HofTitle=THIS.GetProperty( 'Height', HDF_OBJTYPE, TITLE_OBJCODE)
		THIS.HofHeader=THIS.GetProperty( 'Height', HDF_OBJTYPE, HEADER_OBJCODE)
		THIS.HofGroup=THIS.GetProperty( 'Height', HDF_OBJTYPE, GROUP_OBJCODE)
		THIS.HofDetail=THIS.GetProperty( 'Height', HDF_OBJTYPE, DETAIL_OBJCODE)
		THIS.HofGroupFooter=THIS.GetProperty( 'Height', HDF_OBJTYPE, GROUPFOOTER_OBJCODE)
		THIS.HofFooter=THIS.GetProperty( 'Height', HDF_OBJTYPE, FOOTER_OBJCODE)
		THIS.HofSummary=THIS.GetProperty( 'Height', HDF_OBJTYPE, SUMMARY_OBJCODE)
		
		THIS.BofTitle=0
		THIS.BofHeader=THIS.BofTitle+THIS.HofTitle+REPORT_OFFSET
		THIS.BofGroup=THIS.BofHeader+THIS.HofHeader+REPORT_OFFSET
		THIS.BofDetail=THIS.BofGroup+THIS.HofGroup+REPORT_OFFSET
		THIS.BofGroupFooter=THIS.BofDetail+THIS.HofDetail+REPORT_OFFSET
		THIS.BofFooter=THIS.BofGroupFooter+THIS.HofGroupFooter+REPORT_OFFSET
		THIS.BofSummary=THIS.BofFooter+THIS.HofFooter+REPORT_OFFSET
	ENDPROC
	
	PROCEDURE GetReportPort
	PARAMETER otype
		DO CASE
			CASE TYPE('otype')="L"
			CASE otype=TITLE_OBJCODE
				THIS.HofPlace=THIS.HofTitle
				THIS.BofPlace=THIS.BofTitle
			CASE otype=HEADER_OBJCODE
				THIS.HofPlace=THIS.HofHeader
				THIS.BofPlace=THIS.BofHeader
			CASE otype=GROUP_OBJCODE
				THIS.HofPlace=THIS.HofGroup
				THIS.BofPlace=THIS.BofGroup
			CASE otype=DETAIL_OBJCODE
				THIS.HofPlace=THIS.HofDetail
				THIS.BofPlace=THIS.BofDetail
			CASE otype=GROUPFOOTER_OBJCODE
				THIS.HofPlace=THIS.HofGroupFooter
				THIS.BofPlace=THIS.BofGroupFooter
			CASE otype=FOOTER_OBJCODE
				THIS.HofPlace=THIS.HofFooter
				THIS.BofPlace=THIS.BofFooter
			CASE otype=SUMMARY_OBJCODE
				THIS.HofPlace=THIS.HofSummary
				THIS.BofPlace=THIS.BofSummary

		ENDCASE
	ENDPROC
		
	FUNCTION getownergroup
	PARAMETER obj
	LOCAL o
	o=obj
	DO WHILE TYPE('o')='O'
		IF UPPER(o.Class)=SFM_GROUPPREFIXCLASS OR TYPE('o.parent')<>'O'
			EXIT
		ENDIF
		o=o.parent
	ENDDO
	RETURN IIF(TYPE('o.parent')<>'O', obj.parent,o)	
	ENDFUNC
	
	FUNCTION getobjtype
	PARAMETER o
	LOCAL otype
	otype=IIF(o.parent.BaseClass="Form", ;
		IIF(INLIST(TYPE('o.objtype'),'L','U'), DEFAULT_OUTPUT, o.objtype), ;
		IIF(INLIST(TYPE('o.parent.objtype'),'L','U'), DEFAULT_OUTPUT, o.parent.objtype))
		DO CASE
			CASE otype=PAGE_TITLE
				RETURN TITLE_OBJCODE
			CASE otype=PAGE_HEADER
				RETURN HEADER_OBJCODE
			CASE otype=PAGE_GROUP
				RETURN GROUP_OBJCODE
			CASE otype=PAGE_DETAIL
				RETURN DETAIL_OBJCODE
			CASE otype=PAGE_GROUPFOOTER
				RETURN GROUPFOOTER_OBJCODE
			CASE otype=PAGE_FOOTER
				RETURN FOOTER_OBJCODE
			CASE otype=PAGE_SUMMARY
				RETURN SUMMARY_OBJCODE
				
		ENDCASE

	RETURN otype
	ENDFUNC
	
	PROTECTED FUNCTION GetAlignment
	PARAMETER  o
	LOCAL lnAlignment
	lnAlignment=0
	DO CASE
		CASE o.BaseClass="Textbox" OR;
			o.BaseClass="Combobox"
			IF o.Alignment=3
				lnAlignment=0
			ELSE
				lnAlignment=o.Alignment
			ENDIF
	ENDCASE
	RETURN lnAlignment
	ENDFUNC
	
ENDDEFINE

DEFINE CLASS ReportObject AS Custom

	uniqueid=""
	owner=0
	bofowner=0
	objtype=0
	objcode=0
	expr=""
	vpos=0
	hpos=0
	_height=0
	_width=0
	fillchar=""
	_fontface=""
	_fontstyle=0
	_fontsize=0
	stretch=.F.
	offset=0
	_top=.T.
	_bottom=.F.
	Picture=""
	
	PROCEDURE Init
		PARAMETER tnVpos, tnHpos, tnHeight, tnWidth
		
		THIS.uniqueid=SYS(2015)
		
		THIS.vpos=tnVpos
		THIS.hpos=tnHpos
		THIS._height=tnHeight
		THIS._width=tnWidth
		
		THIS._fontface=oReport.objfontname
		THIS._fontstyle=IIF(oReport.objfontstyle="N",0,1)
		THIS._fontsize=oReport.objfontsize
		
	ENDPROC
	PROCEDURE Add
		PARAMETER tnObjPlace

		oReport.GetReportPort( tnObjPlace )

		INSERT INTO reportobject;
		VALUES(;
		THIS.uniqueid,;
		tnObjPlace,;
		oReport.BofPlace,;
		THIS.objtype,;
		THIS.objcode,;
		THIS.expr,;
		THIS.vpos,;
		THIS.hpos,;
		THIS._height,;
		THIS._width,;
		THIS.fillchar,;
		THIS._fontface,;
		THIS._fontstyle,;
		THIS._fontsize,;
		THIS.stretch,;
		THIS.offset,;
		THIS._top,;
		THIS._bottom,THIS.Picture)
		
	ENDPROC
ENDDEFINE

DEFINE CLASS FieldObject AS ReportObject
		objtype=FIELD_OBJTYPE
		objcode=FIELD_OBJCODE
ENDDEFINE
DEFINE CLASS LabelObject AS ReportObject
		objtype=LABEL_OBJTYPE
		objcode=LABEL_OBJCODE
ENDDEFINE
DEFINE CLASS LineObject AS ReportObject
		objtype=LINE_OBJTYPE
		objcode=LINE_OBJCODE
ENDDEFINE
DEFINE CLASS BoxObject AS ReportObject
		objtype=BOX_OBJTYPE
		objcode=BOX_OBJCODE
ENDDEFINE
DEFINE CLASS PictObject AS ReportObject
		objtype=PICT_OBJTYPE
		objcode=PICT_OBJCODE
		
ENDDEFINE
