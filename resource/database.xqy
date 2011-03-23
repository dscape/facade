xquery version "1.0-ml";

import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare function local:list() {
  mvc:mustRevalidateCache(), mvc:render( 'json-list', db:list() )  } ;

xdmp:apply( mvc:function() )