xquery version "3.0";

module namespace wdbst = "https://github.com/dariok/wdbplus/start";

import module namespace wdb  = "https://github.com/dariok/wdbplus/wdb" at "app.xql";
import module namespace wdbm = "https://github.com/dariok/wdbplus/nav" at "/db/apps/edoc/modules/nav.xqm";

declare namespace output  = "http://www.w3.org/2010/xslt-xquery-serialization";

declare option output:method "html5";
declare option output:media-type "text/html";

declare function wdbst:getStartHeader($node as node(), $model as map(*)) as node()* {
  if (doc-available($model("pathToEd") || '/resources/startHeader.html'))
  then doc($model("pathToEd") || '/resources/startHeader.html')
  else if (wdb:findProjectFunction($model, 'getStartHeader', 1))
  then wdb:eval('wdbPF:getStartHeader($model)', false(), (xs:QName('model'), $model))
  else (
    <h1>{$model("title")}</h1>,
    <hr/>
  )
};

declare function wdbst:getStartLeft($node as node(), $model as map(*)) as node()* {
  if (doc-available($model("pathToEd") || '/resources/startLeft.html'))
  then doc($model("pathToEd") || '/resources/startLeft.html')
  else if (wdb:findProjectFunction($model, 'getStartLeft', 1))
  then wdb:eval('wdbPF:getStartLeft($model)', false(), (xs:QName('model'), $model))
  else (<h1>Inhalt</h1>,())
};

declare function wdbst:getStart ($node as node(), $model as map(*)) as node()* {
  if (doc-available($model("pathToEd") || '/resources/startRight.html'))
  then doc($model("pathToEd") || '/resources/startRight.html')
  else if (wdb:findProjectFunction($model, 'getStart', 1))
  then wdb:eval('wdbPF:getStart($model)', false(), (xs:QName('model'), $model))
  else wdbm:getRight(<void/>, $model)
};