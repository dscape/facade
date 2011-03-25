xquery version "1.0-ml";

import module namespace doc    = "model:document" at "/models/document.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare variable $database := xdmp:get-request-field( 'database' ) [1] ;
declare variable $uri      := xdmp:get-request-field( 'document' ) [1] ;

declare function local:put()    { 
  xdmp:log(xdmp:get-request-field-names()),
  mvc:mustRevalidateCache(), mvc:render( 'shared/create', 
    doc:create( $database, $uri, text{" "} ) )  } ;

declare function local:get() { 'foo' };

xdmp:apply( mvc:function() )