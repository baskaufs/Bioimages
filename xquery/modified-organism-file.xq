xquery version "3.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace dwc="http://rs.tdwg.org/dwc/terms/";
declare namespace dwciri="http://rs.tdwg.org/dwc/iri/";
declare namespace dsw="http://purl.org/dsw/";
declare namespace xmp="http://ns.adobe.com/xap/1.0/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace tc="http://rs.tdwg.org/ontology/voc/TaxonConcept#";
declare namespace txn="http://lod.taxonconcept.org/ontology/txn.owl#";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace blocal="http://bioimages.vanderbilt.edu/rdf/local#";

declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

let $localFilesFolderUnix := "c:/test"
let $localFilesFolderPC := "c:\test"

(: Create local files folder if it doesn't already exist. :)
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($localFilesFolderPC)

(: Uses http:send-request to fetch CSV files from GitHub :)
(: BaseX 8.0 requires 'map' keyword) before key/value maps :)
(: Older versions of BaseX may not have this requirement :)

(:let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]:)
let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms-small.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true() })
(: When we implement Ken's output with pipe ("|") separators, the parse function will have to change to this:
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })
:)

(:let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]:)
let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations-small.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true() })

(:let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]:)
let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names-small.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true() })

(:let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]:)
let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu-small.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true() })

(:let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]:)
let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images-small.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true() })

(:let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]:)
let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents-small.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true() })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true() })

(:
!!!!!!!!! Needs to error trap condition where last published doc doesn't exist, i.e. new implementation !!!!!!
:)

let $lastPublishedDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/last-published.xml'))
let $lastPublished := $lastPublishedDoc/body/dcterms:modified/text()
(: use this if last published doc doesn't exist:  
let $lastPublished := '2000-01-01T00:00:00-00:00'
:)
return (file:write(concat($localFilesFolderPC,"\organisms-to-write.txt"),
        for $orgRecord in $xmlOrganisms/csv/record, 
            $detRecord in $xmlDeterminations/csv/record, 
            $imgRecord in $xmlImages/csv/record
        let $chkOrg := xs:dateTime($orgRecord/dcterms_modified/text()) > xs:dateTime($lastPublished)
        let $chkDet := xs:dateTime($detRecord/dcterms_modified/text()) > xs:dateTime($lastPublished)
        let $chkImg := xs:dateTime($imgRecord/dcterms_modified/text()) > xs:dateTime($lastPublished)
        
        where ($chkOrg or $chkDet or $chkImg) 
           and $detRecord/dsw_identified/text()=$orgRecord/dcterms_identifier/text() 
           and $orgRecord/dcterms_identifier/text()=$imgRecord/foaf_depicts/text()
        return ($orgRecord/dcterms_identifier/text(),"&#10;")
))

