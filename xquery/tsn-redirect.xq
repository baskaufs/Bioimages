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

declare function local:get-taxon-name-clean
($name as element()+)
{
  for $nameRecord in $name
  return if ($nameRecord/dwc_taxonRank/text() = "species")
         then ($nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text())
         else 
           if ($nameRecord/dwc_taxonRank/text() = "genus")
           then ($nameRecord/dwc_genus/text()||" sp.")
           else 
             if ($nameRecord/dwc_taxonRank/text() = "subspecies")
             then ($nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" ssp. "||$nameRecord/dwc_infraspecificEpithet/text())
             else
               if ($nameRecord/dwc_taxonRank/text() = "variety")
               then ($nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" var. "||$nameRecord/dwc_infraspecificEpithet/text())
               else ()
};

let $localFilesFolderUnix := "c:/github/bioimages"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "j:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $lastPublishedDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/last-published.xml'))
let $lastPublished := $lastPublishedDoc/body/dcterms:modified/text()
(: use this if last published doc doesn't exist:  
let $lastPublished := '2015-10-14T11:04:06-05:00'
:)

for $nameRecord in $xmlNames/csv/record
where xs:dateTime($nameRecord/dcterms_modified/text()) > xs:dateTime($lastPublished)

let $taxonNameClean := local:get-taxon-name-clean($nameRecord)
let $tsnID := $nameRecord/dcterms_identifier/text()

let $fileName := concat($tsnID,".htm")
let $namespace := "tsn"
let $filePath := concat($rootPath,"\",$namespace,"\", $fileName)

return (file:create-dir(concat($rootPath,"\",$namespace)), file:write($filePath,
<html>
  <head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <title>Stable URL for {$taxonNameClean}</title>

  </head>
  <body>
      Loading database-based page.
      <script type="text/javascript">
      window.location.replace("../metadata.htm?/{$tsnID}/metadata/sp");
      </script>
  </body>
</html>

))
