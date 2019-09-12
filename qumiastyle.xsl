<?xml version="1.0" encoding="ISO-8859-1"?>

<xsl:stylesheet version="1.0"
xmlns:xsl="http://www.w3.org/1999/XSL/Transform">

<xsl:template match="/">
  <html>
  <body>
    <h1>QUMIA verslag</h1><br></br>

	<h2>Patient gegevens</h2>
    <b>Datum:</b> <xsl:value-of select="qumia_xml/patient/meetdatum"/> <br></br><br></br>
    <b>Patient naam: </b><xsl:value-of select="qumia_xml/patient/name"/><br></br>
    <b>Patient nummer: </b><xsl:value-of select="qumia_xml/patient/patientid"/><br></br>
    <b>Geboortedatum: </b><xsl:value-of select="qumia_xml/patient/geboortedatum"/><br></br>
    <b>Gewicht: </b><xsl:value-of select="qumia_xml/patient/gewicht"/><br></br>
    <b>Leeftijd:</b> <xsl:value-of select="qumia_xml/patient/leeftijd"/><br></br>
    <b>Geslacht:</b> <xsl:value-of select="qumia_xml/patient/geslacht"/><br></br>
    <b>Dominantie:</b> <xsl:value-of select="qumia_xml/patient/kant"/><br></br>

    <h2>Spier echo intensiteit</h2>
    <table border="1">
    <tr bgcolor="#00F0FA">
      <th align="left">Spier</th>
      <th align="left">Kant</th>
      <th align="left">Echo intensiteit</th>
      <th align="left">Normaalwaarde</th>
      <th align="left">Z-score</th>
    </tr>
    <xsl:for-each select="qumia_xml/muscle">
    <xsl:if test="EI > 0"> 	
    <tr>	  
      <td><xsl:value-of select="muscle_name"/></td>
      <td><xsl:value-of select="side"/></td>
      <td><xsl:value-of select="EI"/></td>
      <td><xsl:value-of select="EI_normal"/></td>
      <td><xsl:value-of select="EI_zscore"/></td>
    </tr>
    </xsl:if>
    </xsl:for-each>
    </table>

    <h2>Spierdikte</h2>
    <table border="1">
    <tr bgcolor="#9acd32">
      <th align="left">Spier</th>
      <th align="left">Kant</th>
      <th align="left">Dikte</th>
      <th align="left">Normaalwaarde</th>
      <th align="left">Z-score</th>
    </tr>
    <xsl:for-each select="qumia_xml/muscle">
    <xsl:if test="thickness > 0"> 	
    <tr>
      <td><xsl:value-of select="muscle_name"/></td>
      <td><xsl:value-of select="side"/></td>
      <td><xsl:value-of select="thickness"/></td>
      <td><xsl:value-of select="thickness_normal"/></td>
      <td><xsl:value-of select="thickness_zscore"/></td>
    </tr>
    </xsl:if>
    </xsl:for-each>
    </table>

    <br></br><br></br>
	<h2>Echo-intensiteit afbeelding</h2>
	<img>
	<xsl:attribute name="src"><xsl:value-of select="translate(qumia_xml/zscore_image,'/','\')"/></xsl:attribute>
	</img>

    <br></br><br></br>
	<h2>Fasciculaties afbeelding</h2>
	<img>
	<xsl:attribute name="src"><xsl:value-of select="translate(qumia_xml/fasc_image,'/','\')"/></xsl:attribute>
	</img>


    <br></br>
    <b>Machine:</b> <xsl:value-of select="qumia_xml/machine"/><br></br>
    <b>Qumia:</b> <xsl:value-of select="qumia_xml/qumiaversion"/><br></br>
    <b>Technician:</b> <xsl:value-of select="qumia_xml/laborant/naam"/><br></br>

  </body>
  </html>
</xsl:template>

</xsl:stylesheet>
