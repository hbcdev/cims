set escape on
close tables
use "ORDERS.DBF" shared alias first in 0
use "ORDERS.DBF" again shared alias second in 0

select second
set order to tag ordernum
select first
set order to tag ordernum

lnFound = 0
lnNotFound = 0
go top
do while not eof()
	select first
	lnOrderNum = First.OrderNum
	select Second
	llResult = seek(lnOrderNum)
	if llResult
		? "Found: " + transform(lnOrderNum)
		lnFound = lnFound + 1
	else
		? "Could not find order: " + transform(lnOrderNum)
		lnNotFound = lnNotFound + 1
	endif
	select First
	skip
enddo

messagebox("Done with USE AGAIN.  Found: " + transform(lnFound) + "  Not Found: " + transform(lnNotFound))

oConn = createobject("adodb.connection")
oOrdersRS = createobject("adodb.recordset")

oConn.Open("OMPDBF", "", "")
oOrdersRS.Open("SELECT * FROM ORDERS", oConn, 3, 4)

? "Found Orders: " + transform(oOrdersRS.RecordCount)

lnFound = 0
lnNotFound = 0
oOrdersRS.MoveFirst()
do while not oOrdersRS.Eof()

	lnOrderNum = oOrdersRS.Fields("ORDERNUM").value
	select Second
	llResult = seek(lnOrderNum)
	if llResult
		? "Found: " + transform(lnOrderNum)
		lnFound = lnFound + 1
	else
		? "Could not find order: " + transform(lnOrderNum)
		lnNotFound = lnNotFound + 1
	endif
	oOrdersRS.MoveNext()
enddo

messagebox("Done with recordset  Found: " + transform(lnFound) + "  Not Found: " + transform(lnNotFound))

lnFound = 0
lnNotFound = 0
oOrdersRS.MoveFirst()
do while not oOrdersRS.Eof()

	lnOrderNum = oOrdersRS.Fields("ORDERNUM").value
	select Second
	llResult = seek(int(lnOrderNum))
	if llResult
		? "Found: " + transform(lnOrderNum)
		lnFound = lnFound + 1
	else
		? "Could not find order: " + transform(lnOrderNum)
		lnNotFound = lnNotFound + 1
	endif
	oOrdersRS.MoveNext()
enddo

messagebox("Done with INT search w/recordset  Found: " + transform(lnFound) + "  Not Found: " + transform(lnNotFound))

select First
use
select Second
use
