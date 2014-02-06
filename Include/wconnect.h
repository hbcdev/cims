************************************************************************
* WCONNECT Header File
**********************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1997
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 02/09/97
***  Function: Global DEFINEs used by Web Connection.
***             
*** IMPORTANT: Any changes made here require a recompile of
***            all files that use this header file! I suggest
***            you build a project for this purpose and include
***            all files used for CGI processing purposes
************************************************************************

*** System Defines
#define WWVERSION "Version 2.73"
#define WWVERSIONDATE "March 12, 1998"

*** Set this flag when running an OLE server
*** Determines whether results are passed back as a string
#define OLESERVER .f.

*** DEBUGMODE effects how errors are handled.
*** If .T. errors are not handled and the server stops on
*** offending line of code. If .F. the Web Connection 
*** error handlers kick in and provide error pages and logging
#define DEBUGMODE .F. 

*** Machine Type:   1  -  Local Machine
***                 2  -  Production/Online
***                 3  -  Notebook    etc.
***                11  -  Remote Server
#define LOCALSITE 1

*** Set this flag to .T. if you want the server window
*** to run as an SDI form on the Windows Desktop.

#define SERVER_IN_DESKTOP .F.

*** Specify VFP version: 03 or 05 or 06
#define wwVFPVERSION  VAL(SUBSTR(Version(),ATC("FoxPro",VERSION())+7,2))

*** Allow logging of physical path script
#DEFINE LOGSCRIPTNAME .T.

*** Administrator Email Flags - sent on application errors
#define WWC_SENDEMAIL_ONERROR .T.
#define WWC_ADMINISTRATOR_EMAIL "rstrahl@west-wind.com"
#define WWC_MAILSERVER "mail.gorge.net"

#define MAX_INI_BUFFERSIZE  512
#define MAX_INI_ENUM_BUFFERSIZE 8196

*** Maximum String size for the HTMLString Class
#define MAX_STRINGSIZE  2500

*** Special 'NULL' String to differentiate none from empty strings
#define WWC_NULLSTRING "*#*"

*** HTML Class DEFINES ***
#define CR					CHR(13)+CHR(10)
#define MAX_TABLE_CELLS 	1500         && If greater use <PRE> formatted text  

*** New Messaging Flag - .T. - URLEncoded   .F. - INI File
#define POSTDATA         .T.
#define POST_BOUNDARY    CHR(13)+CHR(10)+ "#@$ FORM VARIABLES $@#" + CHR(13)+CHR(10)

*** Web Connection Class #defines for all subclassed classes
*** These DEFINES are used inside of WC to allow easy overriding of classes
*** that aren't at the bottom of the hierarchy. For example to subclass wwHTML
*** and have the changes take in wwHTMLString you need to change the wwHTML class
*** to point at your subclass rather than wwHTML. One change here will adjust the
*** framework in all places.

*** Class Names - These classes are defined here and used in the code
***               so if you subclass an essential class you can change
***               the class used here to your subclass
#define WWC_wwServer 		wwServer
#define WWC_wwOLEServer 	wwOLEServer

*** If you override the wwHTML classes with your own subclasses
*** change the class names here for filebased and OLE messaging
#define WWC_wwHTML			wwHTML
#define WWC_wwHTMLString	wwHTMLString

#define WWC_wwEval 			wwEval
#define WWC_wwHTMLControl 	wwHTMLControl
#define WWC_WWSESSION 		wwSession
#define WWC_WWVFPSCRIPT     wwVFPScript

*** Class Include flags - Use these to make the install lighter   -  New 07/05/97
#define WWC_LOAD_DYNAMICHTML_FORMRENDERING  .T. 
#define WWC_LOAD_WWSESSION 					.T.
#define WWC_LOAD_WWBANNER 					.T.
#define WWC_LOAD_WWDBFPOPUP 				.T.
#define WWC_LOAD_WWIPSTUFF 					.T.
#define WWC_LOAD_WWVFPSCRIPT 				.T.

*** VERSION CONSTANTS
#define ENTERPRISE .T.
#define SHAREWARE .F.    
#define SWTIMEOUT 1800    && Shareware Timeout 1800 secs - 1/2 hour
#define HTMLCLASSONLY .F.

#define FOXISAPI .F.

*** wwHTMLForm options

*** Images in forms are pathed relative to the Web request
*** and must be located in the directory specified here
#define WWFORM_IMAGEPATH "formimages/"

*** wwList ActiveX Control settings - Changed 10/20/97
*#define WWLIST_CLASSID "36E500EB-8219-11D1-A398-00600889F23B"
#define WWLIST_CLASSID "DCECEE2C-C8D4-11D1-A42F-00600889F23B"
#define WWLIST_CODEBASE "wwCTLS.cab"


*** API Constants etc. 

*** Registry roots 
#define HKEY_CLASSES_ROOT           -2147483648  && (( HKEY ) 0x80000000 )
#define HKEY_CURRENT_USER           -2147483647  && (( HKEY ) 0x80000001 )
#define HKEY_LOCAL_MACHINE          -2147483646  && (( HKEY ) 0x80000002 )
#define HKEY_USERS                  -2147483645  && (( HKEY ) 0x80000003 )

*** Success Flag
#define ERROR_SUCCESS               0

*** Registry Value types
#define REG_NONE					0    && Undefined Type (default)
#define REG_SZ						1	 && Regular Null Terminated String
#define REG_BINARY					3    && ??? (unimplemented) 
#define REG_DWORD					4    && Long Integer value
#define MULTI_SZ					7	 && Multiple Null Term Strings (not implemented)


*** wwIPStuff/WinINET Constants
#define INTERNET_OPEN_TYPE_PRECONFIG    		0
#define INTERNET_OPEN_TYPE_DIRECT       		1
#define INTERNET_OPEN_TYPE_PROXY                3

#define INTERNET_OPTION_CONNECT_TIMEOUT         2
#define INTERNET_OPTION_CONNECT_RETRIES         3
#define INTERNET_OPTION_DATA_SEND_TIMEOUT       7
#define INTERNET_OPTION_DATA_RECEIVE_TIMEOUT    8
#define INTERNET_OPTION_LISTEN_TIMEOUT          11

#define INTERNET_DEFAULT_HTTP_PORT      		80       
#define INTERNET_DEFAULT_HTTPS_PORT   		  	443
#define INTERNET_SERVICE_HTTP         			3

#define INTERNET_FLAG_RELOAD            		2147483648
#define INTERNET_FLAG_SECURE            		8388608 

#define ERROR_INTERNET_EXTENDED_ERROR           12003


#define FORMAT_MESSAGE_FROM_SYSTEM     			4096
#define FORMAT_MESSAGE_FROM_HMODULE    			2048

