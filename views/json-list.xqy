declare variable $params external ;

xdmp:to-json(fn:tokenize($params,",")),''