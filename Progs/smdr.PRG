public m.room,m.line,m.date,m.time,m.telno,m.ctime
* สร้าง object ตรงนี้แล้วตัด รูปโทรศัพท์ ใน form คุณออกไปได้เลย
tele=createobject('mscommlib.mscomm')
tele.commport=2
tele.settings='1200,n,8,1'
tele.inputlen=43
tele.handshaking=1
tele.inbuffercount=0
tele.inputmode=0
*tele.portopen=.f.
data_input=''
cou=0
do while empty(data_input)
tele.portopen=.t.
tele.inbuffercount=0
* ตรงนี้ เป็นการส่งสัญญาณ ไป start ให้เครื่องทำงานอาจจะตัดออกไปสำหรับเครื่องชั่งน้ำหนัก
tele.output=chr(1)
** ความยาวสัญญาณ ที่ส่ง มาอาจจะปรับค่าได้ให้ต่ำหรือมากกว่า 43
do while tele.inbuffercount<43
cou=cou+1
if cou>=200
exit
endif
enddo
if cou>=200
exit
endif
data_input=rtrim(tele.input)
wait
if .not.empty(data_input)
cou=0
endif
tele.portopen=.f.
**** รับค่ามาได้แล้วก็แยกว่าอะไรเป็นอะไร
m.room=substr(data_input,1,4)
m.line=substr(data_input,6,2)
m.date=substr(data_input,9,4)
m.time=substr(data_input,14,4)
m.telno=substr(data_input,19,9)
m.ctime=substr(data_input,38,4)
insert into phone from memvar
data_input=''
thisform.refresh
cou=cou+1
enddo
tele.output=chr(7)
? messagebox('Finish')
tele.portopen=.f.
thisform.refresh
ลองเอาไปใส่ ใน init form สงสัยอีเมลล์หา ที่ sakonsin@yahoo.com 