xquery version "1.0-ml";

(:~
 : Turns the advanced search form into a query string for the search API.
 :)
module namespace adv = "http://marklogic.com/MLU/search-app/advanced";

(: A form field as a single trimmed string ("" when it is missing). :)
declare function adv:field($name as xs:string) as xs:string
{
    fn:normalize-space(fn:string(xdmp:get-request-field($name)[1]))
};

(: The words typed into a form field. :)
declare function adv:words($name as xs:string) as xs:string*
{
    fn:tokenize(adv:field($name), " ")[. ne ""]
};

(: Builds name:value, quoting the value when it is more than one plain word. :)
declare function adv:constraint($name as xs:string, $value as xs:string) as xs:string?
{
    let $value := fn:normalize-space(fn:translate($value, '"', ' '))
    return
        if ($value eq "")
        then ()
        else if (fn:matches($value, "\W"))
        then fn:concat($name, ':"', $value, '"')
        else fn:concat($name, ":", $value)
};

declare function adv:advanced-q() as xs:string
{
    let $keywords := adv:words("keywords")
    let $type := adv:field("type")
    let $status := adv:field("status")

    let $keywords :=
        if (fn:empty($keywords))
        then ()
        else if ($type eq "any")
        then fn:string-join($keywords, " OR ")
        else if ($type eq "phrase")
        then fn:concat('"', fn:translate(fn:string-join($keywords, " "), '"', ''), '"')
        else fn:string-join($keywords, " ")

    let $exclude :=
        for $word in adv:words("exclude")
        return fn:concat("-", $word)

    let $status :=
        if ($status eq "all")
        then ()
        else adv:constraint("Status", $status)

    let $title := adv:constraint("Title", adv:field("Title"))

    return fn:string-join(($keywords, $exclude, $status, $title), " ")
};
