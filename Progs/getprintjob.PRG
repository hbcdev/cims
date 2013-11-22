ooo = NEWOBJECT("EnumJobs", "EnumJobsClass.fxp")
ooo.GetJobList("EPSON Stylus C82 Series")

FOR i=1 TO ooo.oJobList.Count
	loOneJob = ooo.oJobList.Item(i)
	? loOneJob.JobId, loOneJob.Document
ENDFOR

ooo = Null
RETURN
*EnumJobs.prg
DEFINE CLASS EnumJobs AS Custom
	HIDDEN hHeap
	cPrinterName = ""
	nApiErrorCode = 0
	cApiErrorMessage = ""
	cErrorMessage = ""
	hHeap = 0
	oJobList = Null

	PROCEDURE Init()
	This.oJobList = CREATEOBJECT("Collection")
	This.LoadApiDlls()
	This.hHeap = HeapCreate(0, 4096, 0)
	* Use Windows default printer
	This.cPrinterName = SET("Printer",2)
	ENDPROC

	PROCEDURE Destroy
	IF This.hHeap <> 0
		HeapDestroy(This.hHeap)
	ENDIF
	ENDPROC

	PROCEDURE GetJobList(tcPrinterName)
	LOCAL lhPrinter, llSuccess, lnNeeded, lnNumberOfJobs, lnBuffer, i

	IF PCOUNT() > 0
		This.cPrinterName = tcPrinterName
	ENDIF

	This.ClearErrors()
	lhPrinter = 0
	IF OpenPrinter(This.cPrinterName, @lhPrinter, 0) = 0
		This.cErrorMessage = "Unable to get printer handle for '" ;
			+ This.cPrinterName + "."
		This.nApiErrorCode = GetLastError()
		This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
		RETURN .F.
	ENDIF

	lnNeeded = 0
	lnNumberOfJobs = 0

	* Get the size of the buffer in lnNeeded
	IF EnumJobs(lhPrinter, 0, 127, 1, 0, 0, ;
			@lnNeeded, 	@lnNumberOfJobs  ) = 0
		IF GetLastError() <> 122   && The buffer too small error
			This.cErrorMessage = "Unable to Enumerate Jobs."
			This.nApiErrorCode = GetLastError()
			This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
			RETURN .F.
		ENDIF
	ENDIF
        * Allocate the buffer of required size and call EnumJobs again
	lnBuffer = HeapAlloc(This.hHeap, 0, lnNeeded)
	llSuccess = .T.
	IF EnumJobs(lhPrinter, 0, 127, 1, lnBuffer, @lnNeeded, ;
			@lnNeeded, 	@lnNumberOfJobs  ) = 0
		This.cErrorMessage = "Unable to Enumerate Jobs."
		This.nApiErrorCode = GetLastError()
		This.cApiErrorMessage = This.ApiErrorText(This.nApiErrorCode)
		llSuccess = .F.
	ENDIF

	IF llSuccess
		FOR i=1 TO lnNumberOfJobs
			loOneJob = This.OneJobObj()
			WITH loOneJob
				lnPointer = lnBuffer + (i-1) * 64
				.JobId = This.Long2NumFromBuffer(lnPointer)
				.PrinterName = This.StrZFromBuffer(lnPointer+4)
				.MachineName = This.StrZFromBuffer(lnPointer+8)
				.UserName = This.StrZFromBuffer(lnPointer+12)
				.Document = This.StrZFromBuffer(lnPointer+16)
				.Datatype = This.StrZFromBuffer(lnPointer+20)
				.StatusText = This.StrZFromBuffer(lnPointer+24)
				.Status = This.Long2NumFromBuffer(lnPointer+28)
				.Priority = This.Long2NumFromBuffer(lnPointer+32)
				.Position = This.Long2NumFromBuffer(lnPointer+36)
				.TotalPages = This.Long2NumFromBuffer(lnPointer+40)
				.PagesPrinted = This.Long2NumFromBuffer(lnPointer+44)
			ENDWITH
			This.oJobList.Add(loOneJob, TRANSFORM(loOneJob.JobId))
		ENDFOR
	ENDIF

	= HeapFree(This.hHeap, 0, lnBuffer )
	= ClosePrinter(lhPrinter)
	RETURN llSuccess

	PROCEDURE StrZFromBuffer(tnPointer)
        * Copy zero-terminated string from buffer to VFP string
	LOCAL lcStr, lnStrPointer
	lcStr = SPACE(256)
	lnStrPointer = 0
	= RtlCopy(@lnStrPointer, tnPointer, 4)
	lstrcpy(@lcStr, lnStrPointer)
	RETURN LEFT(lcStr, AT(CHR(0),lcStr)-1)
	ENDPROC

	PROCEDURE Long2NumFromBuffer(tnPointer)
        * Copy Long number from buffer into VFP variable
	LOCAL lnNum
	lnNum = 0
	= RtlCopy(@lnNum, tnPointer, 4)
	RETURN lnNum
	ENDPROC

	PROCEDURE OneJobObj
	LOCAL loOneJob
	loOneJob = NEWOBJECT("Empty")
	ADDPROPERTY(loOneJob, "JobId", 0)
	ADDPROPERTY(loOneJob, "PrinterName", "")
	ADDPROPERTY(loOneJob, "MachineName", "")
	ADDPROPERTY(loOneJob, "UserName", "")
	ADDPROPERTY(loOneJob, "Document", "")
	ADDPROPERTY(loOneJob, "Datatype", "")
	ADDPROPERTY(loOneJob, "StatusText", "")
	ADDPROPERTY(loOneJob, "Status", 0)
	ADDPROPERTY(loOneJob, "Priority", 0)
	ADDPROPERTY(loOneJob, "Position", 0)
	ADDPROPERTY(loOneJob, "TotalPages", 0)
	ADDPROPERTY(loOneJob, "PagesPrinted", 0)
	*  SYSTEMTIME Submitted
	RETURN loOneJob
	ENDPROC

	PROCEDURE ClearErrors
	This.cErrorMessage = ""
	This.nApiErrorCode = 0
	This.cApiErrorMessage = ""
	ENDPROC

	FUNCTION Num2LOng(tnNum)
	DECLARE RtlMoveMemory IN WIN32API AS RtlCopyLong ;
		STRING @Dest, Long @Source, Long Length
	LOCAL lcString
	lcString = SPACE(4)
	=RtlCopyLong(@lcString, BITOR(tnNum,0), 4)
	RETURN lcString
	ENDFUNC

	FUNCTION Long2Num(tcLong)
	DECLARE RtlMoveMemory IN WIN32API AS  AS RtlCopyNum ;
		Long @Dest, String @Source, Long Length
	LOCAL lnNum
	lnNum = 0
	= RtlCopyNum(@lnNum, tcLong, 4)
	RETURN lnNum
	ENDFUNC

	HIDDEN PROCEDURE ApiErrorText
		LPARAMETERS tnErrorCode
		Local lcErrBuffer
		lcErrBuffer = REPL(CHR(0),1024)
		= FormatMessage(0x1000 ,.NULL., tnErrorCode, 0, @lcErrBuffer, 1024,0)
		RETURN LEFT(lcErrBuffer, AT(CHR(0),lcErrBuffer)- 1 )
		ENDPROC

	HIDDEN PROCEDURE LoadApiDlls
		DECLARE INTEGER OpenPrinter IN winspool.drv;
			STRING  pPrinterName,;
			INTEGER @phPrinter,;
			INTEGER pDefault
		DECLARE INTEGER ClosePrinter IN winspool.drv;
			INTEGER hPrinter
		Declare Integer EnumJobs in WinSpool.Drv ;
			Integer hPrinter, ;
			Integer FirstJob, ;
			Integer NoJobs, ;
			Integer Level, ;
			Integer pJob, ;
			Integer cbBuf, ;
			Integer @pcbNeeded, ;
			Integer @pcReturned
		DECLARE INTEGER HeapCreate IN Win32API;
			INTEGER dwOptions, INTEGER dwInitialSize,;
			INTEGER dwMaxSize
		DECLARE INTEGER HeapAlloc IN Win32API;
			INTEGER hHeap, INTEGER dwFlags, INTEGER dwBytes
		DECLARE lstrcpy IN Win32API;
			STRING @lpstring1, INTEGER lpstring2
		DECLARE INTEGER HeapFree IN Win32API;
			INTEGER hHeap, INTEGER dwFlags, INTEGER lpMem
		DECLARE HeapDestroy IN Win32API;
			INTEGER hHeap
		DECLARE RtlMoveMemory IN WIN32API AS RtlCopy ;
			Long @Dest, Long Source, Long Length
		DECLARE lstrcpy IN Win32API;
			STRING @lpstring1, INTEGER lpstring2
		DECLARE INTEGER GetLastError IN kernel32
		Declare Integer FormatMessage In kernel32.dll ;
			Integer dwFlags, String @lpSource, ;
			Integer dwMessageId, Integer dwLanguageId, ;
			String @lpBuffer, Integer nSize, Integer Arguments

		ENDPROC

ENDDEFINE

