*!* The following code commences the OLE Automation process.                 *!*
oExcelObject = CREATEOBJECT('Excel.Application')                                
                                                                              
*!* The following code opens the "VFP_to_Excel" file that was created by the *!*
*!* "COPY TO" command                                                        *!*
oExcelWorkbook = oExcelObject.Application.Workbooks.Open(gcReportPath + "WT3")
                                                                               
*!* The following code activates the Worksheet which contains the "COPY TO"  *!*
*!* data                                                                     *!*
oActiveExcelSheet = oExcelWorkbook.Worksheets("WT3").Activate
                                                                                
*!* The following code establishes an Object Reference to the "VFP_to_Excel" *!*
*!* worksheet                                                                *!*
oExcelSheet = oExcelWorkbook.Worksheets("WT3")
                                                                                
WAIT WINDOW "Developing Microsoft Excel File..." + CHR(13) + "" + CHR(13) + ;   
         "Passing formatting information to Excel." + CHR(13) + "" NOWAIT       
                                                                                
*!* The following code selects row 2 and then inserts a row that will serve  *!*
*!* as a spacer between the field names and the first row of data.           *!*
oExcelSheet.Rows("2:2").Select                                                  
oExcelSheet.Rows("2:2").Insert                                                  
                                                                                
*!* The following code sets font attributes of row 1 (the field names).      *!*
oExcelSheet.Rows("1:1").Font.Name = "Arial"                                     
oExcelSheet.Rows("1:1").Font.FontStyle = "Bold"                                 
oExcelSheet.Rows("1:1").Font.Size = 8                                           
                                                                                
*!* The following code creates an array using the AFIELDS() Function.  This  *!*
*!* array will provide information pertaining to the data type, width, and   *!*
*!* number of decimal places for each field of the source table.             *!*
lnFields = AFIELDS(laFields)                                                    
                                                                                
*!* The following code in the FOR loop will be processed for each field in   *!*
*!* the source table.                                                        *!*
FOR iField1 = 1 TO lnFields                                                     
                                                                                
   *!* The following line of code uses a Procedure (ColumnLetter) that is    *!*
   *!* contained in this program.  This procedure will return a              *!*
   *!* corresponding Excel Column (letter) reference that must be used in    *!*
   *!* passing any cell or column specific formatting or information to      *!*
   *!* Excel.                                                                *!*
   lcColumn    = ColumnLetter(iField1)                                          
                                                                                
   *!* The following code creates strings of information in a format         *!*
   *!* required by Excel for the processing of commands that are specific to *!*
   *!* rows, columns, and/or cells.  For example, in order to SELECT a range *!*
   *!* of cells from the third field of a 62 record table, you must bear the *!*
   *!* following in mind:                                                    *!*
   *!* 1. The top 2 rows consist of the field names and then a spacer row    *!*
   *!*    between that and the top data.                                     *!*
   *!* 2. On account of the above, the data will start at row 3 and end at   *!*
   *!*    row 62 + 2.                                                        *!*
   *!* 3. Also on account of the above, any added numeric calculation must   *!*
   *!*    be contained at row 62 + 3.                                        *!*
   *!* So, in order to pass the cell to contain a calculation for column 3,  *!*
   *!* you must pass (with the quotes) "C65"  The range of cells for the     *!*
   *!* calculation must be passed (with the quotes) as "C3:C64"  Lastly, the *!*
   *!* string to pass to Select column 3 (with the quotes) as "C:C"          *!*
   *!* Therefore, this program builds these strings out and stores them to   *!*
   *!* variables for Macro Substitution so that the literal string contains  *!*
   *!* quotes for passing the information to Excel.                          *!*
   lcCellForCalcuation = ;                                                      
      ["] + lcColumn + ALLTRIM(STR(RECCOUNT() + 3)) + ["]                       
   lcCalculationRange = ;                                                       
      lcColumn + [3:] + lcColumn + ALLTRIM(STR(RECCOUNT() + 2))                 
   lcColumnExpression = ;                                                       
      ["] + lcColumn + [:] + lcColumn + ["]                                     
   oExcelSheet.Columns(&lcColumnExpression.).Select                             
                                                                                
   *!* The following code checks for the data type of the source Visual      *!*
   *!* FoxPro table by referencing the array created earlier in the program. *!*
   *!* Depending upon the data type, a literal format expression is built to *!*
   *!* contain quotes and is later passed to Excel by Macro Substituted      *!*
   *!* reference (i.e. an ampersand [&] followed by a period [.] terminator).*!*
   DO CASE                                                                      
                                                                                
      CASE (laFields(iField1,2)$"C.L")  &&  Is the field data type Character *!*
                                        *!* or Logical                       *!*
         lcFmtExp = ["@"]               &&  Pass Character formatting        *!*
                                                                                
      CASE (laFields(iField1,2)$"N.I.Y")&&  Is the field data type Numeric,  *!*
                                        *!* Integer, or Currency             *!*
         IF (laFields(iField1,2)$"Y")      &&  If it is Currency             *!*
            lcFmtExp = ["$#,##0.00"]          &&  Pass Currency Formatting   *!*
                                              *!* with a comma separator     *!*
         ELSE                              &&  If it is other than Currency  *!*
            IF laFields(iField1,4) = 0        &&  If the Decimal Width is    *!*
                                              *!* zero                       *!*
               lcFmtExp = ["0"]                  &&  Pass Numeric formatting *!*
                                                 *!* with no decimals        *!*
            ELSE                              &&  Otherwise                  *!*
               *!* Build a format string containing the appropriate number   *!*
               *!* of decimals                                               *!*
               lcFmtExp = ["0.] + REPLICATE("0", laFields(iField1,4)) + ["]     
            ENDIF                                                               
         ENDIF                                                                  
                                                                                
      CASE (laFields(iField1,2)$"D.T")  &&  Is the field data type Date or   *!*
                                        *!* DateTime                         *!*
         lcFmtExp = ["mm/dd/yy"]           &&  Pass Date formatting          *!*
                                                                                
   ENDCASE                                                                      
                                                                                
   *!* The following code passes the derived format expression to Excel      *!*
   oExcelSheet.Columns(&lcColumnExpression.).NumberFormat = &lcFmtExp.          
                                                                                
   *!* If the field data type is Numeric, Integer, or Currency, will add a   *!*
   *!* calculation to the cell immediately below the last row containing     *!*
   *!* data.                                                                 *!*
   IF (laFields(iField1,2)$"N.I.Y")     &&  Is the field data type Numeric,  *!*
                                        *!* Integer, or Currency             *!*
      oExcelSheet.Range(&lcCellForCalcuation.).Value = ;                        
         [=SUM(&lcCalculationRange.)]                                           
      IF (laFields(iField1,2)$"N.I")       &&  Is the field data type        *!*
                                           *!* Numeric or Integer            *!*
         oExcelSheet.Range(&lcCellForCalcuation.).Select                        
                                                                                
         *!* The following code will format the cell containing the          *!*
         *!* calculation to have a comma separator.  This process was        *!*
         *!* already done for any event where the field data type was        *!*
         *!* currency.                                                       *!*
         lcCalculationFormat = ["#,##0] + IIF(laFields(iField1,4) > 0, [.] +;   
            REPLICATE("0", laFields(iField1,4)), []) + ["]                      
         oExcelSheet.Range(&lcCellForCalcuation.).NumberFormat = ;              
            &lcCalculationFormat.                                               
      ENDIF                                                                     
   ENDIF                                                                        
                                                                                
ENDFOR                                                                          
                                                                                
*!* Once the data has been formatted and any calculation have been added,    *!*
*!* the file is ready for the application of final formatting, autofitting   *!*
*!* of cells, and the setting of print attributes.                           *!*
WAIT WINDOW "Developing Excel File Report" + CHR(13) + "" + CHR(13) +;          
   "setting print area and final formatting" NOWAIT                             
oExcelSheet.Cells.Select                                                        
oExcelSheet.Cells.EntireColumn.AutoFit                                          
oExcelSheet.Range(&lcTotalRangeExpr.).Select                                    
                                                                                
*!* IMPORTANT NOTE - POSSIBILITY OF PAGE SETUP OBJECT UNAVAILABLE ERRORS IF  *!*
*!*                  THIS PROGRAM IS RUN ON A MACHINE WITH NO REGISTERED     *!*
*!*                  PRINTER DEVICE.                                         *!*
*!*                                                                          *!*
*!* The following code section performs operations that are offered in the   *!*
*!* "Page Setup" user interface of Microsoft Excel.  If this program is run  *!*
*!* from a computer where no printer driver is installed (it can be off line *!*
*!* or online or disconnected, but the printer driver software must be       *!*
*!* installed and a registered printer device must be available as a         *!*
*!* printer), then this section may produce errors than can be ignored.      *!*
WITH oExcelSheet.PageSetup                                                      
                                                                                
   *!* This area sets to Title Rows of the spreadsheet that will be printed  *!*
   *!* on each page.  Since this example contains the table field names on   *!*
   *!* the top row, and then an empty row of cells that was inserted by this *!*
   *!* program, then we will set row 1 through row 2 as the title rows.      *!*
   .PrintTitleRows = "$1:$2"                                                    
   *!* Setting Title Columns would work in similar fashion to Setting Title  *!*
   *!* Rows.  Here, however, the column letter would be used in syntax       *!*
   *!* similar to the above example.  Here, however, a null string is        *!*
   *!* passed.  This example simply shows that the option is available.      *!*
   .PrintTitleColumns = ""                                                      
   .PrintArea = &lcTotalPrintArea.      &&  The print area is set            *!*
   .LeftHeader = lcExcelFile            &&  The left header is populated     *!*
                                        *!* with the file name               *!*
   .CenterHeader = ""                   && The Center Header and the ...     *!*
   .RightHeader = ""                    && Right Header are left blank       *!*
   *!* The below referenced "cStamp" is a procedure contained in this        *!*
   *!* program.  It builds out a string which contains the computer system   *!*
   *!* date and time on which the resulting Excel file was created.          *!*
   .LeftFooter = cStamp()               &&  Left Footer is populated with    *!*
                                        *!* cStamp returned string           *!*
   .RightFooter = "Page &P of &N"       &&  Right Footer is populated with   *!*
                                        *!* Page _ of _                      *!*
   .CenterHorizontally = .T.            &&  Print area centered horizontally *!*
   .CenterVertically = .F.              &&  Print area not centered          *!*
                                        *!* vertically                       *!*
   .Orientation = lnPrintOrientation    &&  The parameter derived print      *!*
                                        *!* orientation is set               *!*
   .Papersize = lnPaperSize             &&  The parameter derived paper size *!*
                                        *!* is set                           *!*
   .Zoom = .F.                          &&  The "Adjust to" scaling is       *!*
                                        *!* suppressed                       *!*
   .FitToPagesWide = 1                  &&  The scaling of "Fit To" and 1    *!*
                                        *!* page wide is selected            *!*
   .FitToPagesTall = 99                 &&  The scaling of "Fit To" and 99   *!*
                                        *!* pages tall is selected           *!*
                                        *!* NOTE: This will not cause a      *!*
                                        *!* small file to span 99 pages, but *!*
                                        *!* it would cause a smaller file to *!*
                                        *!* be compressed.                   *!*
                                                                                
ENDWITH                                                                         
                                                                                
*!* The following code selects the upper left cell of the derived Excel      *!*
*!* file                                                                     *!*
oExcelSheet.Range("A1").Select                                                  
                                                                                
*!* The following code saves the derived Excel file to its assigned name and *!*
*!* location                                                                 *!*
oExcelWorkbook.SaveAs(lcExcelFile)                                              
                                                                                
=MESSAGEBOX("Your Excel File is Ready!",64)                                     
                                                                                
*!* The following code turns the OLE instance of Excel visible               *!*
oExcelObject.Visible = .T.                                                      
                                                                                
*!****************************************************************************!*
*!*                       End of program VFPExcel.prg                        *!*
*!****************************************************************************!*
                                                                                
                                                                                
*!****************************************************************************!*
*!* Beginning of PROCEDURE ColumnLetter                                      *!*
*!* This procedure derives a letter reference based on a numeric value.  It  *!*
*!* uses the basis of the ASCII Value of the upper case letters A to Z (65   *!*
*!* through 90) to return the proper letter (or letter combination) for a    *!*
*!* provided numeric value.                                                  *!*
*!****************************************************************************!*
                                                                                
PROCEDURE ColumnLetter                                                          
                                                                                
   PARAMETER lnColumnNumber                                                     
                                                                                
      lnFirstValue = INT(lnColumnNumber/27)                                     
      lcFirstLetter = IIF(lnFirstValue=0,"",CHR(64+lnFirstValue))               
      lcSecondLetter = CHR(64+MOD(lnColumnNumber,26))                           
                                                                                
RETURN lcFirstLetter + lcSecondLetter                                           
                                                                                
*!****************************************************************************!*
*!*                      End of procedure ColumnLetter                       *!*
*!****************************************************************************!*
                                                                                
                                                                                
*!****************************************************************************!*
*!* Beginning of PROCEDURE cStamp                                            *!*
*!* This procedure derives a text representation of the system date and time *!*
*!* in the form of:                                                          *!*
*!* 01/01/2000 11:59:00 would be rendered as:                                *!*
*!* Saturday, January 1, 2000 @ 11:59 am                                     *!*
*!****************************************************************************!*
                                                                                
PROCEDURE cStamp                                                                
                                                                                
   cDTString1 = CDOW(DATE()) + ", "                                             
   cDTString2 = CMONTH(DATE()) + " "                                            
   cDTString3 = ALLTRIM(STR(DAY(DATE()))) + ", "                                
   cDTString4 = ALLTRIM(STR(YEAR(DATE()))) + " @ "                              
   cDTString5 = IIF(VAL(LEFT(TIME(), 2)) > 12, ;                                
      ALLTRIM(STR(VAL(LEFT(TIME(), 2)) - 12)) +;                                
      SUBSTR(TIME(), 3, 3), LEFT(TIME(), 5))                                    
   cDTString6 = IIF(VAL(LEFT(TIME(),2))=>12,"pm","am")                          
   cDTString  = "Created on " + cDTString1 + ;                                  
      cDTString2 + cDTString3 + cDTString4 + cDTString5 + cDTString6            
                                                                                
RETURN cDTString                                                                
                                                                                
*!****************************************************************************!*
*!*                    End of procedure cStamp                               *!*
*!****************************************************************************!*
