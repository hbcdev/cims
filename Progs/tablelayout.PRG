**********************************************************************
* Program....: TABLELAYOUT.PRG
* Version....: 
* Author.....: B.L.P.M. Lutgerink
* Date.......: 17 August 2003, 07:26:32
* Notice.....: Copyright © 2003,  Placed in public domain through www.foxite.com
* Compiler...: Visual FoxPro 08.00.0000.2521 for Windows
* Abstract...: 
* Changes....: 17-08-2003, created
* Parameters.: 
* Purpose....: 
**********************************************************************

local loword as "word.application", laFld[1], lnI as Integer

IF AFIELDS(laFld)>0
   #DEFINE wdLine 5
   #DEFINE wdCell 12
   #DEFINE wdColorGray15 14277081
   #DEFINE wdToggle 9999998
   #DEFINE wdFieldPage 33
   
   loWord = CREATEOBJECT("Word.Application")
   loWord.documents.add

   loword.ActiveDocument.PageSetup.Orientation= 1  && wdOrientLandscape

   * pageheader
   loword.ActiveWindow.ActivePane.View.SeekView= 9  && wdSeekCurrentPageHeader
   WITH loword
      WITH .Selection
         .ParagraphFormat.Alignment= 1  && wdAlignParagraphCenter
         .Text="Lay-Out of: "+ALIAS()
         .EndKey( wdLine)
         .TypeParagraph
         .Text="Page: "
         .EndKey( wdLine)
         .Fields.Add(loword.Selection.Range, wdFieldPage)
      ENDWITH

      * main document
      .ActiveWindow.ActivePane.View.SeekView= 0  && wdSeekMainDocument
      
      WITH .selection
         .Range.Text="Table lay-out"
         .EndKey( wdLine)
         .TypeParagraph
   
         * add the table
         .Tables.Add( loword.Selection.Range,1,4)
         .Range.Text="Field name"
         .Tables(1).Cell(1, 2).select
         .Range.Text="Field type"
         .Tables(1).Cell(1, 3).select
         .Range.Text="Field length"

         .Tables(1).Cell(1, 4).select
         .Range.Text="Decimals (optional)"

         .Tables(1).Rows( 1).Select
         .InsertRowsBelow
         .Tables(1).Rows( 1).Select
         .Cells.Shading.BackgroundPatternColor= wdColorGray15
         .Rows.HeadingFormat=wdToggle

         FOR lnI = 1 TO ALEN( laFld,1)
            
            .Tables(1).Rows( lnI+1).Select
            
            .Tables(1).Cell(lnI+1, 1).select
            .Range.Text=laFld[ lnI,1]
            
            .Tables(1).Cell(lnI+1, 2).select
            .Range.Text=laFld[ lnI,2]
            
            .Tables(1).Cell(lnI+1, 3).select
            .Range.Text=TRANSFORM(laFld[ lnI,3])

            .Tables(1).Cell(lnI+1, 4).select
            .Range.Text=TRANSFORM(laFld[ lnI,4])      

            IF lnI < FCOUNT()
               .InsertRowsBelow
            ENDIF
            
         ENDFOR
       ENDWITH   
   ENDWITH
   
ENDIF
IF TAGCOUNT()>0
   WITH loword.selection
      .MoveDown
      .TypeParagraph
      .Range.Text="Index information"
      .EndKey( wdLine)
      .TypeParagraph

      .Tables.Add( loword.Selection.Range,1,2)
      .Tables(1).Cell(1, 1).select
      .Range.Text="Tagname"
      .Tables(1).Cell(1, 2).select
      .Range.Text="Key"

      .Tables(1).Rows( 1).Select
      .InsertRowsBelow
      .Tables(1).Rows( 1).Select
      .Cells.Shading.BackgroundPatternColor= wdColorGray15

      FOR lnI = 1 TO TAGCOUNT()
            .Tables(1).Cell(lnI+1, 1).select
            .Range.Text=TAG(lnI)
            
            .Tables(1).Cell(lnI+1, 2).select
            .Range.Text=KEY(lnI)

            IF lnI < TAGCOUNT()
               .InsertRowsBelow
            ENDIF
      ENDFOR
   ENDWITH
ELSE
   WITH loword.selection
      .EndKey( wdLine)
      .MoveDown
      .TypeParagraph
      .Range.Text="No Indexes available"
      .EndKey( wdLine)
   ENDWITH
ENDIF

*loword.ActiveWindow.PrintOut
loword.ActiveDocument.SaveAs( FULLPATH(CURDIR())+ALIAS())
loword.ActiveDocument.Close(0)
INKEY(2,'M')
loword.Quit
RELEASE loWord
