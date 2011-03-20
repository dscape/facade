declare variable $params external ;

fn:string(
  <txt> {{"couchdb":"Welcome","version":"{$params}"}} </txt>
)