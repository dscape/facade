xquery version "1.0-ml";
module namespace doc = "model:document";

import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace h    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;
import module namespace json = "http://marklogic.com/json"
  at "/lib/json.xqy" ;

declare variable $couchBase := '/_couchBase/' ;

declare function doc:create( $database, $uri, $json ) {
  (: if uri is valid and
   : json doesnt contain invalid,
   : plus create revision 
   :)
  let $m := map:map()
  let $_ := map:put( $m, 'bad_request', ( 400, 'Bad Request', 'bad_request',
     'Document must be a JSON object.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'doc_create_exc',
    'The document could not be created, an exception ocurred.' ) )
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found', 
    'no_db_file.' ) )  
  let $uri := fn:concat( $couchBase, $uri )
  let $q :=
   'declare variable $uri external;
    declare variable $json external;
    xdmp:document-insert( $uri, $json )'
  return 
    if ( db:exists( $database ) )
    then 
      try { ( xdmp:eval( $q, ( xs:QName("uri"), $uri, xs:QName("json"), $json ) ,
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
          <isolation>different-transaction</isolation>
        </options> ), <ok/> ) }
      catch ( $e ) { xdmp:log($e),
        h:errorFor( map:get( $m, '500' ) )
      } 
    else h:errorFor( map:get( $m, '404' ) ) } ;