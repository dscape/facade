xquery version "1.0-ml" ;

import module namespace r = "routes.xqy" at "/lib/rewrite/routes.xqy" ;

declare function local:documentGet( $path ) { 
  xdmp:document-get( fn:concat( xdmp:modules-root(), $path ) ) } ;

declare variable $routesCfg := local:documentGet( "config/routes.xml" ) ;

let $r :=
  r:selectedRoute( $routesCfg/routes )
  let $_ := xdmp:log ($r)
  return $r