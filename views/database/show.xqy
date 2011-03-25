declare variable $params external ;
declare variable $l := xdmp:from-json( $params ) ;

fn:string( <v>
{{ 
   "db_name": "{ $l[1] }",
   "doc_count": { $l[2] },
   "doc_del_count": { $l[3] },
   "compact_running": { $l[4] },
   "update_seq": { $l[5] },
   "disk_size": 0
}}&#x0a;</v> )