xquery version "1.0-ml";
module namespace server = "model:server";

declare function server:version() { xdmp:version() } ;

declare function server:uuids( $count ) {
  xdmp:to-json( for $c in ( 1 to xs:integer( $count ) ) 
  return fn:substring( xdmp:md5( fn:concat( fn:string( fn:current-date() ), 
    fn:string( $c ), fn:string( xdmp:request() ) ) ), 1, 32 ) ) };
