xquery version "1.0-ml";
module namespace db = "model:database";

import module namespace info="http://marklogic.com/appservices/infostudio" 
  at "/MarkLogic/appservices/infostudio/info.xqy";

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
  then db:error( map:get( $m, '412' ) )
  else 
    let $db := 
      try { info:database-create( $database ) }
      catch ( $e ) { db:error( map:get( $m, '500' ) ) }
    return 
      if ( $db castable as xs:integer ) then <ok/> 
      else db:error( map:get( $m, '500' ) )
   else db:error( map:get( $m, '400' ) ) } ;

declare function db:database( $database ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found',
    'Database does not exist.' ) )
  return
    if ( db:exists ( $database ) )
    then 'not yet'
    else db:error( map:get( $m, '404' ) ) };

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
        catch ( $e ) { db:error( map:get( $m, '500' ) ) }
      return <ok/>
  else db:error( map:get( $m, '404' ) ) };

declare function db:list() { 
  fn:string-join( xdmp:database-name( xdmp:databases() ), "," ) } ;

declare function db:exists ( $database ){ db:list() [ . = $database ] } ;

declare function db:validName( $database ) { 
  fn:matches( $database, '^[a-z]([a-z]|[0-9]|_|-)*$' ) } ;

declare function db:error( $l ) { xdmp:set-response-code( $l[1], $l[2] ),
  document { <e> <id> {$l[3]} </id> { $l[4] } </e> } };