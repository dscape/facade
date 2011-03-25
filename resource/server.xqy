xquery version "1.0-ml";

import module namespace server = "model:server" at "/models/server.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare function local:version() {
  mvc:mustRevalidateCache(), mvc:render( 'server/version', 
    server:version() )  } ;

declare function local:session() {
  mvc:mustRevalidateCache(), mvc:render( 'server/session', 
    server:session() )  } ;

declare function local:uuids() { ( 
  mvc:noCache(), mvc:render( 'server/uuids',
    server:uuids( xdmp:get-request-field( "count", "1" ) [1] ) ) ) } ;

xdmp:apply( mvc:function() )