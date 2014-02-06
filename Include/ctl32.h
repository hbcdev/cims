********************************************************************************
*!* ctl32.h include file for ctl32 classes
*!*
*!* This file has 3 parts:
*!* 1: custom defines
*!* 2: Windows API defines
*!* 3: A subset of defines from foxpro.h
********************************************************************************

*!* Minimum system required 			Macros to define
*!* Windows Vista 						NTDDI_VERSION >=NTDDI_LONGHORN
*!* Windows Server 2003 SP1 			NTDDI_VERSION >=NTDDI_WS03SP1
*!* Windows Server 2003 				NTDDI_VERSION >=NTDDI_WS03
*!* Windows XP SP2 						NTDDI_VERSION >=NTDDI_WINXPSP2
*!* Windows XP SP1 						NTDDI_VERSION >=NTDDI_WINXPSP1
*!* Windows XP 							NTDDI_VERSION >=NTDDI_WINXP
*!* Windows 2000 SP4 					NTDDI_VERSION >=NTDDI_WIN2KSP4
*!* Windows 2000 SP3 					NTDDI_VERSION >=NTDDI_WIN2KSP3
*!* Windows 2000 SP2 					NTDDI_VERSION >=NTDDI_WIN2KSP2
*!* Windows 2000 SP1 					NTDDI_VERSION >=NTDDI_WIN2KSP1
*!* Windows 2000 						NTDDI_VERSION >=NTDDI_WIN2K

*!* The following table describes the legacy macros in use by the Windows header files.
*!* Minimum system required 			Macros to define
*!* Windows Vista 						_WIN32_WINNT>=0x0600	WINVER>=0x0600
*!* Windows Server 2003 				_WIN32_WINNT>=0x0502	WINVER>=0x0502
*!* Windows XP 							_WIN32_WINNT>=0x0501	WINVER>=0x0501
*!* Windows 2000 						_WIN32_WINNT>=0x0500	WINVER>=0x0500
*!* Windows NT 4.0 						_WIN32_WINNT>=0x0400	WINVER>=0x0400
*!* Windows Me 							_WIN32_WINDOWS=0x0500	WINVER>=0x0500
*!* Windows 98 							_WIN32_WINDOWS>=0x0410	WINVER>=0x0410
*!* Windows 95 							_WIN32_WINDOWS>=0x0400	WINVER>=0x0400

*!* Internet Explorer 7.0 				_WIN32_IE>=0x0700
*!* Internet Explorer 6.0 SP2 			_WIN32_IE>=0x0603
*!* Internet Explorer 6.0 SP1 			_WIN32_IE>=0x0601
*!* Internet Explorer 6.0 				_WIN32_IE>=0x0600
*!* Internet Explorer 5.5 				_WIN32_IE>=0x0550
*!* Internet Explorer 5.01 				_WIN32_IE>=0x0501
*!* Internet Explorer 5.0, 5.0a, 5.0b 	_WIN32_IE>=0x0500
*!* Internet Explorer 4.01 				_WIN32_IE>=0x0401
*!* Internet Explorer 4.0 				_WIN32_IE>=0x0400
*!* Internet Explorer 3.0, 3.01, 3.02 	_WIN32_IE>=0x0300

********************************************************************************
*!* CTL CUSTOM
********************************************************************************
*!* 20061004 Replaced the CTL prefix with CON (Constant) to avoid conflict with
*!* Win API constants that start also with CON_

#Define TRUE									.T.		&& 1
#Define FALSE									.F.		&& 0

#Define CR										chr(0x0d)
#Define LF										chr(0x0a)
#Define CRLF									chr(0x0d) + chr(0x0a)

*!* Missing MousePointer constants in foxpro.h
#Define MOUSE_HAND								15      && 15 - Hand
#Define MOUSE_DN_ARROW							16      && 16 - Down Arrow
#Define MOUSE_MGLASS							17      && 17 - Magnifying Glass

* This are used to clear certain style bits
#Define CON_BIT_WS_BORDER						23
#Define CON_BIT_WS_EX_LAYOUTRTL					22
#Define CON_BIT_WS_EX_STATICEDGE				17
#Define CON_BIT_TTS_BALLOON						6
#Define CON_BIT_TTS_CLOSE						7

*!* BorderStyle
#Define CON_BS_NONE								0
#Define CON_BS_FIXEDSINGLE						1
#Define CON_BS_FIXEDDIALOG						2
#Define CON_BS_SIZABLE							3

#Define CON_BTPOS_NONE 							1
#Define CON_BTPOS_ACTIVECTRL 					2
#Define CON_BTPOS_CARET							3
#Define CON_BTPOS_SYS1270						4
#Define CON_BTPOS_CTRLREF						5
#Define CON_BTPOS_MOUSE							6

#Define CON_EFFECT_RAISED						0
#Define CON_EFFECT_SUNKEN						1
#Define CON_EFFECT_FLAT							2

#Define CON_FORMTYPE_DEFAULT					0
#Define CON_FORMTYPE_TOPLEVEL					1
#Define CON_FORMTYPE_SCREEN						2

*!* ObjToClient parameters
#Define CON_OBJTOCLI_TOP						1
#Define CON_OBJTOCLI_LEFT						2
#Define CON_OBJTOCLI_WIDTH						3
#Define CON_OBJTOCLI_HEIGHT						4

*!* Pemstatus  Values
#Define CON_PEMSTAT_CHANGED						0
#Define CON_PEMSTAT_READONLY					1
#Define CON_PEMSTAT_PROTECTED					2
#Define CON_PEMSTAT_TYPE						3
#Define CON_PEMSTAT_USERDEFINED					4
#Define CON_PEMSTAT_DEFINED						5
#Define CON_PEMSTAT_INHERITED					6

#Define CON_SBBORDER_HORIZONTAL					1
#Define CON_SBBORDER_VERTICAL					2
#Define CON_SBBORDER_SEPARATOR					3

*!* ShowWindow
#Define CON_SHOWWIN_INSCREEN					0
#Define CON_SHOWWIN_INTOPLEVELFORM				1
#Define CON_SHOWWIN_ASTOPLEVELFORM				2

#Define CON_STYLE_BALLOON						1
#Define CON_STYLE_RECT							2
#Define CON_STYLE_NOBORDER						3

*!* TabOrientation parameters
#Define CON_TABOR_TOP							0
#Define CON_TABOR_BOTTOM						1
#Define CON_TABOR_LEFT							2
#Define CON_TABOR_RIGHT							3

*!* VFP VERSION() 
#Define CON_VER_DATESERIAL						1
#Define CON_VER_TYPE							2
#Define CON_VER_LANG							3
#Define CON_VER_CHAR							4
#Define CON_VER_NUM								5

#Define CON_VER_TYPE_RUNTIME					0
#Define CON_VER_TYPE_STANDARD					1
#Define CON_VER_TYPE_PRO						2

#Define CON_VER_LANG_ENGLISH					[00]
#Define CON_VER_LANG_RUSSSIAN					[07]
#Define CON_VER_LANG_FRENCH						[33]
#Define CON_VER_LANG_SPANISH					[34]
#Define CON_VER_LANG_CZECH						[39]
#Define CON_VER_LANG_GERMAN						[48]
#Define CON_VER_LANG_KOREAN						[55]
#Define CON_VER_LANG_SCHINESE					[86]
#Define CON_VER_LANG_TCHINESE					[88]


*!* WindowType constants
#Define CON_WINTYPE_MODELESS					0
#Define CON_WINTYPE_MODAL						1
#Define CON_WINTYPE_READ						2
#Define CON_WINTYPE_READMODAL					3

*!* These should be removed
#Define OS_WIN95								400
#Define OS_WIN98								410
#Define OS_WINME								500
#Define OS_WINNT4								400
#Define OS_WIN2K								500
#Define OS_WINXP								501
#Define OS_WIN2K3								502
#Define OS_WINVISTA								600

#Define CON_OS_WIN95							4000000
#Define CON_OS_WIN98							4100000
#define CON_OS_WIN2K							5000000
#define CON_OS_WIN2KSP1							5000100
#define CON_OS_WIN2KSP2							5000200
#define CON_OS_WIN2KSP3							5000300
#define CON_OS_WIN2KSP4							5000400
#define CON_OS_WINXP							5010000
#define CON_OS_WINXPSP1							5010100
#define CON_OS_WINXPSP2							5010200
#define CON_OS_WS03								5020000
#define CON_OS_WS03SP1							5020100
#define CON_OS_LONGHORN 						6000000
#define CON_OS_WINVISTA                    		6000000

********************************************************************************
*!* WINDOWS API
********************************************************************************

*!* Common Controls Names
#Define TOOLTIPS_CLASSA							[tooltips_class32]
#Define TOOLTIPS_CLASSW							[tooltips_class32]
#Define WC_STATICA								[Static]
#Define WC_STATICW								[Static]
#Define PROGRESS_CLASSA							[msctls_progress32]
#Define PROGRESS_CLASSW							[msctls_progress32]
#Define STATUSCLASSNAMEA						[msctls_statusbar32]
#Define STATUSCLASSNAMEW						[msctls_statusbar32]
#Define WC_SCROLLBARA							[ScrollBar]
#Define WC_SCROLLBARW							[ScrollBar]
#Define WC_TABCONTROLA							[SysTabControl32]
#Define WC_TABCONTROLW							[SysTabControl32]

#Define CLIP_STROKE_PRECIS						2
#Define DEFAULT_PITCH							0
#Define OUT_DEFAULT_PRECIS						0
#Define OUT_OUTLINE_PRECIS						8
#Define PROOF_QUALITY							2

#Define CCM_FIRST								0x2000
#Define CCM_GETCOLORSCHEME 						0x2003
#Define CCM_GETDROPTARGET						0x2004
#Define CCM_GETUNICODEFORMAT					0x2006
#Define CCM_GETVERSION							0x2008
#Define CCM_LAST								0x2200
#Define CCM_SETBKCOLOR							0x2001
#Define CCM_SETCOLORSCHEME						0x2002
#Define CCM_SETNOTIFYWINDOW						0x2009
#Define CCM_SETUNICODEFORMAT					0x2005
#Define CCM_SETVERSION							0x2007
#Define CCM_SETWINDOWTHEME						0x200B

#Define CCS_ADJUSTABLE							0x20
#Define CCS_BOTTOM								0x3
#Define CCS_LEFT        						0x81
#Define CCS_NODIVIDER							0x40
#Define CCS_NOMOVEX								0x82
#Define CCS_NOMOVEY								0x2
#Define CCS_NOPARENTALIGN						0x8
#Define CCS_NORESIZE							0x4
#Define CCS_RIGHT								0x83
#Define CCS_TOP									0x1
#Define CCS_VERT								0x80

* CHARSETS
#Define ANSI_CHARSET							0
#Define ARABIC_CHARSET							178
#Define BALTIC_CHARSET							186
#Define CHINESEBIG5_CHARSET						136
#Define DEFAULT_CHARSET							1
#Define EASTEUROPE_CHARSET						238
#Define GB2312_CHARSET							134
#Define GREEK_CHARSET							161
#Define HANGUL_CHARSET							129
#Define HEBREW_CHARSET							177
#Define JOHAB_CHARSET							130
#Define MAC_CHARSET								77
#Define OEM_CHARSET								255
#Define RUSSIAN_CHARSET							204
#Define SHIFTJIS_CHARSET						128
#Define SYMBOL_CHARSET							2
#Define THAI_CHARSET							222
#Define TURKISH_CHARSET							162
#Define VIETNAMESE_CHARSET						163

#Define CLR_DEFAULT								0xff000000
#Define CLR_HILIGHT								0xff000000
#Define CLR_INVALID								0xffff
#Define CLR_NONE								0xffffffff

#Define COLOR_3DDKSHADOW						21
#Define COLOR_3DFACE							15 	&& COLOR_BTNFACE
#Define COLOR_3DHIGHLIGHT						20 	&& COLOR_BTNHIGHLIGHT
#Define COLOR_3DHILIGHT							20 	&& COLOR_BTNHIGHLIGHT
#Define COLOR_3DLIGHT							22
#Define COLOR_3DSHADOW							16 	&& COLOR_BTNSHADOW
#Define COLOR_ACTIVEBORDER						10
#Define COLOR_ACTIVECAPTION						2
#Define COLOR_ADD								712
#Define COLOR_ADJ_MAX							100
#Define COLOR_ADJ_MIN							-100
#Define COLOR_APPWORKSPACE						12
#Define COLOR_BACKGROUND						1
#Define COLOR_BLUE								708
#Define COLOR_BLUEACCEL							728
#Define COLOR_BOX1								720
#Define COLOR_BTNFACE							15
#Define COLOR_BTNHIGHLIGHT						20
#Define COLOR_BTNHILIGHT						20 	&&COLOR_BTNHIGHLIGHT
#Define COLOR_BTNSHADOW							16
#Define COLOR_BTNTEXT							18
#Define COLOR_CAPTIONTEXT						9
#Define COLOR_CURRENT							709
#Define COLOR_CUSTOM1							721
#Define COLOR_DESKTOP							1 	&&COLOR_BACKGROUND
#Define COLOR_ELEMENT							716
#Define COLOR_GRADIENTACTIVECAPTION				27
#Define COLOR_GRADIENTINACTIVECAPTION   		28
#Define COLOR_GRAYTEXT							17
#Define COLOR_GREEN								707
#Define COLOR_GREENACCEL						727
#Define COLOR_HIGHLIGHT							13
#Define COLOR_HIGHLIGHTTEXT						14
#Define COLOR_HOTLIGHT							26
#Define COLOR_HUE								703
#Define COLOR_HUEACCEL							723
#Define COLOR_HUESCROLL							700
#Define COLOR_INACTIVEBORDER					11
#Define COLOR_INACTIVECAPTION					3
#Define COLOR_INACTIVECAPTIONTEXT				19
#Define COLOR_INFOBK							24
#Define COLOR_INFOTEXT							23
#Define COLOR_LUM								705
#Define COLOR_LUMACCEL							725
#Define COLOR_LUMSCROLL							702
#Define COLOR_MATCH_VERSION						0x200
#Define COLOR_MENU								4
#Define COLOR_MENUTEXT							7
#Define COLOR_MIX								719
#Define COLOR_NO_TRANSPARENT					0xffffffff
#Define COLOR_PALETTE							718
#Define COLOR_RAINBOW							710
#Define COLOR_RED								706
#Define COLOR_REDACCEL							726
#Define COLOR_SAMPLES							717
#Define COLOR_SAT 								704
#Define COLOR_SATACCEL							724
#Define COLOR_SATSCROLL							701
#Define COLOR_SAVE								711
#Define COLOR_SCHEMES							715
#Define COLOR_SCROLLBAR							0
#Define COLOR_SOLID								713
#Define COLOR_SOLID_LEFT						730
#Define COLOR_SOLID_RIGHT						731
#Define COLOR_TUNE								714
#Define COLOR_WINDOW							5
#Define COLOR_WINDOWFRAME						6
#Define COLOR_WINDOWTEXT						8

#Define CW_USEDEFAULT							0x80000000

#Define DATE_LONGDATE							0x2
#Define DATE_LTRREADING							0x10
#Define DATE_RTLREADING							0x20
#Define DATE_SHORTDATE       					0x1
#Define DATE_USE_ALT_CALENDAR     				0x4
#Define DATE_YEARMONTH       					0x8

#Define DEFAULT_GUI_FONT						17

#Define FW_BLACK								900
#Define FW_BOLD									700
#Define FW_DEMIBOLD								600
#Define FW_DONTCARE								0
#Define FW_EXTRABOLD							800
#Define FW_EXTRALIGHT							200
#Define FW_HEAVY								900
#Define FW_LIGHT								300
#Define FW_MEDIUM								500
#Define FW_NORMAL								400
#Define FW_REGULAR								400
#Define FW_SEMIBOLD								600
#Define FW_THIN									100
#Define FW_ULTRABOLD							800
#Define FW_ULTRALIGHT							200

*!* 0x4d36e967L, 0xe325, 0x11ce, 0xbf, 0xc1, 0x08, 0x00, 0x2b, 0xe1, 0x03, 0x18
#Define GUID_DEVCLASS_DISKDRIVE 				0h67E9364D25E3CE11BFC108002BE10318

#Define GW_CHILD        						5	
#Define GW_ENABLEDPOPUP       					6
#Define GW_HWNDFIRST       						0
#Define GW_HWNDLAST        						1
#Define GW_HWNDNEXT       						2
#Define GW_HWNDPREV        						3
#Define GW_MAX         							5
#Define GW_OWNER        						4
#Define GWL_EXSTYLE        						-20
#Define GWL_HINSTANCE       					-6
#Define GWL_HWNDPARENT       					-8
#Define GWL_ID         							-12
#Define GWL_STYLE        						-16
#Define GWL_USERDATA       						-21
#Define GWL_WNDPROC        						-4

#Define HEAP_CREATE_ALIGN_16     				0x10000
#Define HEAP_CREATE_ENABLE_TRACING    			0x20000
#Define HEAP_DISABLE_COALESCE_ON_FREE   		0x80
#Define HEAP_FREE_CHECKING_ENABLED    			0x40
#Define HEAP_GENERATE_EXCEPTIONS    			0x4
#Define HEAP_GROWABLE       					0x2
#Define HEAP_MAXIMUM_TAG     					0xfff
#Define HEAP_NO_SERIALIZE      					0x1
#Define HEAP_PSEUDO_TAG_FLAG     				0x8000
#Define HEAP_REALLOC_IN_PLACE_ONLY    			0x10
#Define HEAP_TAG_SHIFT       					18
#Define HEAP_TAIL_CHECKING_ENABLED    			0x20
#Define HEAP_ZERO_MEMORY      					0x8

#Define HWND_BOTTOM        						1
#Define HWND_BROADCAST      					0xffff
#Define HWND_DESKTOP       						0
#Define HWND_MESSAGE       						-3
#Define HWND_NOTOPMOST      					-2
#Define HWND_TOP        						0
#Define HWND_TOPMOST       						-1

#DEFINE HTBORDER								18
#DEFINE HTBOTTOM								15
#DEFINE HTBOTTOMLEFT							16
#DEFINE HTBOTTOMRIGHT							17
#DEFINE HTCAPTION								2
#DEFINE HTCLIENT								1
#DEFINE HTCLOSE									20
#DEFINE HTERROR									-2
#DEFINE HTGROWBOX								4
#DEFINE HTHELP									21
#DEFINE HTHSCROLL								6
#DEFINE HTLEFT									10
#DEFINE HTMAXBUTTON								9
#DEFINE HTMENU									5
#DEFINE HTMINBUTTON								8
#DEFINE HTNOWHERE								0
#DEFINE HTOBJECT								19
#DEFINE HTREDUCE								8
#Define HTTRANSPARENT							-1
#DEFINE HTRIGHT									11
#DEFINE HTSIZE									4
#DEFINE HTSIZEFIRST								10
#DEFINE HTSIZELAST								17
#DEFINE HTSYSMENU								3
#DEFINE HTTOP									12
#DEFINE HTTOPLEFT								13
#DEFINE HTTOPRIGHT								14


#Define ICC_ANIMATE_CLASS      					0x80
#Define ICC_BAR_CLASSES       					0x4
#Define ICC_COOL_CLASSES      					0x400
#Define ICC_DATE_CLASSES      					0x100
#Define ICC_HOTKEY_CLASS      					0x40
#Define ICC_INTERNET_CLASSES     				0x800
#Define ICC_LINK_CLASS       					0x8000
#Define ICC_LISTVIEW_CLASSES     				0x1
#Define ICC_NATIVEFNTCON_CLASS     				0x2000
#Define ICC_PAGESCROLLER_CLASS     				0x1000
#Define ICC_PROGRESS_CLASS      				0x20
#Define ICC_STANDARD_CLASSES     				0x4000
#Define ICC_TAB_CLASSES       					0x8
#Define ICC_TREEVIEW_CLASSES     				0x2
#Define ICC_UPDOWN_CLASS      					0x10
#Define ICC_USEREX_CLASSES      				0x200
#Define ICC_WIN95_CLASSES      					0xff

#Define ICON_BIG								1
#Define ICON_SMALL								0

#Define ILC_COLOR								0x0
#Define ILC_COLOR16								0x10
#Define ILC_COLOR24								0x18
#Define ILC_COLOR32								0x20
#Define ILC_COLOR4								0x4
#Define ILC_COLOR8								0x8
#Define ILC_COLORDDB							0xfe
#Define ILC_MASK								0x1
#Define ILC_MIRROR              				0x2000      	&& Mirror the icons contained, if the process is mirrored
#Define ILC_PERITEMMIRROR       				0x8000      	&& Causes the mirroring code to mirror each item when inserting a set of images, verses the whole strip
#Define ILC_ORIGINALSIZE        				0x10000      	&& VISTA Imagelist should accept smaller than set images and apply OriginalSize based on image added
#Define ILC_HIGHQUALITYSCALE    				0x20000      	&& VISTA Imagelist should enable use of the high quality scaler.

#Define LANG_AFRIKAANS                   		0x36
#Define LANG_ALBANIAN                    		0x1c
#Define LANG_ARABIC                      		0x01
#Define LANG_BASQUE                      		0x2d
#Define LANG_BELARUSIAN                  		0x23
#Define LANG_BULGARIAN                   		0x02
#Define LANG_CATALAN                     		0x03
#Define LANG_CHINESE                     		0x04
#Define LANG_CROATIAN                    		0x1a
#Define LANG_CZECH                       		0x05
#Define LANG_DANISH                      		0x06
#Define LANG_DUTCH                       		0x13
#Define LANG_ENGLISH                     		0x09
#Define LANG_ESTONIAN                    		0x25
#Define LANG_FAEROESE                    		0x38
#Define LANG_FARSI                       		0x29
#Define LANG_FINNISH                     		0x0b
#Define LANG_FRENCH                      		0x0c
#Define LANG_GALICIAN                    		0x56
#Define LANG_GERMAN                      		0x07
#Define LANG_GREEK                       		0x08
#Define LANG_HEBREW                      		0x0d
#Define LANG_HUNGARIAN                   		0x0e
#Define LANG_ICELANDIC                   		0x0f
#Define LANG_INDONESIAN                  		0x21
#Define LANG_ITALIAN                     		0x10
#Define LANG_JAPANESE                    		0x11
#Define LANG_KOREAN                      		0x12
#Define LANG_LATVIAN                     		0x26
#Define LANG_LITHUANIAN                  		0x27
#Define LANG_MALAY						 		0x3e
#Define LANG_NEUTRAL                     		0x00
#Define LANG_NORWEGIAN                   		0x14
#Define LANG_POLISH                      		0x15
#Define LANG_PORTUGUESE                  		0x16
#Define LANG_ROMANIAN                    		0x18
#Define LANG_RUSSIAN                     		0x19
#Define LANG_SERBIAN                     		0x1a
#Define LANG_SLOVAK                      		0x1b
#Define LANG_SLOVENIAN                   		0x24
#Define LANG_SPANISH                     		0x0a
#Define LANG_SWEDISH                     		0x1d
#Define LANG_THAI                        		0x1e
#Define LANG_TURKISH                     		0x1f
#Define LANG_UKRAINIAN                   		0x22
#Define LANG_VIETNAMESE                  		0x2a

#Define LOCALE_FONTSIGNATURE     				0x58
#Define LOCALE_ICALENDARTYPE     				0x1009
#Define LOCALE_ICENTURY       					0x24
#Define LOCALE_ICOUNTRY       					0x5
#Define LOCALE_ICURRDIGITS      				0x19
#Define LOCALE_ICURRENCY      					0x1b
#Define LOCALE_IDATE       						0x21
#Define LOCALE_IDAYLZERO      					0x26
#Define LOCALE_IDEFAULTANSICODEPAGE    			0x1004
#Define LOCALE_IDEFAULTCODEPAGE     			0xb
#Define LOCALE_IDEFAULTCOUNTRY     				0xa
#Define LOCALE_IDEFAULTEBCDICCODEPAGE   		0x1012
#Define LOCALE_IDEFAULTLANGUAGE     			0x9
#Define LOCALE_IDEFAULTMACCODEPAGE    			0x1011
#Define LOCALE_IDIGITS       					0x11
#Define LOCALE_IDIGITSUBSTITUTION    			0x1014
#Define LOCALE_IFIRSTDAYOFWEEK     				0x100c
#Define LOCALE_IFIRSTWEEKOFYEAR     			0x100d
#Define LOCALE_IINTLCURRDIGITS     				0x1a
#Define LOCALE_ILANGUAGE      					0x1
#Define LOCALE_ILDATE       					0x22
#Define LOCALE_ILZERO       					0x12
#Define LOCALE_IMEASURE       					0xD
#Define LOCALE_IMONLZERO      					0x27
#Define LOCALE_INEGCURR       					0x1C
#Define LOCALE_INEGNUMBER      					0x1010
#Define LOCALE_INEGSEPBYSPACE     				0x57
#Define LOCALE_INEGSIGNPOSN      				0x53
#Define LOCALE_INEGSYMPRECEDES     				0x56
#Define LOCALE_IOPTIONALCALENDAR    			0x100B
#Define LOCALE_IPAPERSIZE      					0x100A
#Define LOCALE_IPOSSEPBYSPACE     				0x55
#Define LOCALE_IPOSSIGNPOSN      				0x52
#Define LOCALE_IPOSSYMPRECEDES     				0x54
#Define LOCALE_ITIME       						0x23
#Define LOCALE_ITIMEMARKPOSN     				0x1005
#Define LOCALE_ITLZERO       					0x25
#Define LOCALE_NOUSEROVERRIDE     				0x80000000
#Define LOCALE_RETURN_NUMBER     				0x20000000
#Define LOCALE_S1159       						0x28
#Define LOCALE_S2359       						0x29
#Define LOCALE_SABBREVCTRYNAME     				0x7
#Define LOCALE_SABBREVDAYNAME1     				0x31
#Define LOCALE_SABBREVDAYNAME2     				0x32
#Define LOCALE_SABBREVDAYNAME3     				0x33
#Define LOCALE_SABBREVDAYNAME4     				0x34
#Define LOCALE_SABBREVDAYNAME5     				0x35
#Define LOCALE_SABBREVDAYNAME6     				0x36
#Define LOCALE_SABBREVDAYNAME7     				0x37
#Define LOCALE_SABBREVLANGNAME     				0x3
#Define LOCALE_SABBREVMONTHNAME1    			0x44
#Define LOCALE_SABBREVMONTHNAME10    			0x4D
#Define LOCALE_SABBREVMONTHNAME11    			0x4E
#Define LOCALE_SABBREVMONTHNAME12    			0x4F
#Define LOCALE_SABBREVMONTHNAME13    			0x100F
#Define LOCALE_SABBREVMONTHNAME2    			0x45
#Define LOCALE_SABBREVMONTHNAME3    			0x46
#Define LOCALE_SABBREVMONTHNAME4    			0x47
#Define LOCALE_SABBREVMONTHNAME5    			0x48
#Define LOCALE_SABBREVMONTHNAME6    			0x49
#Define LOCALE_SABBREVMONTHNAME7    			0x4A
#Define LOCALE_SABBREVMONTHNAME8    			0x4B
#Define LOCALE_SABBREVMONTHNAME9    			0x4C
#Define LOCALE_SCOUNTRY       					0x6
#Define LOCALE_SCURRENCY      					0x14
#Define LOCALE_SDATE       						0x1D
#Define LOCALE_SDAYNAME1      					0x2A
#Define LOCALE_SDAYNAME2      					0x2B
#Define LOCALE_SDAYNAME3      					0x2C
#Define LOCALE_SDAYNAME4      					0x2D
#Define LOCALE_SDAYNAME5      					0x2E
#Define LOCALE_SDAYNAME6      					0x2F
#Define LOCALE_SDAYNAME7      					0x30
#Define LOCALE_SDECIMAL       					0xE
#Define LOCALE_SENGCOUNTRY      				0x1002
#Define LOCALE_SENGCURRNAME      				0x1007
#Define LOCALE_SENGLANGUAGE      				0x1001
#Define LOCALE_SGROUPING      					0x10
#Define LOCALE_SINTLSYMBOL      				0x15
#Define LOCALE_SISO3166CTRYNAME     			0x5A
#Define LOCALE_SISO639LANGNAME     				0x59
#Define LOCALE_SLANGUAGE      					0x2
#Define LOCALE_SLIST       						0xC
#Define LOCALE_SLONGDATE      					0x20
#Define LOCALE_SMONDECIMALSEP     				0x16
#Define LOCALE_SMONGROUPING      				0x18
#Define LOCALE_SMONTHNAME1      				0x38
#Define LOCALE_SMONTHNAME10      				0x41
#Define LOCALE_SMONTHNAME11      				0x42
#Define LOCALE_SMONTHNAME12      				0x43
#Define LOCALE_SMONTHNAME13      				0x100E
#Define LOCALE_SMONTHNAME2      				0x39
#Define LOCALE_SMONTHNAME3      				0x3A
#Define LOCALE_SMONTHNAME4      				0x3B
#Define LOCALE_SMONTHNAME5      				0x3C
#Define LOCALE_SMONTHNAME6      				0x3D
#Define LOCALE_SMONTHNAME7      				0x3E
#Define LOCALE_SMONTHNAME8      				0x3F
#Define LOCALE_SMONTHNAME9      				0x40
#Define LOCALE_SMONTHOUSANDSEP     				0x17
#Define LOCALE_SNATIVECTRYNAME     				0x8
#Define LOCALE_SNATIVECURRNAME     				0x1008
#Define LOCALE_SNATIVEDIGITS     				0x13
#Define LOCALE_SNATIVELANGNAME     				0x4
#Define LOCALE_SNEGATIVESIGN     				0x51
#Define LOCALE_SPOSITIVESIGN     				0x50
#Define LOCALE_SSHORTDATE      					0x1F
#Define LOCALE_SSORTNAME      					0x1013
#Define LOCALE_STHOUSAND      					0xF
#Define LOCALE_STIME       						0x1E
#Define LOCALE_STIMEFORMAT      				0x1003
#Define LOCALE_SYEARMONTH      					0x1006
#Define LOCALE_SYSTEM_DEFAULT					0x800
#Define LOCALE_USE_CP_ACP      					0x40000000
#Define LOCALE_USER_DEFAULT						0x400
#Define LOGPIXELSX								88
#Define LOGPIXELSY								90
#Define MAXLONG         						0x7fffffff

#Define MCM_FIRST        						0x1000
#Define MCM_GETCOLOR       						0x100b
#Define MCM_GETCURSEL							0x1001
#Define MCM_GETFIRSTDAYOFWEEK     				0x1010
#Define MCM_GETMAXSELCOUNT      				0x1003
#Define MCM_GETMAXTODAYWIDTH     				0x1015
#Define MCM_GETMINREQRECT      					0x1009
#Define MCM_GETMONTHDELTA      					0x1013
#Define MCM_GETMONTHRANGE      					0x1007
#Define MCM_GETRANGE       						0x1011
#Define MCM_GETSELRANGE       					0x1005
#Define MCM_GETTODAY       						0x100d
#Define MCM_GETUNICODEFORMAT     				0x2006
#Define MCM_HITTEST        						0x100e
#Define MCM_SETCOLOR       						0x100a
#Define MCM_SETCURSEL       					0x1002
#Define MCM_SETDAYSTATE       					0x1008
#Define MCM_SETFIRSTDAYOFWEEK     				0x100f
#Define MCM_SETMAXSELCOUNT      				0x1004
#Define MCM_SETMONTHDELTA      					0x1014
#Define MCM_SETRANGE       						0x1012
#Define MCM_SETSELRANGE       					0x1006
#Define MCM_SETTODAY       						0x100c
#Define MCM_SETUNICODEFORMAT     				0x2005

#Define MCS_COMMAND_CONNECT      				19
#Define MCS_COMMAND_DISABLE      				14
#Define MCS_COMMAND_ENABLE      				13
#Define MCS_COMMAND_GET_CONFIG     				16
#Define MCS_COMMAND_REFRESH_STATUS				21
#Define MCS_COMMAND_RENAME      				20
#Define MCS_COMMAND_SET_CONFIG     				15
#Define MCS_COMMAND_START      					17
#Define MCS_COMMAND_STOP      					18
#Define MCS_CREATE_CONFIGS_BY_DEFAULT   		0x10
#Define MCS_CREATE_ONE_PER_NETCARD    			0x1
#Define MCS_CREATE_PMODE_NOT_REQUIRED   		0x100
#Define MCS_DAYSTATE       						0x1
#Define MCS_MULTISELECT       					0x2
#Define MCS_NOTODAY        						0x10
#Define MCS_NOTODAYCIRCLE      					0x8
#Define MCS_WEEKNUMBERS       					0x4

#Define MCSC_BACKGROUND       					0
#Define MCSC_MONTHBK       						4
#Define MCSC_TEXT        						1
#Define MCSC_TITLEBK       						2
#Define MCSC_TITLETEXT       					3
#Define MCSC_TRAILINGTEXT      					5

#Define MF_APPEND        						0x100
#Define MF_BITMAP        						0x4
#Define MF_BYCOMMAND       						0x0
#Define MF_BYPOSITION       					0x400
#Define MF_CALLBACKS       						0x8000000
#Define MF_CHANGE        						0x80
#Define MF_CHECKED        						0x8
#Define MF_CONV         						0x40000000
#Define MF_DEFAULT        						0x1000
#Define MF_DELETE        						0x200
#Define MF_DISABLED        						0x2
#Define MF_DLL_NAME        						[Microsoft Picture Converter]
#Define MF_ENABLED        						0x0
#Define MF_END         							0x80
#Define MF_ERRORS        						0x10000000
#Define MF_FLAGS_CREATE_BUT_NO_SHOW_DISABLED 	0x8
#Define MF_FLAGS_EVEN_IF_NO_RESOURCE   			0x1
#Define MF_FLAGS_FILL_IN_UNKNOWN_RESOURCE  		0x4
#Define MF_FLAGS_NO_CREATE_IF_NO_RESOURCE  		0x2
#Define MF_FPCR_FUNC       						0x25
#Define MF_FPCR_FUNC_STR      					[mf_fpcr]
#Define MF_GRAYED        						0x1
#Define MF_HELP         						0x4000
#Define MF_HILITE        						0x80
#Define MF_HSZ_INFO        						0x1000000
#Define MF_INSERT        						0x0
#Define MF_LINKS        						0x20000000
#Define MF_MASK         						0xff000000
#Define MF_MENUBARBREAK       					0x20
#Define MF_MENUBREAK       						0x40
#Define MF_MOUSESELECT       					0x8000
#Define MF_OWNERDRAW       						0x100
#Define MF_POPUP        						0x10
#Define MF_POSTMSGS        						0x4000000
#Define MF_REMOVE        						0x1000
#Define MF_RIGHTJUSTIFY       					0x4000
#Define MF_SENDMSGS        						0x2000000
#Define MF_SEPARATOR       						0x800
#Define MF_STRING        						0x0
#Define MF_SYSMENU        						0x2000
#Define MF_UNCHECKED       						0x0
#Define MF_UNHILITE        						0x0
#Define MF_USECHECKBITMAPS      				0x200

#Define NM_CLICK								-2
#Define NM_FIRST								0
#Define NM_RCLICK								-5
#Define NM_RDBLCLK								-6
#Define NM_RELEASEDCAPTURE						-16

#Define PBM_DELTAPOS       						0x403
#Define PBM_GETPOS        						0x408
#Define PBM_GETRANGE       						0x407
#Define PBM_SETBARCOLOR       					0x409
#Define PBM_SETBKCOLOR       					0x2001
#Define PBM_SETMARQUEE							0x40a
#Define PBM_SETPOS        						0x402
#Define PBM_SETRANGE       						0x401
#Define PBM_SETRANGE32       					0x406
#Define PBM_SETSTEP        						0x404
#Define PBM_STEPIT        						0x405

#Define PBS_MARQUEE             				0x8      && Comctl32.dll version 6
#Define PBS_SMOOTH              				0x1      && Comctl32.dll Version 4.7 or later
#Define PBS_VERTICAL            				0x4      && Comctl32.dll Version 4.7 or later

#Define PICTYPE_UNINITIALIZED					-1
#Define PICTYPE_NONE							0
#Define PICTYPE_BITMAP							1
#Define PICTYPE_METAFILE						2
#Define PICTYPE_ICON							3
#Define PICTYPE_ENHMETAFILE						4

#Define PS_SOLID        						0

#Define RBS_AUTOSIZE       						0x2000
#Define RBS_BANDBORDERS       					0x400
#Define RBS_DBLCLKTOGGLE      					0x8000
#Define RBS_FIXEDORDER       					0x800
#Define RBS_REGISTERDROP      					0x1000
#Define RBS_TOOLTIPS       						0x100
#Define RBS_VARHEIGHT       					0x200
#Define RBS_VERTICALGRIPPER      				0x4000
#Define RBSTR_CHANGERECT      					0x2
#Define RBSTR_PREFERNOLINEBREAK     			0x1

#Define RDW_ALLCHILDREN							0x80
#Define RDW_ERASE								0x4
#Define RDW_ERASENOW							0x200
#Define RDW_FRAME								0x400
#Define RDW_INTERNALPAINT						0x2
#Define RDW_INVALIDATE							0x1
#Define RDW_NOCHILDREN							0x40
#Define RDW_NOERASE								0x20
#Define RDW_NOFRAME								0x800
#Define RDW_NOINTERNALPAINT						0x10
#Define RDW_UPDATENOW							0x100
#Define RDW_VALIDATE							0x8

#Define SB_BOTH         						3
#Define SB_BOTTOM        						7
#Define SB_CONST_ALPHA       					0x1
#Define SB_CTL         							2
#Define SB_ENDSCROLL       						8
#Define SB_GETBORDERS       					0x407
#Define SB_GETICON        						0x414
#Define SB_GETPARTS        						0x406
#Define SB_GETRECT        						0x40a
#Define SB_GETTEXTA        						0x402
#Define SB_GETTEXTLENGTHA      					0x403
#Define SB_GETTEXTLENGTHW      					0x40c
#Define SB_GETTEXTW        						0x40d
#Define SB_GETTIPTEXTA       					0x412
#Define SB_GETTIPTEXTW       					0x413
#Define SB_GETUNICODEFORMAT						0x2006
#Define SB_GRAD_RECT       						0x10
#Define SB_GRAD_TRI        						0x20
#Define SB_HORZ         						0
#Define SB_ISSIMPLE        						0x40e
#Define SB_LEFT         						6
#Define SB_LINEDOWN        						1
#Define SB_LINELEFT        						0
#Define SB_LINERIGHT       						1
#Define SB_LINEUP        						0
#Define SB_NONE         						0x0
#Define SB_PAGEDOWN        						3
#Define SB_PAGELEFT        						2
#Define SB_PAGERIGHT       						3
#Define SB_PAGEUP        						2
#Define SB_PIXEL_ALPHA       					0x2
#Define SB_PREMULT_ALPHA      					0x4
#Define SB_RIGHT        						7
#Define SB_SETBKCOLOR       					0x2001
#Define SB_SETICON        						0x40f
#Define SB_SETMINHEIGHT       					0x408
#Define SB_SETPARTS        						0x404
#Define SB_SETTEXTA        						0x401
#Define SB_SETTEXTW        						0x40b
#Define SB_SETTIPTEXTA       					0x410
#Define SB_SETTIPTEXTW       					0x411
#Define SB_SETUNICODEFORMAT						0x2005
#Define SB_SIMPLE        						0x409
#Define SB_SIMPLEID        						0xff
#Define SB_THUMBPOSITION      					4
#Define SB_THUMBTRACK       					5
#Define SB_TOP         							6
#Define SB_VERT         						1

#Define SBARS_SIZEGRIP       					0x100
#Define SBARS_TOOLTIPS       					0x800

#Define SBM_ENABLE_ARROWS      					0xE4
#Define SBM_GETPOS        						0xE1
#Define SBM_GETRANGE       						0xE3
#Define SBM_GETSCROLLBARINFO    				0xEB
#Define SBM_GETSCROLLINFO      					0xEA
#Define SBM_SETPOS        						0xE0
#Define SBM_SETRANGE       						0xE2
#Define SBM_SETRANGEREDRAW      				0xE6
#Define SBM_SETSCROLLINFO      					0xE9

#Define SBS_BOTTOMALIGN       					0x4
#Define SBS_HORZ        						0x0
#Define SBS_LEFTALIGN       					0x2
#Define SBS_RIGHTALIGN       					0x4
#Define SBS_SIZEBOX        						0x8
#Define SBS_SIZEBOXBOTTOMRIGHTALIGN    			0x4
#Define SBS_SIZEBOXTOPLEFTALIGN     			0x2
#Define SBS_SIZEGRIP							0x10
#Define SBS_TOPALIGN							0x2
#Define SBS_VERT								0x1

#Define SBT_NOBORDERS							0x100
#Define SBT_NOTABPARSING						0x800
#Define SBT_OWNERDRAW							0x1000
#Define SBT_POPOUT								0x200
#Define SBT_RTLREADING							0x400
#Define SBT_TOOLTIPS							0x800

#Define SC_ARRANGE								0xF110
#Define SC_CLOSE								0xF060
#Define SC_CONTEXTHELP							0xF180
#Define SC_DEFAULT								0xF160
#Define SC_DLG_FORCE_UI							0x4
#Define SC_DLG_MINIMAL_UI						0x1
#Define SC_DLG_NO_UI							0x2
#Define SC_ENUM_PROCESS_INFO					0
#Define SC_FLAGS								0x400
#Define SC_FLAGS_STR							[/sc]
#Define SC_HOTKEY								0xF150
#Define SC_HSCROLL								0xF080
#Define SC_ICON									0xF020		&&SC_MINIMIZE
#Define SC_KEYMENU								0xF100
#Define SC_MAXIMIZE								0xF030
#Define SC_MINIMIZE								0xF020
#Define SC_MONITORPOWER							0xF170
#Define SC_MOUSEMENU							0xF090
#Define SC_MOVE									0xF010
#Define SC_NEXTWINDOW							0xF040
#Define SC_PREVWINDOW							0xF050
#Define SC_RESTORE								0xF120
#Define SC_SCREENSAVE							0xF140
#Define SC_SEPARATOR							0xF00F
#Define SC_SIZE									0xF000
#Define SC_TASKLIST								0xF130
#Define SC_VSCROLL								0xF070
#Define SC_ZOOM 								0xF030		&&SC_MAXIMIZE

#Define SIF_ALL         						BITOR(SIF_RANGE, SIF_PAGE, SIF_POS, SIF_TRACKPOS)
#Define SIF_DISABLENOSCROLL      				0x8
#Define SIF_PAGE        						0x2
#Define SIF_POS         						0x4
#Define SIF_RANGE        						0x1
#Define SIF_TRACKPOS       						0x10

#Define SS_BITMAP        						0xE
#Define SS_BLACKFRAME       					0x7
#Define SS_BLACKRECT       						0x4
#Define SS_CENTER        						0x1
#Define SS_CENTERIMAGE       					0x200
#Define SS_ELLIPSISMASK       					0xC000
#Define SS_ENDELLIPSIS       					0x4000
#Define SS_ENHMETAFILE       					0xF
#Define SS_ETCHEDFRAME       					0x12
#Define SS_ETCHEDHORZ       					0x10
#Define SS_ETCHEDVERT       					0x11
#Define SS_GRAYFRAME       						0x8
#Define SS_GRAYRECT        						0x5
#Define SS_ICON         						0x3
#Define SS_LEFT         						0x0
#Define SS_LEFTNOWORDWRAP      					0xC
#Define SS_LEVEL_VERSION      					0
#Define SS_MAJOR_VERSION      					7
#Define SS_MINIMUM_VERSION      				[7.00.00.0000]
#Define SS_MINOR_VERSION      					0
#Define SS_NOPREFIX        						0x80
#Define SS_NOTIFY        						0x100
#Define SS_OWNERDRAW       						0xD
#Define SS_PATHELLIPSIS       					0x8000
#Define SS_REALSIZECONTROL      				0x40
#Define SS_REALSIZEIMAGE      					0x800
#Define SS_RIGHT        						0x2
#Define SS_RIGHTJUST       						0x400
#Define SS_SIMPLE								0xB
#Define SS_SUNKEN								0x1000
#Define SS_TYPEMASK								0x1F
#Define SS_USERITEM 							0xA
#Define SS_WHITEFRAME							0x9
#Define SS_WHITERECT							0x6
#Define SS_WORDELLIPSIS							0xC000

#Define STANDARD_RIGHTS_REQUIRED    			0xF0000

#Define SUBLANG_ARABIC_ALGERIA						0x5
#Define SUBLANG_ARABIC_BAHRAIN						0xf
#Define SUBLANG_ARABIC_EGYPT						0x3
#Define SUBLANG_ARABIC_IRAQ							0x2
#Define SUBLANG_ARABIC_JORDAN						0xb
#Define SUBLANG_ARABIC_KUWAIT						0xd
#Define SUBLANG_ARABIC_LEBANON						0xc
#Define SUBLANG_ARABIC_LIBYA						0x4
#Define SUBLANG_ARABIC_MOROCCO						0x6
#Define SUBLANG_ARABIC_OMAN							0x8
#Define SUBLANG_ARABIC_QATAR						0x10
#Define SUBLANG_ARABIC_SAUDI_ARABIA					0x1
#Define SUBLANG_ARABIC_SYRIA						0xa
#Define SUBLANG_ARABIC_TUNISIA						0x7
#Define SUBLANG_ARABIC_UAE							0xe
#Define SUBLANG_ARABIC_YEMEN						0x9
#Define SUBLANG_AZERI_CYRILLIC						0x2
#Define SUBLANG_AZERI_LATIN							0x1
#Define SUBLANG_CHINESE_HONGKONG					0x3
#Define SUBLANG_CHINESE_MACAU						0x5
#Define SUBLANG_CHINESE_SIMPLIFIED					0x2
#Define SUBLANG_CHINESE_SINGAPORE					0x4
#Define SUBLANG_CHINESE_TRADITIONAL					0x1
#Define SUBLANG_CROATIAN_BOSNIA_HERZEGOVINA_LATIN 	0x04
#Define SUBLANG_CROATIAN_CROATIA 					0x01
#Define SUBLANG_DEFAULT								0x1
#Define SUBLANG_DUTCH								0x1
#Define SUBLANG_DUTCH_BELGIAN						0x2
#Define SUBLANG_ENGLISH_AUS							0x3
#Define SUBLANG_ENGLISH_BELIZE						0xa
#Define SUBLANG_ENGLISH_CAN							0x4
#Define SUBLANG_ENGLISH_CARIBBEAN					0x9
#Define SUBLANG_ENGLISH_EIRE						0x6
#Define SUBLANG_ENGLISH_JAMAICA						0x8
#Define SUBLANG_ENGLISH_NZ							0x5
#Define SUBLANG_ENGLISH_PHILIPPINES					0xd
#Define SUBLANG_ENGLISH_SOUTH_AFRICA				0x7
#Define SUBLANG_ENGLISH_TRINIDAD					0xb
#Define SUBLANG_ENGLISH_UK							0x2
#Define SUBLANG_ENGLISH_US							0x1
#Define SUBLANG_ENGLISH_ZIMBABWE					0xc
#Define SUBLANG_FRENCH								0x1
#Define SUBLANG_FRENCH_BELGIAN						0x2
#Define SUBLANG_FRENCH_CANADIAN						0x3
#Define SUBLANG_FRENCH_LUXEMBOURG					0x5
#Define SUBLANG_FRENCH_MONACO						0x6
#Define SUBLANG_FRENCH_SWISS						0x4
#Define SUBLANG_GERMAN								0x1
#Define SUBLANG_GERMAN_AUSTRIAN						0x3
#Define SUBLANG_GERMAN_LIECHTENSTEIN				0x5
#Define SUBLANG_GERMAN_LUXEMBOURG					0x4
#Define SUBLANG_GERMAN_SWISS						0x2
#Define SUBLANG_ITALIAN								0x1
#Define SUBLANG_ITALIAN_SWISS						0x2
#Define SUBLANG_KASHMIRI_INDIA						0x2
#Define SUBLANG_KOREAN								0x1
#Define SUBLANG_LITHUANIAN							0x1
#Define SUBLANG_MALAY_BRUNEI_DARUSSALAM				0x2
#Define SUBLANG_MALAY_MALAYSIA						0x1
#Define SUBLANG_NEPALI_INDIA						0x2
#Define SUBLANG_NEUTRAL								0x0
#Define SUBLANG_NORWEGIAN_BOKMAL					0x1
#Define SUBLANG_NORWEGIAN_NYNORSK					0x2
#Define SUBLANG_PORTUGUESE							0x2
#Define SUBLANG_PORTUGUESE_BRAZILIAN				0x1
#Define SUBLANG_PORTUGUESE_PORTUGAL					0x2
#Define SUBLANG_SERBIAN_CYRILLIC					0x3
#Define SUBLANG_SERBIAN_LATIN						0x2
#Define SUBLANG_SPANISH								0x1
#Define SUBLANG_SPANISH_ARGENTINA					0xb
#Define SUBLANG_SPANISH_BOLIVIA						0x10
#Define SUBLANG_SPANISH_CHILE						0xd
#Define SUBLANG_SPANISH_COLOMBIA					0x9
#Define SUBLANG_SPANISH_COSTA_RICA					0x5
#Define SUBLANG_SPANISH_DOMINICAN_REPUBLIC			0x7
#Define SUBLANG_SPANISH_ECUADOR						0xc
#Define SUBLANG_SPANISH_EL_SALVADOR					0x11
#Define SUBLANG_SPANISH_GUATEMALA					0x4
#Define SUBLANG_SPANISH_HONDURAS					0x12
#Define SUBLANG_SPANISH_MEXICAN						0x2
#Define SUBLANG_SPANISH_MODERN						0x3
#Define SUBLANG_SPANISH_NICARAGUA					0x13
#Define SUBLANG_SPANISH_PANAMA						0x6
#Define SUBLANG_SPANISH_PARAGUAY					0xf
#Define SUBLANG_SPANISH_PERU						0xa
#Define SUBLANG_SPANISH_PUERTO_RICO					0x14
#Define SUBLANG_SPANISH_URUGUAY						0xe
#Define SUBLANG_SPANISH_VENEZUELA					0x8
#Define SUBLANG_SWEDISH								0x1
#Define SUBLANG_SWEDISH_FINLAND						0x2
#Define SUBLANG_SYS_DEFAULT							0x2
#Define SUBLANG_URDU_INDIA							0x2
#Define SUBLANG_URDU_PAKISTAN						0x1
#Define SUBLANG_UZBEK_CYRILLIC						0x2
#Define SUBLANG_UZBEK_LATIN							0x1

#Define SW_AUTOPROF_LOAD_MASK     					0x1
#Define SW_AUTOPROF_SAVE_MASK     					0x2
#Define SW_ERASE        							0x4
#Define SW_FORCEMINIMIZE      						11
#Define SW_HIDE         							0
#Define SW_INVALIDATE       						0x2
#Define SW_MAX         								10
#Define SW_MAXIMIZE        							3
#Define SW_MINIMIZE        							6
#Define SW_NORMAL        							1
#Define SW_OTHERUNZOOM       						4
#Define SW_OTHERZOOM       							2
#Define SW_PARENTCLOSING      						1
#Define SW_PARENTOPENING      						3
#Define SW_RESTORE        							9
#Define SW_SCROLLCHILDREN      						0x1
#Define SW_SHOW         							5
#Define SW_SHOWDEFAULT       						10
#Define SW_SHOWMAXIMIZED      						3
#Define SW_SHOWMINIMIZED      						2
#Define SW_SHOWMINNOACTIVE      					7
#Define SW_SHOWNA       		 					8
#Define SW_SHOWNOACTIVATE      						4
#Define SW_SHOWNORMAL       						1
#Define SW_SMOOTHSCROLL       						0x10

#Define SWP_ASYNCWINDOWPOS      				0x4000
#Define SWP_DEFERERASE       					0x2000
#Define SWP_DRAWFRAME       					0x20		&& SWP_FRAMECHANGED
#Define SWP_FRAMECHANGED      					0x20
#Define SWP_HIDEWINDOW       					0x80
#Define SWP_NOACTIVATE       					0x10
#Define SWP_NOCOPYBITS       					0x100
#Define SWP_NOMOVE        						0x2
#Define SWP_NOOWNERZORDER      					0x200
#Define SWP_NOREDRAW       						0x8
#Define SWP_NOREPOSITION      					0x200		&& SWP_NOOWNERZORDER
#Define SWP_NOSENDCHANGING      				0x400
#Define SWP_NOSIZE        						0x1
#Define SWP_NOZORDER       						0x4
#Define SWP_SHOWWINDOW       					0x40

#Define TCIF_IMAGE								0x2
#Define TCIF_PARAM								0x8
#Define TCIF_RTLREADING							0x4
#Define TCIF_STATE								0x10
#Define TCIF_TEXT								0x1

#Define TCIS_BUTTONPRESSED						0x1
#Define TCIS_HIGHLIGHTED						0x2

#Define TCM_ADJUSTRECT							0x13290
#Define TCM_DELETEALLITEMS						0x1309
#Define TCM_DELETEITEM							0x1308
#Define TCM_DESELECTALL							0x1332
#Define TCM_FIRST								0x1300
#Define TCM_GETCURFOCUS							0x132f
#Define TCM_GETCURSEL							0x130b
#Define TCM_GETEXTENDEDSTYLE					0x1335
#Define TCM_GETIMAGELIST						0x1302
#Define TCM_GETITEMA							0x1305
#Define TCM_GETITEMCOUNT						0x1304
#Define TCM_GETITEMRECT							0x130a
#Define TCM_GETITEMW							0x133c
#Define TCM_GETROWCOUNT							0x132c
#Define TCM_GETTOOLTIPS							0x132d
#Define TCM_GETUNICODEFORMAT					0x2006
#Define TCM_HIGHLIGHTITEM						0x1333
#Define TCM_HITTEST								0x130d
#Define TCM_INSERTITEMA							0x1307
#Define TCM_INSERTITEMW							0x133e
#Define TCM_REMOVEIMAGE							0x132a
#Define TCM_SETCURFOCUS							0x1330
#Define TCM_SETCURSEL							0x130c
#Define TCM_SETEXTENDEDSTYLE					0x1334
#Define TCM_SETIMAGELIST						0x1303
#Define TCM_SETITEMA							0x1306
#Define TCM_SETITEMEXTRA						0x130e
#Define TCM_SETITEMSIZE							0x1329
#Define TCM_SETITEMW							0x133d
#Define TCM_SETMINTABWIDTH						0x1331
#Define TCM_SETPADDING							0x132b
#Define TCM_SETTOOLTIPS							0x132e
#Define TCM_SETUNICODEFORMAT					0x2005

#Define TCN_FIRST								-550
#Define TCN_FOCUSCHANGE							-554
#Define TCN_GETOBJECT							-553
#Define TCN_KEYDOWN								-550
#Define TCN_LAST								-580
#Define TCN_SELCHANGE							-551
#Define TCN_SELCHANGING							-552

#Define TCS_BOTTOM								0x2
#Define TCS_BUTTONS								0x100
#Define TCS_EX_FLATSEPARATORS					0x1
#Define TCS_EX_REGISTERDROP						0x2
#Define TCS_FIXEDWIDTH							0x400
#Define TCS_FLATBUTTONS							0x8
#Define TCS_FOCUSNEVER							0x8000
#Define TCS_FOCUSONBUTTONDOWN					0x1000
#Define TCS_FORCEICONLEFT						0x10
#Define TCS_FORCELABELLEFT						0x20
#Define TCS_HOTTRACK							0x40
#Define TCS_MULTILINE							0x200
#Define TCS_MULTISELECT							0x4
#Define TCS_OWNERDRAWFIXED						0x2000
#Define TCS_RAGGEDRIGHT							0x800
#Define TCS_RIGHT								0x2
#Define TCS_RIGHTJUSTIFY						0x0
#Define TCS_SCROLLOPPOSITE						0x1
#Define TCS_SINGLELINE							0x0
#Define TCS_TABS								0x0
#Define TCS_TOOLTIPS							0x4000
#Define TCS_VERTICAL							0x80

#Define TIME_BYTES        						0x4
#Define TIME_CALLBACK_EVENT_PULSE    			0x20
#Define TIME_CALLBACK_EVENT_SET     			0x10
#Define TIME_CALLBACK_FUNCTION     				0x0
#Define TIME_EXCEEDED       					11
#Define TIME_FORCE24HOURFORMAT     				0x8
#Define TIME_MIDI        						0x10
#Define TIME_MS         						0x1
#Define TIME_NOMINUTESORSECONDS     			0x1
#Define TIME_NOSECONDS       					0x2
#Define TIME_NOTIMEMARKER      					0x4
#Define TIME_ONESHOT       						0
#Define TIME_PERIODIC       					1
#Define TIME_SAMPLES       						0x2
#Define TIME_SMPTE        						0x8
#Define TIME_STAMP_CAPABLE      				0x20
#Define TIME_TICKS        						0x20
#Define TIME_ZONE_ID_DAYLIGHT     				2
#Define TIME_ZONE_ID_INVALID     				0xffffffff
#Define TIME_ZONE_ID_STANDARD     				1
#Define TIME_ZONE_ID_UNKNOWN     				0

#Define TTDT_AUTOMATIC       					0
#Define TTDT_AUTOPOP       						2
#Define TTDT_INITIAL       						3
#Define TTDT_RESHOW        						1

#Define TTF_ABSOLUTE							0x80
#Define TTF_CENTERTIP							0x2
#Define TTF_DI_SETITEM							0x8000
#Define TTF_IDISHWND							0x1
#Define TTF_PARSELINKS							0x1000
#Define TTF_RTLREADING							0x4
#Define TTF_SUBCLASS							0x10
#Define TTF_TRACK								0x20
#Define TTF_TRANSPARENT							0x100
#Define TTF_BITMAP								0x10000		&& VISTA

#Define TTI_NONE								0
#Define TTI_INFO								1
#Define TTI_WARNING								2
#Define TTI_ERROR								3
#Define TTI_INFO_LARGE          				4		&& VISTA
#Define TTI_WARNING_LARGE       				5		&& VISTA
#Define TTI_ERROR_LARGE         				6		&& VISTA

#Define TTM_ACTIVATE							0x401
#Define TTM_ADDTOOLA							0x404
#Define TTM_ADDTOOLW							0x432
#Define TTM_ADJUSTRECT							0x41f
#Define TTM_DELTOOLA							0x405
#Define TTM_DELTOOLW							0x433
#Define TTM_ENUMTOOLSA							0x40e
#Define TTM_ENUMTOOLSW							0x43a
#Define TTM_GETBUBBLESIZE						0x41e
#Define TTM_GETCURRENTTOOLA						0x40f
#Define TTM_GETCURRENTTOOLW						0x43b
#Define TTM_GETDELAYTIME						0x415
#Define TTM_GETMARGIN							0x41b
#Define TTM_GETMAXTIPWIDTH						0x419
#Define TTM_GETTEXTA							0x40b
#Define TTM_GETTEXTW							0x438
#Define TTM_GETTIPBKCOLOR						0x416
#Define TTM_GETTIPTEXTCOLOR						0x417
#Define TTM_GETTOOLCOUNT 						0x40d
#Define TTM_GETTOOLINFOA						0x408
#Define TTM_GETTOOLINFOW 						0x435
#Define TTM_HITTESTA							0x40a
#Define TTM_HITTESTW							0x437
#Define TTM_NEWTOOLRECTA						0x406
#Define TTM_NEWTOOLRECTW						0x434
#Define TTM_POP									0x41c
#Define TTM_POPUP								0x422
#Define TTM_RELAYEVENT							0x407
#Define TTM_SETDELAYTIME						0x403
#Define TTM_SETMARGIN							0x41a
#Define TTM_SETMAXTIPWIDTH						0x418
#Define TTM_SETTIPBKCOLOR						0x413
#Define TTM_SETTIPTEXTCOLOR						0x416
#Define TTM_SETTITLEA							0x420
#Define TTM_SETTITLEW 							0x421
#Define TTM_SETTOOLINFOA						0x409
#Define TTM_SETTOOLINFOW						0x436
#Define TTM_SETWINDOWTHEME 						0x200B
#Define TTM_TRACKACTIVATE						0x411
#Define TTM_TRACKPOSITION						0x412
#Define TTM_UPDATE								0x41d
#Define TTM_UPDATETIPTEXTA						0x40c
#Define TTM_UPDATETIPTEXTW 						0x439
#Define TTM_WINDOWFROMPOINT						0x410

#Define TTN_FIRST								-520
#Define TTN_GETDISPINFO							-520
#Define TTN_GETDISPINFOA						-520
#Define TTN_GETDISPINFOW 						-530
#Define TTN_LAST 								-549
#Define TTN_LINKCLICK							-523
#Define TTN_NEEDTEXT 							-520
#Define TTN_NEEDTEXTA							-520
#Define TTN_NEEDTEXTW 							-530
#Define TTN_POP									-522
#Define TTN_SHOW								-521

#Define TTS_ALWAYSTIP							0x1
#Define TTS_BALLOON								0x40
#Define TTS_CLOSE								0x80
#Define TTS_NOANIMATE							0x10
#Define TTS_NOFADE								0x20
#Define TTS_NOPREFIX							0x2
#Define TTS_USEVISUALSTYLE						0x100		&& VISTA

#Define VK_CAPITAL	0x14

#Define WM_ACTIVATE        						0x6
#Define WM_ACTIVATEAPP       					0x1C
#Define WM_ADSPROP_NOTIFY_APPLY     			0x850
#Define WM_ADSPROP_NOTIFY_CHANGE    			0x84f
#Define WM_ADSPROP_NOTIFY_ERROR     			0x856
#Define WM_ADSPROP_NOTIFY_EXIT     				0x853
#Define WM_ADSPROP_NOTIFY_FOREGROUND			0x852
#Define WM_ADSPROP_NOTIFY_PAGEHWND    			0x84e
#Define WM_ADSPROP_NOTIFY_PAGEINIT    			0x84d
#Define WM_ADSPROP_NOTIFY_SETFOCUS    			0x851
#Define WM_ADSPROP_NOTIFY_SHOW_ERROR_DIALOG		0x857
#Define WM_AFXFIRST        						0x360
#Define WM_AFXLAST        						0x37F
#Define WM_APP         							0x8000
#Define WM_APPCOMMAND       					0x319
#Define WM_ASKCBFORMATNAME      				0x30C
#Define WM_CANCELJOURNAL      					0x4B
#Define WM_CANCELMODE       					0x1F
#Define WM_CAPTURECHANGED      					0x215
#Define WM_CHANGECBCHAIN      					0x30D
#Define WM_CHANGEUISTATE      					0x127
#Define WM_CHAR         						0x102
#Define WM_CHARTOITEM       					0x2F
#Define WM_CHILDACTIVATE      					0x22
#Define WM_CHOOSEFONT_GETLOGFONT    			0x401
#Define WM_CHOOSEFONT_SETFLAGS     				0x466
#Define WM_CHOOSEFONT_SETLOGFONT    			0x465
#Define WM_CLEAR        						0x303
#Define WM_CLOSE        						0x10
#Define WM_COMMAND        						0x111
#Define WM_COMMNOTIFY       					0x44
#Define WM_COMPACTING       					0x41
#Define WM_COMPAREITEM       					0x39
#Define WM_CONTEXTMENU       					0x7B
#Define WM_CONVERTREQUEST      					0x10A
#Define WM_CONVERTREQUESTEX      				0x108
#Define WM_CONVERTRESULT      					0x10B
#Define WM_COPY         						0x301
#Define WM_COPYDATA        						0x4A
#Define WM_CPL_LAUNCH       					0x7e8
#Define WM_CPL_LAUNCHED       					0x7e9
#Define WM_CREATE        						0x1
#Define WM_CTLCOLOR        						0x19
#Define WM_CTLCOLORBTN       					0x135
#Define WM_CTLCOLORDLG       					0x136
#Define WM_CTLCOLOREDIT       					0x133
#Define WM_CTLCOLORLISTBOX      				0x134
#Define WM_CTLCOLORMSGBOX      					0x132
#Define WM_CTLCOLORSCROLLBAR     				0x137
#Define WM_CTLCOLORSTATIC      					0x138
#Define WM_CUT         							0x300
#Define WM_DDE_ACK        						0x3e4
#Define WM_DDE_ADVISE       					0x3e2
#Define WM_DDE_DATA        						0x3e5
#Define WM_DDE_EXECUTE       					0x3e8
#Define WM_DDE_FIRST       						0x3E0
#Define WM_DDE_INITIATE       					0x3e0
#Define WM_DDE_LAST        						0x3e8
#Define WM_DDE_POKE        						0x3e7
#Define WM_DDE_REQUEST       					0x3e6
#Define WM_DDE_TERMINATE      					0x3e1
#Define WM_DDE_UNADVISE       					0x3e3
#Define WM_DEADCHAR        						0x103
#Define WM_DELETEITEM       					0x2D
#Define WM_DESTROY        						0x2
#Define WM_DESTROYCLIPBOARD      				0x307
#Define WM_DEVICECHANGE       					0x219
#Define WM_DEVMODECHANGE      					0x1B
#Define WM_DISPLAYCHANGE      					0x7E
#Define WM_DRAWCLIPBOARD      					0x308
#Define WM_DRAWITEM        						0x2B
#Define WM_DROPFILES       						0x233
#Define WM_ENABLE        						0xA
#Define WM_ENDSESSION       					0x16
#Define WM_ENTERIDLE       						0x121
#Define WM_ENTERMENULOOP      					0x211
#Define WM_ENTERSIZEMOVE      					0x231
#Define WM_ERASEBKGND       					0x14
#Define WM_EXITMENULOOP       					0x212
#Define WM_EXITSIZEMOVE       					0x232
#Define WM_FONTCHANGE       					0x1D
#Define WM_FORWARDMSG       					0x37F
#Define WM_GETDLGCODE       					0x87
#Define WM_GETFONT        						0x31
#Define WM_GETHOTKEY       						0x33
#Define WM_GETICON        						0x7F
#Define WM_GETMINMAXINFO      					0x24
#Define WM_GETOBJECT       						0x3D
#Define WM_GETTEXT        						0xD
#Define WM_GETTEXTLENGTH      					0xE
#Define WM_HANDHELDFIRST      					0x358
#Define WM_HANDHELDLAST       					0x35F
#Define WM_HELP         						0x53
#Define WM_HOTKEY        						0x312
#Define WM_HSCROLL        						0x114
#Define WM_HSCROLLCLIPBOARD      				0x30E
#Define WM_ICONERASEBKGND      					0x27
#Define WM_IME_CHAR        						0x286
#Define WM_IME_COMPOSITION      				0x10F
#Define WM_IME_COMPOSITIONFULL     				0x284
#Define WM_IME_CONTROL       					0x283
#Define WM_IME_ENDCOMPOSITION     				0x10E
#Define WM_IME_KEYDOWN       					0x290
#Define WM_IME_KEYLAST       					0x10F
#Define WM_IME_KEYUP       						0x291
#Define WM_IME_NOTIFY       					0x282
#Define WM_IME_REPORT       					0x280
#Define WM_IME_REQUEST       					0x288
#Define WM_IME_SELECT       					0x285
#Define WM_IME_SETCONTEXT      					0x281
#Define WM_IME_STARTCOMPOSITION     			0x10D
#Define WM_IMEKEYDOWN       					0x290
#Define WM_IMEKEYUP        						0x291
#Define WM_INITDIALOG       					0x110
#Define WM_INITMENU        						0x116
#Define WM_INITMENUPOPUP      					0x117
#Define WM_INPUTLANGCHANGE      				0x51
#Define WM_INPUTLANGCHANGEREQUEST    			0x50
#Define WM_INTERIM        						0x10C
#Define WM_KEYDOWN        						0x100
#Define WM_KEYFIRST        						0x100
#Define WM_KEYLAST        						0x108
#Define WM_KEYUP        						0x101
#Define WM_KILLFOCUS       						0x8
#Define WM_LBUTTONDBLCLK      					0x203
#Define WM_LBUTTONDOWN       					0x201
#Define WM_LBUTTONUP       						0x202
#Define WM_MBUTTONDBLCLK      					0x209
#Define WM_MBUTTONDOWN       					0x207
#Define WM_MBUTTONUP       						0x208
#Define WM_MDIACTIVATE       					0x222
#Define WM_MDICASCADE       					0x227
#Define WM_MDICREATE       						0x220
#Define WM_MDIDESTROY       					0x221
#Define WM_MDIGETACTIVE       					0x229
#Define WM_MDIICONARRANGE      					0x228
#Define WM_MDIMAXIMIZE       					0x225
#Define WM_MDINEXT        						0x224
#Define WM_MDIREFRESHMENU      					0x234
#Define WM_MDIRESTORE       					0x223
#Define WM_MDISETMENU       					0x230
#Define WM_MDITILE        						0x226
#Define WM_MEASUREITEM       					0x2C
#Define WM_MENUCHAR        						0x120
#Define WM_MENUCOMMAND       					0x126
#Define WM_MENUDRAG        						0x123
#Define WM_MENUGETOBJECT      					0x124
#Define WM_MENURBUTTONUP      					0x122
#Define WM_MENUSELECT       					0x11F
#Define WM_MOUSEACTIVATE      					0x21
#Define WM_MOUSEFIRST       					0x200
#Define WM_MOUSEHOVER       					0x2A1
#Define WM_MOUSELAST       						0x209
#Define WM_MOUSELEAVE       					0x2A3
#Define WM_MOUSEMOVE       						0x200
#Define WM_MOUSEWHEEL       					0x20A
#Define WM_MOVE         						0x3
#Define WM_MOVING        						0x216
#Define WM_NCACTIVATE       					0x86
#Define WM_NCCALCSIZE       					0x83
#Define WM_NCCREATE        						0x81
#Define WM_NCDESTROY       						0x82
#Define WM_NCHITTEST       						0x84
#Define WM_NCLBUTTONDBLCLK      				0xA3
#Define WM_NCLBUTTONDOWN      					0xA1
#Define WM_NCLBUTTONUP       					0xA2
#Define WM_NCMBUTTONDBLCLK      				0xA9
#Define WM_NCMBUTTONDOWN      					0xA7
#Define WM_NCMBUTTONUP       					0xA8
#Define WM_NCMOUSEHOVER       					0x2A0
#Define WM_NCMOUSELEAVE       					0x2A2
#Define WM_NCMOUSEMOVE       					0xA0
#Define WM_NCPAINT        						0x85
#Define WM_NCRBUTTONDBLCLK      				0xA6
#Define WM_NCRBUTTONDOWN      					0xA4
#Define WM_NCRBUTTONUP       					0xA5
#Define WM_NCXBUTTONDBLCLK      				0xAD
#Define WM_NCXBUTTONDOWN      					0xAB
#Define WM_NCXBUTTONUP       					0xAC
#Define WM_NEXTDLGCTL       					0x28
#Define WM_NEXTMENU        						0x213
#Define WM_NOTIFY        						0x4E
#Define WM_NOTIFYFORMAT       					0x55
#Define WM_NULL         						0x0
#Define WM_OTHERWINDOWCREATED     				0x42
#Define WM_OTHERWINDOWDESTROYED     			0x43
#Define WM_PAINT        						0xF
#Define WM_PAINTCLIPBOARD      					0x309
#Define WM_PAINTICON       						0x26
#Define WM_PALETTECHANGED      					0x311
#Define WM_PALETTEISCHANGING     				0x310
#Define WM_PARENTNOTIFY       					0x210
#Define WM_PASTE        						0x302
#Define WM_PENWINFIRST       					0x380
#Define WM_PENWINLAST       					0x38F
#Define WM_POWER        						0x48
#Define WM_POWERBROADCAST      					0x218
#Define WM_PRINT        						0x317
#Define WM_PRINTCLIENT       					0x318
#Define WM_PSD_ENVSTAMPRECT      				0x405
#Define WM_PSD_FULLPAGERECT      				0x401
#Define WM_PSD_GREEKTEXTRECT     				0x404
#Define WM_PSD_MARGINRECT      					0x403
#Define WM_PSD_MINMARGINRECT     				0x402
#Define WM_PSD_PAGESETUPDLG      				0x400
#Define WM_PSD_YAFULLPAGERECT     				0x406
#Define WM_QUERYDRAGICON      					0x37
#Define WM_QUERYENDSESSION      				0x11
#Define WM_QUERYNEWPALETTE      				0x30F
#Define WM_QUERYOPEN       						0x13
#Define WM_QUERYUISTATE       					0x129
#Define WM_QUEUESYNC       						0x23
#Define WM_QUIT         						0x12
#Define WM_RASDIALEVENT       					0xCCCD
#Define WM_RBUTTONDBLCLK      					0x206
#Define WM_RBUTTONDOWN       					0x204
#Define WM_RBUTTONUP       						0x205
#Define WM_RENDERALLFORMATS      				0x306
#Define WM_RENDERFORMAT       					0x305
#Define WM_SETCURSOR       						0x20
#Define WM_SETFOCUS        						0x7
#Define WM_SETFONT        						0x30
#Define WM_SETHOTKEY       						0x32
#Define WM_SETICON        						0x80
#Define WM_SETREDRAW       						0xB
#Define WM_SETTEXT        						0xC
#Define WM_SETTINGCHANGE      					0x1A
#Define WM_SHOWWINDOW       					0x18
#Define WM_SIZE         						0x5
#Define WM_SIZECLIPBOARD      					0x30B
#Define WM_SIZING        						0x214
#Define WM_SPOOLERSTATUS      					0x2A
#Define WM_STYLECHANGED       					0x7D
#Define WM_STYLECHANGING      					0x7C
#Define WM_SYNCPAINT       						0x88
#Define WM_SYSCHAR        						0x106
#Define WM_SYSCOLORCHANGE      					0x15
#Define WM_SYSCOMMAND       					0x112
#Define WM_SYSDEADCHAR       					0x107
#Define WM_SYSKEYDOWN       					0x104
#Define WM_SYSKEYUP        						0x105
#Define WM_TCARD        						0x52
#Define WM_THEMECHANGED               			0x031A
#Define WM_TIMECHANGE       					0x1E
#Define WM_TIMER        						0x113
#Define WM_UNDO         						0x304
#Define WM_UNINITMENUPOPUP      				0x125
#Define WM_UPDATEUISTATE      					0x128
#Define WM_USER         						0x400
#Define WM_USERCHANGED       					0x54
#Define WM_VKEYTOITEM       					0x2E
#Define WM_VSCROLL								0x115
#Define WM_VSCROLLCLIPBOARD      				0x30A
#Define WM_WINDOWPOSCHANGED      				0x47
#Define WM_WINDOWPOSCHANGING     				0x46
#Define WM_WININICHANGE       					0x1A
#Define WM_WNT_CONVERTREQUESTEX     			0x109
#Define WM_XBUTTONDBLCLK      					0x20D
#Define WM_XBUTTONDOWN       					0x20B
#Define WM_XBUTTONUP       						0x20C

#Define WS_ACTIVECAPTION      					0x1
#Define WS_BORDER        						0x800000
#Define WS_CAPTION        						0xC00000
#Define WS_CHILD        						0x40000000
#Define WS_CHILDWINDOW       					0x40000000
#Define WS_CLIPCHILDREN       					0x2000000
#Define WS_CLIPSIBLINGS       					0x4000000
#Define WS_DISABLED        						0x8000000
#Define WS_DLGFRAME        						0x400000
#Define WS_EX_ACCEPTFILES      					0x10
#Define WS_EX_APPWINDOW       					0x40000
#Define WS_EX_CLIENTEDGE      					0x200
#Define WS_EX_CONTEXTHELP      					0x400
#Define WS_EX_CONTROLPARENT      				0x10000
#Define WS_EX_DLGMODALFRAME      				0x1
#Define WS_EX_LAYERED       					0x80000
#Define WS_EX_LAYOUTRTL       					0x400000
#Define WS_EX_LEFT        						0x0
#Define WS_EX_LEFTSCROLLBAR      				0x4000
#Define WS_EX_LTRREADING      					0x0
#Define WS_EX_MDICHILD       					0x40
#Define WS_EX_NOACTIVATE      					0x8000000
#Define WS_EX_NOINHERITLAYOUT     				0x100000
#Define WS_EX_NOPARENTNOTIFY     				0x4
#Define WS_EX_OVERLAPPEDWINDOW     				0x300
#Define WS_EX_PALETTEWINDOW      				0x188
#Define WS_EX_RIGHT        						0x1000
#Define WS_EX_RIGHTSCROLLBAR     				0x0
#Define WS_EX_RTLREADING      					0x2000
#Define WS_EX_STATICEDGE      					0x20000
#Define WS_EX_TOOLWINDOW      					0x80
#Define WS_EX_TOPMOST       					0x8
#Define WS_EX_TRANSPARENT      					0x20
#Define WS_EX_WINDOWEDGE      					0x100
#Define WS_GROUP        						0x20000
#Define WS_GT         							0x30000
#Define WS_HSCROLL        						0x100000
#Define WS_ICONIC        						0x20000000
#Define WS_MAXIMIZE        						0x1000000
#Define WS_MAXIMIZEBOX       					0x10000
#Define WS_MINIMIZE        						0x20000000
#Define WS_MINIMIZEBOX       					0x20000
#Define WS_OVERLAPPED       					0x0
#Define WS_OVERLAPPEDWINDOW      				0xCF0000
#Define WS_POPUP        						0x80000000
#Define WS_POPUPWINDOW       					0x80880000
#Define WS_SIZEBOX        						0x40000
#Define WS_SYSMENU        						0x80000
#Define WS_TABSTOP        						0x10000
#Define WS_THICKFRAME       					0x40000
#Define WS_TILED        						0x0
#Define WS_TILEDWINDOW       					0xCF0000
#Define WS_VISIBLE        						0x10000000
#Define WS_VSCROLL        						0x200000

********************************************************************************
* FROM FOXPRO.H
********************************************************************************

*!* Sysmetric() parameter values
#Define SYSMETRIC_SCREENWIDTH              1 && Screen width
#Define SYSMETRIC_SCREENHEIGHT             2 && Screen width
#Define SYSMETRIC_SIZINGBORDERWIDTH        3 && Width of the sizing border around a resizable window
#Define SYSMETRIC_SIZINGBORDERHEIGHT       4 && Height of the sizing border around a resizable window
#Define SYSMETRIC_VSCROLLBARWIDTH          5 && Width of a vertical scroll bar
#Define SYSMETRIC_VSCROLLBARHEIGHT         6 && Height of the arrow bitmap on a vertical scroll bar
#Define SYSMETRIC_HSCROLLBARWIDTH          7 && Width of the arrow bitmap on a horizontal scroll bar
#Define SYSMETRIC_HSCROLLBARHEIGHT         8 && Height of a horizontal scroll bar
#Define SYSMETRIC_WINDOWTITLEHEIGHT        9 && Height of window title (caption) area
#Define SYSMETRIC_WINDOWBORDERWIDTH       10 && Width of a window border
#Define SYSMETRIC_WINDOWBORDERHEIGHT      11 && Height of a window border
#Define SYSMETRIC_WINDOWFRAMEWIDTH        12 && Width of the frame around the perimeter of a window that has a caption but is not sizable
#Define SYSMETRIC_WINDOWFRAMEHEIGHT       13 && Height of the frame around the perimeter of a window that has a caption but is not sizable
#Define SYSMETRIC_THUMBBOXWIDTH           14 && Width of the thumb box in a horizontal scroll bar
#Define SYSMETRIC_THUMBBOXHEIGHT          15 && Height of the thumb box in a vertical scroll bar
#Define SYSMETRIC_ICONWIDTH               16 && Width of an icon
#Define SYSMETRIC_ICONHEIGHT              17 && Height of an icon
#Define SYSMETRIC_CURSORWIDTH             18 && Width of a cursor
#Define SYSMETRIC_CURSORHEIGHT            19 && Height of a cursor
#Define SYSMETRIC_MENUBAR                 20 && Height of a single-line menu bar
#Define SYSMETRIC_CLIENTWIDTH             21 && Width of the client area for a full-screen window
#Define SYSMETRIC_CLIENTHEIGHT            22 && Height of the client area for a full-screen window
#Define SYSMETRIC_KANJIWINHEIGHT          23 && Height of the Kanji window at the bottom of the screen in DBCS versions
#Define SYSMETRIC_MINDRAGWIDTH            24 && Minimum tracking width of a window. (The user cannot drag the window frame to a size smaller than this)
#Define SYSMETRIC_MINDRAGHEIGHT           25 && Minimum tracking height of a window. (The user cannot drag the window frame to a size smaller than this)
#Define SYSMETRIC_MINWINDOWWIDTH          26 && Minimum width of a window
#Define SYSMETRIC_MINWINDOWHEIGHT         27 && Minimum height of a window
#Define SYSMETRIC_TITLEBARBUTTONWIDTH     28 && Width of a title bar button
#Define SYSMETRIC_TITLEBARBUTTONHEIGHT    29 && Height of a title bar button
#Define SYSMETRIC_MOUSEPRESENT            30 && Is mouse present?  1 => mouse is installed, 0 => no mouse is installed
#Define SYSMETRIC_DEBUGVERSION            31 && Is this a debug version?  1 => debug version, 0 => retail version
#Define SYSMETRIC_MOUSEBUTTONSWAP         32 && Are mouse buttons swapped?  1 => Yes, 0 => No
#Define SYSMETRIC_HALFHEIGHTBUTTONWIDTH   33 && Width of a button in a half-height title bar
#Define SYSMETRIC_HALFHEIGHTBUTTONHEIGHT  34 && Height of a button in a half-height title bar

*!* Window Borders
#Define BORDER_NONE                       0
#Define BORDER_SINGLE                     1
#Define BORDER_DOUBLE                     2
#Define BORDER_SYSTEM                     3

*!* WindowState
#Define WINDOWSTATE_NORMAL                0       && Normal
#Define WINDOWSTATE_MINIMIZED             1       && Minimized
#Define WINDOWSTATE_MAXIMIZED             2       && Maximized

*!* Toolbar and Form Docking Positions
#Define TOOL_NOTDOCKED                   -1
#Define TOOL_TOP                          0
#Define TOOL_LEFT                         1
#Define TOOL_RIGHT                        2
#Define TOOL_BOTTOM                       3
#Define TOOL_TAB                          4
#Define TOOL_LINK                         5

*!* TYPE() tags
#Define T_CHARACTER     "C"
#Define T_NUMERIC       "N"
#Define T_DOUBLE        "B"
#Define T_DATE          "D"
#Define T_DATETIME      "T"
#Define T_MEMO          "M"
#Define T_GENERAL       "G"
#Define T_OBJECT        "O"
#Define T_SCREEN        "S"
#Define T_LOGICAL       "L"
#Define T_CURRENCY      "Y"
#Define T_UNDefineD     "U"
#Define T_INTEGER       "N"
#Define T_VARCHAR       "C"
#Define T_VARBINARY     "Q"
#Define T_BLOB          "W"

*!* Button parameter masks
#Define BUTTON_LEFT     1
#Define BUTTON_RIGHT    2
#Define BUTTON_MIDDLE   4

*!* Function Parameters
*!* MessageBox parameters
#Define MB_OK                   0       && OK button only
#Define MB_OKCANCEL             1       && OK and Cancel buttons
#Define MB_ABORTRETRYIGNORE     2       && Abort, Retry, and Ignore buttons
#Define MB_YESNOCANCEL          3       && Yes, No, and Cancel buttons
#Define MB_YESNO                4       && Yes and No buttons
#Define MB_RETRYCANCEL          5       && Retry and Cancel buttons

#Define MB_ICONSTOP             16      && Critical message
#Define MB_ICONQUESTION         32      && Warning query
#Define MB_ICONEXCLAMATION      48      && Warning message
#Define MB_ICONINFORMATION      64      && Information message

#Define MB_APPLMODAL            0       && Application modal message box
#Define MB_DEFBUTTON1           0       && First button is default
#Define MB_DEFBUTTON2           256     && Second button is default
#Define MB_DEFBUTTON3           512     && Third button is default
#Define MB_SYSTEMMODAL          4096    && System Modal

*!* MousePointer
#Define MOUSE_DEFAULT           0       && 0 - Default
#Define MOUSE_ARROW             1       && 1 - Arrow
#Define MOUSE_CROSSHAIR         2       && 2 - Cross
#Define MOUSE_IBEAM             3       && 3 - I-Beam
#Define MOUSE_ICON_POINTER      4       && 4 - Icon
#Define MOUSE_SIZE_POINTER      5       && 5 - Size
#Define MOUSE_SIZE_NE_SW        6       && 6 - Size NE SW
#Define MOUSE_SIZE_N_S          7       && 7 - Size N S
#Define MOUSE_SIZE_NW_SE        8       && 8 - Size NW SE
#Define MOUSE_SIZE_W_E          9       && 9 - Size W E
#Define MOUSE_UP_ARROW          10      && 10 - Up Arrow
#Define MOUSE_HOURGLASS         11      && 11 - Hourglass
#Define MOUSE_NO_DROP           12      && 12 - No drop
#Define MOUSE_HIDE_POINTER      13      && 13 - Hide Pointer
#Define MOUSE_ARROW2            14      && 14 - Arrow
#Define MOUSE_CUSTOM            99      && 99 - Custom

