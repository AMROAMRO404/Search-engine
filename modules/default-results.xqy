module namespace def = "http://marklogic.com/mlu/main-programm/default";

declare function local:description($article)
{
	for $text in $article/search:snippet/search:match/node()
	return 
		if(fn:node-name($text) eq xs:QName("search:highlight"))
		then <span style="background-color:#e9de3f;"> {$text/text()}, </span>
		else $text
		
};
