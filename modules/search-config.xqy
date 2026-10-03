xquery version "1.0-ml";

(:~
 : Shared search configuration.
 :
 : Everything that has to match the database's index settings (element names,
 : collations, the year field) lives here, so the pages cannot drift apart.
 :)
module namespace cfg = "http://marklogic.com/MLU/search-app/config";

declare namespace search = "http://marklogic.com/appservices/search";

(: Collation of the range index on the journal <Title> element. :)
declare variable $cfg:title-collation as xs:string :=
    "http://marklogic.com/collation/en/S1/AS/T00BB";

(: Sort orders the user can pick: value = state name in the search options. :)
declare variable $cfg:sort-choices as element(option)+ := (
    <option value="relevance">relevance</option>,
    <option value="newest">newest</option>,
    <option value="oldest">oldest</option>,
    <option value="ArticleTitle">article title</option>
);

declare variable $cfg:sort-names as xs:string+ :=
    for $choice in $cfg:sort-choices return fn:string($choice/@value);

(: Options for the main search: facets, constraints, snippets and sorting. :)
declare variable $cfg:search-options as element(search:options) :=
    <options xmlns="http://marklogic.com/appservices/search">
        <constraint name="Author">
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1/T00BB/AS">
                <element name="LastName"/>
                <facet-option>limit=20</facet-option>
                <facet-option>frequency-order</facet-option>
                <facet-option>descending</facet-option>
            </range>
        </constraint>

        <constraint name="Year">
            <range type="xs:gYear">
                <bucket ge="2020" name="2020s">2020 - Present</bucket>
                <bucket lt="2020" ge="2018" name="2018s">2018 - 2019</bucket>
                <bucket lt="2018" ge="2015" name="2015s">2015 - 2017</bucket>
                <bucket lt="2015" ge="2010" name="2010s">2010 - 2014</bucket>
                <bucket lt="2010" ge="2000" name="2000s">2000 - 2009</bucket>
                <bucket lt="2000" name="1999s">before 2000</bucket>
                <field name="neededYear"/>
                <facet-option>limit=10</facet-option>
                <facet-option>descending</facet-option>
            </range>
        </constraint>

        <constraint name="Status">
            <range type="xs:string" collation="http://marklogic.com/collation/en/S1" facet="true">
                <attribute name="Status"/>
                <element name="MedlineCitation"/>
                <facet-option>ascending</facet-option>
            </range>
        </constraint>

        <constraint name="Title">
            <range type="xs:string" collation="{$cfg:title-collation}" facet="false">
                <element name="Title"/>
            </range>
        </constraint>

        <transform-results apply="snippet">
            <preferred-elements>
                <element name="ArticleTitle"/>
            </preferred-elements>
        </transform-results>

        <operator name="sort">
            <state name="relevance">
                <sort-order direction="descending">
                    <score/>
                </sort-order>
            </state>
            <state name="newest">
                <sort-order direction="descending" type="xs:gYear">
                    <field name="neededYear"/>
                </sort-order>
                <sort-order>
                    <score/>
                </sort-order>
            </state>
            <state name="oldest">
                <sort-order direction="ascending" type="xs:gYear">
                    <field name="neededYear"/>
                </sort-order>
                <sort-order>
                    <score/>
                </sort-order>
            </state>
            <state name="ArticleTitle">
                <sort-order direction="ascending" type="xs:string" collation="{$cfg:title-collation}">
                    <element name="ArticleTitle"/>
                </sort-order>
                <sort-order>
                    <score/>
                </sort-order>
            </state>
        </operator>
    </options>;

(: Options that only return the Status facet, used to fill the advanced search drop-down. :)
declare variable $cfg:status-facet-options as element(search:options) :=
    <options xmlns="http://marklogic.com/appservices/search">
        <return-results>false</return-results>
        <return-facets>true</return-facets>
        {$cfg:search-options/search:constraint[@name eq "Status"]}
    </options>;
