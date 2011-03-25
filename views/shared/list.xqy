declare variable $params external ;
declare variable $l := xdmp:from-json($params) ;

if( fn:count( $l ) = 1 )
then fn:concat( '[', $params, ']' )
else $params, ''