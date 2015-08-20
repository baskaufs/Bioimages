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



let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

(:let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]:)
let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms-small.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

(:let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]:)
let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations-small.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|" })

(:let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]:)
let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names-small.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true(),'separator' : "|" })

(:let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]:)
let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images-small.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true(),'separator' : "|" })

let $textTourButtons := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/tour-buttons.csv'/>)[2]
let $xmlTourButtons := csv:parse($textTourButtons, map { 'header' : true(),'separator' : "|" })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true(),'separator' : "|" })

let $lastPublishedDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/last-published.xml'))
let $lastPublished := $lastPublishedDoc/body/dcterms:modified/text()

let $organismsToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/organisms-to-write.txt'))
let $xmlOrganismsToWrite := csv:parse($organismsToWriteDoc, map { 'header' : false() })

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

(:
*********** Main query *********
:)

return (
(:     file:write(concat($rootPath,"\list\metadata-tax.xml"),:)
<mb:request xsi:schemaLocation="http://www.morphbank.net/mbsvc3/ http://www.morphbank.net/schema/mbsvc3.xsd" xmlns:dwc="http://rs.tdwg.org/dwc/dwcore/" xmlns:mb="http://www.morphbank.net/mbsvc3/" xmlns:dwcg="http://rs.tdwg.org/dwc/geospatial/" xmlns:dwce="http://rs.tdwg.org/dwc/dwelement" xmlns:dwcc="http://rs.tdwg.org/dwc/curatorial/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <submitter>
    <userId>224687</userId>
    <groupId>224688</groupId>
  </submitter>
  <insert>
    <submitter>
      <userId>224687</userId>
      <groupId>224688</groupId>
    </submitter>
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
  </insert>
</mb:request>
               )
(:               ),

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
                                            order by $det/dwc_dateIdentified/text() descending
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

) :)