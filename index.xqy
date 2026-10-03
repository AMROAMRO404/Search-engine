xquery version "1.0-ml";

(:~
 : Main page: the search box, facets, result list and the article detail view.
 :
 :   index.xqy?q=...&sortby=...&start=...   search results
 :   index.xqy?advanced=advanced&...        results for the advanced search form
 :   index.xqy?uri=...                      one article
 :)

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace adv = "http://marklogic.com/MLU/search-app/advanced" at "modules/advanced-lib.xqy";
import module namespace cfg = "http://marklogic.com/MLU/search-app/config" at "modules/search-config.xqy";
import module namespace layout = "http://marklogic.com/MLU/search-app/layout" at "modules/layout.xqy";

(: Facet values shown before the "more" link. :)
declare variable $FACET-SIZE as xs:integer := 10;
(: Page links shown on each side of the current page. :)
declare variable $PAGE-WINDOW as xs:integer := 2;
(: Authors listed under each search result. :)
declare variable $RESULT-AUTHORS as xs:integer := 3;


(: ---------- request ---------- :)

(: A request field as a single string ("" when it is missing). :)
declare function local:param($name as xs:string) as xs:string
{
    fn:string(xdmp:get-request-field($name)[1])
};

(: The sort order typed into the search box as sort:<name>, if it is a known one. :)
declare function local:typed-sort($q as xs:string) as xs:string?
{
    let $token := (fn:tokenize($q, "\s+")[fn:matches(., "^\(*sort:")])[1]
    let $name := fn:replace(fn:substring-after($token, "sort:"), "[()]", "")
    return $name[. = $cfg:sort-names]
};

declare variable $uri as xs:string := local:param("uri");

declare variable $raw-q as xs:string :=
    if (local:param("advanced") ne "")
    then adv:advanced-q()
    else local:param("q");

declare variable $typed-sort as xs:string? := local:typed-sort($raw-q);

(: The query without its sort order; this is what the search box shows. :)
declare variable $base-q as xs:string :=
    fn:normalize-space(
        if ($typed-sort)
        then fn:string(search:remove-constraint($raw-q, fn:concat("sort:", $typed-sort), $cfg:search-options))
        else $raw-q
    );

(: A sort typed in the box wins over the drop-down. With nothing to search for
   there is no relevance, so the default is to browse by article title. The form
   sends browse=1 from that browsing view: a first search made from there starts
   by relevance instead of inheriting the browsing order. :)
declare variable $sort as xs:string :=
    let $selected := local:param("sortby")
    let $first-search := local:param("browse") ne "" and $base-q ne ""
    return
        if ($typed-sort) then $typed-sort
        else if ($selected = $cfg:sort-names and fn:not($first-search)) then $selected
        else if ($base-q eq "") then "ArticleTitle"
        else "relevance";

declare variable $start as xs:unsignedLong :=
    let $requested := local:param("start")
    return
        if ($requested castable as xs:positiveInteger)
        then xs:unsignedLong($requested)
        else xs:unsignedLong(1);

declare variable $results as element(search:response)? :=
    if ($uri ne "")
    then ()
    else search:search(fn:normalize-space(fn:concat($base-q, " sort:", $sort)), $cfg:search-options, $start);


(: ---------- helpers ---------- :)

(: Link to a page of results for $q, keeping the current sort order. :)
declare function local:search-href($q as xs:string, $from as xs:anyAtomicType) as xs:string
{
    fn:concat("index.xqy?q=", fn:encode-for-uri($q), "&amp;sortby=", $sort, "&amp;start=", $from)
};

(: Escapes a string so it can be used literally inside a regular expression. :)
declare function local:regex-escape($text as xs:string) as xs:string
{
    fn:replace($text, "([\\\.\[\]\{\}\(\)\*\+\?\^\$\|\-])", "\\$1")
};

declare function local:author-name($author as element()) as xs:string
{
    fn:normalize-space(
        if ($author/LastName)
        then fn:concat(($author/ForeName)[1], " ", ($author/LastName)[1])
        else fn:string(($author/CollectiveName)[1])
    )
};

declare function local:author-names($article as node()?) as xs:string*
{
    for $author in $article//Author
    return local:author-name($author)[. ne ""]
};

declare function local:article-title($article as node()?) as xs:string
{
    let $title := fn:normalize-space(fn:string(($article//ArticleTitle)[1]))
    return if ($title ne "") then $title else "Untitled article"
};


(: ---------- article detail ---------- :)

declare function local:detail-row($label as xs:string, $value as xs:string?) as element(tr)?
{
    if (fn:normalize-space($value) ne "")
    then <tr><th>{$label}</th><td>{fn:normalize-space($value)}</td></tr>
    else ()
};

declare function local:article-detail() as element(div)
{
    let $article := fn:doc($uri)
    let $back := <a href="{local:search-href($base-q, $start)}">&#8592; Back to results</a>
    return
        if (fn:empty($article))
        then
            <div>
                <div class="notification is-warning">This article could not be found.</div>
                <p>{$back}</p>
            </div>
        else
            let $pmid := fn:normalize-space(fn:string(($article//MedlineCitation/PMID, $article//PMID)[1]))
            let $completed := ($article//DateCompleted)[1]
            let $authors := local:author-names($article)
            let $abstract := $article//AbstractText[fn:normalize-space(.) ne ""]
            let $rows := (
                local:detail-row("Journal", fn:string(($article//Title)[1])),
                local:detail-row("Abbreviation", fn:string(($article//ISOAbbreviation)[1])),
                local:detail-row("Authors", fn:string-join($authors, ", ")),
                local:detail-row("Date completed",
                    fn:string-join(($completed/Year, $completed/Month, $completed/Day), "-")),
                local:detail-row("Language", fn:string-join($article//Language, ", ")),
                local:detail-row("Status", fn:string(($article//MedlineCitation/@Status)[1])),
                local:detail-row("PMID", $pmid)
            )
            return
                <div class="article-detail">
                    <p class="mb-4">{$back}</p>
                    <h1 class="title is-4">{local:article-title($article)}</h1>
                    {
                        if ($rows)
                        then <table class="table is-fullwidth is-striped"><tbody>{$rows}</tbody></table>
                        else ()
                    }
                    <h2 class="title is-5">Abstract</h2>
                    {
                        if ($abstract)
                        then
                            for $part in $abstract
                            return
                                <p class="mb-3">
                                    {if ($part/@Label) then <strong>{fn:string($part/@Label)}: </strong> else ()}
                                    {fn:string($part)}
                                </p>
                        else <p class="has-text-grey">No abstract is available for this article.</p>
                    }
                    {
                        if ($pmid ne "")
                        then
                            <p class="mt-5">
                                <a class="button is-info is-light" href="https://pubmed.ncbi.nlm.nih.gov/{fn:encode-for-uri($pmid)}/"
                                   target="_blank" rel="noopener">View on PubMed</a>
                            </p>
                        else ()
                    }
                </div>
};


(: ---------- search results ---------- :)

(: The matching text of a result, with the matched words highlighted. :)
declare function local:snippet($result as element(search:result)) as node()*
{
    for $match at $position in $result/search:snippet/search:match
    return (
        if ($position gt 1) then text {" &#8230; "} else (),
        for $node in $match/node()
        return
            if ($node instance of element(search:highlight))
            then <mark class="highlight">{fn:string($node)}</mark>
            else text {fn:string($node)}
    )
};

(: "Journal · Year · Author, Author, Author et al." :)
declare function local:result-meta($article as node()?) as xs:string
{
    let $authors := local:author-names($article)
    let $author-text :=
        if (fn:count($authors) gt $RESULT-AUTHORS)
        then fn:concat(fn:string-join($authors[1 to $RESULT-AUTHORS], ", "), " et al.")
        else fn:string-join($authors, ", ")
    let $parts := (
        fn:string(($article//Title)[1]),
        fn:string(($article//PubDate/Year, $article//DateCompleted/Year)[1]),
        $author-text
    )
    return fn:string-join($parts[fn:normalize-space(.) ne ""], " &#183; ")
};

declare function local:result-card($result as element(search:result)) as element(div)
{
    let $doc-uri := fn:string($result/@uri)
    let $article := fn:doc($doc-uri)
    let $href := fn:concat(
        "index.xqy?uri=", xdmp:url-encode($doc-uri),
        "&amp;q=", fn:encode-for-uri($base-q),
        "&amp;sortby=", $sort,
        "&amp;start=", $start
    )
    let $meta := local:result-meta($article)
    let $snippet := local:snippet($result)
    return
        <div class="card result-card">
            <div class="card-content">
                <p class="title is-5"><a href="{$href}">{local:article-title($article)}</a></p>
                {if ($meta ne "") then <p class="result-meta">{$meta}</p> else ()}
                {if ($snippet) then <p class="result-snippet">{$snippet}</p> else ()}
            </div>
            <footer class="card-footer">
                <a class="card-footer-item" href="{$href}">Read more</a>
            </footer>
        </div>
};

declare function local:page-link($page as xs:integer, $current as xs:integer, $length as xs:integer) as element(li)
{
    <li>
    {
        if ($page eq $current)
        then <a class="pagination-link is-current" aria-label="Page {$page}" aria-current="page">{$page}</a>
        else
            <a class="pagination-link" aria-label="Go to page {$page}"
               href="{local:search-href($base-q, ($page - 1) * $length + 1)}">{$page}</a>
    }
    </li>
};

(: Previous / next links and the page numbers around the current page. :)
declare function local:pagination() as element(nav)?
{
    let $total := xs:integer($results/@total)
    let $length := xs:integer($results/@page-length)
    let $pages := xs:integer(fn:ceiling($total div $length))
    let $current := xs:integer(fn:ceiling(xs:integer($results/@start) div $length))
    let $first := fn:max((1, $current - $PAGE-WINDOW))
    let $last := fn:min(($pages, $current + $PAGE-WINDOW))
    return
        if ($pages le 1)
        then ()
        else
            <nav class="pagination is-centered" role="navigation" aria-label="pagination">
                {
                    if ($current gt 1)
                    then
                        <a class="pagination-previous" title="View previous {$length} results"
                           href="{local:search-href($base-q, ($current - 2) * $length + 1)}">Previous</a>
                    else ()
                }
                {
                    if ($current lt $pages)
                    then
                        <a class="pagination-next" title="View next {$length} results"
                           href="{local:search-href($base-q, $current * $length + 1)}">Next page</a>
                    else ()
                }
                <ul class="pagination-list">
                    {
                        if ($first gt 1)
                        then (
                            local:page-link(1, $current, $length),
                            if ($first gt 2) then <li><span class="pagination-ellipsis">&#8230;</span></li> else ()
                        )
                        else ()
                    }
                    {for $page in ($first to $last) return local:page-link($page, $current, $length)}
                    {
                        if ($last lt $pages)
                        then (
                            if ($last lt $pages - 1) then <li><span class="pagination-ellipsis">&#8230;</span></li> else (),
                            local:page-link($pages, $current, $length)
                        )
                        else ()
                    }
                </ul>
            </nav>
};

declare function local:search-results() as node()*
{
    let $hits := $results/search:result
    let $total := xs:integer($results/@total)
    let $from := xs:integer($results/@start)
    return
        if (fn:empty($hits))
        then
            <div class="notification">
                <p><strong>Sorry, no results for your search.</strong></p>
                <p>Check the spelling, try fewer words, or remove a filter on the left.</p>
            </div>
        else (
            <p class="result-count">
                Showing <strong>{$from}</strong> to <strong>{$from + fn:count($hits) - 1}</strong> of <strong>{$total}</strong> articles
            </p>,
            for $result in $hits return local:result-card($result),
            local:pagination()
        )
};


(: ---------- facets ---------- :)

(: The text that selects a facet value in the query, e.g. Author:"De Vries". :)
declare function local:facet-term($facet-name as xs:string, $value as xs:string) as xs:string
{
    fn:concat(
        $facet-name, ":",
        if ($value eq "" or fn:matches($value, "\W"))
        then fn:concat('"', $value, '"')
        else $value
    )
};

(: One facet value: a link that adds it to the query, or removes it when it is already selected. :)
declare function local:facet-value($facet-name as xs:string, $value as element(search:facet-value)) as element(div)
{
    let $label := if (fn:normalize-space($value) ne "") then fn:string($value) else "Unknown"
    let $term := local:facet-term($facet-name, fn:string($value/@name))
    let $selected := fn:matches($base-q, fn:concat("(^|[\s(])", local:regex-escape($term), "($|[\s)])"), "i")
    let $q :=
        if ($selected)
        then fn:normalize-space(fn:string(search:remove-constraint($base-q, $term, $cfg:search-options)))
        else if ($base-q ne "")
        then fn:concat("(", $base-q, ") AND ", $term)
        else $term
    return
        <div class="facet-value">
            <img src="images/{if ($selected) then 'checkmark.gif' else 'checkblank.gif'}" alt="{if ($selected) then 'selected' else ''}"/>
            <a href="{local:search-href($q, 1)}" title="{if ($selected) then 'Remove this filter' else 'Filter by this value'}">{$label}</a>
            <span class="facet-count">[{fn:data($value/@count)}]</span>
        </div>
};

declare function local:facets() as element()*
{
    let $facets :=
        for $facet in $results/search:facet[search:facet-value]
        let $name := fn:string($facet/@name)
        let $values := for $value in $facet/search:facet-value return local:facet-value($name, $value)
        return
            <div class="card facet">
                <p class="facet-name">{$name}</p>
                {$values[fn:position() le $FACET-SIZE]}
                {
                    if (fn:count($values) gt $FACET-SIZE)
                    then (
                        <div class="is-hidden" id="facet-{$name}">{$values[fn:position() gt $FACET-SIZE]}</div>,
                        <a class="facet-toggle" href="#" onclick="return toggleFacet(this, 'facet-{$name}');">more...</a>
                    )
                    else ()
                }
            </div>
    return
        if ($facets)
        then $facets
        else <p class="has-text-grey">No filters for this search.</p>
};


(: ---------- page ---------- :)

declare function local:sort-select() as element(div)
{
    <div class="select is-info">
        <select name="sortby" aria-label="Sort by" onchange="this.form.submit()">
        {
            for $choice in $cfg:sort-choices
            return
                <option value="{$choice/@value}">
                    {if ($choice/@value eq $sort) then attribute selected {"selected"} else ()}
                    Sort by {fn:string($choice)}
                </option>
        }
        </select>
    </div>
};

declare function local:search-form() as element(form)
{
    <form name="form1" method="get" action="index.xqy" class="search-form">
        {if ($base-q eq "") then <input type="hidden" name="browse" value="1"/> else ()}
        <div class="field is-grouped is-grouped-multiline">
            <div class="control is-expanded">
                <input class="input is-info" type="text" name="q" id="q" value="{$base-q}"
                       placeholder="Search articles, e.g. cancer therapy" aria-label="Search articles"/>
            </div>
            <div class="control">
                <button class="button is-info" type="submit">Search</button>
            </div>
            {
                if ($base-q ne "")
                then <div class="control"><a class="button is-light" href="index.xqy">Clear</a></div>
                else ()
            }
            <div class="control">{local:sort-select()}</div>
        </div>
    </form>
};

declare function local:search-page() as element(div)
{
    <div class="columns">
        <div class="column is-one-quarter">{local:facets()}</div>
        <div class="column">
            {local:search-form()}
            {local:search-results()}
        </div>
    </div>
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
if ($uri ne "")
then layout:page("Article", (), local:article-detail())
else layout:page(if ($base-q ne "") then $base-q else "Search", "js/facets.js", local:search-page())
