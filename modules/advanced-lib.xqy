module namespace adv = "http://marklogic.com/MLU/search-app/advanced";


declare function advanced-q()
{
    let $keywords := fn:tokenize(xdmp:get-request-field("keywords")," ")
    let $type := xdmp:get-request-field("type")
    let $exclude := fn:tokenize(xdmp:get-request-field("exclude")," ")  
    let $status := xdmp:get-request-field("status")    
    let $status := if ($status eq "all")
                  then ""
                  else $status
    let $Title := xdmp:get-request-field("Title")
    
    let $keywords := 
      if($keywords) 
      then 
        if($type eq "any")
        then fn:string-join($keywords," OR ")
        else if($type eq "phrase")
             then fn:concat('"',fn:string-join($keywords," "),'"')
             else $keywords
      else ()

    let $exclude := 
        if($exclude)
        then fn:string-join((for $i in $exclude 
                             return fn:concat("-",$i))," ")
        else ()
        
    let $status :=
        if($status)
        then
            if (fn:matches($status,"\W"))
            then fn:concat('Status:"',$status,'"')
            else fn:concat("Status:",$status)
        else () 
          

    let $Title :=
        if($Title)
        then
            if (fn:matches($Title,"\W"))
            then fn:concat('Title:"',$Title,'"')
            else fn:concat("Title:",$Title)
        else ()
         
    let $q-text := fn:string-join(($keywords,$exclude,$status,$Title)," ")
    return $q-text
};