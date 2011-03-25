import module namespace m = "mustache.xq" at "/lib/mustache/mustache.xq" ;

declare variable $params external ;
declare variable $l := xdmp:from-json( $params ) ;


m:render(
  fn:string( <v>
  {{ 
   "total_rows": { $l [2] },
   "offset": { $l [3] },
   "rows": [
     { $l [4] }
     {{{{#array}}}} {{{{.}}}} {{{{/array}}}}
   ]
  }}&#x0a;</v> ),
  $l [4] )
