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
  <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css"/>
</head>
<body>
  <div class="tabs is-centered is-info">
      <ul class="is-info" style="background-color:hsl(204, 86%, 53%);">
        <li class="is-info">
          <a style="color:white; font-size:22px;" href= "index.xqy">Home</a>
        </li>
      </ul>
  </div>
  
  <div style="padding-top:50px;width: 50%;display: block;margin-left: auto;margin-right:auto;">
    <P style="padding-bottom:30px;"><strong style="font-size:30px;">Advanced search option</strong></P>
    <form name="formadv" method="get" action="index.xqy" id="formadv">
      <input type="hidden" name="advanced" value="advanced"/>
      <label><strong>Search for:</strong></label>
      <div style="white-space: nowrap;">
        <input style="display: inline-block;" class="input is-info" type="text" name="keywords" id="keywords" size="40"/>
        <div style="padding-left:10px;" class="select is-info">
          <select style="display: inline-block; paddin-left:10px;" class="is-info" name="type" id="type">
            <option value="all">all of these words</option>
              <option value="any">any of these words</option>
              <option value="phrase">exact phrase</option>
          </select>
        </div>
      </div>
    <br>
      <label><strong>Words to exclude: </strong></label>
      <input class="input is-info" type="text" name="exclude" id="exclude" size="40"/>
    </br>

    <br>
      <p><strong>Status: </strong></p>
      <div style="paddin-left:10px;" class="select is-info">
        <select class="is-info" name="status" id="Status">
          <option value="all">all</option>
              {local:list-status-vals()}
        </select>
      </div>
    </br>
    
    <br>
      <label><strong>Journal title: </strong></label>
      <input class="input is-info" type="text" name="Title" id="Title" size="40" autocomplete="off"/>
    </br>

    <br>
      <button class="button" style="background-color:hsl(204, 86%, 53%); color:white;" type="submit" id="submitbtn" name="submitbtn">Apply</button>
    </br>
  </form>
<div id="footer"></div>
</div>
</body>
</html>
