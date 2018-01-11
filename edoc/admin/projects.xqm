xquery version "3.0";

module namespace wdbPL = "https://github.com/dariok/wdbplus/ProjectList";

import module namespace wdb			= "https://github.com/dariok/wdbplus/wdb"		at "../modules/app.xql";
import module namespace wdbs		= "https://github.com/dariok/wdbplus/stats"	at "../modules/stats.xqm";
import module namespace console	= "http://exist-db.org/xquery/console";

declare namespace meta	= "https://github.com/dariok/wdbplus/wdbmeta";
declare namespace tei		= "http://www.tei-c.org/ns/1.0";

declare function wdbPL:body ( $node as node(), $model as map(*) ) {
	let $ed := request:get-parameter('ed', '')
	let $file := request:get-parameter('file', '')
	let $job := request:get-parameter('job', '')
	
	return
		if ($job != '') then
			let $edition := substring-before(substring-after($file, $wdb:edocBaseDB||'/'), '/')
			let $metaFile := doc($wdb:edocBaseDB || '/' || $edition || '/wdbmeta.xml')
			let $relativePath := substring-after($file, $edition||'/')
			let $subColl := local:substring-before-last($file, '/')
			let $resource := local:substring-after-last($file, '/')
			
			return switch ($job)
				case 'add' return
					let $ins := <file xmlns="https://github.com/dariok/wdbplus/wdbmeta" path="{$relativePath}" uuid="{util:uuid(doc($file))}" 
						date="{xmldb:last-modified(local:substring-before-last($file, '/'), local:substring-after-last($file, '/'))}"/>
					let $up1 := update insert $ins into $metaFile//meta:files
					return local:getFileStat($edition, $file)
					
				case 'uuid' return
					let $fileEntry := $metaFile//meta:file[@path = $relativePath]
					let $up1 := update value $fileEntry/@uuid with util:uuid(doc($file))
					return local:getFileStat($edition, $file)
					
				case 'date' return
					let $fileEntry := $metaFile//meta:file[@path = $relativePath]
					let $up1 := update value $fileEntry/@date with xmldb:last-modified($subColl, $resource)
					return local:getFileStat($edition, $file)
					
				default return
					<div id="data"><div><h3>Strange Error</h3></div></div>
					
		else if ($ed = '' and $file = '') then
			<div id="content">
				<h3>Liste der Projekte</h3>
				{wdbs:projectList(true())}
			</div>
		else if ($ed != '' and $file = '') then
			local:getFiles($ed)
		else
			local:getFileStat($ed, $file)
};

declare function wdbPL:head ($node as node(), $model as map(*)) {
	let $ed := request:get-parameter('ed', '')
	return if ($ed = '')
		then <h1>Projekte</h1>
		else <h1>Projekt {$ed}</h1>
};

declare function local:getFiles($edoc as xs:string) {
	let $ed := collection($wdb:edocBaseDB || '/' || $edoc)//tei:teiHeader
	return
		<div id="content">
			<h1>Insgesamt {count($ed)} EE</h1>
			<table>
				<tbody>
					<tr>
						<th>Nr.</th>
						<th>Pfad</th>
						<th>Titel</th>
						<th>Status</th>
					</tr>
					{
						for $doc in $ed
							let $docUri := base-uri($doc)
							return
								<tr>
									<td>{$doc/tei:TEI/@n}</td>
									<td>{$docUri}</td>
									<td>{normalize-space($doc//tei:title[1])}</td>
									<td><a href="javascript:show('{$edoc}', '{$docUri}')">anzeigen</a></td>
								</tr>
					}
				</tbody>
			</table>
		</div>
};

declare function local:getFileStat($ed, $file) {
	let $doc := doc($file)
	let $subColl := local:substring-before-last($file, '/')
	let $resource := local:substring-after-last($file, '/')
	let $metaFile := doc($wdb:edocBaseDB || '/' || $ed || '/wdbmeta.xml')
	let $relativePath := substring-after($file, $ed||'/')
	let $entry := $metaFile//meta:file[@path = $relativePath]
	let $uuid := util:uuid($doc)
	let $date := xmldb:last-modified($subColl, $resource)
	
	return
		<div id="data">
			<div style="width: 100%;">
				<h3>{$file}</h3>
				<hr />
				<table style="width: 100%;">
					<tbody>
						{
							for $title in $doc//tei:teiHeader/tei:title
								return <tr><td>Titel</td><td>{$title}</td></tr>
						}
						<tr>
							<td>UUID v3</td>
							<td>{$uuid}</td>
						</tr>
						<tr>
							<td>Timestamp</td>
							<td>{$date}</td>
						</tr>
						<tr>
							<td>Eintrag in <i>wdbmeta.xml</i> vorhanden?</td>
							{
								if ($entry/@path != '')
									then <td>OK</td>
									else <td>fehlt <a href="javascript:job('add', '{$file}')">hinzufügen</a></td>
							}
						</tr>
						<tr>
							<td>UUID in wdbMeta</td>
							{if ($entry/@uuid = $uuid)
										then <td>OK: {$uuid}</td>
										else <td>{normalize-space($entry/@uuid)}<br/><a href="javascript:job('uuid', '{$file}')">UUID aktualisieren</a></td>
							}
						</tr>
						<tr>
							<td>Timestamp in wdbMeta</td>
							{if ($entry/@date = $date)
										then <td>OK: {$date}</td>
										else <td>{normalize-space($entry/@date)}<br/><a href="javascript:job('date', '{$file}')">Timestamp aktualisieren</a></td>
							}
						</tr>
					</tbody>
				</table>
				{
					if ($role = 'workbench') then
						<table>
							<tbody>
								<tr>
									<td>Peer Server</td>
									<td>{$wdb:peer}</td>
								</tr>
							</tbody>
						</table>
					else ()
				}
			</div>
		</div>
};

declare function local:substring-before-last($s, $c) {
	string-join(tokenize(normalize-space($s), $c)[not(position() = last())], $c)
};

declare function local:substring-after-last($s, $c) {
	tokenize(normalize-space($s), $c)[last()]
};