declare variable $params external ;
declare variable $l := xdmp:from-json( $params ) ;

let $e := $params/e
return 
  if( $e )
  then fn:string( <v>{{"error":"{$e/id}","reason":"{$e/text()}"}}&#x0a;</v> )
  else ( xdmp:set-response-code( 201, 'Created' ), 
  fn:string( <a>{{"ok":true,"id":"{$l[1]}","rev":"{$l[2]}"}}</a> ) )
