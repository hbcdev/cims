**************************************************************
*** This program file consists of two classes:
***
***     wwEval        -  Single statement Evaluation routine
***     wwCodeBlock   -  Multiple command 'program' evaluation
***                      routine. This class is really 
***                      Randy Pearson's CodeBlock class
***                      renamed here for consistency with 
***                      Web Connection
*************************************************************
#INCLUDE Include\WCONNECT.H

*************************************************************
DEFINE CLASS wwEval AS RELATION
*************************************************************
***    Author: Rick Strahl
***            (c) West Wind Technologies, 1996
***   Contact: (541) 386-2087  / rstrahl@west-wind.com
***  Modified: 05/01/96
***  Function: Evaluation Class used to safely execute
***            evaluation strings and test for error
*************************************************************

*** Custom Properties
lError=.F.
nError=0
cResultType="C"
vErrorResult="Error"
Result=""

*** These properties are specific to executing
*** Code Block 
oCodeBlock=.Null.
nErrorLine=0
cErrorCode=""
cErrorMessage=""


*** Stock Properties

************************************************************************
* wwEval :: Evaluate
*********************************
***  Function: Actually evaluates expression.
***      Pass: lcExpression  -  Expression to evaluate
***    Return: Result
************************************************************************
FUNCTION Evaluate
LPARAMETERS lcEvalString

THIS.lError=.F.

THIS.Result=EVALUATE(lcEvalString)

IF THIS.lError  && OR TYPE("THIS.Result")#THIS.cResultType
   THIS.lError=.T.
   THIS.cErrorMessage=Message()+ " - " + Message(1) 
   RETURN THIS.vErrorResult
ENDIF   
   
RETURN THIS.Result
* Evaluate

************************************************************************
* wwEval :: ExecuteClassMethod
*********************************
***  Function:
***    Assume:
***      Pass:
***    Return:
************************************************************************
FUNCTION EvaluateClassMethod
LPARAMETERS lcClass, lcMethod, lcClassLib
LOCAL loObject

THIS.lError=.F.

IF !EMPTY(lcClass) AND !EMPTY(lcMethod)
   IF EMPTY(lcClassLib)
      loObject=CreateObject(lcClass)
    ELSE      
      #IF wwVFPVersion > 5
        loObject=NewObject(lcClass,lcClassLib)
      #ELSE
        SET CLASSLIB TO (lcClassLib) ADDITIVE
        loObject=CreateObject(lcClass)
      #ENDIF
    ENDIF
ENDIF    

lcEvalString= "loObject."+lcMethod + IIF( ATC( "(",lcMethod)>0,"","()")
THIS.Result=EVALUATE(lcEvalString)

IF THIS.lError  && OR TYPE("THIS.Result")#THIS.cResultType
   THIS.cErrorMessage=Message()+ " - " + Message(1) 
   RETURN THIS.vErrorResult
ENDIF   

RETURN THIS.Result
ENDFUNC
* wwEval :: EvaluateClassMethod

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
LOCAL lnLoc1,lnLoc2,lnIndex, lcEvalText, lcExtractText, lcOldError, ;
   lnErrCount, lcType,lcResult
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
THIS.SetResultType("C")
THIS.SetErrorResult("")

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

         THIS.lError = .F.
         IF llNoASPSyntax
            lcResult = EVALUATE(lcExtractText)
            IF THIS.lError
               lcResult = THIS.cErrorResult
            ELSE
               #IF wwVFPVersion > 5
                  IF VARTYPE(lcResult) # "C"
                     lcResult = TRANSFORM(lcResult)
                  ENDIF
               #ELSE
                  IF TYPE("lcResult") # "C"
                     lcResult = TRANSFORM(lcResult,"")
                  ENDIF
               #ENDIF
            ENDIF
         ELSE
            *** ASP Syntax allows for <%= Expression %> <% CodeBlock %>
            IF  lcExtractText = "="
               lcResult = EVALUATE(SUBSTR(lcExtractText,2))
               IF !THIS.lError
                  #IF wwVFPVersion > 5
                     IF VARTYPE(lcResult) # "C"
                        lcResult = TRANSFORM(lcResult)
                     ENDIF
                  #ELSE
                     IF TYPE("lcResult") # "C"
                        lcResult = TRANSFORM(lcResult,"")
                     ENDIF
                  #ENDIF
               ENDIF
            ELSE
               THIS.Execute(lcExtractText)
               lcResult = THIS.cResult
               #IF wwVFPVersion > 5
                  IF VARTYPE(lcResult) # "C"
                #ELSE
                  IF TYPE("lcResult") # "C"
                #ENDIF
                     lcResult = ""
                  ENDIF
               ENDIF
            ENDIF

            IF !THIS.lError AND !plEvalError
               *** Now translate and evaluate the expression
               *** NOTE: Any delimiters contained in the evaluated
               ***       string are discarded!!! Otherwise we could end
               ***       up in an endless loop...
               tcString= STRTRAN(tcString,tcDelimiter+lcExtractText+tcDelimiter2,;
                  TRIM(lcResult))
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
 ENDFUNC
 *EOF MergeText


************************************************************************
* wwEval :: Execute
*********************************
***  Function: Executes a block of code using Randy Pearson's CodeBlock
***            class.
***      Pass: lcCode   -   Any block of Visual FoxPro code.
***    Return: Result of the code
************************************************************************
FUNCTION Execute
LPARAMETERS lcCode

IF TYPE("THIS.oCodeBlock")#"O"
   THIS.oCodeBlock=CREATE("cusCodeBlock")
ENDIF

THIS.lError=.F.
THIS.nErrorLine=0
THIS.cErrorCode=""
THIS.cErrorMessage=""

*** Have to update the Error Result as pass through
THIS.oCodeBlock.xErrorReturn=THIS.vErrorResult
*THIS.oCodeBlock.SetAltMergeFunction( "MergeText" )
THIS.Result=THIS.oCodeBlock.Execute(lcCode)

IF THIS.oCodeBlock.lError  && OR TYPE(THIS.Result)#THIS.cResultType
   THIS.lError=.T.
   THIS.nError=THIS.oCodeBlock.nError 
   THIS.nErrorLine=THIS.oCodeBlock.nLinePointer - 1
   THIS.cErrorCode=THIS.oCodeBlock.cLineOfCode
   THIS.cErrorMessage=THIS.oCodeBlock.cErrorMessage
   RETURN THIS.vErrorResult
ENDIF   
   
RETURN THIS.Result
* Execute

************************************************************************
* wwEval :: ExecutePRG
*********************************
***  Function: Executes a program by dumping it to a PRG and then
***            running the PRG file.
***    Assume: Works only in the Development version of Web Connection
***            but is significantly faster on larger code blocks
***      Pass: lcCode   -   Code to run
***            llNoDeleteFiles    Leave FXP in place
************************************************************************
FUNCTION ExecutePRG
LPARAMETER lcExtractTxt, lcFileName, llNoDeleteFile
LOCAL lcFilename

THIS.lError=.F.

lcFilename=IIF(EMPTY("lcFilename"),SYS(2015),lcFilename)

*** Store text to a file
=File2Var(lcFileName+".PRG",lcExtractTxt)
          
*** Run the Program - NOTE: Must return Character expression!
THIS.Result=EVALUATE(lcFileName+"()")            

IF !llNoDeleteFile
  ERASE(lcFileName+".PRG")
  ERASE(lcFileName+".FXP")
ENDIF
ERASE(lcFileName+".ERR")

IF THIS.lError  && OR TYPE("THIS.Result")#THIS.cResultType
   THIS.lError=.T.
   THIS.cErrorMessage=Message()+ " - " + Message(1) 
   THIS.nErrorCode=Error()
   RETURN THIS.vErrorResult
ENDIF   

RETURN THIS.Result
* ExecutePRG

************************************************************************
* wwEval :: SetResultType
*********************************
***  Function: Set the Result Type for the Evaluated expression.
***      Pass: lcType -   Valid FoxPro Type
***    Return: nothing
************************************************************************
FUNCTION SetResultType
LPARAMETERS lcType
lcType=IIF(type("lcType")="C",UPPER(lcType),"C")
THIS.cResultType=lcType
ENDFUNC
* SetResultType

************************************************************************
* wwEval :: SetErrorResult
*********************************
***  Function: Set the Default value that is returned if the Eval
***            fails.
***      Pass: lvErrorResult   -   Result value to assign
***    Return: nothing
************************************************************************
FUNCTION SetErrorResult
LPARAMETERS lvErrorResult
THIS.vErrorResult=lvErrorResult
ENDFUNC
* SetErrorResult

************************************************************************
* wwEval :: IsError
*********************************
***  Function: Returns error status of previous eval operation
***    Return: .T. or .F.
************************************************************************
FUNCTION IsError
RETURN THIS.lError
* IsError

************************************************************************
* wwEval :: GetErrorNumber
*********************************
***  Function: Returns the error number of the previous eval operation
***            if an error occurred.
***    Return: Error number or 0
************************************************************************
FUNCTION GetErrorNumber
IF !THIS.lError
   RETURN 0
ENDIF
RETURN THIS.nError  
* GetErrorNumber


*#IF !DEBUGMODE

************************************************************************
* wwEval :: Error
*********************************
***  Function: Traps Evaluation error, sets error flag and error number
************************************************************************
FUNCTION ERROR
LPARAMETER nError, cMethod, nLine

THIS.lError=.T.
THIS.nError=nError
THIS.nErrorLine=nLine
ENDFUNC
* Error

*#ENDIF

ENDDEFINE
*EOC wwEval

#IF .T.

* CdBlkCls.PRG : Code Block Class
*
* Author: Randy Pearson ( RandyP@cycla.com )
* Public Domain
* Purpose: Executes un-compiled, structured FoxPro code 
*   at runtime.
*
* General Strategy:
*   If code were all simple "in-line" code (no SCAN, DO, etc.),
*   it is easy to run uncompiled by simply storing each line to
*   a memory variable and then macro substituting each line.
*
*   Thus, we adopt that approach, but when we encounter any control
*   structure, we capture the actual code block within the structure,
*   create an artificial simulation of the structure, and pass the
*   internal code block recursively to this same routine.  Nesting
*   is handled automatically by this approach.
*
* Limitations: 
*   - Does not support embedded subroutines (PROC or FUNC)
*     within code passed.
*     Performs implied RETURN .T. if subroutine found.
*     To use UDF's, capture each PROC/FUNC as its own code
*     block and call CODEBLCK repeatedly as needed.
*   - Doesn't accept TEXT w/ no ENDTEXT (although FP doc's
*     suggest that this is acceptable to FP.
*   - Does not support FOR EACH..ENDFOR. See notes on why in
*     Execute() method.

* Notes:
*   If your code block begins with a semicolon ";", the block is
*   assumed to be a dBW-style code block, and all semicolons are
*   translated to Cr-Lf pairs for the execution in this routine.
*   (Existing code in files is not altered.)
*
*   You may want to SET TALK OFF when testing this program (either
*   from the Command Window or in your code block).

* ------------------------------------------------------------- *
* KEY NOTES about RETURN VALUES <-- IMPORTANT, PLEASE READ!!
*
*!*	The class can *return* a value if you call the Execute() method
*!*	as a function. The actual value returned is dependent on 3 factors:

*!*	1. did an error occur running the code?
*!*	2. did you specify a special return value to use in error conditions?
*!*	3. did the code itself include a RETURN statement?

*!*	IF an error occurred
*!*		IF you specified an error return value (property Result)
*!*			RETURN THIS.Result
*!*		ELSE
*!*			RETURN .F.
*!*		ENDIF
*!*	ELSE no error occurred
*!*		IF code included a RETURN statement that was executed
*!*			RETURN that value (or .T. if a plain "RETURN")
*!*		ELSE 
*!*			RETURN .T.
*!*		ENDIF
*!*	ENDIF

* ------------------------------------------------------------- *

* I - MINIMUM CALLING SYNTAX EXAMPLE
* ==================================
** SETUP: Ensure this class is available in memory. If using this file
**   natively you must:
**
**   SET PROCEDURE TO CdBlkCls.PRG ADDITIVE
**
** If using the wwEval class with West-Wind Web Connection, all you
** need is for WWEVAL.PRG to be included (which it is by default).

*!*	LOCAL oCode
*!*	oCode = CREATEOBJECT( "cusCodeBlock")
*!*	* Assumes this class is already loaded into memory via
*!*	* SET PROCEDURE or equivalent.

*!*	oCode.SetCodeBlock( MyTable.MyMemoField )
*!*	* Whatever you pass has structured FoxPro code.
*!*   * This could also be a memory variable.

*!*	oCode.Execute()
*!*   RELEASE oCode

* II - DEALING WITH ERRORS IN THE CODE
* ====================================
* To pre-establish the RETURN value should an error arise,
* use the "xErrorReturn" Property:

*!*	LOCAL oCode, nResult
*!*	oCode = CREATEOBJECT( "cusCodeBlock")
*!*	oCode.xErrorReturn = -1  && can be any type
*!*	oCode.SetCodeBlock( MyTable.MyMemoField )
*!*	nResult = oCode.Execute()
*!*	RELEASE oCode
*!*	IF nResult = -1
*!*		= MessageBox( ...
*!*	ENDIF

* Instead, you could also just check to see if an error occurred by 
* looking at a few properties afterward:

*!*	LOCAL oCode
*!*	oCode = CREATEOBJECT( "cusCodeBlock")
*!*	oCode.SetCodeBlock( MyTable.MyMemoField )
*!*	oCode.Execute()
*!*	IF oCode.lError
*!*		= MessageBox( "NOTE: " + oCode.cErrorMessage + " occurred.", ...)
*!*	ENDIF
*!*	RELEASE oCode

* Of course, combinations of the above can be used.

* III - PREVENTING ACCESS TO DANGEROUS COMMANDS <== NEW !!
* =============================================
* There are some commands I won't even try to let the program 
* execute. These include CLEAR ALL and CLOSE ALL. There are also
* some commands that you normally won't want to provide access to,
* except in certain circumstances. The *default* ones that are
* precluded are:
*
*  QUIT
*  CANCEL
*  THIS.  (since you will be referring to cusCodeBlock class not your own!)
*
* To ADD another command to the disallowed list, use the 
* AddIllegalCommand() Method, e.g.:
*
*!*	* Before calling the Execute() method:
*!*	oCode.AddIllegalCommand( "ZAP")

* To instead DROP on of the restrictions that I have added (or that you
* have added to the Init() method in a sub-class), use the
* DropIllegalCommand() Method, e.g.:

*!*	* Before calling the Execute() method:
*!*	oCode.DropIllegalCommand( "QUIT")

* IV - CODE CONTAINED IN FILES
* ============================
* If your code is in a file (perhaps a non-compiled PRG), you 
* can either extract it yourself to a memo field or variable;
* or you can use the Method: SetCodeBlockFromFile( pcFileSpec).

* V - SPECIAL "TESTING" MODE
* ==========================
* You can test the structure of your code without executing any
* non-structured code (i.e, all the stuff between DO..ENDDO,
* FOR..ENDFOR, etc., by setting the following property before
* calling the Execute() method:
*
*!*	oCode.lDontExecute = .T.

* Record of Revision
* ==================
* TO DO STILL
*  - Support for FOR EACH [ After much thought, this may not be practical. ]

* 04/24/1997
*  - Changed Public Domain file name to CDBLKCLS.PRG for 
*    compatibility with 8.3 naming for file download and PKZIP purposes.
*
*  - Fixed problem where lines greater than 254 characters
*    within control structures were causing problems. 2nd
*    parameter added to _0_q_Line() function to differentiate
*    call from Block() constructor.
*
*  - Renamed 2 properties for consistency with West-Wind
*    Web Connection wwEval class:
*    1. "xReturnValue" renamed to "Result"
*    2. "xErrorReturnValue" renamed to "xErrorReturn"
*    (Neither of above is relevant if you use the preferred
*    methods such as SetErrorReturnValue().)

* 11/18/1996
*  - Added LPARAMETER to Execute() method that allows direct 
*    passing of code block.
*  - Added Method Release().
*  - Added Property "cReturnType" and method SetReturnType().
*    If return value is not of this type ("X" or empty = 
*    any type OK), an error is flagged and xErrorReturn is 
*    substituted.
*  - Changed LPARAMETER names to start with "t" prefix.
*  - Added property nErrorRecursionLevel that stores nRecursionLevel
*    at which an error occurred.
*  - Added method SetErrorReturnValue().
*  - Added 5 optinal Lparameters to Init() to allow direct in-line
*    call via CreateObject().
* ------------------------------------------------------------- *

DEFINE CLASS cusCodeBlock AS Custom

* ------------------------------------------------------------- *
* Constants:
* ------------------------------------------------------------- *
#DEFINE dnMaxLineWidth  254
#DEFINE CrLf            CHR(13)+CHR(10)

* ------------------------------------------------------------- *
* Properties:
* ------------------------------------------------------------- *

*!*	Note: It may ultimately be desireable to PROTECT
*!*	some of the following, but their omission from 
*!*	the Locals Window when doing so makes debugging
*!*	much harder!

*!*	PROTECTED ;
*!*		cLastExact, ;
*!*		nLastMemoWidth, ;
*!*		nCodeLines, ;
*!*		nLinePointer, ;
*!*		cLineOfCode, ;
*!*		cUpperCaseLine, ;
*!*		cExpression, ;
*!*		nCounter, ;
*!*		nAtPos, ;
*!*		oChild, ;
*!*		cChildBlock, ;
*!*		aIllegal[ 1, 2]

cLastExact      = SET( "EXACT")
nLastMemoWidth  = SET( "MEMOWIDTH")

nCodeLines      = 0      && MEMLINES() of code in original block
cCodeBlock      = ""     && block to execute, set by SetCodeBlock()
nLinePointer    = 1      && pointer to MLINE() of next line to process
cLineOfCode     = ""     && current line of code to process
cUpperCaseLine  = ""     && upper case of above

lPreEval        = .T.    && attempt to avoid VFP errors by pre-EVAL()s, can be overridden
lDontExecute    = .F.    && set to TRUE while testing to verify structure w/o running
                         && and non-structured code

cExpression     = ""     && [internal control variable]
nCounter        = 0      && [internal control variable]
nAtPos          = 0      && [internal control variable]

nRecursionLevel = 0      && depth of recursive calls 
oChild          = NULL   && object reference to recursive cusCodeBlock (child) object
cChildBlock     = ""     && code to be executed in recursive call

Result          = .T.    && used internally to establish RETURN value
xErrorReturn    = .F.    && value to RETURN if an error occurs (default .F.)
cReturnType     = "X"    && Type-check of return value. (X = any, can be multiple, i.e. "DT")

cExitCode       = ""     && [internal control variable]

DIMENSION aIllegal[ 1, 2]
aIllegal[ 1, 2] = .F.    && array of optional illegal commands to cause code abort

DIMENSION aWith[ 1]
aWith[ 1]       = ""     && array of WITH arguments, stored as a stack
nWith           = 0      && stack counter

lError          = .F.    && did error occur flag
nError          = 0      && VFP error (1089, user-defined, when program detects error)
cErrorMethod    = ""     && method in which VFP error occurred
nErrorLine      = 0      && line # of code in which VFP error occurred
cErrorMessage   = ""     && error message
cErrorCode      = ""     && errant line of code, or similar message
nErrorRecursionLevel = 0 && level of recursion at whoch error occurred
* ------------------------------------------------------------- *
* Methods:
* ------------------------------------------------------------- *

FUNCTION Init( tcCode, txReturnValue, txErrorReturnValue, ;
	tcReturnType, tlNoRelease)
* None of the LPARAMETERS are normally used, but this allows
* single line call to this class.

* Create default set of illegal commands:
THIS.AddIllegalCommand( "QUIT")
THIS.AddIllegalCommand( "CANC")
THIS.AddIllegalCommand( "THIS.")

* KEY NOTE: All of remaining code in Init() is for people that 
*   want to call CodeBlock all in 1 line within the CreateObject()
*   function. This is supported, but not recommended since it is
*   less flexible than some of the approaches discussed in the 
*   notes above.
*
*   Example call this way: 
*
*     = CreateObject( "cusCodeBlock", MyTable.MyMemo, ;
*             @lnReturnVal, -1, "NI", .F.)
*
IF PCOUNT() > 0
	* 1) establish code block
	IF NOT EMPTY( m.tcCode) AND TYPE( "m.tcCode") == "C"
		THIS.SetCodeBlock( m.tcCode)
	ENDIF

	IF PCOUNT() >= 2
		* 2) Fill in default RETURN value.
		THIS.Result = m.txReturnValue
	
		* 3) Deal with ErrorReturnValue, if specified.
		IF PCOUNT() >= 3
			THIS.SetErrorReturnValue( m.txErrorReturnValue)
		ENDIF
	
		* 4) Deal with forced RETURN type, if specified.
		IF PCOUNT() >= 4
			IF TYPE( "m.tcReturnType") == "C"
				THIS.SetReturnType( m.tcReturnType)
			ENDIF
		ENDIF
	ENDIF

	* 5) Run code block:
	THIS.Execute()
	
	* 6) Store return value back to parameter variable.
	IF PCOUNT() >= 2
		m.txReturnValue = THIS.Result
		* For this to be helpful, pass txReturnValue by reference.
	ENDIF

	* 7) Release object, unless requested otherwise (for example
	*    to investigate error parameters).
	IF NOT m.tlNoRelease
		* By default, release object when we call class with 
		* CreateObject() parameters.
		RETURN .F.
	ENDIF
ENDIF

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION Release()

RELEASE THIS

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION Execute( tcCode)
*
* Executes the code block residing in property "cCodeBlock".
*
* Attempts to return a value based on numerous factors, including
* whether any error occurred. (See note at top about return values.)
*
* LPARAMETERS tcCode
* Normally, this is "set" via SetCodeBlock(), but this allows direct call.
IF NOT EMPTY( m.tcCode) AND TYPE( "m.tcCode") == "C"
	THIS.SetCodeBlock( m.tcCode)
ENDIF

LOCAL _0_qcMacroSubstitutionString
* Make variable name as obscure as possible, to minimize possibility
* of conflict with variable name in code to be executed.

* Critical that these properties be reset, in case same class
* handle is used to execute more than 1 blocks of code:
*
THIS.lError = .F.
THIS.cExitCode = ""
THIS.nLinePointer = 1

THIS.nLastMemoWidth = SET( "MEMOWIDTH")
SET MEMOWIDTH TO dnMaxLineWidth
THIS.nCodeLines = MEMLINES( THIS.cCodeBlock)
SET MEMOWIDTH TO THIS.nLastMemoWidth

DO WHILE THIS.nLinePointer <= THIS.nCodeLines AND ;
	NOT THIS.lError
	*
	THIS.GetNextLine()
	THIS.cUpperCaseLine = UPPER( THIS.cLineOfCode)
	
	DO CASE
	CASE EMPTY( THIS.cLineOfCode)
		* Not supposed to happen unless we're past
		* end of code. (Could try an assertion here someday.)
		LOOP
		
	CASE PADR( THIS.cUpperCaseLine, 5) == "WITH "
		* We don't "do" WITH's, we store argument in stack and
		* apply them to subsequent lines of code.
		THIS.nWith = THIS.nWith + 1
		DIMENSION THIS.aWith[ THIS.nWith]
		THIS.aWith[ THIS.nWith] = ALLTRIM( SUBSTR( THIS.cLineOfCode, 5))
		LOOP
		
	CASE PADR( THIS.cUpperCaseLine, 4) == "ENDW"
		* ENDWITH - see note above on WITH
		THIS.nWith = MAX( 0, THIS.nWith - 1)
		IF THIS.nWith = 0
			DIMENSION THIS.aWith[ 1]
			THIS.aWith[ 1] = ""
		ELSE
			DIMENSION THIS.aWith[ THIS.nWith]
		ENDIF
		LOOP
		
	CASE PADR( THIS.cUpperCaseLine, 8) == "DO WHILE"
		_0_qcMacroSubstitutionString = SUBSTR( THIS.cLineOfCode, 9)
		* portion after DO WHILE
		
		IF THIS.lPreEval
			* check if logical value before going on
			IF TYPE( m._0_qcMacroSubstitutionString) <> "L"
				THIS.SetError( "DO WHILE expression did not evaluate to TRUE/FALSE.", ;
					THIS.cLineOfCode)
				EXIT
			ENDIF
		ENDIF
		
		* Extract all code between DO WHILE and ENDDO.  Place in 
		* property "cChildBlock" in preparation for recursive
		* call to this class:
		= THIS.GetChildBlock( 'DO WHILE')
		
		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF
		
		* Simulate original DO WHILE block by re-constructing it
		* here with a recursive call to this class for the code
		* inside the language structure:
		*
		DO WHILE &_0_qcMacroSubstitutionString
			IF NOT EMPTY( THIS.cChildBlock)
				* Call child instance of this class recursively:
				THIS.oChild = CREATEOBJECT( "cusCodeBlock")
				THIS.PassThroughProperties()
				THIS.Result = THIS.oChild.Execute()
				THIS.cExitCode = THIS.oChild.cExitCode

				IF THIS.oChild.lError
					* Error occurred in recursive call--store the parameters
					* back to calling object so that error parameters are
					* eventually available to the object that called the
					* top level cusCodeBlock class:
					THIS.BubbleErrorParameters()
				ENDIF

				THIS.oChild = NULL
			ENDIF

			IF NOT EMPTY( THIS.cExitCode)
				IF THIS.cExitCode = 'LOOP'
					THIS.cExitCode = SPACE(0)
					LOOP
				ENDIF
				IF THIS.cExitCode = 'EXIT'
					THIS.cExitCode = SPACE(0)
				ENDIF
				EXIT
			ENDIF
		ENDDO

	CASE PADR( THIS.cUpperCaseLine, 4) == "SCAN"
		_0_qcMacroSubstitutionString = ;
			IIF( ALLTRIM( THIS.cUpperCaseLine) == "SCAN", ;
			SPACE(0), ALLTRIM( SUBSTR( THIS.cLineOfCode, 5)))

		* Extract all code between SCAN and ENDSCAN.  Place in 
		* property "cChildBlock" in preparation for recursive
		* call to this class:
		= THIS.GetChildBlock( 'SCAN')

		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF
		
		SCAN &_0_qcMacroSubstitutionString
			IF NOT EMPTY( THIS.cChildBlock)
				* Call child instance of this class recursively:
				THIS.oChild = CREATEOBJECT( "cusCodeBlock")
				THIS.PassThroughProperties()
				THIS.Result = THIS.oChild.Execute()
				THIS.cExitCode = THIS.oChild.cExitCode
				
				IF THIS.oChild.lError
					* Error occurred in recursive call--store the parameters
					* back to calling object so that error parameters are
					* eventually available to the object that called the
					* top level cusCodeBlock class:
					THIS.BubbleErrorParameters()
				ENDIF
				
				THIS.oChild = NULL
			ENDIF

			IF NOT EMPTY( THIS.cExitCode)
				IF THIS.cExitCode = 'LOOP'
					THIS.cExitCode = SPACE(0)
					LOOP
				ENDIF
				IF THIS.cExitCode = 'EXIT'
					THIS.cExitCode = SPACE(0)
				ENDIF
				EXIT
			ENDIF
		ENDSCAN

	CASE PADR( THIS.cUpperCaseLine, 8) == "FOR EACH"
		* Still working on this!
		* BUG in VFP prevents using macro substitution on this command.
		* Major difficulties would be encountered to support this. Here
		* are some points:
		*  - must be supported by simulating a regular FOR..ENDFOR
		*  - create property for copy of array
		*  - must deal with changes made to array within the loop
		*  - create property for first element (the "ii" in after FOR EACH ii)
		*  - must parse out all existence of the first element and array
		*    name in child block and translate to THIS.<new_properties>
		*  - must support *nested* FOR EACH (yuck)
		* This seems much too complex and not worth it, for now.
		THIS.SetError( "Sorry, FOR EACH..ENDFOR structure is not yet supported.", ;
			THIS.cLineOfCode )
		EXIT

	CASE PADR( THIS.cUpperCaseLine, 3) == "FOR"
		
		_0_qcMacroSubstitutionString = SUBSTR( THIS.cLineOfCode, 4)
		* all after word "FOR" 

		* Extract all code between FOR and ENDFOR.  Place in 
		* property "cChildBlock" in preparation for recursive
		* call to this class:

		= THIS.GetChildBlock( 'FOR')

		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF
		
		* Simulate original FOR..ENDFOR block:
		FOR &_0_qcMacroSubstitutionString

			IF NOT EMPTY( THIS.cChildBlock)
				* Call child instance of this class recursively:
				THIS.oChild = CREATEOBJECT( "cusCodeBlock")
				THIS.PassThroughProperties()
				THIS.Result = THIS.oChild.Execute()
				THIS.cExitCode = THIS.oChild.cExitCode
				
				IF THIS.oChild.lError
					* Error occurred in recursive call--store the parameters
					* back to calling object so that error parameters are
					* eventually available to the object that called the
					* top level cusCodeBlock class:
					THIS.BubbleErrorParameters()
				ENDIF
				
				THIS.oChild = NULL
			ENDIF

			IF NOT EMPTY( THIS.cExitCode)
				IF THIS.cExitCode = 'LOOP'
					THIS.cExitCode = SPACE(0)
					LOOP
				ENDIF
				IF THIS.cExitCode = 'EXIT'
					THIS.cExitCode = SPACE(0)
				ENDIF
				EXIT
			ENDIF

		ENDFOR

	CASE PADR( THIS.cUpperCaseLine, 2) == "IF"

		_0_qcMacroSubstitutionString = ALLTRIM( SUBSTR( THIS.cLineOfCode, 3))
		* code after word "IF" in line

		IF THIS.lPreEval
			* check if logical value before going on
			IF TYPE( m._0_qcMacroSubstitutionString) <> "L"
				THIS.SetError( "IF expression did not evaluate to TRUE/FALSE.", ;
					THIS.cLineOfCode)
				EXIT
			ENDIF
		ENDIF
		
		IF &_0_qcMacroSubstitutionString
			* IF expression is TRUE, extract all code between IF and 
			* ELSE (or ENDIF if no ELSE).  Place in property "cChildBlock" 
			* in preparation for recursive call to this class:
			
			= THIS.GetChildBlock( "IF")
		ELSE
			* IF expression is FALSE, extract all code between ELSE and 
			* ENDIF, if any.  Place in property "cChildBlock" 
			* in preparation for recursive call to this class:

			= THIS.GetChildBlock( "ELSE")
		ENDIF

		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF
		
		IF NOT EMPTY( THIS.cChildBlock)
			* Call child instance of this class recursively:
			THIS.oChild = CREATEOBJECT( "cusCodeBlock")
			THIS.PassThroughProperties()
			THIS.Result = THIS.oChild.Execute()
			THIS.cExitCode = THIS.oChild.cExitCode
				
			IF THIS.oChild.lError
				* Error occurred in recursive call--store the parameters
				* back to calling object so that error parameters are
				* eventually available to the object that called the
				* top level cusCodeBlock class:
				THIS.BubbleErrorParameters()
			ENDIF
				
			THIS.oChild = NULL
		ENDIF

	CASE PADR( THIS.cUpperCaseLine, 7) == "DO CASE"

		= THIS.GetChildBlock( "DO CASE")
		* THIS.GetChildBlock() figures out which CASE to use, and stores
		* all code between that CASE and the next CASE or OTHERWISE (or 
		* alternatively after the OTHERWISE if all CASEs are FALSE) in
		* property "cChildBlock" in preparation for recursive call.
		
		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF
		
		IF NOT EMPTY( THIS.cChildBlock)
			* Call child instance of this class recursively:
			THIS.oChild = CREATEOBJECT( "cusCodeBlock")
			THIS.PassThroughProperties()
			THIS.Result = THIS.oChild.Execute()
			THIS.cExitCode = THIS.oChild.cExitCode
				
			IF THIS.oChild.lError
				* Error occurred in recursive call--store the parameters
				* back to calling object so that error parameters are
				* eventually available to the object that called the
				* top level cusCodeBlock class:
				THIS.BubbleErrorParameters()
			ENDIF
				
			THIS.oChild = NULL
		ENDIF
		
	CASE PADR( THIS.cUpperCaseLine, 4) == "TEXT"
		
		* NOTE: Recursion is *not* used for TEXT..ENDTEXT.

		* Get all code between TEXT and ENDTEXT:
		= THIS.GetChildBlock( 'TEXT')

		IF THIS.lError = .T.
			* Syntax error found in child block--can't proceed.
			EXIT
		ENDIF

		THIS.nLastMemoWidth = SET("MEMOWIDTH")
		SET MEMOWIDTH TO dnMaxLineWidth
		
		FOR THIS.nCounter = 1 TO MEMLINES( THIS.cChildBlock)

			* Use TEXTMERGE output command "\" to output each
			* line that existed between TEXT and ENDTEXT:
			
			_0_qcMacroSubstitutionString = ;
				"\" + MLINE( THIS.cChildBlock, THIS.nCounter)
				
			&_0_qcMacroSubstitutionString
		ENDFOR

		SET MEMOWIDTH TO THIS.nLastMemoWidth
		
	CASE PADR( THIS.cUpperCaseLine, 4) == "LOOP"
		* This should only occur in recursive call, since only applies
		* within a control structure (DO WHILE, SCAN, or FOR).  Further,
		* cannot macro substitute these lines since child block is
		* called recursively. Instead we create a code indicating how the
		* block was terminated, and exit back to the simulated control
		* structure. Those structures (above) check for cExitCode's of
		* "LOOP" or "EXIT" and act accordingly.
		
		IF THIS.nRecursionLevel = 0
			THIS.SetError( "LOOP statement not within control structure.", ;
				THIS.cLineOfCode)
			EXIT
		ENDIF
		
		THIS.cExitCode = "LOOP"
		EXIT
		
	CASE PADR( THIS.cUpperCaseLine, 4) == "EXIT"
		* See comment above on "LOOP"--applies exactly to EXIT, too.
		
		IF THIS.nRecursionLevel = 0
			THIS.SetError( "EXIT statement not within control structure.", ;
				THIS.cLineOfCode)
			EXIT
		ENDIF

		THIS.cExitCode = "EXIT"
		EXIT

	CASE THIS.IllegalCommandFound()
		= .F.
		* This method can also set THIS.lError for certain commands.
				
	CASE PADR( THIS.cUpperCaseLine, 9) == "CLEAR ALL" OR ;
		PADR( THIS.cUpperCaseLine, 8) == "CLEA ALL" OR ;
		PADR( THIS.cUpperCaseLine, 10) == "CLEAR MEMO" OR ;
		PADR( THIS.cUpperCaseLine, 9) == "CLEA MEMO" OR ;
		PADR( THIS.cUpperCaseLine, 7) == "RETU TO" OR ;
		PADR( THIS.cUpperCaseLine, 8) == "RETUR TO" OR ;
		PADR( THIS.cUpperCaseLine, 9) == "RETURN TO" OR ;
		PADR( THIS.cUpperCaseLine, 8) == "RELE ALL" OR ;
		PADR( THIS.cUpperCaseLine, 9) == "RELEA ALL" OR ;
		PADR( THIS.cUpperCaseLine, 10) == "RELEAS ALL" OR ;
		PADR( THIS.cUpperCaseLine, 11) == "RELEASE ALL" 
		*
		* These are known to break the system.
		THIS.cExitCode = "ILLEGAL"
		THIS.SetError( "Command not supported: " + THIS.cLineOfCode )
		EXIT

	CASE PADR( THIS.cUpperCaseLine, 4) == "REST" AND ;
		"FROM " $ THIS.cUpperCaseLine AND ;
		NOT "ADDI" $ THIS.cUpperCaseLine
		*
		THIS.SetError( "Can't have RESTORE FROM w/o ADDITIVE.", THIS.cLineOfCode)
		EXIT
		
	CASE INLIST( PADR( THIS.cUpperCaseLine, 4), "PROC", "FUNC")
		* Probably NOT good news, but maybe OK.
		* This program does not support embedded PROC's
		* and FUNC's.  It can only call compiled routines.
		
		THIS.cExitCode = "RETURN"
		
	CASE INLIST( PADR( THIS.cUpperCaseLine, 4), ;
		"ENDS", "ENDD", "ENDF", "ENDI", ;
		"NEXT", "ENDC", "ENDT", "ELSE", "CASE")
		*
		* Nesting error in user's code.
		THIS.nAtPos = AT( SPACE(1), THIS.cUpperCaseLine)
		THIS.cExpression = LEFT( THIS.cUpperCaseLine, ;
			IIF( THIS.nAtPos = 0, 7, THIS.nAtPos - 1))
			
		THIS.SetError( [Nesting Error - "] + THIS.cExpression + ;
			[" statement found, ] + ;
			[but there was no matching beginning statement.])
		EXIT
		
	CASE PADR( THIS.cUpperCaseLine, 4) == "RETU"
		THIS.cExitCode = "RETURN"
		THIS.Result = .T.
		THIS.nAtPos = AT( SPACE(1), THIS.cLineOfCode)
		IF THIS.nAtPos > 0
			_0_qcMacroSubstitutionString = ;
				ALLTRIM( SUBSTR( THIS.cLineOfCode, THIS.nAtPos))
				
			IF NOT EMPTY( m._0_qcMacroSubstitutionString)
				* RETURN <something>
				THIS.Result = EVAL( m._0_qcMacroSubstitutionString)
			ENDIF
		ENDIF
		
	OTHERWISE
		IF EMPTY( THIS.cExitCode)
			* Normal line of code, just do it:
			_0_qcMacroSubstitutionString = THIS.cLineOfCode
			
			IF THIS.nWith > 0 AND ;
				TYPE( "THIS.aWith[ THIS.nWith]") = "C"
				*
				* We're within WITH..ENDWITH, so STRTRAN() as needed first.
				
				_0_qcMacroSubstitutionString = STRTRAN( ;
					_0_qcMacroSubstitutionString, SPACE(1) + ".", ;
					SPACE(1) + THIS.aWith[ THIS.nWith] + ".")
			ENDIF
			
			IF NOT THIS.lDontExecute
				&_0_qcMacroSubstitutionString
			ENDIF
		ENDIF

	ENDCASE

	IF THIS.lError OR NOT EMPTY( THIS.cExitCode)
		* Some error or exit code encountered.
		EXIT
	ENDIF
ENDDO

SET MEMOWIDTH TO THIS.nLastMemoWidth

IF THIS.cExitCode == "ERROR"
	THIS.lError = .T.
ENDIF

IF THIS.nRecursionLevel = 0 AND NOT THIS.lError
	* We're about to return from entire block,
	* perform type-check, if specified:
	IF NOT EMPTY( THIS.cReturnType) AND ;
		NOT "X" $ THIS.cReturnType
		*
		* a specific type is required
		IF NOT TYPE( "THIS.Result") $ UPPER( THIS.cReturnType)
			* incompatible type
			THIS.SetError( "RETURN type did not match requirement. + ", ;
				TYPE( "THIS.Result") + " was attempted, when " + ;
				THIS.cReturnType + " was specified." )
				
			* THIS.Result will be set below, due to THIS.lError flag.
		ENDIF
	ENDIF
ENDIF

IF THIS.lError = .T.
	THIS.Result = THIS.xErrorReturn
ENDIF

RETURN THIS.Result

ENDFUNC

* ------------------------------------------------------------- *

PROTECTED FUNCTION GetNextLine( tcType, tlKeepSemi)
*
* Replaces FUNCTION _0_qLine in CODEBLCK.PRG
*
* Determine next line of code, ignoring comments and
* blank lines. Leave nNextLinePointer pointing to first
* text line *after* next line of code.  Set to null string
* if no code line found to end of block.
*
* Assume nLinePointer : points to line to read
*        nMemoLines   : counts total # of lines
*        cCodeBlock   : contains the total code block
*
* LPARAMETER tcType
* Type of inner most block.  If "TEXT" skip almost 
* all "conditioning" steps and take literally.

THIS.nLastMemoWidth = SET( "MEMOWIDTH")
SET MEMOWIDTH TO dnMaxLineWidth

THIS.cLastExact = SET( 'EXACT')
SET EXACT OFF

THIS.cLineOfCode = SPACE(0)

LOCAL llContinued, lnAtPos, llComment, llText, lcUpper
llContinued = .F.
lnAtPos = 0
llComment = .F.
llText = TYPE( "m.tcType") == "C" AND m.tcType == "TEXT"

DO WHILE THIS.nLinePointer <= THIS.nCodeLines

	SET MEMOWIDTH TO dnMaxLineWidth
	DO CASE
	CASE m.llText
		* Within TEXT...ENDTEXT, leave alone.
		THIS.cLineOfCode = MLINE( THIS.cCodeBlock, THIS.nLinePointer)
		
	CASE m.llContinued
		* 2nd or later line in multi-line
		* statement, attach but don't LTRIM(),
		* since we could be in middle of delimited string.
		THIS.cLineOfCode = THIS.cLineOfCode + TRIM( STRTRAN( ;
			MLINE( THIS.cCodeBlock, THIS.nLinePointer), ;
			CHR(9), SPACE(1)))
			
	OTHERWISE
		* Beginning of new line of normal code, LTRIM
		* any indentation after removing TAB's.
		THIS.cLineOfCode = ALLTRIM( STRTRAN( ;
			MLINE( THIS.cCodeBlock, THIS.nLinePointer), ;
			CHR(9), SPACE(1)))
		
		IF EMPTY( THIS.cLineOfCode) OR ;
			INLIST( LTRIM( THIS.cLineOfCode), "*", "&" + "&", "#")
			* Blank or comment line OR compiler directive.
			* (Can't type 2 &'s together in FoxPro)
			* (Probably if compiler directive, subsequent 
			*  code will fail, but give it a try.)
			THIS.cLineOfCode = SPACE(0)
		ENDIF
	ENDCASE

	SET MEMOWIDTH TO THIS.nLastMemoWidth
	THIS.nLinePointer = THIS.nLinePointer + 1

	IF m.llText
		EXIT
	ENDIF

	IF EMPTY( THIS.cLineOfCode)
		LOOP
	ENDIF
	
	lnAtPos = AT( "&" + "&", THIS.cLineOfCode)
	* Note gymnastics to avoid compile error.
	
	IF m.lnAtPos > 0
		IF LEN( THIS.cLineOfCode) >= m.lnAtPos + 3 AND ;
			SUBSTR( THIS.cLineOfCode, m.lnAtPos, 4) == "&" + "&##"
			* Ignore line - feature retained for compatibility.
			* Allows line of PRG to be skipped by CodeBlock but
			* used by compiler.
			THIS.cLineOfCode = SPACE(0)
			LOOP
		ENDIF

		THIS.cLineOfCode = TRIM( LEFT( THIS.cLineOfCode, m.lnAtPos - 1))
		llComment = .T.
	ELSE
		llComment = .F.
	ENDIF
	
	IF RIGHT( THIS.cLineOfCode, 1) = CHR( 59)
		* Semi-colon.
		IF m.llComment
			* Not allowed on same line!
			THIS.SetError( "Syntax Error: Semi-Colon and double-& on same line.", ;
				THIS.cLineOfCode )
			THIS.cLineOfCode = SPACE(0)
			EXIT
		ELSE
			llContinued = .T.
			IF m.tlKeepSemi
				THIS.cLineOfCode = THIS.cLineOfCode + CrLf
			ELSE
				THIS.cLineOfCode = LEFT( THIS.cLineOfCode, LEN( THIS.cLineOfCode) - 1)
			ENDIF
			
			LOOP
		ENDIF
	ELSE
		* llContinued = .F.
		EXIT
	ENDIF
ENDDO

IF NOT m.llText
	* Re-format line so control structures are easily recognized
	* by main Execute() method.
	
	lcUpper = UPPER( THIS.cLineOfCode)

	IF m.lcUpper = "DO" AND ;
		NOT INLIST( m.lcUpper, "DO WHILE", "DO CASE")
		*
		lcStub = LTRIM( SUBSTR( THIS.cLineOfCode, 3))
		lcUpper = UPPER( m.lcStub)
	
		DO CASE
		CASE INLIST( m.lcUpper, "WHILE", "CASE")
			THIS.cLineOfCode = "DO " + m.lcStub
		CASE m.lcUpper = "WHIL"
			THIS.cLineOfCode = "DO WHILE " + SUBSTR( m.lcStub, 5)
		OTHERWISE
			* Hopefully DO <SomeLegitProcedure>
			* Leave alone.
		ENDCASE
	ENDIF

	IF m.lcUpper = "WITH" AND ;
		INLIST( SUBSTR( m.lcUpper, 5, 1), SPACE(1), CHR(9) )
		*
		* WITH..ENDWITH
		THIS.cLineOfCode = "WITH " + LTRIM( SUBSTR( THIS.cLineOfCode, 5))
	ENDIF

ENDIF [NOT m.llText]

IF THIS.cLastExact == "ON"
	SET EXACT ON
ENDIF

SET MEMOWIDTH TO THIS.nLastMemoWidth

ENDFUNC
* ------------------------------------------------------------- *

PROTECTED FUNCTION GetChildBlock( tcBlockType)
*
* Replace Function _0_qBlock() in CODEBLCK.PRG
*
* Fetch block of code for recursive call, and increment 
* pointer m._0_qnNext to point past end of block (e.g., 
* line after ENDCASE).
*
* LPARAMETER tcBlockType
* {FOR, DO WHILE, IF, ELSE, DO CASE, SCAN, TEXT}

LOCAL lcLastExact
lcLastExact = SET( 'EXACT')
SET EXACT OFF

THIS.cChildBlock = SPACE(0)

LOCAL laBlkStack, lnDepth
DIMENSION laBlkStack[ 1]

IF m.tcBlockType == "ELSE"
	laBlkStack[ 1] = "IF"
ELSE
	laBlkStack[ 1] = m.tcBlockType
ENDIF

lnDepth = 1

LOCAL lcSubstr
LOCAL llSubSect, llTrueCase

llSubSect = NOT INLIST( m.tcBlockType, "ELSE", "DO CASE")
* Flag indicating whether we're within any of the following
* sub-sections of code:
* 1) The *first* CASE that evaluates to .T.
* 2) The OTHERWISE code when *no* CASEs evaluated to .T.
* 3) The code after IF when the IF expression evaluated to .T.
* 4) The code after ELSE when the IF expression evaluated to .F.

* In any of the above instances, the code should be returned.

llTrueCase = .F.
* Flag of whether a .T. case has 
* yet been found (thus don't evaluate 
* further CASE's or process OTHERWISE or ELSE).

DO WHILE NOT THIS.lError
	= THIS.GetNextLine( laBlkStack[ m.lnDepth], .T.)
	IF THIS.lError
		* (Syntax) Error discovered by Line function.
		EXIT
	ENDIF

	IF EMPTY( THIS.cLineOfCode) AND ;
		NOT laBlkStack[ m.lnDepth] == "TEXT"
		*
		* Syntax Error
		* 
		THIS.SetError( "Nesting Error - no matching final END found " + ;
			"for " + laBlkStack[ m.lnDepth] + ".")
		EXIT
	ENDIF

	THIS.cUpperCaseLine = UPPER( THIS.cLineOfCode)

	DO CASE

	CASE INLIST( THIS.cUpperCaseLine, "END", "NEXT") AND ;
		NOT THIS.cUpperCaseLine = "ENDWITH"
		* end of control structure
		IF ( THIS.cUpperCaseLine = "ENDC" AND ;
				INLIST( laBlkStack[ m.lnDepth], ;
				"CASE", "OTHERWISE")) OR ;
			( THIS.cUpperCaseLine = "ENDD" AND ;
				laBlkStack[ m.lnDepth] = "DO WHILE") OR ;
			( INLIST( THIS.cUpperCaseLine, "ENDF", "NEXT") AND ;
				laBlkStack[ m.lnDepth] = "FOR") OR ;
			( THIS.cUpperCaseLine = "ENDS" AND ;
				laBlkStack[ m.lnDepth] = "SCAN") OR ;
			( THIS.cUpperCaseLine = "ENDT" AND ;
				laBlkStack[ m.lnDepth] = "TEXT") OR ;
			( THIS.cUpperCaseLine = "ENDI" AND ;
				INLIST( laBlkStack[ m.lnDepth], "ELSE", "IF"))
			*
			lnDepth = m.lnDepth - 1
			IF m.lnDepth = 0
				* Only valid exit point!
				EXIT
			ELSE
				IF m.llSubSect
					THIS.cChildBlock = THIS.cChildBlock + THIS.cLineOfCode + CrLf
				ENDIF
				LOOP
			ENDIF
		ELSE
			THIS.SetError( "Nesting error. " + ;
				TRIM( PADR( THIS.cUpperCaseLine, 8)) + ;
				" found, when matching begin " + ;
				"line was " + laBlkStack[ m.lnDepth] + ".", ;
				THIS.cLineOfCode)
				
		ENDIF

	CASE laBlkStack[ m.lnDepth] = "TEXT"
		* Within TEXT..ENDTEXT, we treat everything but an ENDTEXT as text.
		THIS.cChildBlock = THIS.cChildBlock + THIS.cLineOfCode + CrLf
		
	CASE UPPER( THIS.cLineOfCode) = "ELSE"
		IF laBlkStack[ m.lnDepth] = "IF"
			laBlkStack[ m.lnDepth] = "ELSE"
	
			IF m.lnDepth = 1
				IF m.tcBlockType == "IF"
					m.llSubSect = .F.
				ELSE
					m.llSubSect = .T.
				ENDIF
			ELSE
				IF m.llSubSect
					THIS.cChildBlock = THIS.cChildBlock + THIS.cLineOfCode + CrLf
				ENDIF
			ENDIF
		
			LOOP
		ELSE
			THIS.SetError( "ELSE nesting error - no matching IF.", THIS.cLineOfCode)
		ENDIF

	CASE UPPER( THIS.cLineOfCode) = "CASE"

		IF INLIST( laBlkStack[ m.lnDepth], "DO CASE", "CASE")
			laBlkStack[ m.lnDepth] = "CASE"
		
			IF m.lnDepth = 1
				IF m.llTrueCase
					m.llSubSect = .F.
				ELSE
					lcSubstr = SUBSTR( THIS.cLineOfCode, 5)

					IF THIS.lPreEval
						* check if logical value before going on
						IF TYPE( m.lcSubstr) <> "L"
							THIS.SetError( "CASE argument did not evaluate TRUE/FALSE", ;
								THIS.cLineOfCode)
							EXIT
						ENDIF
					ENDIF
					
					IF &lcSubstr
						m.llTrueCase = .T.
						m.llSubSect = .T.
					ENDIF
				ENDIF
			ELSE
				IF m.llSubSect
					THIS.cChildBlock = m.THIS.cChildBlock + THIS.cLineOfCode + CrLf
				ENDIF
			ENDIF
		
			LOOP
		ELSE
			THIS.SetError( "CASE nesting error - no matching DO CASE.", ;
				THIS.cLineOfCode)
		ENDIF

	CASE UPPER( THIS.cLineOfCode) = "OTHE"
		IF INLIST( laBlkStack[ m.lnDepth], "DO CASE", "CASE")
			laBlkStack[ m.lnDepth] = "OTHERWISE"
		
			IF m.lnDepth = 1
				IF m.llTrueCase
					m.llSubSect = .F.
				ELSE
					m.llSubSect = .T.
				ENDIF
			ELSE
				IF m.llSubSect
					THIS.cChildBlock = m.THIS.cChildBlock + THIS.cLineOfCode + CrLf
				ENDIF
			ENDIF
		
			LOOP
		ELSE
			THIS.SetError( "OTHERWISE nesting error - no matching DO CASE.", ;
				THIS.cLineOfCode)
		ENDIF

	CASE INLIST( THIS.cUpperCaseLine, "IF", "DO WHIL", "SCAN", ;
		"TEXT", "DO CASE", "FOR")
		*
		IF laBlkStack[ m.lnDepth] = "DO CASE"
			THIS.SetError( "Nesting error - DO CASE w/o CASE.", THIS.cLineOfCode)
		ELSE
			lnDepth = m.lnDepth + 1
			DIMENSION laBlkStack[ m.lnDepth]
		
			DO CASE
			CASE UPPER( THIS.cLineOfCode) = "IF"
				laBlkStack[ m.lnDepth] = "IF"
		
			CASE UPPER( THIS.cLineOfCode) = "DO WHIL"
				laBlkStack[ m.lnDepth] = "DO WHILE"

			CASE UPPER( THIS.cLineOfCode) = "SCAN"
				laBlkStack[ m.lnDepth] = "SCAN"

			CASE UPPER( THIS.cLineOfCode) = "TEXT"
				laBlkStack[ m.lnDepth] = "TEXT"

			CASE UPPER( THIS.cLineOfCode) = "DO CASE"
				laBlkStack[ m.lnDepth] = "DO CASE"

			CASE UPPER( THIS.cLineOfCode) = "FOR"
				laBlkStack[ m.lnDepth] = "FOR"
		
			OTHERWISE
				THIS.SetError( "Internal CODEBLCK consistency error.", THIS.cLineOfCode)

			ENDCASE
		
			IF m.llSubSect
				THIS.cChildBlock = THIS.cChildBlock + THIS.cLineOfCode + CrLf
			ENDIF
			LOOP
		ENDIF

	OTHERWISE
		* legitimate in-line code
		IF m.llSubSect
			THIS.cChildBlock = THIS.cChildBlock + THIS.cLineOfCode + CrLf
		ENDIF
	
	ENDCASE

ENDDO

*!*	CREATE CURSOR Temp (Block M)
*!*	APPEND BLANK
*!*	REPLACE Block WITH THIS.cChildBlock
*!*	MODIFY MEMO Block

IF m.lcLastExact == "ON"
	SET EXACT ON
ENDIF

IF THIS.lError
	THIS.cChildBlock = SPACE(0)
ENDIF

ENDFUNC
* ------------------------------------------------------------- *

FUNCTION SetCodeBlock( tcCodeBlock)

IF TYPE( "m.tcCodeBlock") $ "CM"
	THIS.cCodeBlock = m.tcCodeBlock
ELSE
	THIS.lError = .T.
ENDIF

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION SetCodeBlockFromFile( tcFileSpec)
*
* Get file contents.
*
IF TYPE( "m.tcFileSpec") <> "C"
	THIS.cCodeBlock = ""
	THIS.SetError( "No file name passed to SetCodeBlockFromFile() method." )
	RETURN
ENDIF
	
IF NOT FILE( m.tcFileSpec)
	THIS.cCodeBlock = ""
	THIS.SetError( "File " + m.tcFileSpec + " not found." )
	RETURN
ENDIF

LOCAL lnSelect
lnSelect = SELECT()
SELECT 0
CREATE CURSOR _0_qFile (Contents M)
APPEND BLANK
APPEND MEMO Contents FROM ( m.tcFileSpec)
THIS.cCodeBlock = Contents
USE
SELECT ( m.lnSelect)

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION SetReturnType( tcType)
*
* Sets property "cReturnType".
*
IF TYPE( "m.tcType") == "C"
	THIS.cReturnType = UPPER( ALLTRIM( m.tcType))
ENDIF

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION SetErrorReturnValue( txValue)
*
* Sets property "xErrorReturn".
*
IF TYPE( "m.txValue") == "U"
	THIS.xErrorReturn = .F. && default
ELSE
	THIS.xErrorReturn = m.txValue
ENDIF

ENDFUNC

* ------------------------------------------------------------- *

PROTECTED FUNCTION IllegalCommandFound()
*
* Scans array THIS.aIllegal to see if current command is disallowed.
*
* Array is built via methods AddIllegalCommand() and 
* DropIllegalCommand(). In the base class for cusCodeBlock, QUIT,
* CANCEL, and THIS. are disallowed. It is easy to subclass this behaviour.

LOCAL ii, lFound
lFound = .F.

FOR ii = 1 TO ALEN( THIS.aIllegal, 1)
	IF NOT EMPTY( THIS.aIllegal[ m.ii, 1])
		IF PADR( THIS.cUpperCaseLine, LEN( THIS.aIllegal[ m.ii, 1])) ;
			== THIS.aIllegal[ m.ii, 1]
			*
			lFound = .T.
			= THIS.SetError( "Command " + THIS.aIllegal[ m.ii, 1] + ;
				" not allowed.", THIS.cLineOfCode )
			
			EXIT
		ENDIF
	ENDIF
ENDFOR

RETURN m.lFound

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION AddIllegalCommand( tcCommand)

LOCAL ii
FOR ii = 1 TO ALEN( THIS.aIllegal, 1)
	IF EMPTY( THIS.aIllegal[ m.ii, 1])
		EXIT
	ENDIF
ENDFOR
IF m.ii > ALEN( THIS.aIllegal, 1)
	DIMENSION THIS.aIllegal[ m.ii, 1]
ENDIF
THIS.aIllegal[ m.ii, 1] = UPPER( m.tcCommand)

ENDFUNC

* ------------------------------------------------------------- *

FUNCTION DropIllegalCommand( tcCommand )

LOCAL ii
FOR ii = 1 TO ALEN( THIS.aIllegal, 1)
	IF NOT EMPTY( THIS.aIllegal[ m.ii, 1] ) AND ;
		THIS.aIllegal[ m.ii, 1] == UPPER( m.tcCommand)
		*
		THIS.aIllegal[ m.ii, 1] = .F.
		EXIT
	ENDIF
ENDFOR

ENDFUNC
* ------------------------------------------------------------- *

FUNCTION SetError( tcMessage, tcCode)

THIS.lError = .T.
THIS.nError = 1089 && user-defined
THIS.nErrorRecursionLevel = THIS.nRecursionLevel

IF TYPE( "m.tcMessage") == "C"
	THIS.cErrorMessage = m.tcMessage
ENDIF

IF TYPE( "m.tcCode") == "C"
	THIS.cErrorCode = m.tcCode
ENDIF

ENDFUNC
* ------------------------------------------------------------- *

FUNCTION Error( tnError, tcMethod, tnLine)

THIS.lError = .T.
THIS.nError = m.tnError
THIS.nErrorRecursionLevel = THIS.nRecursionLevel
THIS.cErrorMessage = MESSAGE()

THIS.cErrorCode = MESSAGE( 1)
IF UPPER( THIS.cErrorCode) = UPPER( "&_0_qcMacroSubstitutionString")
	* Show command that was attempted instead of & command:
	THIS.cErrorCode = THIS.cLineOfCode
ENDIF

THIS.cErrorMethod = m.tcMethod
THIS.nErrorLine = m.tnLine

* Take this out--used for testing:
* WAIT WINDOW THIS.cErrorMessage

ENDFUNC
* ------------------------------------------------------------- *

FUNCTION BubbleErrorParameters()
* Save child error parameters to parent error parameters
* to allow retrieval to class that called cusCodeBlock.
THIS.lError = .T.
THIS.cErrorMessage = THIS.oChild.cErrorMessage
THIS.cErrorCode = THIS.oChild.cErrorCode
THIS.nError = THIS.oChild.nError

ENDFUNC
* ------------------------------------------------------------- *

FUNCTION PassThroughProperties()
* For recursion, pass some properties on to child object.
THIS.oChild.SetCodeBlock( THIS.cChildBlock)
THIS.oChild.nRecursionLevel = THIS.nRecursionLevel + 1

THIS.oChild.nWith = THIS.nWith
DIMENSION THIS.oChild.aWith[ ALEN( THIS.aWith)]
= ACOPY( THIS.aWith, THIS.oChild.aWith)

ENDFUNC
* ------------------------------------------------------------- *

ENDDEFINE 
*[ Class cusCodeBlock ]
* ------------------------------------------------------------- *
*[ End: CdBlkCls.PRG ]

#ENDIF