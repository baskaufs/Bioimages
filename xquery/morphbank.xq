xquery version "3.0";
declare namespace fn = "http://www.w3.org/2005/xpath-functions";

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
This has no contingency for organisms with no cameo (i.e. standardImage).  It creates an empty element for the external ID.  This should not be a problem for new images since they will all have a default cameo assigned.
This has no contingency for contributors that don't have Morphbank User IDs. It will generate an empty element
if an agent doesn't have one.
TODO: EarliestDateCollected and LatestDateCollected doesn't really work.
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



let $localFilesFolderUnix := "c:/test"

let $localFilesFolderPC := "c:\test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)
let $nothing := file:create-dir($localFilesFolderPC)

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

let $organismsToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/organisms-to-write.txt'))
let $xmlOrganismsToWrite := csv:parse($organismsToWriteDoc, map { 'header' : false() })

let $imagesToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/images-to-write.txt'))
let $xmlImagesToWrite := csv:parse($imagesToWriteDoc, map { 'header' : false() })

let $licenseDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/license.xml')
let $licenseCategory := $licenseDoc/license/category

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

let $userId := "224687"
let $groupId := "224688"

(:
*********** Main query *********
:)
return (
     file:write(concat($localFilesFolderPC,"\morphbank.xml"),
<mb:request xsi:schemaLocation="http://www.morphbank.net/mbsvc3/ http://www.morphbank.net/schema/mbsvc3.xsd" xmlns:dwc="http://rs.tdwg.org/dwc/dwcore/" xmlns:mb="http://www.morphbank.net/mbsvc3/" xmlns:dwcg="http://rs.tdwg.org/dwc/geospatial/" xmlns:dwce="http://rs.tdwg.org/dwc/dwelement" xmlns:dwcc="http://rs.tdwg.org/dwc/curatorial/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
  <submitter>
    <userId>{$userId}</userId>
    <groupId>{$groupId}</groupId>
  </submitter>
  <insert>{
    <submitter>
      <userId>{$userId}</userId>
      <groupId>{$groupId}</groupId>
    </submitter>,
    
for $orgRecord in $xmlOrganisms/csv/record, $organismsToWrite in distinct-values($xmlOrganismsToWrite/csv/record/entry)
where $orgRecord/dcterms_identifier/text() = $organismsToWrite
count $counter
return (
      <object type="specimen">{
        <sourceId>
          <local>{"local:"||xs:string(xs:integer($counter)-1)}</local>
          <external>{$orgRecord/dcterms_identifier/text()}</external>
        </sourceId>,
        <owner>{

        for $depiction in $xmlImages/csv/record
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
        let $orgGroup := $depiction/foaf_depicts
        group by $orgGroup
        return (
               for $agent in $xmlAgents/csv/record
               where $agent/dcterms_identifier/text()=$depiction[1]/owner/text()
               return (<userId>{$agent/morphbankUserID/text()}</userId>)
               ),
               
          <groupId>{$groupId}</groupId>
        }</owner>,
        <dateToPublish>{fn:adjust-date-to-timezone(current-date(), ())}</dateToPublish>,
        <objectTypeId>Specimen</objectTypeId>,
        <externalRef type="5">{
          <label>{"Organism metadata for GUID "||$orgRecord/dcterms_identifier/text()}</label>,
          <urlData>{$orgRecord/dcterms_identifier/text()}</urlData>
(: The schema has <externalId> as an element that can go here, but I don't know how it is used.
Perhaps it can replace the three elements above.  :)
        }</externalRef>,
        <determination>{         
          for $detRecord in $xmlDeterminations/csv/record
          where $detRecord/dsw_identified=$orgRecord/dcterms_identifier
          (: Note: the determinations must be saved in order of descending dateIdentified in order for the most recent determination to come first.  That is the only one that is actually sent to Morphbank. :)
          order by $detRecord/dwc_dateIdentified/text() descending
          return <external>{"ITIS:"||$detRecord[1]/tsnID/text()}</external>              
        }</determination>,
        <standardImage>
          <external>{$orgRecord/cameo/text()}</external>
        </standardImage>,
        <dwc:BasisOfRecord>Living organism</dwc:BasisOfRecord>,
        
        for $depiction in $xmlImages/csv/record
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
        let $occurrenceDate := substring($depiction/dcterms_created/text(),1,10)
        let $orgGroup := $depiction/foaf_depicts
        group by $orgGroup
        (:order by $occurrenceDate:)
        return (
               for $agent in $xmlAgents/csv/record
               where $agent/dcterms_identifier/text()=$depiction[1]/photographerCode/text()
               return (<dwc:Collector>{$agent/dc_contributor/text()}</dwc:Collector>),
               <dwc:EarliestDateCollected>{$occurrenceDate[1]}</dwc:EarliestDateCollected>,
               <dwc:LatestDateCollected>{$occurrenceDate[1]}</dwc:LatestDateCollected>,

               if ($orgRecord/dwc_decimalLatitude/text() != "")
               then (
                   <dwcg:DecimalLatitude>{$orgRecord/dwc_decimalLatitude/text()}</dwcg:DecimalLatitude>,
                   <dwcg:DecimalLongitude>{$orgRecord/dwc_decimalLongitude/text()}</dwcg:DecimalLongitude>
                    )
               else (),
               
               if ($orgRecord/geo_alt/text() != "")
               then (
                 <dwc:MinimumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$orgRecord/geo_alt/text()}</dwc:MinimumElevationInMeters>,
                 <dwc:MaximumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$orgRecord/geo_alt/text()}</dwc:MaximumElevationInMeters>
                    )
               else (),
               
               <dwc:StateProvince>{$depiction[1]/dwc_stateProvince/text()}</dwc:StateProvince>,
               <dwc:County>{$depiction[1]/dwc_county/text()}</dwc:County>,
               <dwc:Locality>{$depiction[1]/dwc_locality/text()}</dwc:Locality>
               )      
      }</object>
    ),
    
let $nOrganisms := count(distinct-values($xmlOrganismsToWrite/csv/record))-1    
for $imgRecord at $position in $xmlImages//record, $imagesToWrite in distinct-values($xmlImagesToWrite//record/entry)
where $imgRecord/dcterms_identifier/text() = $imagesToWrite
count $counter
return (
      <object type="image">{
        <sourceId>
          <local>{"local:"||xs:string(xs:integer($counter)+$nOrganisms)}</local>
          <external>{$imgRecord/dcterms_identifier/text()}</external>
        </sourceId>,

        <owner>{
           for $agent in $xmlAgents/csv/record
           where $agent/dcterms_identifier/text()=$imgRecord/owner/text()
           return (<userId>{$agent/morphbankUserID/text()}</userId>),
          <groupId>{$groupId}</groupId>
        }</owner>,

        <dateToPublish>{fn:adjust-date-to-timezone(current-date(), ())}</dateToPublish>,
        <objectTypeId>Image</objectTypeId>,
        <externalRef type="5">{
          <label>{"Image metadata for GUID "||$imgRecord/dcterms_identifier/text()}</label>,
          <urlData>{$imgRecord/dcterms_identifier/text()}</urlData>
        }</externalRef>,
       <imageType>jpg</imageType>,
       <copyrightText>{$imgRecord/dc_rights/text()}</copyrightText>,
       <originalFileName>{$imgRecord/fileName/text()}</originalFileName>,       
       <creativeCommons>&lt;a href="{$licenseCategory[@id=$imgRecord/usageTermsIndex/text()]/IRI/text()}" rel="license"&gt; &lt;img src="{$licenseCategory[@id=$imgRecord/usageTermsIndex/text()]/thumb/text()}" style="border-width: 0pt;" alt="Creative Commons License"/&gt; &lt;/a&gt;</creativeCommons>,
       
        for $agent in $xmlAgents//record
        where $agent/dcterms_identifier=$imgRecord/photographerCode
        return (
              <photographer>{$agent/dc_contributor/text()}</photographer>
              ),

      <specimen>
      <external>{$imgRecord/foaf_depicts/text()}</external>
      </specimen>,
      <view>
      <morphbank>{$viewCategory/stdview[@id=substring($imgRecord/view/text(),2)]/text()}</morphbank>
      </view>
      
      }</object>    
      )


  }</insert>
</mb:request>
               )
)