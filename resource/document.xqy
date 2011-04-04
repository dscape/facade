xquery version "1.0-ml";

import module namespace doc    = "model:document" at "/models/document.xqy" ;
import module namespace att    = "model:attachment" at "/models/attachment.xqy" ;
import module namespace mvc    = "helper.xqy" at "/lib/rewrite/helper.xqy" ;

declare variable $database := xdmp:get-request-field( 'database' ) [1] ;
declare variable $document := xdmp:get-request-field( 'document' ) [1] ;

declare function local:put()    {
  mvc:mustRevalidateCache(),
  let $json := xdmp:get-request-body( 'text' )
  return mvc:render( 'document/create', 
    doc:create( $database, $document, $json ) )  } ;

declare function local:delete()    { 
  mvc:mustRevalidateCache(), mvc:render( 'shared/ok', 
    doc:delete( $database, $document ) )  } ;

declare function local:get() { 
  mvc:mustRevalidateCache(), mvc:render( 'document/show', 
    doc:document( $database, $document,
      xdmp:get-request-field( 'revs_info') [1],
      xdmp:get-request-field( 'rev', "" ) [1] ) ) };

declare function local:post() {
  let $attachment  := xdmp:get-request-field( "_attachments" )
  let $filename    := xdmp:get-request-field-filename( "_attachments" )
  let $rev         := xdmp:get-request-field( "_rev" )
  return att:create( $database, $document, $filename, $attachment, $rev ) };

xdmp:apply( mvc:function() )