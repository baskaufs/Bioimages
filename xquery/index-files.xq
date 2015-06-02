xquery version "3.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace sitemap="http://www.sitemaps.org/schemas/sitemap/0.9";
(:
TODO: 
Discover Live harvest file
EOL harvest file
Morphbank push file
GBIF DwC-A files
Files for list management.  Note: it should be possible to generate these files using a hack of the existing code since the output is basically the same except that there must be a match with the TSN in the list's list of taxa.
NCBI index file
:)

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

(:
*********** Set up local folders *********
:)

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)
let $nothing := file:create-dir(concat($rootPath,"\list"))

(:
*********** Get data from GitHub *********
:)
let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|" })

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

(:
*********** Main query *********
:)

return (
     file:write(concat($rootPath,"\list\metadata-tax.xml"),
                  <DarwinRecordSet>{
                        for $name in $xmlNames//record,
                            $det in $xmlDeterminations//record,
                            $org in $xmlOrganisms//record
                        where $det/dsw_identified/text()=$org/dcterms_identifier/text() and $name/dcterms_identifier/text()=$det/tsnID/text()
                        order by $name/dcterms_identifier
                        let $tsn := $name/dcterms_identifier/text()
                        group by $tsn
                        return (
                                <taxon>
                                  <tsn>{$name/dcterms_identifier/text()}</tsn>
                                  <class>{$name/dwc_class/text()}</class>
                                  <order>{$name/dwc_order/text()}</order>
                                  <family>{$name/dwc_family/text()}</family>
                                  <genus>{$name/dwc_genus/text()}</genus>
                                  <species>{$name/dwc_specificEpithet/text()}</species>
                                  <rank>{$name/dwc_taxonRank/text()}</rank>
                                  <ife>{$name/dwc_infraspecificEpithet/text()}</ife>
                                  <author>{$name/dwc_scientificNameAuthorship/text()}</author>
                                  <vernac>{$name/dwc_vernacularName/text()}</vernac>
                                </taxon>
                               )
                         
                  }</DarwinRecordSet>
               ),

      file:write(concat($rootPath,"\list\metadata-ind.xml"),
                <DarwinRecordSet>{
                        for $org in $xmlOrganisms//record
                        order by $org/dcterms_identifier
                        let $orgID := $org/dcterms_identifier/text()
                        group by $orgID
                        return (
                                <Individual>{
                                    let $localID := local:substring-after-last($orgID,"/")
                                    let $temp1 := substring-before($orgID,concat("/",$localID))
                                    let $namespace := local:substring-after-last($temp1,"/")
                                    return (
                                            <cc>{$namespace}</cc>,
                                            <cn>{$localID}</cn>,
                                            <em>{$org/dwc_establishmentMeans/text()}</em>,
                                            for $det in $xmlDeterminations//record
                                            where $det/dsw_identified/text()=$org/dcterms_identifier/text()
                                            return (<taxonID>{$det/tsnID/text()}</taxonID>),
                                            for $img in $xmlImages//record
                                            where $img/foaf_depicts/text()=$org/dcterms_identifier/text()
                                            return (
                                                <dO>{
                                                    let $imgID := $img/dcterms_identifier/text()
                                                    let $imgLocalID := local:substring-after-last($imgID,"/")
                                                    let $temp2 := substring-before($imgID,concat("/",$imgLocalID))
                                                    let $imgNamespace := local:substring-after-last($temp2,"/")
                                                    return (
                                                      <n>{$imgNamespace}</n>,
                                                      <i>{$imgLocalID}</i>,
                                                      <f>{$img/fileName/text()}</f>,
                                                      <v>{substring($img/view/text(),2)}</v>
                                                          )
                                                }</dO>
                                                   )
                                           )
                               }</Individual>
                               )       
                }</DarwinRecordSet>
            ),

      file:write(concat($rootPath,"\status.xml"),
                <root>{
                   <individuals>{count($xmlOrganisms//record)}</individuals>,
                   <images>{count($xmlImages//record)}</images>,
                   <taxonNames>{count($xmlNames//record)}</taxonNames>,
                   <lastModified>{fn:current-dateTime()}</lastModified>
                }</root>
            )

)