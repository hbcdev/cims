SET PATH TO c:\STRUCT  && Change this to be wherever you unzipped the class.
SET CLASSLIB TO STRUCT.vcx

CLEAR ALL
CLEAR

*!* Windows API call to list printer forms.
DECLARE LONG EnumFormsA IN winspool.drv AS EnumForms ;
   LONG hPrinter, LONG Level, LONG pForm, ;
   LONG cbBuf, LONG @pcbNeeded, ;
   LONG @ pcReturned
   
*!* Windows API call to get a printer handle.
DECLARE LONG OpenPrinterA IN winspool.drv AS OpenPrinter ;
   STRING pPrinterName, LONG @ phPrinter, LONG pDefault

phPrinter = 0   && Define printer handle for pass-by-reference
*!* You do not pass a specific printer here, because the custom form
*!* is defined on the local computer.
lnRetVal = OpenPrinter(0, @phPrinter, 0)
IF lnRetVal = 0
   MESSAGEBOX("OpenPrinter failed!")
   RETURN
ENDIF

*!* Create structure to hold returned printer forms.
loForms = CREATEOBJECT("clsPrinterForms")

*!* Define variables for pass-by-reference.
lnFormsPtr = loForms.GetPointer(255)
lnBytesNeeded = 0
lnFormCount = 0

*!* lnRetVal will indicate that this next call failed. This is because
*!* it was told to return 0-length information.
*!* The second call should work properly.
lnRetVal = EnumForms(phPrinter, 1, lnFormsPtr, 0, @lnBytesNeeded, ;
   @lnFormCount)
loForms.FreePointer(lnFormsPtr) && clean up memory

*!* Get the proper memory size reserved, and call EnumForms.
lnFormsPtr = loForms.GetPointer(lnBytesNeeded)
lnRetVal = EnumForms(phPrinter, 1, lnFormsPtr, lnBytesNeeded, ;
   @lnBytesNeeded, @lnFormCount)
IF lnRetVal = 0
   MESSAGEBOX("EnumForms call failed")
   loForms.FreePointer(lnFormsPtr) && clean up memory
   RETURN
ENDIF

*!* When you defined the PrinterForms class, you didn't know how many forms
*!* were being returned. Now that you do, you need to redimension the array
*!* property to hold the proper number of forms, and get them ready to hold 
*!* the form information.
DIMENSION loForms.aForms[lnFormCount]
FOR i = 1 TO lnFormCount
   loForms.aForms[i] = CREATEOBJECT("clsFormInfo")
ENDFOR

*!* Take the memory pointer you received, and break it up into the objects you 
*!* defined below.
loForms.SetPointer(lnFormsPtr)

loForms.FreePointer(lnFormsPtr) && clean up memory

FOR i = 1 TO lnFormCount
   loForm = loForms.aForms[i]
   
   *!* i is what you would see in PaperSize in the Expr field, or in 
   *!* the PRTINFO() function. The Size.cx and cy values are in 1000ths
   *!* of a millimeter: there are 25.4 millimeters to an inch.
   ? i, PADR(loForm.pName, 30), loForm.Size.cx / 25400, loForm.Size.cy / 25400
ENDFOR

RETURN

*!* The class properties correspond to the members of the structures,
*!* and cMembers indicates what type of variables are in the return
*!* from the API call. "l:" indicates a long, "o:" indicates 
*!* a structure, and "pz:" indicates a pointer to a null-terminated 
*!* string.
*!* See Struct.vcx documentation for more information about the STRUCT 
*!* class and its settings.
DEFINE CLASS clsPrinterForms AS STRUCT
   DIMENSION aForms[1]
   cMembers = "o:aForms"

   nMemorySize = 100000  && Reserve memory for pointers

   PROCEDURE INIT
      This.aForms[1] = CREATEOBJECT("clsFormInfo")
      DODEFAULT()
   ENDPROC
ENDDEFINE

DEFINE CLASS clsFormInfo AS STRUCT
   flags = 0
   pName = ""      && form name
   Size = .NULL.   && paper size
   ImageableArea = .NULL.

   cMembers = "l:flags, pz:pName, o:size, o:imageableArea"

   PROCEDURE INIT
      This.Size  = CREATEOBJECT("clsSizeL")
      This.ImageableArea = CREATEOBJECT("clsRectL")
      DODEFAULT()
   ENDPROC
ENDDEFINE

DEFINE CLASS clsSizeL AS STRUCT
   cx = 0   && paper width
   cy = 0   && paper height

   cMembers = "l:cx, l:cy"
ENDDEFINE

DEFINE CLASS clsRectL AS STRUCT
   nLeft = 0
   nTop = 0
   nRight = 0
   nBottom = 0

   cMembers = "l:nLeft, l:nTop, l:nRight, l:nBottom"
ENDDEFINE
