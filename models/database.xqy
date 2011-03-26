xquery version "1.0-ml";
module namespace db = "model:database";

import module namespace admin = "http://marklogic.com/xdmp/admin" 
  at "/MarkLogic/admin.xqy";

import module namespace h    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;
import module namespace info="http://marklogic.com/appservices/infostudio" 
  at "/MarkLogic/appservices/infostudio/info.xqy";

declare function db:list() { xdmp:to-json( db:_list() ) } ;

declare function db:_list() { xdmp:database-name( xdmp:databases() ) } ;

declare function db:exists ( $database ){ db:_list() [ . = $database ] } ;

declare function db:validName( $database ) { 
  fn:matches( $database, '^[a-z]([a-z]|[0-9]|_|-)*$' ) } ;

declare function db:documents( $database, $limit, $startKey, $endKey, 
  $descending, $includeDocs ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found',
    'Database does not exist.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'db_docs_exc',
    'The database docs could not be retrieved, an exception ocurred.' ) )
  return 
    if ( db:exists( $database ) )
    then 
      try {
      let $offset := 0
      let $rows := xdmp:eval('
    import module namespace dls = "http://marklogic.com/xdmp/dls" 
      at "/MarkLogic/dls.xqy";
    declare variable $args external ;
    declare variable $couchBase := "/_couchBase/" ;
    declare variable $l         := xdmp:from-json($args) ;
    let $l           := $l[1]
    let $d           := $l[2]
    let $includeDocs := $l[3]
    let $startKey    := if ( $l[4] ) then $l[4] else ()
    let $endKey      := $l [5]
    let $uris := 
      cts:uris( $startKey, ( $l, $d ), cts:directory-query( $couchBase, "infinity" ) )
        [ fn:not( fn:matches( ., "versions/" ) ) ]
        [ if($endKey) then . < fn:concat($couchBase, $endKey) else fn:true() ] 
    let $history := dls:document-history( $uris ) [.//*:latest]
    return fn:string-join(
      for $h in document{ $history } /*:document-history
      let $uri := fn:replace( fn:string( $h//*:document-uri ), $couchBase, "" )
      let $rev := fn:concat( fn:string( $h//*:version-id ), "-", 
        fn:string( $h//*:annotation ) )
      return  fn:concat(
        "{""key"": """, $uri,""", ",
        """id"": """, $uri,""", ",
        """value"": { ""rev"": """, $rev,""" } }"), ",&#x0a;" )',
        ( xs:QName("args"), 
          xdmp:to-json( (fn:concat( "limit=", ( $limit, 11 ) [1] ),
          if ( $descending ) then "descending" else 'ascending',
          if ( $includeDocs ) then fn:true() else fn:false(),
          if ( $startKey ) then $startKey else fn:false(),
          $endKey ) ) ),
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
        </options> )
    return text { xdmp:to-json(
      ( $database, db:_database( $database ) [2], $offset, $rows ) ) } }
    catch( $e ) { xdmp:log( $e ), h:errorFor( map:get( $m, '500' ) ) }
    else
      h:errorFor( map:get( $m, '404' ) ) };

declare function db:create( $database ) { 
  let $m := map:map()
  let $_ := map:put( $m, '412', ( 412, 'Pre-condicion failed', 'file_exists',
    'The database could not be created, the file already exists.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'db_create_exc',
    'The database could not be created, an exception ocurred.' ) )
  let $_ := map:put( $m, '400', ( 400, 'Bad Request', 'illegal_database_name',
    fn:concat( 'Only lowercase characters (a-z), digits (0-9), and any of the',
     ' characters _, and - are allowed. Must begin with a letter.' ) ) )
  return
  if ( db:validName( $database ) )
  then if ( db:exists ( $database ) )
  then h:errorFor( map:get( $m, '412' ) )
  else 
    let $db := 
      try { info:database-create( $database ),
        db:setURILexicon( $database ) }
      catch ( $e ) { xdmp:log($e), h:errorFor( map:get( $m, '500' ) ) }
    return 
      if ( $db castable as xs:integer ) then <ok/> 
      else h:errorFor( map:get( $m, '500' ) )
   else h:errorFor( map:get( $m, '400' ) ) } ;

declare function db:setURILexicon( $database ) {
  admin:save-configuration-without-restart(
    admin:database-set-uri-lexicon( admin:get-configuration(), 
      xdmp:database( $database ), fn:true() ) ) } ;

declare function db:database( $database ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found',
    'Database does not exist.' ) )
  return
    if ( db:exists ( $database ) )
    then xdmp:to-json( db:_database( $database ) )
    else h:errorFor( map:get( $m, '404' ) ) };

declare function db:_database( $database ) {
  let $db     := xdmp:read-cluster-config-file("databases.xml") 
    //*:database [ *:database-name = $database ] 
  let $forestCounts := 
    for $id in $db//*:forest-id
    return xdmp:forest-counts(xs:unsignedLong($id))
  let $forestStatus := 
    for $id in $db//*:forest-id
    return xdmp:forest-status(xs:unsignedLong($id))
  let $activeCount := xdmp:eval('
    declare variable $couchBase := "/_couchBase/" ;
    xdmp:estimate( 
      cts:search( fn:doc(), cts:directory-query( $couchBase ) ) )',
    (), <options xmlns="xdmp:eval">
      <database> { xdmp:database( $database ) } </database>
    </options>)
  let $deletedCount := fn:sum( $forestCounts//*:deleted-fragment-count)
  let $updateSeq    := xdmp:request-timestamp() 
  let $merging      := 
    some $f in $forestStatus//*:merges satisfies $f/node()
  return ( $database, $activeCount, $deletedCount, $merging, $updateSeq ) };

declare function db:delete( $database ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found',
    'Database does not exist.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'db_delete_exc',
    'The database could not be deleted, an exception ocurred.' ) )
  return
    if ( db:exists ( $database ) )
    then 
      let $db := 
        try { info:database-delete( $database ) }
        catch ( $e ) { xdmp:log($e), h:errorFor( map:get( $m, '500' ) ) }
      return <ok/>
  else h:errorFor( map:get( $m, '404' ) ) };