xquery version "1.0-ml";

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";

declare variable $options-status :=                    
    <options xmlns="http://marklogic.com/appservices/search">
        <return-results>false</return-results>
        <return-facets>true</return-facets>   
        <constraint name="Status">
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1" facet="true">
                <attribute name="Status"/>
                <element name="MedlineCitation"/>
                <facet-option>ascending</facet-option>
            </range>
        </constraint>            
    </options>;
    
declare function local:list-status-vals()
{
    for $status in (search:search("", $options-status)//search:facet-value)
    return (<option value="{fn:data($status/@name)}">{fn:lower-case($status/text())} [{fn:data($status/@count)}]</option>) 
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title>Search App</title>
<script type="text/javascript" src="/autocomplete/lib/prototype/prototype.js"></script> 
<script type="text/javascript" src="/autocomplete/lib/scriptaculous/scriptaculous.js"></script> 
<script type="text/javascript" src="/autocomplete/src/AutoComplete.js"></script>
<script type="text/javascript" src="/autocomplete/src/lib.js"></script>
</head>
<body>
<div id="wrapper">
<div id="rightcol">
  <div id="searchdiv">
  <form name="formadv" method="get" action="index.xqy" id="formadv">
  <input type="hidden" name="advanced" value="advanced"/>
  <table border="0" cellspacing="8">
    <tr>
      <td align="right">&#160;</td>
      <td colspan="4" class="songnamelarge"><span class="tiny">&#160;&#160;</span><br />
        Advanced Search<br />
        <span class="tiny">&#160;&#160;</span></td>
    </tr>
    <tr>
      <td align="right">Search for:</td>
      <td colspan="4"><input type="text" name="keywords" id="keywords" size="40"/>
        &#160;
        <select name="type" id="type">
          <option value="all">all of these words</option>
          <option value="any">any of these words</option>
          <option value="phrase">exact phrase</option>
        </select></td>
    </tr>
    <tr>
      <td align="right">Words to exclude:</td>
      <td colspan="4"><input type="text" name="exclude" id="exclude" size="40"/></td>
    </tr>
    <tr>
      <td align="right">Status:</td>
      <td colspan="4"><select name="status" id="Status">
        <option value="all">all</option>
		      {local:list-status-vals()}
      </select></td>
    </tr>
    <tr>
      <td align="right">Journal title:</td>
      <td colspan="4"><input type="text" name="Title" id="Title" size="40" autocomplete="off"/></td>
    </tr>
    <tr valign="top">
      <td align="right">&#160;</td>
      <td><span class="tiny">&#160;&#160;</span><br /><input type="submit" name="submitbtn" id="submitbtn" value="search"/></td>
    </tr>
  </table>
  </form>
  </div>
</div>
<div id="footer"></div>
</div>
</body>
</html>
