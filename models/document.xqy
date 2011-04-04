xquery version "1.0-ml";
module namespace doc = "model:document";

import module namespace db   = "model:database" at "/models/database.xqy" ;
import module namespace h    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;
import module namespace mem  = "update.xqy" at "/lib/update.xqy" ;
import module namespace json = "http://marklogic.com/json"
  at "/lib/json.xqy" ;

declare variable $couchBase := '/_couchBase/' ;

declare function doc:delete( $database, $uri ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found', 
    'No DB File.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'doc_get_exc',
    'The document could not be retrieved, an exception ocurred.' ) )
  let $uri := fn:concat( $couchBase, $uri )
  let $q :=
   'import module namespace dls = "http://marklogic.com/xdmp/dls" 
     at "/MarkLogic/dls.xqy" ;
    declare variable $uri external ;
    dls:document-delete( $uri, fn:true(), fn:true() )'
  return
    if ( db:exists( $database ) )
    then 
      try { 
        let $_ := 
        ( xdmp:eval( $q, ( xs:QName("uri"), $uri ) ,
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
        </options> ) )
        return <ok/> }
      catch ( $e ) { xdmp:log( $e ), h:errorFor( map:get( $m, '500' ) ) } 
    else h:errorFor( map:get( $m, '404' ) ) } ;

declare function doc:document( $database, $uri, $revsInfo, $rev ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found', 
    'No DB File.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'doc_get_exc',
    'The document could not be retrieved, an exception ocurred.' ) )
  let $uri := fn:concat( $couchBase, $uri )
  let $q :=
   'import module namespace dls = "http://marklogic.com/xdmp/dls" 
     at "/MarkLogic/dls.xqy" ;
    declare variable $uri external ;
    declare variable $rev external ;
    declare variable $versions := dls:document-history( $uri ) /*:version ;
    
    declare function local:versionIsAvailable( $version ) {
      $version castable as xs:unsignedInt and
      fn:exists( $versions [*:deleted=fn:false()] 
        /*:version-id = xs:unsignedInt($version) ) } ;

    declare function local:getDoc( $fromRev ) {
      let $version := fn:tokenize( $fromRev, "-" )[1]
      return
      if( local:versionIsAvailable( $version ) )
      then 
        let $doc := dls:document-version( $uri, xs:unsignedInt( $version ) )
        let $rev := fn:concat( $version, "-", $doc//_rev[1] )
        return ( xdmp:add-response-header( "ETag", $rev ), $doc, $rev )
      else 
        let $version := fn:string( 
          $versions [ *:latest/fn:string() = "true" ] /*:version-id )
        let $rev := fn:concat( $version, "-", fn:string(
          $versions [ *:latest/fn:string() = "true" ] /*:annotation[1] ) )
        return ( xdmp:add-response-header( "ETag", $rev ), fn:doc( $uri ), $rev ) };

   ( local:getDoc( $rev ), $versions )'
  return
    if ( db:exists( $database ) )
    then 
      try { 
        let $l := 
        ( xdmp:eval( $q, ( xs:QName("uri"), $uri, xs:QName("rev"), $rev ) ,
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
        </options> ) )
        let $revs := if($revsInfo) then <_revs_info type="array">
            { for $i in $l[3 to fn:last()]
              let $version := fn:string( $i//*:version-id )
              let $r     := fn:string( $i//*:annotation )
              let $status := if( $i//*:deleted=fn:true() ) then "missing" else "available"
              order by $version descending
              return <item type="object">
                <rev type="string">{fn:concat($version,"-",$r)}</rev>
                <status type="string">{$status}</status>
              </item>
            }
        </_revs_info> else ()
        let $idNode := <a> { $l[1]/json } </a>//_id[1]
        let $json := <b> { mem:node-insert-after( $idNode, $revs ) } </b> //json
        let $dispRev := $l[2]
        let $jsonCorrectRev := mem:node-replace( $json//_rev[1],
          <_rev type="string">{$dispRev}</_rev> ) //json 
        return text { json:xmlToJSON( $jsonCorrectRev ) } }
      catch ( $e ) { xdmp:log($e), h:errorFor( map:get( $m, '500' ) ) } 
    else h:errorFor( map:get( $m, '404' ) ) } ;

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
  let $_ := map:put( $m, '409', ( 409, "Conflict", "conflict", 
  "Document update conflict." ) )
  let $curi        := fn:concat( $couchBase, $uri )
  let $doc         := doc:valid( $json )
  let $invalidKeys := doc:invalidKeys( $doc )
  let $q           :=
   'import module namespace dls = "http://marklogic.com/xdmp/dls" 
    at "/MarkLogic/dls.xqy" ;
    declare variable $uri external ;
    declare variable $json external ;
    declare variable $fromVersion external ;
    
    let $rev := fn:string( ($json//_rev) [1] )
    let $version := if (dls:document-is-managed( $uri ))
      then fn:string( dls:document-history( $uri ) /*:version
        [ *:latest/fn:string() = "true" ] /*:version-id )
      else "1"
    let $etag := fn:concat( $version, "-", $rev )
    return 
      if ( $fromVersion = $version )
      then ( xdmp:add-response-header( "ETag", $etag ), $etag,
        if ( dls:document-is-managed( $uri ) )
        then 
          dls:document-checkout-update-checkin( $uri, $json, $rev, fn:true() )
        else ( 
          dls:document-insert-and-manage( $uri, fn:false(), $json, $rev ), $etag ) )
      else fn:error(xs:QName("FAC-CONFLICT"), "Conflict")'
  return 
    if ( db:exists( $database ) )
    then if( $doc )
    then if( fn:exists( $invalidKeys ) )
    then h:errorFor( map:get( $m, '500v' ) )
    else
      try { 
        let $rev := <_rev type="string">{
          xdmp:md5( fn:concat( fn:string( xdmp:random() ), $json ) ) } </_rev>
        let $a := <a>{$doc/node()}</a>
        let $jsonWithId :=
          mem:node-insert-after( $a/json/@*[fn:last()],
            ( if ($a//_id) then () else 
            <_id  type="string">{$uri}</_id>) ) 
        let $revFromId := ( $jsonWithId//_rev ) [1]
        let $jsonWithRevs := if ($revFromId)
          then mem:node-replace( $revFromId, $rev )
          else mem:node-insert-after( ($jsonWithId//_id) [1], $rev ) 
        return text { xdmp:to-json( ( $uri, 
          xdmp:eval( $q, ( xs:QName("uri"), $curi, xs:QName("json"), 
            $jsonWithRevs/json,
            xs:QName("fromVersion"), if($revFromId) 
            then fn:tokenize($revFromId, "-")[1] else "1" ) ,
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
          <isolation>different-transaction</isolation>
        </options> ) ) ) } }
      catch ( $e ) { xdmp:log($e), 
        if($e//*:name="FAC-CONFLICT")
        then h:errorFor( map:get( $m, '409' ) )
        else h:errorFor( map:get( $m, '500' ) ) } 
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