xquery version "1.0-ml";

(:~
 : The HTML shell (head, navigation bar, page container) shared by every page.
 :)
module namespace layout = "http://marklogic.com/MLU/search-app/layout";

declare variable $layout:app-name as xs:string := "Article Search";

(:~
 : Wraps page content in the common HTML document.
 :
 : @param $title    text for the browser tab
 : @param $scripts  URLs of the JavaScript files the page needs
 : @param $content  the page body
 :)
declare function layout:page(
    $title as xs:string,
    $scripts as xs:string*,
    $content as item()*
) as item()*
{
    '<!DOCTYPE html>',
    <html xmlns="http://www.w3.org/1999/xhtml" lang="en">
        <head>
            <meta charset="utf-8"/>
            <meta name="viewport" content="width=device-width, initial-scale=1"/>
            <title>{$title} | {$layout:app-name}</title>
            <link rel="stylesheet" href="https://cdn.jsdelivr.net/npm/bulma@0.9.3/css/bulma.min.css"/>
            <link rel="stylesheet" href="css/search.css" type="text/css"/>
            {
                for $src in $scripts
                return <script type="text/javascript" src="{$src}"></script>
            }
        </head>
        <body>
            <nav class="navbar is-info" role="navigation" aria-label="main navigation">
                <div class="navbar-brand">
                    <a class="navbar-item app-name" href="index.xqy">{$layout:app-name}</a>
                    <a class="navbar-item" href="advanced.xqy">Advanced search</a>
                </div>
            </nav>
            <section class="section">
                <div class="container">
                    {$content}
                </div>
            </section>
        </body>
    </html>
};
