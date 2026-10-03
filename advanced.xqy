xquery version "1.0-ml";

(:~
 : Advanced search form. It submits to index.xqy, which builds the query
 : with modules/advanced-lib.xqy.
 :)

import module namespace search = "http://marklogic.com/appservices/search" at "/MarkLogic/appservices/search/search.xqy";
import module namespace cfg = "http://marklogic.com/MLU/search-app/config" at "modules/search-config.xqy";
import module namespace layout = "http://marklogic.com/MLU/search-app/layout" at "modules/layout.xqy";

(: Scripts for the journal title autocomplete. :)
declare variable $SCRIPTS as xs:string+ := (
    "autocomplete/lib/prototype/prototype.js",
    "autocomplete/lib/scriptaculous/scriptaculous.js",
    "autocomplete/src/AutoComplete.js",
    "autocomplete/src/lib.js"
);

(: One <option> per status found in the database, with its article count. :)
declare function local:status-options() as element(option)*
{
    for $status in search:search("", $cfg:status-facet-options)//search:facet-value
    return
        <option value="{fn:data($status/@name)}">
            {fn:lower-case(fn:string($status))} [{fn:data($status/@count)}]
        </option>
};

declare function local:form() as element(div)
{
    <div class="advanced-form">
        <h1 class="title">Advanced search</h1>
        <form name="formadv" method="get" action="index.xqy" id="formadv">
            <input type="hidden" name="advanced" value="advanced"/>

            <div class="field">
                <label class="label" for="keywords">Search for</label>
                <div class="field has-addons">
                    <div class="control is-expanded">
                        <input class="input is-info" type="text" name="keywords" id="keywords"/>
                    </div>
                    <div class="control">
                        <div class="select is-info">
                            <select name="type" id="type" aria-label="How to match the words">
                                <option value="all">all of these words</option>
                                <option value="any">any of these words</option>
                                <option value="phrase">exact phrase</option>
                            </select>
                        </div>
                    </div>
                </div>
            </div>

            <div class="field">
                <label class="label" for="exclude">Words to exclude</label>
                <div class="control">
                    <input class="input is-info" type="text" name="exclude" id="exclude"/>
                </div>
            </div>

            <div class="field">
                <label class="label" for="status">Status</label>
                <div class="control">
                    <div class="select is-info">
                        <select name="status" id="status">
                            <option value="all">all</option>
                            {local:status-options()}
                        </select>
                    </div>
                </div>
            </div>

            <div class="field">
                <label class="label" for="Title">Journal title</label>
                <div class="control">
                    <input class="input is-info" type="text" name="Title" id="Title" autocomplete="off"/>
                </div>
                <p class="help">Start typing to see matching journal titles.</p>
            </div>

            <div class="field is-grouped">
                <div class="control">
                    <button class="button is-info" type="submit">Search</button>
                </div>
                <div class="control">
                    <a class="button is-light" href="index.xqy">Cancel</a>
                </div>
            </div>
        </form>
    </div>
};

xdmp:set-response-content-type("text/html; charset=utf-8"),
layout:page("Advanced search", $SCRIPTS, local:form())
