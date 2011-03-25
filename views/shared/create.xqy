declare variable $params external ;

let $e := $params/e
return 
  if( $e )
  then fn:string( <v>{{"error":"{$e/id}","reason":"{$e/text()}"}}&#x0a;</v> )
  else (xdmp:set-response-code( 201, 'Created' ), '{"ok":true}
')
