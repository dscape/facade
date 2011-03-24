xquery version "1.0-ml";

import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare variable $database := 
  xdmp:get-request-field( 'database' ) [1] ;

declare function local:list() {
  mvc:mustRevalidateCache(), mvc:render( 'json-list', db:list() )  } ;

declare function local:_all_docs() {
  mvc:mustRevalidateCache(), mvc:render( 'all-docs', db:documents(
    $database,
    xdmp:get-request-field( 'limit' ) [1],
    xdmp:get-request-field( 'startkey' ) [1],
    xdmp:get-request-field( 'endkey' ) [1],
    xdmp:get-request-field( 'descending' ) [1] = 'true',
    xdmp:get-request-field( 'include_docs' ) [1] ) )  } ;

declare function local:put()    { 
  mvc:mustRevalidateCache(), mvc:render( 'ok', db:create( $database ) )  } ;

declare function local:get()    { 
  mvc:mustRevalidateCache(), mvc:render( 'database', 
    db:database( $database ) )  } ;

declare function local:delete()    { 
  mvc:mustRevalidateCache(), mvc:render( 'ok', db:delete( $database ) )  } ;

xdmp:apply( mvc:function() )