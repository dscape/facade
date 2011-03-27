xquery version "1.0-ml";

import module namespace doc    = "model:document" at "/models/document.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare variable $database := xdmp:get-request-field( 'database' ) [1] ;
declare variable $uri      := xdmp:get-request-field( 'document' ) [1] ;

declare function local:put()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/create', 
    doc:create( $database, $uri, xdmp:get-request-body( 'text' ) ) )  } ;

declare function local:delete()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/ok', 
    doc:delete( $database, $uri ) )  } ;

declare function local:get() { 
  mvc:mustRevalidateCache(), mvc:render( 'document/show', 
    doc:document( $database, $uri,
      xdmp:get-request-field( 'revs_info' ) [1],
      xdmp:get-request-field( 'rev', "" ) [1] ) ) };

xdmp:apply( mvc:function() )