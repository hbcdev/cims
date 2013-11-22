* Program-ID.. ..: ERRTRAP
* Purpose.. .. ..: General purpose error trap
PARAMETERS ErrNum, Msg, Code
* Called with: ON ERROR DO ERRTRAP WITH ERROR(),MESSAGE(),MESSAGE(1)
ON ERROR
SaveAlias = ALIAS()
SaveDB = SET("DATABASE")
SET DATABASE TO
SET MEMOWIDTH TO 80
IF NOT FILE ( "ERRORS.DBF")
   CREATE TABLE ERRORS FREE ;
   ( Date D(8), Time C(5), Program C(50),;
     ErrorNum N(4), Message C(240), BadCodeC (240))
ENDIF
IF NOT USED ( "ERRORS" )
   SELECT 0
   USE ERRORS
ENDIF
DIMENSION pROGnAME[10]
FOR i = 1 TO 10
    ProgName[I] = SYS (16, I)
ENDFOR

Name = IIF ( m.Name = "PROCEDURE ", SUBSTR ( m.Name, 11 ), m.Name )
INSERT INTO ERRORS VALUES ( DATE(), TIME(), m.Name, ERRNUM, Msg, m.Code )

IF NOT EMPTY ( SaveAlias )
   SELECT ( SaveAlias )
ENDIF
SET MEMOWIDTH TO 90
Msg1 = MLINE ( Msg, 1 )
Msg2 = MLINE ( Msg, 2 )
Code1 = MLINE ( m.Code, 1 )
Code2 = MLINE ( m.Code, 2 )
Code3 = MLINE ( m.Code, 3 )
Code4 = MLINE ( m.Code, 4 )
msg = [Error in ] + Name + CHR(13);
    + Msg1 + CHR(13) + Msg2 + CHR(13);
    + "Code was ;"+CHR(13) + Code3 + CHR(13) + Code4
=MessageBox ( msg, 64, AppName )
WAIT WINDOW "<C>ancel, <R>esume, <D>ebug: " TO Result
* There are three valid responses:
DO CASE
CASE Result $ [Cc]
     SET SYSMENU TO DEFAULT
     * Clear open transactions
     DO WHILE TXNLEVEL() > 0
        ROLLBACK
     ENDDO
     IF CursorGetProp ("Buffering") = 3
        IF "2" $ GetFldState(-1)
           =TableRevert(.T.)
        ENDIF
     ENDIF
     CLEAR EVENTS
     CLEAR WINDOW
     CANCEL
CASE Result $ [Dd]
     IF NOT EMPTY ( SaveDB )
        SET DATABASE TO ( SaveDB )
     ENDIF
     SET SYSMENU TO DEFAULT
     ACTIVATE WINDOW DEBUG
     SET STEP ON
OTHERWISE  &&default to "Resume"
IF NOT EMPTY ( SaveDB )
   SET DATABASE TO &SaveDB
ENDIF
ON ERROR DO ERRTRAP WITH ERROR(), MESSAGE(), MESSAGE(1)
ENDCASE
