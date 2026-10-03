xquery version "1.0-ml";

(:~
 : Journal title suggestions for the advanced search form.
 : Called as autocomplete.xqy?q=<typed text>, answers with
 : <Suggestions><suggestion>...</suggestion></Suggestions>.
 :)

import module namespace cfg = "http://marklogic.com/MLU/search-app/config" at "modules/search-config.xqy";

declare option xdmp:mapping "false";
(: The widget reads the XML node by node, so there must be no whitespace between elements. :)
declare option xdmp:output "indent=no";

declare variable $MAX-SUGGESTIONS as xs:integer := 10;

(: Journal titles containing the typed text, read from the Title range index. :)
declare function local:suggestions($q as xs:string) as element(suggestion)*
{
    for $title in cts:element-value-match(
        xs:QName("Title"),
        fn:concat("*", $q, "*"),
        (fn:concat("collation=", $cfg:title-collation), fn:concat("limit=", $MAX-SUGGESTIONS))
    )
    return element suggestion {$title}
};

let $q := fn:normalize-space(fn:string(xdmp:get-request-field("q")[1]))
return (
    xdmp:set-response-content-type("text/xml"),
    if ($q ne "")
    then <Suggestions>{local:suggestions($q)}</Suggestions>
    else ()
)
