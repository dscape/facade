xquery version "1.0-ml";

import module namespace server    = "model:server" at "/models/server.xqy" ;
import module namespace doc    = "model:document" at "/models/document.xqy" ;
import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare variable $database := xdmp:get-request-field( 'database' ) [1] ;

declare function local:list() {
  mvc:mustRevalidateCache(), mvc:render( 'shared/list', db:list() )  } ;

declare function local:_all_docs() {
  mvc:mustRevalidateCache(), mvc:render( 'database/alldocs', db:documents(
    $database,
    xdmp:get-request-field( 'limit' ) [1],
    xdmp:get-request-field( 'startkey' ) [1],
    xdmp:get-request-field( 'endkey' ) [1],
    xdmp:get-request-field( 'descending' ) [1] = 'true',
    xdmp:get-request-field( 'include_docs' ) [1] ) )  } ;

declare function local:post()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/create', 
    doc:create( $database, 
      fn:string( server:_uuids( 1 ) )
      , xdmp:get-request-body( 'text' ) ) )  } ;

declare function local:put()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/create', 
    db:create( $database ) )  } ;

declare function local:get()    { 
  mvc:mustRevalidateCache(), mvc:render( 'database/show', 
    db:database( $database ) )  } ;

declare function local:delete()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/ok', 
    db:delete( $database ) )  } ;

xdmp:apply( mvc:function() )