xquery version "1.0-ml";
import module namespace search = "http://marklogic.com/appservices/search" at
"/MarkLogic/appservices/search/search.xqy";

import module namespace adv = "http://marklogic.com/MLU/search-app/advanced" at "modules/advanced-lib.xqy";
declare variable $facet-size as xs:integer := 10;

declare function local:result-controller()
{
	if(xdmp:get-request-field("q"))
	then local:search-results()
	else if(xdmp:get-request-field("uri"))
		 then local:article-detail()  
		 else local:default-results()
};

declare function local:default-results()
{
	for $article in fn:doc() [1 to 15]
	return 
		<br>
			<div>
				<strong>{$article//..//ArticleTitle/text()}</strong>
			</div>
			<div class="description">
				{fn:tokenize($article//..//ArticleTitle/text(), " ") [1 to 15]}..
			</div>
			<strong><a href="index.xqy?uri={xdmp:url-encode(fn:base-uri($article))}">  Read more</a></strong>
		</br>
};

declare function local:article-detail()
{
	let $uri := xdmp:get-request-field("uri")

	let $article := fn:doc($uri) 
	return 
		<div>
			{if ($article//..//ArticleTitle) then <h2 >{$article//..//ArticleTitle/text()}</h2> else ()}
			{if ($article//..//Title) then <div class="detailitem"><strong>Journal title: </strong> {$article//..//Title/text()}</div> else ()}
			{if ($article//..//ISOAbbreviation) then <div class="detailitem"><strong>ISO Abbreviation: </strong> {$article//..//ISOAbbreviation/text()}</div> else ()}
			{if ($article//..//LastName) then <div class="detailitem"><strong>Authors: </strong> {fn:string-join(($article//..//LastName/text())[1 to 3], ", ")}</div> else ()}
			{if ($article//..//AbstractText) then <div class="detailitem"><strong>Abstract Text: </strong> {$article//..//AbstractText/text()}</div> else ()}
			{if ($article//..//DateCompleted)
			then 
				<div class="detailitem">
					<strong>Date Completed: </strong>
					 {$article//..//DateCompleted//Year/text()}
					- {$article//..//DateCompleted//Month/text()}
					- {$article//..//DateCompleted//Day/text()}
				</div> else ()}
			{if ($article//..//Language) then <div class="detailitem"><strong>Language: </strong> {$article//..//Language/text()}</div> else ()}
		</div>
};



declare function local:description($article)
{
	for $text in $article/search:snippet/search:match/node()
	return 
		if(fn:node-name($text) eq xs:QName("search:highlight"))
		then <span class="highlight">{$text/text()}</span>
		else $text
};


declare variable $options := <search:options xmlns="http://marklogic.com/appservices/search">
	<search:constraint name="Author">
		<range type="xs:string" collation="http://marklogic.com/collation/en/S1/T00BB/AS">
		<element  name="LastName"/>
			<facet-option>limit=20</facet-option>
			<facet-option>frequency-order</facet-option>
			<facet-option>descending</facet-option>
		</range>
	</search:constraint>
	<search:constraint name="Year">
		<search:range type="xs:gYear">
	
			<search:bucket ge='2020' name="2020s">2020 - Present</search:bucket>
			<search:bucket lt='2020' ge='2018' name="2018s">2018 - 2019</search:bucket>
			<search:bucket lt='2018' ge='2015' name="2015s">2015 - 2017</search:bucket>
			<search:bucket lt='2015' ge='2010' name="2010s">2010 - 2014</search:bucket>
			<search:bucket lt='2010' ge='2000' name="2000s">2000 - 2009</search:bucket>
			<search:bucket lt='2000' name="1999s">before 2000</search:bucket>
			<search:field  name="neededYear"/>
			<facet-option>limit=10</facet-option>
			<facet-option>descending</facet-option>
		</search:range>
	</search:constraint>

        <constraint name="Status">
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1" facet="true">
                <attribute name="Status"/>
                <element name="MedlineCitation"/>
                <facet-option>ascending</facet-option>
            </range>
        </constraint>    

		<constraint name="Title">
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB" facet="false">
                <element name="Title"/>
            </range>
        </constraint>     
	
	<transform-results apply="snippet">
		<preferred-elements>
			<element name="ArticleTitle"/>
		</preferred-elements>
	</transform-results>

	<search:operator name="sort">

		<search:state name="relevance">
			<search:sort-order direction="descending">
				<search:score/>
			</search:sort-order>
		</search:state>

		<search:state name="newest">

			<search:sort-order direction="descending" type="xs:gYear" >
				<field  name="neededYear"/>
			</search:sort-order>
		
			<search:sort-order>
				<search:score/>
			</search:sort-order>

		</search:state>


		<search:state name="oldest">

			<search:sort-order direction="ascending" type="xs:gYear" >				
				<field  name="neededYear"/>
			</search:sort-order>

			<search:sort-order>
				<search:score/>
			</search:sort-order>
		
		</search:state>

		<search:state name="ArticleTitle">
			<search:sort-order direction="ascending" type="xs:string" collation="http://marklogic.com/collation/en/S1/AS/T00BB"  facet="false">
				<element name="ArticleTitle"/>
			</search:sort-order>
			<search:sort-order>
				<search:score/>
			</search:sort-order>
		</search:state>
	</search:operator>
</search:options>;

declare variable $q-text := 
  let $q := if(xdmp:get-request-field("advanced"))
            then adv:advanced-q()
            else xdmp:get-request-field("q", "sort:ArticleTitle")
  let $q := local:add-sort($q)
  return $q;

declare variable $results := 
		search:search($q-text, $options, xs:unsignedLong(xdmp:get-request-field("start","1")));



declare function local:search-results()
{
	let $items :=
		for $article in $results/search:result
		let $uri := fn:data($article/@uri)
		let $articledoc := fn:doc($uri)
		return
			<div>
				<div class="songname">{$articledoc//..//ArticleTitle/text()}</div> 
				<div>
					{local:description($article)}
					<a href="index.xqy?uri={xdmp:url-encode($uri)}"> [more info]</a>
				</div> 
			</div>
	return
	if($items)
	then (local:pagination($results), $items)
	else <div>Sorry, no results for your search.<br/><br/><br/></div>
};


(: gets the current sort argument from the query string :)
declare function local:get-sort($q){
	fn:replace(fn:tokenize($q," ") [fn:contains(.,"sort")],"[()]","")
};

declare function local:add-sort($q){
	let $sortby := local:sort-controller()
	return
		if($sortby)
		then
			let $old-sort := local:get-sort($q)
			let $q :=
				if($old-sort)
				then search:remove-constraint($q,$old-sort,$options)
				else $q
			return fn:concat($q," sort:",$sortby)
		else $q
};

(: determines if the end-user set the sort through the drop-down or through editing
the search text field :)
declare function local:sort-controller(){
	if(xdmp:get-request-field("submitbtn") or not(xdmp:get-request-field("sortby")))
	then

	let $order := fn:replace(
		fn:substring-after(
			fn:tokenize(xdmp:get-request-field("q"), " ")[fn:contains(.,"sort")],"sort:"
		),"[()]",""
	)
	return
		if(fn:string-length($order) lt 1)
		then "relevance"
		else $order
	else xdmp:get-request-field("sortby")
};


(: builds the sort drop-down with appropriate option selected :)

declare function local:sort-options() {
	let $sortby := local:sort-controller()
	let $sort-options :=
	<options>
		<option value="relevance">relevance</option>
		<option value="newest">newest</option>
		<option value="oldest">oldest</option>
		<option value="ArticleTitle">article title</option>
	</options>
	let $newsortoptions :=
		for $option in $sort-options/*
		return
		element {fn:node-name($option)}
		{
			$option/@*,
			if($sortby eq $option/@value)
			then attribute selected {"true"} else (),
			$option/node()
		}
	return
		<div id="sortbydiv">
			sort by:
			<select name="sortby" id="sortby" onchange='this.form.submit()'>
				{$newsortoptions}
			</select>
		</div>
};



declare function local:pagination($resultspag)
{
	let $start := xs:unsignedLong($resultspag/@start)
	let $length := xs:unsignedLong($resultspag/@page-length)
	let $total := xs:unsignedLong($resultspag/@total)
	let $last := xs:unsignedLong($start + $length -1)
	let $end := if ($total > $last) then $last else $total
	let $qtext := $resultspag/search:qtext[1]/text()
	let $next := if ($total > $last) then $last + 1 else ()
	let $previous := if (($start > 1) and ($start - $length > 0)) then fn:max((($start - $length),1)) else ()
	let $next-href :=
		if ($next)
			then fn:concat("/index.xqy?q=",
				if ($qtext) then fn:encode-for-uri($qtext)
				else (),"&amp;start=",$next,"&amp;submitbtn=page")
		else ()
	let $previous-href :=
		if ($previous)
			then fn:concat("/index.xqy?q=",
				if ($qtext) then fn:encode-for-uri($qtext)
				else (),"&amp;start=",$previous,"&amp;submitbtn=page")
		else ()

	let $total-pages := fn:ceiling($total div $length)
	let $currpage := fn:ceiling($start div $length)
	let $pagemin := fn:min(for $i in (1 to 4)
	where ($currpage - $i) > 0
	return $currpage - $i)

	let $rangestart := fn:max(($pagemin, 1))

	let $rangeend := fn:min(($total-pages,$rangestart + 4))
	return (
		<div id="countdiv">
			<b>{$start}</b>
			to 
			<b>{$end}</b>
			of {$total}
		</div>
		
		,local:sort-options(), 
		if($rangestart eq $rangeend)
			then ()
		else
			<div id="pagenumdiv">

	{
	 if ($previous)
	 then
		<a href="{$previous-href}" title="View previous{$length} results">
			<img src="images/prevarrow.gif" class="imgbaseline" border="0"/>
		</a> else ()
	}

	{
		for $i in ($rangestart to $rangeend)
		let $page-start := (($length * $i) + 1) - $length

		let $page-href := concat("/index.xqy?q=",if ($qtext) then encode-for-uri($qtext) else (),"&amp;start=",$page-start,"&amp;submitbtn=page")

		return
		if ($i eq $currpage)

		then 
			<b>
				&#160;
				<u>{$i}</u>
				&#160;
			</b>

		else 
			<span class="hspace">
				&#160;
				<a href="{$page-href}">{$i}</a>
				&#160;
			</span>

	}
	{if ($next) 
		then 
			<a href="{$next-href}" title="View next {$length} results">
				<img src="images/nextarrow.gif" class="imgbaseline" border="0" />
			</a> 
	else() }
	</div>
	)
};


declare function local:facets()
{
	for $facet in $results/search:facet
	let $facet-count := fn:count($facet/search:facet-value)
	let $facet-name := fn:data($facet/@name)
	return
		if($facet-count > 0)
		then 
		<div class="facet">
				<div class="purplesubheading">
					<img src="images/checkblank.gif"/>{$facet-name}
				</div>
			{ 	let $facet-items :=
					for $val in $facet/search:facet-value
					let $print := if($val/text()) then $val/text() else "Unknown"
					let $qtext := ($results/search:qtext)
					let $sort := local:get-sort($qtext)
					let $this :=
						if (fn:matches($val/@name/string(),"\W"))
						then fn:concat('"',$val/@name/string(),'"')
						else if ($val/@name eq "") then '""'
						else $val/@name/string()

					let $this := fn:concat($facet/@name,':',$this)
					let $selected := fn:matches($qtext,$this,"i")
					let $icon :=
						if($selected)

						then <img src="images/checkmark.gif"/>
						else <img src="images/checkblank.gif"/>

					let $link :=
						if($selected)

						then search:remove-constraint($qtext,$this,$options)
						else if(fn:string-length($qtext) gt 0)
						then fn:concat("(",$qtext,")"," AND ",$this)
						else $this

					let $link := if($sort and fn:not(local:get-sort($link))) then fn:concat($link," ",$sort) else $link
					let $link := fn:encode-for-uri($link)
					return
						<div class="facet-value">{$icon}
							<a href="index.xqy?q={$link}">
								{fn:lower-case($print)}
							</a> 
							[{fn:data($val/@count)}]
						</div>
				return (
					<div>{$facet-items[1 to $facet-size]}</div>,
					if($facet-count gt $facet-size)
					then (
						<div class="facet-hidden" id="{$facet-name}">{$facet-items[position() gt $facet-size]}</div>,
						<div class="facet-toggle" id="{$facet-name}_more">
							<img src="images/checkblank.gif"/>
							<a href="javascript:toggle('{$facet-name}');" class="white">more...</a>
						</div>,
						<div class="facet-toggle-hidden" id="{$facet-name}_less">
							<img src="images/checkblank.gif"/>
							<a href="javascript:toggle('{$facet-name}');" class="white">less...</a>
						</div>
					)
					
					else ()	
				)
			}
		</div>
		else <div>&#160;</div>
};





xdmp:set-response-content-type("text/html; charset=utf-8"),
'<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">',
<html xmlns="http://www.w3.org/1999/xhtml">
	<head>
		<title>Search App</title>
		<link href="css/search-main.css" rel="stylesheet" type="text/css"/>
		<script src="js/top-songs.js" type="text/javascript"/>
		<script type="text/javascript" src="../autocomplete/lib/prototype/prototype.js"></script>
		<script type="text/javascript" src="../autocomplete/lib/scriptaculous/scriptaculous.js"></script>
		<script type="text/javascript" src="../autocomplete/src/autocomplete.js"></script>
		<script type="text/javascript" src="../autocomplete/src/lib.js"></script>
	</head>
<body>
	<div id="wrapper">
	<div id="header"><a href="index.xqy"><img src="images/banner.jpg" width="918" height="153" border="0"/></a></div>
	<div id="leftcol">
	<img src="images/checkblank.gif"/>{local:facets()}<br/>

	</div>
	<div id="rightcol">
	<form name="form1" method="get" action="index.xqy" id="form1">
	<div id="searchdiv">
		<input type="text" name="q" id="q" size="50" value="{$q-text}"/><button type="button" id="reset_button" onclick="document.getElementById('bday').value = ''; document.getElementById('q').value = ''; document.location.href='index.xqy'">x</button>&#160;
		<!--<input type="text" name="q" id="q" size="50" value="{local:add-sort(xdmp:get-request-field("q"))}"/><button type="button" id="reset_button" onclick="document.getElementById('bday').value = ''; document.getElementById('q').value = ''; document.location.href='index.xqy'">x</button>&#160;-->
		<input style="border:0; width:0; height:0; background-color: #A7C030" type="text" size="0" maxlength="0"/><input type="submit" id="submitbtn" name="submitbtn" value="search"/>&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;&#160;<a href="advanced.xqy">advanced search</a>
	</div>
	<div id="detaildiv">
	{local:result-controller()  }  	
	</div>
	</form>
	</div>
	<div id="footer"></div>
	</div>
</body>
</html>
