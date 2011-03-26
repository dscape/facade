declare variable $params external ;

let $e := $params/e
return 
  if( $e )
  then fn:string( <v>{{"error":"{$e/id}","reason":"{$e/text()}"}}&#x0a;</v> )
  else 
    let $l := xdmp:from-json( $params )
    return 
      fn:string( <v>
        {{ 
           "total_rows": { $l [2] },
           "offset": { $l [3] },
           "rows": [ 
            { $l[4] }
           ]
        }}&#x0a;</v> )
