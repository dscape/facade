xquery version "1.0-ml";
module namespace att = "model:attachment";

import module namespace doc   = "model:document" at "/models/document.xqy" ;
import module namespace h     = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare function att:create( $database, $document, $filename, 
  $file, $rev ) {
  let $m := map:map()
  let $_ := map:put( $m, '404', ( 404, 'Not Found', 'not_found', 
    'No DB File.' ) )
  return xdmp:eval('
    declare variable $file external;
    declare variable $uri external;
  
    xdmp:document-insert( $uri, $file )', 
    ( xs:QName("file"), $file,
      xs:QName("uri"), $filename
     ),
    <options xmlns="xdmp:eval">
      <database> { xdmp:database( $database ) } </database>
      <isolation>different-transaction</isolation>
    </options> ) };