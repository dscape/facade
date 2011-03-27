xquery version "1.0-ml";
module namespace db = "model:database";

import module namespace h    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;
import module namespace info="http://marklogic.com/appservices/infostudio" 
  at "/MarkLogic/appservices/infostudio/info.xqy";
import module namespace admin = "http://marklogic.com/xdmp/admin" 
  at "/MarkLogic/admin.xqy";

declare function db:list() { xdmp:to-json( db:_list() ) } ;

declare function db:_list() { xdmp:database-name( xdmp:databases() ) } ;

declare function db:exists ( $database ){ db:_list() [ . = $database ] } ;

declare function db:validName( $database ) { 
  fn:matches( $database, '^[a-z]([a-z]|[0-9]|_|-)*$' ) } ;

declare function db:documents( $database, $limit, $startKey, $endKey, 
  $descending, $includeDocs, $skip ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found',
    'Database does not exist.' ) )
  let $_ := map:put( $m, '500', ( 500, 'Internal Server Error', 'db_docs_exc',
    'The database docs could not be retrieved, an exception ocurred.' ) )
  return 
    if ( db:exists( $database ) )
    then 
      try {
      let $totalDocs := db:_database( $database ) [2]
      let $l := xdmp:eval('
    import module namespace dls = "http://marklogic.com/xdmp/dls" 
      at "/MarkLogic/dls.xqy";
    declare variable $limit external ;
    declare variable $descending external ;
    declare variable $includeDocs external ;
    declare variable $startKey external ;
    declare variable $endKey external ;
    declare variable $skip external ;
    declare variable $totalDocs external ;
    declare variable $couchBase := "/_couchBase/" ;

    let $s := 
      if ( $descending = "descending" )
      then $endKey
      else $startKey
    let $e := 
      if ( $descending = "descending" )
      then $startKey
      else $endKey
    let $total := xs:unsignedInt( $limit ) + $skip + 1
    let $uris := 
      cts:uris( (), ( $descending ), 
        cts:directory-query( $couchBase, "1" ) )
        [ if ($s) then . > fn:concat( $couchBase, $s ) else fn:true()]
        [ if($e) then . < fn:concat($couchBase, $e) else fn:true() ]
        [ $skip+1 to $total+1 ]  
    let $offset :=
      fn:count( cts:uris( $uris[1], ( 
        if ( $descending = "descending" ) then "ascending" else "descending" ) , 
          cts:directory-query( $couchBase, "1" ) ) ) - 1
    let $versions := 
      for $uri in $uris
      return dls:document-history( $uri ) /*:version [ *:latest/fn:string() = "true" ]
    return ($offset, fn:string-join(
      for $h in $versions
      let $uri := fn:replace( fn:string( $h//*:document-uri[1] ), $couchBase, "" )
      let $rev := fn:concat( fn:string( $h//*:version-id ), "-", 
        fn:string( $h//*:annotation ) )
      return  fn:concat(
        "{""key"": """, $uri,""", ",
        """id"": """, $uri,""", ",
        """value"": { ""rev"": """, $rev,""" } }"), ",&#x0a;" ))',
        ( xs:QName("limit"), ( $limit, 11 )[1] ,
          xs:QName("descending"), 
          if ( $descending ) then 'descending' else 'ascending',
          xs:QName("includeDocs"), 
          if ( $includeDocs ) then fn:true() else fn:false(),
          xs:QName("startKey"), 
          if ( $startKey instance of xs:string ) 
            then fn:replace($startKey, '"', '') else fn:false(),
          xs:QName("endKey"), 
          if ( $endKey instance of xs:string ) 
            then fn:replace($endKey, '"', '') else fn:false(),
          xs:QName("skip"), 
          if ( $skip castable as xs:unsignedInt ) 
          then xs:unsignedInt($skip) else 0,
          xs:QName("totalDocs"), $totalDocs ),
        <options xmlns="xdmp:eval">
          <database> { xdmp:database( $database ) } </database>
        </options> )
    let $offset := $l[1]
    let $rows   := $l[2]
    return text { xdmp:to-json(
      ( $database, $totalDocs, $offset, $rows ) ) } }
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
        db:setup( $database ) }
      catch ( $e ) { xdmp:log($e), h:errorFor( map:get( $m, '500' ) ) }
    return 
      if ( $db castable as xs:integer ) then <ok/> 
      else h:errorFor( map:get( $m, '500' ) )
   else h:errorFor( map:get( $m, '400' ) ) } ;

declare function db:setup( $database ) {
  admin:save-configuration-without-restart(
    admin:database-set-uri-lexicon( admin:get-configuration(), 
      xdmp:database( $database ), fn:true() ) ),
  xdmp:eval('import module namespace dls="http://marklogic.com/xdmp/dls" 
    at "/MarkLogic/dls.xqy";
    dls:retention-rule-insert(
    dls:retention-rule(
      "All Versions Retention Rule",
      "Retain all versions of all documents",
      (),
      (),
      "Locate all of the documents",
      cts:and-query(()) ) )', (),
    <options xmlns="xdmp:eval">
      <database> { xdmp:database( $database ) } </database>
    </options> ) } ;

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