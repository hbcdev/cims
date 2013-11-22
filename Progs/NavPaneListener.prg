*--
*-- Implements a Report Preview in HTML format that shows the pages in a Navigation Page
*-- Author: Fabio Vazquez
*--
*-- Goal..: Brazilian Visual FoxPro Conference 2004
*--         Demonstrate the Report Listener funtionalities
*--

LOCAL lcPath as String 
LOCAL loRL   as ReportListener
LOCAL loIE   as InternetExplorer.Application


lcPath = JUSTPATH(SYS(16))
CD (lcPath)


loRL = CREATEOBJECT("NavPaneListener", lcPath)
IF TYPE("loRL") != "O"
  RETURN 
ENDIF 


*-- Renders the page but doesn't send it to to the output device.
*-- The events are triggered normally, giving us the chance to capture 
*-- interesting events like "OutputPage"
loRL.ListenerType =  2


REPORT FORM ? OBJECT loRL 






*================================================
DEFINE CLASS NavPaneListener as ReportListener 
*================================================

   HIDDEN cPathSaida    as String 
   HIDDEN oVisualizador as MeuVisualizador 

   *---------------------------------------------------------------------------
   PROCEDURE Init(tcPathSaida as String)
   *---------------------------------------------------------------------------
     IF MESSAGEBOX("You are about to preview a report. Are you sure?", 4+32, "VFP 9") = 7
       RETURN .F.
     ENDIF 
     
     IF !EMPTY(tcPathSaida)
       This.cPathSaida = ADDBS(tcPathSaida)
     ELSE 
       This.cPathSaida = ""
     ENDIF 
     
     This.oVisualizador = NEWOBJECT("MeuVisualizador")
   ENDPROC 

  
   *---------------------------------------------------------------------------
   PROCEDURE OutputPage ;
             ( ;
               nPageNo     as Integer, ;
               eDevice     as Object, ;
               nDeviceType as Integer ;
             )
   *---------------------------------------------------------------------------
     WAIT WINDOW "Printing page <" + NVL(TRANSFORM(npageNo),"Null") + ">..." NOWAIT 
     
     DO CASE 
       CASE nDeviceType == -1  && None
         nDeviceType = 103     && GIF
         This.OutputPage(nPageNo, This.cPathSaida + "Pagina" + TRANSFORM(nPageNo) + ".GIF", nDeviceType)
       CASE nDeviceType == 103
         This.oVisualizador.AddPagina(eDevice)
     ENDCASE   
     
     WAIT CLEAR 
     
   ENDPROC
   
   
   *---------------------------------------------------------------------------
   PROCEDURE AfterReport
   *---------------------------------------------------------------------------
     This.oVisualizador.GerarVisualizacao(This.cPathSaida)
   ENDPROC    
  
  
ENDDEFINE 




*=========================================
DEFINE CLASS MeuVisualizador as Custom
*=========================================

  HIDDEN oXML as MSXML2.DOMDocument 
  HIDDEN oXSL as MSXML2.DOMDocument
  
  *---------------------------------------------------------------------------
  PROCEDURE Init
  *---------------------------------------------------------------------------
    LOCAL lcXML as String 
    
    This.oXML = NEWOBJECT("MSXML2.DOMDocument")
    This.oXSL = NEWOBJECT("MSXML2.DOMDocument")
    
    TEXT TO lcXML NOSHOW TEXTMERGE PRETEXT 1+2+4
      <Visualizador>
        <Data>2004-10-01T00:00:00</Data>
        <Paginas>
          <!-- The nodes representing each page will be added here -->
        </Paginas>
      </Visualizador>
    ENDTEXT 

    This.oXML.LoadXML(lcXML)
    This.oXSL.LoadXML(This.GetXSL())
  ENDPROC 
  
  
  *---------------------------------------------------------------------------
  HIDDEN FUNCTION GetXSL()
  *---------------------------------------------------------------------------
    LOCAL lcXSL as String 
    
    TEXT TO lcXSL NOSHOW TEXTMERGE PRETEXT 1+2+4
      <?xml version="1.0"?>
      <xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">

        <xsl:template match="/">
          <html>
            <head>
              <title>Report Viewer - Visual FoxPro 9</title>
              <script>
              function teste()
              {
                alert("testando")
              }
              </script>
            </head>
            <body bgcolor="#CCCCCC" >
              <div style="display:block; background-color:Navy;">
                <center> 
                  <font face="Verdana" size="4" color="white">
                    Páginas
                  </font>
                </center>
              </div>
              <p/>
              <xsl:for-each select="Visualizador/Paginas">
                 <xsl:for-each select="Pagina">
                   <xsl:call-template name="Pagina">
                     <xsl:with-param name="nodoPagina" select="." />
                   </xsl:call-template>
                 </xsl:for-each>
              </xsl:for-each>
            </body>            
          </html>
        </xsl:template>
   
        <xsl:template name="Pagina">
          <xsl:param name="nodoPagina" />
            <a href='{$nodoPagina}' target="Previa">
              <img src='{$nodoPagina}' height="20%" width="100%" />
            </a>
            <p/>
        </xsl:template>
   
      </xsl:stylesheet>    
    ENDTEXT 
    
    RETURN lcXSL
  ENDFUNC 
  
  
  *---------------------------------------------------------------------------
  FUNCTION AddPagina(tcNomeArq as String)
  *---------------------------------------------------------------------------
    LOCAL loElemPaginas as MSXML2.IXMLDOMElement 
    LOCAL loElem as MSXML2.IXMLDOMElement 
    
    loElemPaginas = This.oXML.SelectSingleNode("/Visualizador/Paginas")
    
    loElem = THis.oXML.CreateElement("Pagina")
    loElem.Text = alltrim(tcNomeArq)
    
    loElemPaginas.AppendChild(loElem)

  ENDFUNC 
  
  
  *---------------------------------------------------------------------------
  FUNCTION GerarVisualizacao(tcPathSaida as String)
  *---------------------------------------------------------------------------
    LOCAL lcPathSaida as String 
    LOCAL lcHTML      as String 
    LOCAL lcHTMLLista as String 
    LOCAL lcSetSafety as String 
    
    lcPathSaida = EVL(tcPathSaida, "")
    
    lcHTMLLista = This.oXML.TransformNode(This.oXSL)
    
    TEXT TO lcHTML NOSHOW TEXTMERGE 
    <html>
      <frameset cols="15%, 85%">
        <frame name="Lista"  SRC="Lista.htm">
        <frame name="Previa" SRC="Pagina1.gif">
      </frameset>            
    </html>
    ENDTEXT 
    
    lcSetSafety = SET("Safety")
    SET SAFETY OFF 
    STRTOFILE(STRCONV(lcHTML,9),      lcPathSaida + "VisualizadorVFP9.Htm")
    STRTOFILE(STRCONV(lcHTMLLista,9), lcPathSaida + "Lista.Htm")
    SET SAFETY &lcSetSafety.
    
    loIE = CREATEOBJECT("InternetExplorer.Application")
    loIE.Navigate("file:///" + lcPathSaida + "VisualizadorVFP9.Htm")
    loIE.Visible = .T.
    
  ENDFUNC 

ENDDEFINE 

