xquery version "1.0-ml";

import module namespace server = "model:server" at "/models/server.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare function local:version() {
  mvc:mustRevalidateCache(), mvc:render( 'server/version', 
    server:version() )  } ;

declare function local:native_query_servers() { '{}' } ;

declare function local:query_servers() { 
  '{"javascript":"couchdb_1.0.1/bin/couchjs couchdb_1.0.1/share/couchdb/server/main.js"}
' } ;

declare function local:session() {
  '{ "ok": true,
     "userCtx": 
      { "name": null,
        "roles": ["_admin"]
      },
     "info":{"authentication_db":"_users",
     "authentication_handlers":["oauth","cookie","default"],
     "authenticated":"default"}}
  '  } ;

declare function local:uuids() { ( 
  mvc:noCache(), mvc:render( 'server/uuids',
    server:uuids( xdmp:get-request-field( "count", "1" ) [1] ) ) ) } ;

xdmp:apply( mvc:function() )