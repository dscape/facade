xquery version "1.0-ml";
module namespace db = "model:database";

declare function db:list() { 
  fn:string-join( xdmp:database-name( xdmp:databases() ), "," ) } ;