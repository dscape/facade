xquery version "1.0-ml";

import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare function local:list() {
  mvc:mustRevalidateCache(), mvc:render( 'json-list', db:list() )  } ;

declare function local:put()    { 
  mvc:mustRevalidateCache(), mvc:render( 'ok', db:create(
    xdmp:get-request-field( 'database' ) ) )  } ;

declare function local:delete()    { 
  mvc:mustRevalidateCache(), mvc:render( 'ok', db:delete(
    xdmp:get-request-field( 'database' ) ) )  } ;

xdmp:apply( mvc:function() )