*====================================================================
*====================================================================
* Date pick function 
* fGetDate("cReturnChar" ,"cTitle")
* returns a date type of the curent set date format 
* unless parameter cReturnChar is used
*
* Parameters:
* cReturnChar = "C" date returned as Char (American mm/dd/yyyy)
* cReturnChar = "S" date returned as dtos()  (yyyymmdd)
* cTitle = Window title defaults to "Select a date"  
*
* KEYS:  page up and down = month up and down
*        home and end = year up and down
*        nsert and Home = today 
*        Up arrow Down Arrow = week up and down
*        left and right arrow = next and prev day
*        esc = returns empty date or string
*
*====================================================================

function fGetdate
parameters cReturnChar , cTitle

* init local vars
lcSetTalk = set('talk')
set talk off
dimension la[42]
ldDate = date() 
lcSetDate = set('date')
set date to 'american'
lcSetCent = set('century')
Set century on
lnObject = 0
lnKey = 0

* check parameters
if type('cReturnChar') != 'C'
 cReturnChar = ' '
endif

if type('cTitle') != 'C'
 cTitle = "Select a Date"
endif

if _windows 
  * define window (win 26)
  define window wGetDate ;
  in desktop at 5,5 size 16,50 ;
  title cTitle ;
  font "arial", 10  ;
  float noclose nozoom;
  nominimize mdi;
  color rgb(0,0,0,192,192,192)
else
  ** create dos 2.6 window
  define window wGetDate ;
  from 10,21 to 22,60 ;
  color gr+/w ;
  shadow none
endif

Activate window wGetDate noshow 

do while .t.

 lcMY=Upper( cMonth(ldDate) )+' '+str( year(ldDate) , 4)
 
 * call drawgrid 
 =fDrawGrid(ldDate)

 clear gets
 lcOption = 'Today'
 lcR1 ='@*TH '+la[1]+la[2]+la[3]+la[4]+la[5]+la[6]+strtran(la[7],';')
 lcR2 ='@*TH '+la[8]+la[9]+la[10]+la[11]+la[12]+la[13]+strtran(la[14],';')
 lcR3 ='@*TH '+la[15]+la[16]+la[17]+la[18]+la[19]+la[20]+strtran(la[21],';')
 lcR4 ='@*TH '+la[22]+la[23]+la[24]+la[25]+la[26]+la[27]+strtran(la[28],';')
 lcR5 ='@*TH '+la[29]+la[30]+la[31]+la[32]+la[33]+la[34]+strtran(la[35],';')
 lcR6 ='@*TH '+la[36]+la[37]+la[38]+la[39]+la[40]+la[41]+strtran(la[42],';')

 if _windows

  @ .5,10 say padc(lcMy,25) font 'Arial',12 style 'B'
 
  @ 2, 5     say "SU"
  @ 2, 11    say "MO"
  @ 2, 17    say "TU" 
  @ 2, 22.5  say "WE"
  @ 2, 29    say "TH"
  @ 2, 35    say "FR"
  @ 2, 41    say "SA"
  
  @ 3.2,4     GET lcOption PICTURE lcR1 SIZE 1.5,5,1
  @ 4.9,4    GET lcOption PICTURE lcR2 SIZE 1.5,5,1
  @ 6.6,4    GET lcOption PICTURE lcR3 SIZE 1.5,5,1
  @ 8.3,4    GET lcOption PICTURE lcR4 SIZE 1.5,5,1 
  @ 10.0,4  GET lcOption PICTURE lcR5 SIZE 1.5,5,1
  @ 11.7,4     GET lcOption PICTURE lcR6 SIZE 1.5,5,1
  
  @ 14,4  get lcOption picture "@*TH \<+M;M\<-;+Y;Y-" size 1.5,5,1
  @ 14,37 get lcOption picture "@*TH \<Today" size 1.5,8,1
  
 else

  lcColor = ' ,,,,,W+/n,r/w,,W+/w,n+/w '
  @0,0 say padr(space(1)+alltrim(cTitle),40,' ') color w+/rb
  @2,0 say padc(lcMY,40,' ')
  @3,0 say padc('SU   MO   TU   WE   TH   FR   SA',40,' ')  
  @4,3 get lcOption picture lcR1 COLOR (lcColor)
  @5,3 get lcOption picture lcR2 COLOR (lcColor)
  @6,3 get lcOption picture lcR3 COLOR (lcColor)
  @7,3 get lcOption picture lcR4 COLOR (lcColor)
  @8,3 get lcOption picture lcR5 COLOR (lcColor)
  @9,3 get lcOption picture lcR6 COLOR (lcColor)
  @11,3 get lcOption PICTURE '@*TH \<+M;M\<-;+Y;Y-' COLOR (lcColor)
  @11,30 get lcOption PICTURE '@*TH \<Today' COLOR (lcColor)
 endif
 
  
 on key label PGUP clear read
 on key label PGDN Clear read
 on key label UPARROW clear read
 on key label DNARROW clear read
 on key label LEFTARROW clear read
 on key label RIGHTARROW clear read
 on key label HOME clear read
 on key label END clear read
 on key label INS clear read
 on key label DEL clear read

 move window wGetDate center
 Show window wGetDate
 keyboard "%"

 read cycle modal OBJECT lnObject
 * hide window wGetDate
 
 * evaluate selection
 do case
  case lastKey() = 5
   * UPARROW
   ldDate = ldDate - 7
  case lastKey() = 24
   * DNARROW
   ldDate = ldDate + 7
  case lastKey() = 19
   * LEFTARROW
   ldDate = ldDate - 1 
  case lastKey() = 4
   * RIGHTARROW
   ldDate = ldDate + 1 
  case lastKey() = 27
   ldDate = ctod('  /  /    ')
   Exit
  case lcOption = '+M' or LastKey() = 3
   ldDate = gomonth(ldDate,1)
  case lcOption = 'M-'  or LastKey() = 18
   ldDate = gomonth(ldDate,-1) 
  case lcOption = '+Y' or lastkey() = 1
   ldDate = gomonth(ldDate,12)
  case lcOption = 'Y-' or Lastkey() = 6
   ldDate = gomonth(ldDate,-12)
  case lcOption = 'Today' or lastKey() = 7  or lastkey() = 22
   ldDate = date()
  otherwise  
   ldDate = ctod( str(month(ldDate),2) ;
    + '/'+ lcOption + '/' + str(year(ldDate),4)  )
   exit  
 endcase

enddo && main loop

* evaluate return
do case
 case 'C' $ upper(cReturnChar)
  lResult = dtoc(ldDate)
 case 'S' $ upper(cReturnChar)
  lResult = dtos(ldDate)
 otherwise
  lResult = ldDate   
endcase

** cleanup
release window wGetDate
set talk &lcSetTalk
Set century  &lcSetCent
set date to &lcSetDate
on key

keyboard "%"
return lResult
*--------------------------------------------------------------------
function fDrawGrid
parameters p1

ldDate = p1
ldFirst= ldDate - ( day(ldDate) -1 )
ldStart = ldFirst - ( dow(ldFirst) - 1 )

lnctr=0 
for lnRow = 1 to 6
 for lnCol = 1 to 7
  lnCtr = lnCtr + 1
  if month(ldStart)=month(ldFirst)
   if ldStart = ldDate
    la[lnCtr] = transform(day(ldStart) ,"@L 99")+';'
    lnObject = lnCtr
   else
    la[lnCtr] = transform(day(ldStart) ,"@L 99")+';'
   endif 
  else
   la[lnCtr] = '\\'+transform(day(ldStart) ,"@L 99")+';'
  endif
  ldStart = ldStart + 1
 endfor && lnCol
endfor && lRow

return .t.
* fgetdate()
*====================================================================
*====================================================================
 