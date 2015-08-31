xquery version "3.0";
declare namespace xsd="http://www.w3.org/2001/XMLSchema";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace dwc="http://rs.tdwg.org/dwc/dwcore/";
declare namespace adw="http://animaldiversity.ummz.umich.edu/morphology/";
declare namespace xsi="http://www.w3.org/2001/XMLSchema-instance";

declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dwciri="http://rs.tdwg.org/dwc/iri/";
declare namespace dsw="http://purl.org/dsw/";
declare namespace xmp="http://ns.adobe.com/xap/1.0/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace tc="http://rs.tdwg.org/ontology/voc/TaxonConcept#";
declare namespace txn="http://lod.taxonconcept.org/ontology/txn.owl#";
declare namespace blocal="http://bioimages.vanderbilt.edu/rdf/local#";

(:
*********** Functions *********
:)
declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

declare function local:generate-name($name)
{
 if ($name/dwc_taxonRank/text() = "species")
 then ($name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text())
 else 
   if ($name/dwc_taxonRank/text() = "genus")
   then ($name/dwc_genus/text()||" sp.")
   else 
     if ($name/dwc_taxonRank/text() = "subspecies")
     then ($name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text()||" ssp. "||$name/dwc_infraspecificEpithet/text())
     else
       if ($name/dwc_taxonRank/text() = "variety")
       then ($name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text()||" var. "||$name/dwc_infraspecificEpithet/text())
       else ()
};

declare function local:county-units
($state, $countryCode) as xs:string
{
if ($state != "")
then  
  if ($countryCode = "US" or $countryCode = "CA")
  then 
    if ($state = "Louisiana")
    then " Parish"
    else if ($state="Alaska")
          then " Borough"
          else " County"
  else
    ""
else
""
};

declare function local:generate-taxon-elements
($domain, $xmlNames, $xmlDeterminations, $xmlOrganisms, $xmlImages, $xmlAgents, $licenseCategory)
{
for $name in $xmlNames//record
where $name/dwc_specificEpithet/text() != "" (: exclude names at higher taxonomic levels than species :)
return (
        <taxon>{

          if (substring($name/dcterms_identifier/text(), 1, 1) != "x") (:  If no TSN exists, a placeholder value beginning with the character x followed by a number is used instead :)
          then <dc:identifier>{"urn:lsid:itis.gov:itis_tsn:"||$name/dcterms_identifier/text()}</dc:identifier>
          else <dc:identifier>{$name/dcterms_identifier/text()}</dc:identifier> (: use the placeholder if not a TSN :)
          ,
          <dwc:ScientificName>{local:generate-name($name)}</dwc:ScientificName>,

        for $detRecord in $xmlDeterminations/csv/record,
            $orgRecord in $xmlOrganisms/csv/record,
            $imgRecord in $xmlImages/csv/record
            
        let $fileName := local:substring-after-last($imgRecord/dcterms_identifier/text(),"/")
        let $temp1 := substring-before($imgRecord/dcterms_identifier/text(),concat("/",$fileName))
        let $namespace := local:substring-after-last($temp1,"/")
        
        (: images are screened for submission by having a quality rating of greater or equal to 4 :)
        where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $name/dcterms_identifier=$detRecord/tsnID and $imgRecord/foaf_depicts=$orgRecord/dcterms_identifier and fn:number($imgRecord/xmp_Rating/text())>=4
        return (
<dataObject>{
  
    <dc:identifier>{$imgRecord/dcterms_identifier/text()}</dc:identifier>,
    <dataType>http://purl.org/dc/dcmitype/StillImage</dataType>,
    (: Note: this assumes all images are jpegs.  That is currently true, but isn't really a requirement. :)
    <mimeType>image/jpeg</mimeType>,
    
    for $agent in $xmlAgents/csv/record
               where $agent/dcterms_identifier/text()=$imgRecord/photographerCode/text()
               return (<agent role="photographer">{$agent/dc_contributor/text()}</agent>
                      ),
                      
    <dcterms:created>{$imgRecord/dcterms_created/text()}</dcterms:created>,
    <dc:title xml:lang="en">{$imgRecord/dcterms_title/text()}</dc:title>,
    <license>{$licenseCategory[@id=$imgRecord/usageTermsIndex/text()]/IRI/text()}</license>,
    <dc:rights>{$imgRecord/dc_rights/text()}</dc:rights>,
    <dcterms:rightsHolder>{$imgRecord/xmpRights_Owner/text()}</dcterms:rightsHolder>,
    <dc:source>{$imgRecord/dcterms_identifier/text()}</dc:source>,
    
    <mediaURL>{$domain}/gq/{$namespace}/g{$imgRecord/fileName/text()}</mediaURL>,
    <location xml:lang="en">{$imgRecord/dwc_locality/text()||", "||$imgRecord/dwc_county/text()||local:county-units($imgRecord/dwc_stateProvince/text(), $imgRecord/dwc_countryCode/text() )||", "||$imgRecord/dwc_stateProvince/text()||", "||$imgRecord/dwc_countryCode/text()}</location>,
    <geo:Point>{
    <geo:lat>{$imgRecord/dwc_decimalLatitude/text()}</geo:lat>,
    <geo:long>{$imgRecord/dwc_decimalLongitude/text()}</geo:long>
    }</geo:Point>,
    <reference url="{$imgRecord/dcterms_identifier/text()}">Image metadata at Bioimages (http://bioimages.vanderbilt.edu/)</reference>
}</dataObject>
                )
           }</taxon>
       ) 
};

let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

let $domain := "http://bioimages.vanderbilt.edu"

let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]
(:let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms-small.csv'/>)[2]:)
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]
(:let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations-small.csv'/>)[2]:)
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|" })

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
(:let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names-small.csv'/>)[2]:)
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
(:let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images-small.csv'/>)[2]:)
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true(),'separator' : "|" })

let $textTourButtons := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/tour-buttons.csv'/>)[2]
let $xmlTourButtons := csv:parse($textTourButtons, map { 'header' : true(),'separator' : "|" })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true(),'separator' : "|" })

let $lastPublishedDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/last-published.xml'))
let $lastPublished := $lastPublishedDoc/body/dcterms:modified/text()

let $licenseDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/license.xml')
let $licenseCategory := $licenseDoc/license/category

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

(:
*********** Main query *********
:)

return (
     file:write(concat($rootPath,"\eol-harvest.xml"),

(: xmlns="http://www.eol.org/transfer/content/0.3"  Inluding this namespace declaration breaks the query when the
taxon elements are generated directly below, but not when they are generated in a function :)
<response
xmlns="http://www.eol.org/transfer/content/0.3"
xmlns:xsd="http://www.w3.org/2001/XMLSchema"
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:dcterms="http://purl.org/dc/terms/"
xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
xmlns:dwc="http://rs.tdwg.org/dwc/dwcore/"
xmlns:adw="http://animaldiversity.ummz.umich.edu/morphology/"
xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
xsi:schemaLocation="http://www.eol.org/transfer/content/0.3 http://services.eol.org/schema/content_0_3.xsd"
>{
let $tempTaxaSequence := local:generate-taxon-elements($domain, $xmlNames, $xmlDeterminations, $xmlOrganisms, $xmlImages, $xmlAgents, $licenseCategory)
(: return taxon element only if it contains at least one image data object :)
for $taxon in $tempTaxaSequence
where fn:exists($taxon/dataObject)
return $taxon
}</response>
     )

 ) 