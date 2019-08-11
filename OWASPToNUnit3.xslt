<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet version="2.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="msxsl">
  <xsl:output method="xml" indent="yes"/>

  <xsl:param name="sourceFolder"/>

  <xsl:variable name="NumberOfItems" select="count(OWASPZAPReport/site/alerts/alertitem)"/>
  <xsl:variable name="generatedDateTime" select="OWASPZAPReport/generated"/>
  
  <xsl:template match="/">
    <test-run id="1" name="OWASPReport" fullname="OWASPConvertReport" testcasecount="" result="Failed" total="{$NumberOfItems}" passed="0" failed="{$NumberOfItems}" inconclusive="0" skipped="0" asserts="{$NumberOfItems}" engine-version="3.9.0.0" clr-version="4.0.30319.42000" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0">
      <command-line>a</command-line>
      <test-suite type="Assembly" id="0-1005" name="OWASP" fullname="OWASP" runstate="Runnable" testcasecount="{$NumberOfItems}" result="Failed" site="Child" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0.352610" total="{$NumberOfItems}" passed="0" failed="{$NumberOfItems}" warnings="0" inconclusive="0" skipped="0" asserts="{$NumberOfItems}">
        
        <environment framework-version="3.11.0.0" clr-version="4.0.30319.42000" os-version="Microsoft Windows NT 10.0.17763.0" platform="Win32NT" cwd="C:\Program Files (x86)\Microsoft Visual Studio\2017\Enterprise\Common7\IDE" machine-name="Azure Hosted Agent" user="flacroix" user-domain="NORTHAMERICA" culture="en-US" uiculture="en-US" os-architecture="x86" />
        <test-suite type="TestSuite" id="0-1004" name="UnitTestDemoTest" fullname="UnitTestDemoTest" runstate="Runnable" testcasecount="2" result="Failed" site="Child" start-time="2019-02-01 17:03:03Z" end-time="2019-02-01 17:03:04Z" duration="0.526290" total="2" passed="1" failed="1" warnings="0" inconclusive="0" skipped="0" asserts="1">
          <test-suite type="TestFixture" id="0-1000" name="UnitTest1" fullname="UnitTestDemoTest.UnitTest1" classname="UnitTestDemoTest.UnitTest1" runstate="Runnable" testcasecount="2" result="Failed" site="Child" start-time="2019-02-01 17:03:03Z" end-time="2019-02-01 17:03:04Z" duration="0.495486" total="2" passed="1" failed="1" warnings="0" inconclusive="0" skipped="0" asserts="1">
            <attachments>
              <attachment>
                <descrition>
                  Original OWASP Report
                </descrition>
                <filePath>
                  <xsl:value-of select="$sourceFolder"/>\tests\OWASP-ZAP-Report.xml
                </filePath>
              </attachment>
              <attachment>
                <descrition>
                  Original OWASP Report 2
                </descrition>
                <filePath>
                  ($System.DefaultWorkingDirectory)\tests\OWASP-ZAP-Report.xml
                </filePath>
              </attachment>
            </attachments>
            <xsl:for-each select="OWASPZAPReport/site/alerts/alertitem">
            <test-case id="0-1001" name="{name}" fullname="{name}" methodname="Stub" classname="UnitTestDemoTest.UnitTest1" runstate="NotRunnable" seed="400881240" result="Failed" label="Invalid" start-time="{$generatedDateTime}" end-time="{$generatedDateTime}" duration="0" asserts="0">
              <failure>
                <message>
                  <xsl:value-of select="desc"/>. 
                  <xsl:value-of select="solution"/>
                </message>
                <stack-trace>
                  <xsl:for-each select="instances/instance">
                    <xsl:value-of select="uri"/>, <xsl:value-of select="method"/>, <xsl:value-of select="param"/>,
                  </xsl:for-each>
                </stack-trace>
              </failure>
            </test-case>
            </xsl:for-each>
          </test-suite>
        </test-suite>
      </test-suite>
    </test-run>
  </xsl:template>
</xsl:stylesheet>
