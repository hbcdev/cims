** servername = "<ชื่อ Server >"

DECLARE INTEGER NetRemoteTOD IN netapi32 STRING @, INTEGER @
DECLARE INTEGER RtlMoveMemory IN win32api STRING @outbuffer,INTEGER inbuffer,;
INTEGER bytes2copy
tdbuffout=REPLICATE(CHR(0), 48)
tdbuffin = 0
servername = "<ชื่อ Server >"
try_server_name = STRCONV(server_name, 5)
rc = NetRemoteTOD(@try_server_name, tdbuffin)
IF rc = 0
=RtlMoveMemory(@tdbuffout, tdbuffin, 48)
ELSE
try_server_name = STRCONV("\\" + server_name, 5)
rc = NetRemoteTOD(@try_server_name, @tdbuffin)
IF rc = 0
=RtlMoveMemory(@tdbuffout, tdbuffin, 48)
ELSE
? "NetRemoteTOD() call failed. Return code is: ", rc
RETURN
ENDIF
ENDIF
tod_month = str2long(SUBSTR(tdbuffout, 37, 4))
tod_day = str2long(SUBSTR(tdbuffout, 33, 4))
tod_year = str2long(SUBSTR(tdbuffout, 41, 4))
tod_hours = str2long(SUBSTR(tdbuffout, 9, 4))
tod_mins = str2long(SUBSTR(tdbuffout, 13, 4))
tod_secs = str2long(SUBSTR(tdbuffout, 17, 4))
serverdatetime = DATETIME(tod_year, tod_month, tod_day, ;
tod_hours, tod_mins, tod_secs)

?serverdatetime+25200 && 25200 second ของ 7 ชม.

*************************************************************
FUNCTION str2long
*************************************************************
PARAMETERS m.longstr
PRIVATE i, m.retval
m.retval = 0
FOR i = 0 TO 24 STEP 8
m.retval = m.retval + (ASC(m.longstr) * (2^i))
m.longstr = RIGHT(m.longstr, LEN(m.longstr) - 1)
NEXT
RETURN m.retval
