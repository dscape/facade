xquery version "1.0-ml";
module namespace doc = "model:document";

import module namespace db = "model:database" at "/models/database.xqy" ;
import module namespace h    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;
import module namespace json = "http://marklogic.com/json"
  at "/lib/json.xqy" ;

declare variable $couchBase := '/_couchBase/' ;

declare function doc:create( $database, $uri, $json ) {
  let $m := map:map()
  let $_ := map:put( $m, 'bad_request', ( 400, 'Bad Request', 'bad_request',
     'Document must be a JSON object.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'doc_create_exc',
    'The document could not be created, an exception ocurred.' ) )
  let $_ := map:put( $m, '500v', ( 500, 'Internal Server Error', 'doc_validation',
    'Bad special document member.' ) )
  let $_ := map:put( $m, '400', ( 400, 'Bad Request', 'bad_request',
    'Invalid UTF-8 JSON.' ) )
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found', 
    'No DB File.' ) )  
  let $uri := fn:concat( $couchBase, $uri )
  let $doc := doc:valid( $json )
  let $invalidKeys := doc:invalidKeys( $doc )
  let $q :=
   'import module namespace dls = "http://marklogic.com/xdmp/dls" 
    at "/MarkLogic/dls.xqy" ;
    declare variable $uri external ;
    declare variable $json external ;
    declare variable $managed := dls:document-is-managed( $uri ) ;
    
    if ( $managed )
    then 
      let $u := dls:document-checkout-update-checkin( $uri, $json, xdmp:md5($json), fn:true() )
      let $_ := xdmp:add-response-header( "ETag", xdmp:md5($json) )
      return ()
    else dls:document-insert-and-manage( $uri, fn:false(), $json, xdmp:md5($json) )'
  return 
    if ( db:exists( $database ) )
    then if( $doc )
    then if( fn:exists( $invalidKeys ) )
    then h:errorFor( map:get( $m, '500v' ) )
    else
      try { ( xdmp:eval( $q, ( xs:QName("uri"), $uri, xs:QName("json"), $doc ) ,
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
          <isolation>different-transaction</isolation>
        </options> ), <ok/> ) }
      catch ( $e ) { xdmp:log($e), h:errorFor( map:get( $m, '500' ) ) } 
    else h:errorFor( map:get( $m, '400' ) )
    else h:errorFor( map:get( $m, '404' ) ) } ;

declare function doc:invalidKeys( $json ) {
 let $allowed :=
   ('_id', '_rev', '_attachments', '_deleted', '_revisions', '_revs_info', 
    '_conflicts', '_deleted_conflicts')
  return $json//fn:local-name(.) 
    [ fn:starts-with(., "_") and fn:not(. = $allowed) ] };

declare function doc:valid( $text ) {
  try { json:jsonToXML( $text ) } catch ( $e ) { () } } ;