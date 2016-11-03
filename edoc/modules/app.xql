xquery version "3.0";

module namespace hab = "http://diglib.hab.de/ns/hab";

import module namespace templates	= "http://exist-db.org/xquery/templates" ;
import module namespace config		= "http://diglib.hab.de/ns/config" at "config.xqm";
import module namespace habt			= "http://diglib.hab.de/ns/transform" at "transform.xqm";

declare namespace mets = "http://www.loc.gov/METS/";
declare namespace xlink = "http://www.w3.org/1999/xlink";
declare namespace tei = "http://www.tei-c.org/ns/1.0";

declare variable $hab:edoc := "/db/edoc";
declare variable $hab:edocRestBase := "http://dev2.hab.de/rest";
declare variable $hab:edocRest := concat($hab:edocRestBase, $hab:edoc);
declare variable $hab:edocBase := 'http://dev2.hab.de/edoc';

declare %templates:wrap
function hab:getEE($node as node(), $model as map(*), $id as xs:string) as map(*) {
    let $ed := substring-before(substring-after($id, 'edoc_'), '_')
    
	let $mets := doc(concat($hab:edoc, '/', $ed, "/mets.xml"))
	let $metsfile := $mets//mets:file[@ID=$id]
	let $fileLoc := $metsfile/mets:FLocat/@xlink:href
	let $file := doc(concat($hab:edoc, '/', $ed, '/', $fileLoc))
	let $type := $metsfile/parent::mets:fileGrp/@ID
	let $xslt := $mets//mets:behaviorSec[@ID='html']/mets:behavior[@STRUCTID=$type]/mets:mechanism/@xlink:href
	
	let $authors := $file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:author
	let $shortTitle := $file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[@type]
	let $nr := $file/tei:TEI/@n
	let $title := element tei:title {
		$nr,
		$file/tei:TEI/tei:teiHeader/tei:fileDesc/tei:titleStmt/tei:title[not(@type)]/node()
	}
	
	return map { "fileLoc" := $fileLoc, "xslt" := $xslt, "type" := $type, "title" := $title ,
			"shortTitle" := $shortTitle, "authors" := $authors, "ed" := $ed }
};

declare function hab:EEtitle($node as node(), $model as map(*)) {
	let $title := habt:transform($model("title"))
	return $title
};

declare function hab:EEpart($node as node(), $model as map(*)) {
	<h2>{
		switch ($model("type"))
			case "introduction"
				return string("Einleitung")
			case "transcript"
				return string("Text")
			default
				return string($model("type"))}
	</h2>
};

declare function hab:EEbody($node as node(), $model as map(*)) {
	let $file := concat($hab:edoc, '/', $model("ed"), '/', $model("fileLoc"))
	(:let $xslt := concat('xmldb:exist://', $hab:edoc, '/', $model("xslt")):)
	let $xslt := concat($hab:edoc, '/', $model("ed"), '/', $model("xslt"))
	let $params := <parameters><param name="server" value="eXist"/></parameters>
	
	return transform:transform(doc($file), doc($xslt), $params)
(:	return <div><p>f {$file}</p><p>x {$xslt}</p><p>p {$params}</p></div>:)
};

declare function hab:pageTitle($node as node(), $model as map(*)) {
	let $ti := string ($model("shortTitle"))
	return <title>WDB {string($model("title")/@n)} – {$ti}</title>
};

declare function hab:footer($node as node(), $model as map(*)) {
	let $xml := string($model("fileLoc"))
	let $xsl := string($model("xslt"))
	return
	<div class="footer">
		<div class="footerEntry">XML: <a href="{concat($hab:edocRest, '/', $model("ed"), '/', $xml)}">{$xml}</a></div>
		<div class="footerEntry">XSLT: <a href="{concat($hab:edocRest, '/', $model("ed"), '/', $xsl)}">{$xsl}</a></div>
	</div>
};

declare function hab:authors($node as node(), $model as map(*)) {
	let $max := count($model("authors"))
	for $auth at $i in $model("authors")
		let $t := if ($i > 1 and $i < max)
			then ", "
			else if ($i > 1) then " und " else ""
		return concat($t, $auth)
};

declare function hab:getCSS($node as node(), $model as map(*)) {
	let $f := if ($model("type") = "transcript")
			then "transcr.css"
			else "intro.css"
	let $path := concat($model("ed"), "/layout/project.css")
	
	return (<link rel="stylesheet" type="text/css" href="resources/css/{$f}" />,
		<link rel="stylesheet" type="text/css" href="{$path}" />
	)
};

declare function hab:getEENr($node as node(), $model as map(*), $id as xs:string) as node() {
	let $ee := substring-before(substring-after($id, 'edoc_'), '_')
	return <meta name="edition" content="{$ee}" />
};

(: neu für das Laden projektspezifischer JS; 2016-11-02 DK :)
declare function hab:getJS($node as node(), $model as map(*)) {
	let $path := concat($model("ed"), "/script/project.js")
	return <script src="{$path}" type="text/javascript" />
};