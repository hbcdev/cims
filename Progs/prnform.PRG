prnform.prg

parameter _printername,_papername,_formreport,_printalias,_preview

* Form flag values

#define form_user 0x00000000

#define form_builtin 0x00000001

#define form_printer 0x00000002

ooo = newobject("EnumForms", "EnumPrinterFormsClass.fxp")

*lcprinter = set("Printer",3)

*Enumerate forms for specified Windows printer

*lcprinter = "Receipt"

set printer to name '&_printername'

lcprinter = _printername

if not ooo.getformlist(lcprinter) && Error

wait window ooo.cerrormessage nowait

ooo = null

return

endif

find_form = .f.

osname = findos()

if osname $ 'WINNTWINXP'

if _papername > '256'

for i=1 to ooo.oformlist.count

looneform = ooo.oformlist.item(i)

if looneform.formname = _papername

find_form = .t.

formid = looneform.formid

endif

endfor

else

find_form = .t.

formid = val(_papername)

endif

else

find_form = .t.

formid = 256

endif

release osname

ooo = null

if find_form

orpfrx = _formreport+'.frx'

orpfrt = _formreport+'.frt'

print_many_com = .f.

if print_many_com

rp = 'temp\rp'+right(sys(2015),6)

rpfrx = rp+'.frx'

rpfrt = rp+'.frt'

copy file &orpfrx to &rpfrx

copy file &orpfrt to &rpfrt

use &rpfrx alias rptform in 0

else

rp = orpfrx

use &orpfrx alias rptform in 0

endif

exprchar = [PAPERSIZE=]+alltrim(str(formid))+chr(13)+chr(10)+;

[ORIENTATION=0]+chr(13)+chr(10)+;

[DEFAULTSOURCE=8]+chr(13)+chr(10)+;

[TTOPTION=1]+chr(13)+chr(10)+;

[COLLATE=1]

select rptform

repl expr with exprchar

repl tag with ''

repl tag2 with ''

use in rptform

select &_printalias

if _preview

report form &rp noconsole to print preview

else

report form &rp noconsole to print

endif


if print_many_com

delete file &rpfrx

delete file &rpfrt

release all like rpfr*

endif


release exprchar

endif

return

 

* EnumPrinterFormClass.prg

define class enumforms as custom

hidden hheap, ninch2mm, ncm2mm, ncoefficient

* Specified a Printer name for which the list of supported forms is retrieved * If empty, retrieved the list of formds defined on local PC

cprintername = ""

* The form attributes are stored in in thousandths of millimeters * It can be coverted by class to inches ("English") or centimeters ("Metric")

cunit = "Internal"

* Specified how to round result of conversion

nround = 0

* Conversion Coefficients

ninch2mm = 25.4

ncm2mm = 10

ncoefficient = 0

* Error code and Error message returned by Win API

napierrorcode = 0

capierrormessage = ""

* Error message returned by class itself (none-API error)

cerrormessage = ""

hheap = 0

* Collection of Print Forms retrieved

oformlist = null

procedure init(tcunit, tnround)

if pcount() >= 1 and inlist(tcunit, "English", "Metric")

this.cunit = proper(tcunit)

endif

if pcount() = 2

this.nround = tnround

endif

this.oformlist = createobject("Collection")

* Load DLLs

this.loadapidlls()

* Allocate a heap

this.hheap = heapcreate(0, 4096*10, 0)

* Calculate conversion coefficient

do case

case proper(this.cunit) = "English"

this.ncoefficient = this.ninch2mm * 1000

case proper(this.cunit) = "Metric"

this.ncoefficient = this.ncm2mm * 1000

otherwise

this.cunit = "Internal"

this.ncoefficient = 1

endcase

endproc

procedure destroy

if this.hheap <> 0

heapdestroy(this.hheap)

endif

endproc

procedure getformlist(tcprintername)

local lhprinter, llsuccess, lnneeded, lnnumberofforms, lnbuffer, i

if pcount() > 0

this.cprintername = tcprintername

endif

this.clearerrors()

* Open a printer

lhprinter = 0

lcprintername = this.cprintername

if empty(lcprintername)

lnresult = openprinter(0, @lhprinter, 0)

else

lnresult = openprinter(@lcprintername, @lhprinter, 0)

endif

if lnresult = 0

this.cerrormessage = "Unable to get printer handle for '" ;

+ this.cprintername + "'."

this.napierrorcode = getlasterror()

this.capierrormessage = this.apierrortext(this.napierrorcode)

return .f.

endif

lnneeded = 0

lnnumberofforms = 0

* Get the size of the buffer required to fit all forms in lnNeeded

if enumforms(lhprinter, 1, 0, 0, ;

@lnneeded, @lnnumberofforms ) = 0

if getlasterror() <> 122 && The buffer too small error

this.cerrormessage = "Unable to Enumerate Forms."

this.napierrorcode = getlasterror()

this.capierrormessage = this.apierrortext(this.napierrorcode)

return .f.

endif

endif

* Get the list of forms

lnbuffer = heapalloc(this.hheap, 0, lnneeded)

llsuccess = .t.

if enumforms(lhprinter, 1, lnbuffer, @lnneeded, ;

@lnneeded, @lnnumberofforms ) = 0

this.cerrormessage = "Unable to Enumerate Forms."

this.napierrorcode = getlasterror()

this.capierrormessage = this.apierrortext(this.napierrorcode)

llsuccess = .f.

endif

if llsuccess

* Put list of the forms into collection with Form number (i) as a key * A collection here can be replaced with an array or a cursor.

for i=1 to lnnumberofforms

looneform = this.oneformobj()

with looneform

lnpointer = lnbuffer + (i-1) * 32

.formid = i

.formflags = this.long2numfrombuffer(lnpointer)

.formname = this.strzfrombuffer(lnpointer+4)

.width = round(this.long2numfrombuffer(lnpointer+8) / ;

this.ncoefficient, this.nround)

.height = round(this.long2numfrombuffer(lnpointer+12) / ;

this.ncoefficient, this.nround)

.left = round(this.long2numfrombuffer(lnpointer+16) / ;

this.ncoefficient, this.nround)

.top = round(this.long2numfrombuffer(lnpointer+20) / ;

this.ncoefficient, this.nround)

.right = round(this.long2numfrombuffer(lnpointer+24) / ;

this.ncoefficient, this.nround)

.bottom = round(this.long2numfrombuffer(lnpointer+28) / ;

this.ncoefficient, this.nround)

endwith

this.oformlist.add(looneform, transform(i))

endfor

endif

= heapfree(this.hheap, 0, lnbuffer )

= closeprinter(lhprinter)

return llsuccess

* Create an object with forms attributes

procedure oneformobj

local looneform

looneform = newobject("Empty")

addproperty(looneform, "FormFlags", 0)

addproperty(looneform, "FormId", 0)

addproperty(looneform, "FormName", "")

addproperty(looneform, "Width", 0)

addproperty(looneform, "Height", 0)

addproperty(looneform, "Left", 0)

addproperty(looneform, "Top", 0)

addproperty(looneform, "Right", 0)

addproperty(looneform, "Bottom", 0)

return looneform

endproc

procedure clearerrors

this.cerrormessage = ""

this.napierrorcode = 0

this.capierrormessage = ""

endproc

* Retrieve zero-terminated string from a buffer into VFP variable

procedure strzfrombuffer(tnpointer)

local lcstr, lnstrpointer

lcstr = space(256)

lnstrpointer = 0

= rtlcopy(@lnstrpointer, tnpointer, 4)

lstrcpy(@lcstr, lnstrpointer)

return left(lcstr, at(chr(0),lcstr)-1)

endproc

* Convert Long integer into VFP numeric variable

procedure long2numfrombuffer(tnpointer)

local lnnum

lnnum = 0

= rtlcopy(@lnnum, tnpointer, 4)

return lnnum

endproc

* Converts VFP number to the Long integer

function num2long(tnnum)

declare RtlMoveMemory in WIN32API as RtlCopyLong ;

string @dest, long @source, long length

local lcstring

lcstring = space(4)

=rtlcopylong(@lcstring, bitor(tnnum,0), 4)

return lcstring

endfunc

* Convert Long integer into VFP numeric variable

function long2num(tclong)

declare RtlMoveMemory in WIN32API as RtlCopyNum ;

long @dest, string @source, long length

local lnnum

lnnum = 0

= rtlcopynum(@lnnum, tclong, 4)

return lnnum

endfunc

hidden procedure apierrortext

lparameters tnerrorcode

local lcerrbuffer

lcerrbuffer = repl(chr(0),1024)

= formatmessage(0x1000 ,.null., tnerrorcode, 0, @lcerrbuffer, 1024,0)

return left(lcerrbuffer, at(chr(0),lcerrbuffer)- 1 )

endproc

hidden procedure loadapidlls

declare integer OpenPrinter in winspool.drv;

string @pPrinterName,;

integer @phPrinter,;

integer pDefault

declare integer ClosePrinter in winspool.drv;

integer hPrinter

declare long EnumForms in winspool.drv as EnumForms ;

long hPrinter, long level, long pForm, ;

long cbBuf, long @pcbNeeded, ;

long @ pcReturned

declare integer HeapCreate in Win32API;

integer dwOptions, integer dwInitialSize,;

integer dwMaxSize

declare integer HeapAlloc in Win32API;

integer hHeap, integer dwFlags, integer dwBytes

declare lstrcpy in Win32API;

string @lpstring1, integer lpstring2

declare integer HeapFree in Win32API;

integer hHeap, integer dwFlags, integer lpMem

declare HeapDestroy in Win32API;

integer hHeap

declare RtlMoveMemory in WIN32API as RtlCopy ;

long @dest, long source, long length

declare lstrcpy in Win32API;

string @lpstring1, integer lpstring2

declare integer GetLastError in kernel32

declare integer FormatMessage in kernel32.dll ;

integer dwFlags, string @lpSource, ;

integer dwMessageId, integer dwLanguageId, ;

string @lpBuffer, integer nSize, integer Arguments

endproc

enddefine

