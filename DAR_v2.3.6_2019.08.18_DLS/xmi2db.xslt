<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions"
xmlns:xmi="http://www.omg.org/spec/XMI/20110701">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<xsl:template match="/">
		<xsl:for-each select="/xmi:XMI/xmi:Extension/elements/element[@xmi:type='uml:Class']">
	CREATE TABLE <xsl:value-of select="@name"/> (


	<xsl:for-each select="attributes/attribute">
			  <xsl:value-of select="properties/@type"/>(<xsl:value-of select="properties/@length"/>)   <xsl:value-of select="@name"/>, -- <xsl:value-of select="tags/tag[@name='definition']/@value"/>
----
			  <xsl:copy-of select="."/> 
		  </xsl:for-each>
	);
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>
