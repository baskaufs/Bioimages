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
TODO: subtract one from the local variable so that it starts incrementing from zero
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

let $userId := "224687"
let $groupId := "224688"

(:
*********** Main query *********
:)
return (
(:     file:write(concat($rootPath,"\list\metadata-tax.xml"),:)
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
    
for $orgRecord at $position in $xmlOrganisms/csv/record, $organismsToWrite in distinct-values($xmlOrganismsToWrite/csv/record/entry)
where $orgRecord/dcterms_identifier/text() = $organismsToWrite
return (
      (:<rdf:Description rdf:about="{$orgRecord/dcterms_identifier/text()}">{:)
      <object type="specimen">{
        <sourceId>
        <local>{"local:"||$position}</local>
        <external>{$orgRecord/dcterms_identifier/text()}</external>
        </sourceId>,
        <owner>
        <userId>{$userId}</userId>
        <groupId>{$groupId}</groupId>
        </owner>,
        <dateToPublish>{fn:adjust-date-to-timezone(current-date(), ())}</dateToPublish>,
        <objectTypeId>Specimen</objectTypeId>,
        <externalRef type="5">{
          <label>{"Organism metadata for GUID "||$orgRecord/dcterms_identifier/text()}</label>,
          <urlData>{$orgRecord/dcterms_identifier/text()}</urlData>
        }</externalRef>,
        <determination>
          
        for $detRecord in $xmlDeterminations/csv/record,
            $nameRecord in $xmlNames/csv/record,
            $sensuRecord in $xmlSensu/csv/record
        where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
        (: Note: the determinations must be saved in order of descending dateIdentified in order for them to be displayed correctly on the pages that display dynamically by Javascript :)
        order by $detRecord/dwc_dateIdentified/text() descending
        return <dsw:hasIdentification><rdf:Description rdf:about="{$orgRecord/dcterms_identifier/text()||"#"||$detRecord/dwc_dateIdentified/text()||$detRecord/identifiedBy/text()}">{
                  if ($nameRecord/dwc_taxonRank/text() = "species")
                  then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                  else 
                    if ($nameRecord/dwc_taxonRank/text() = "genus")
                    then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                    else 
                      if ($nameRecord/dwc_taxonRank/text() = "subspecies")
                      then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" ssp. "||$nameRecord/dwc_infraspecificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                      else
                        if ($nameRecord/dwc_taxonRank/text() = "variety")
                        then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" var. "||$nameRecord/dwc_infraspecificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                        else ()
                  ,
                  <rdf:type rdf:resource ="http://rs.tdwg.org/dwc/terms/Identification" />,
                  if ($detRecord/dwc_identificationRemarks/text() != "")
                  then <dwc:identificationRemarks>{$detRecord/dwc_identificationRemarks/text()}</dwc:identificationRemarks>
                  else (),
                  <external>{"ITIS:"||$detRecord/tsnID/text()}</external>,
                  <blocal:itisTsn>{$detRecord/tsnID/text()}</blocal:itisTsn>,
                  <dwc:kingdom>{$nameRecord/dwc_kingdom/text()}</dwc:kingdom>,
                  <dwc:class>{$nameRecord/dwc_class/text()}</dwc:class>,
                  
                  if ($nameRecord/dwc_order/text() != "")
                  then <dwc:order>{$nameRecord/dwc_order/text()}</dwc:order>
                  else (),
                  
                  if ($nameRecord/dwc_family/text() != "")
                  then <dwc:family>{$nameRecord/dwc_family/text()}</dwc:family>
                  else (),
                  
                  if ($nameRecord/dwc_genus/text() != "")
                  then <dwc:genus>{$nameRecord/dwc_genus/text()}</dwc:genus>
                  else (),
                  
                  if ($nameRecord/dwc_specificEpithet/text() != "")
                  then <dwc:specificEpithet>{$nameRecord/dwc_specificEpithet/text()}</dwc:specificEpithet>
                  else (),
                  
                  if ($nameRecord/dwc_infraspecificEpithet/text() != "")
                  then <dwc:infraspecificEpithet>{$nameRecord/dwc_infraspecificEpithet/text()}</dwc:infraspecificEpithet>
                  else (),
                  
                  <dwc:taxonRank>{$nameRecord/dwc_taxonRank/text()}</dwc:taxonRank>,
                  <dwc:vernacularName xml:lang="en">{$nameRecord/dwc_vernacularName/text()}</dwc:vernacularName>,
                  <dwc:scientificNameAuthorship>{$nameRecord/dwc_scientificNameAuthorship/text()}</dwc:scientificNameAuthorship>,
                  <dwc:scientificName>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</dwc:scientificName>,
                  if ($sensuRecord/dcterms_identifier/text() != "nominal")
                  then <dwc:nameAccordingTo>{$sensuRecord/dc_creator/text()||", "||$sensuRecord/dcterms_created/text()||". "||$sensuRecord/dc_publisher/text()||"."}</dwc:nameAccordingTo>
                  else (),
                  <blocal:secundumSignature>{$sensuRecord/tcsSignature/text()}</blocal:secundumSignature>,
                  <dwciri:toTaxon><dwc:Taxon>{
                        if ($sensuRecord/dcterms_identifier/text() != "nominal")
                        then <tc:accordingTo rdf:resource="{$sensuRecord/iri/text()}" />
                        else (),
                       <tc:hasName rdf:resource="urn:lsid:ubio.org:namebank:{$nameRecord/ubioID/text()}"/>
                  }</dwc:Taxon></dwciri:toTaxon>,
                  if (string-length($detRecord/dwc_dateIdentified/text()) = 10)
                  then (<dwc:dateIdentified rdf:datatype="http://www.w3.org/2001/XMLSchema#date">{$detRecord/dwc_dateIdentified/text()}</dwc:dateIdentified>)
                  else (
                       if (string-length($detRecord/dwc_dateIdentified/text()) = 4)
                       then (<dwc:dateIdentified rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">{$detRecord/dwc_dateIdentified/text()}</dwc:dateIdentified>)
                       else (<dwc:dateIdentified>{$detRecord/dwc_dateIdentified/text()}</dwc:dateIdentified>)
                       ),
                  for $agentRecord in $xmlAgents/csv/record
                  where $agentRecord/dcterms_identifier=$detRecord/identifiedBy
                  return (
                         <dwc:identifiedBy>{$agentRecord/dc_contributor/text()}</dwc:identifiedBy>,
                         <dwciri:identifiedBy rdf:resource ="{$agentRecord/iri/text()}"/>
                         )
              }</rdf:Description></dsw:hasIdentification>,
        </determination>,

        <standardImage>
          <external>http://bioimages.vanderbilt.edu/baskauf/52142</external>
        </standardImage>,
        <dwc:BasisOfRecord>Living organism</dwc:BasisOfRecord>,
        <dwc:Collector>Steven J. Baskauf</dwc:Collector>,
        <dwc:EarliestDateCollected>2006-05-29T11:18:02</dwc:EarliestDateCollected>,
        <dwc:LatestDateCollected>2006-05-29T11:22:10</dwc:LatestDateCollected>,
        <dwcg:DecimalLatitude> 36.385749</dwcg:DecimalLatitude>,
        <dwcg:DecimalLongitude>-87.006269</dwcg:DecimalLongitude>,
        <dwc:StateProvince>Tennessee</dwc:StateProvince>,
        <dwc:County>Cheatham</dwc:County>,
        <dwc:Locality>Pinnacle Rd., Pleasant View</dwc:Locality>,
        
      <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Organism"/>,
      <rdf:type rdf:resource="http://purl.org/dc/terms/PhysicalResource"/>,
      if ($orgRecord/dwc_collectionCode/text() != "")
      then <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/LivingSpecimen"/>
      else (),
      <!--Basic information about the organism-->,
      <dcterms:identifier>{$orgRecord/dcterms_identifier/text()}</dcterms:identifier>,
      <dcterms:description xml:lang="en">{"Description of an organism having GUID: "||$orgRecord/dcterms_identifier/text()}</dcterms:description>,
      <dwc:organismScope>{$orgRecord/dwc_organismScope/text()}</dwc:organismScope>,
      if ($orgRecord/dwc_organismRemarks/text() != "")
      then <dwc:organismRemarks>{$orgRecord/dwc_organismRemarks/text()}</dwc:organismRemarks>
      else (),
      if ($orgRecord/dwc_organismName/text() != "")
      then <dwc:organismName>{$orgRecord/dwc_organismName/text()}</dwc:organismName>
      else (),
      <dwc:establishmentMeans>{$orgRecord/dwc_establishmentMeans/text()}</dwc:establishmentMeans>,
      if ($orgRecord/cameo/text() != "")
      then <blocal:cameo rdf:resource="{$orgRecord/cameo/text()}"/>
      else (),      
      if ($orgRecord/dwc_collectionCode/text() != "")
      then (
           for $agent in $xmlAgents/csv/record
           where $agent/dcterms_identifier=$orgRecord/dwc_collectionCode
           return <dwciri:inCollection rdf:resource="{$agent/iri/text()}"/>,
           <dwc:collectionCode>{$orgRecord/dwc_collectionCode/text()}</dwc:collectionCode>,
           <dwc:catalogNumber>{$orgRecord/dwc_catalogNumber/text()}</dwc:catalogNumber>
           )
      else (),
      <!--Relationships of the organism to other resources-->,
      <foaf:isPrimaryTopicOf rdf:resource="{$orgRecord/dcterms_identifier/text()||".rdf"}" />,
      <foaf:isPrimaryTopicOf rdf:resource="{$orgRecord/dcterms_identifier/text()||".htm"}" />,
        for $depiction in $xmlImages/csv/record
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
        return (
               <foaf:depiction rdf:resource="{$depiction/dcterms_identifier/text()}" />,
               <dsw:hasDerivative rdf:resource="{$depiction/dcterms_identifier/text()}" />
               ),
        <!--Occurrences documented for the organism-->,
        for $depiction in $xmlImages/csv/record
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
        let $occurrenceDate := substring($depiction/dcterms_created/text(),1,10)
        group by $occurrenceDate
        return (<dsw:hasOccurrence>
              <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||$occurrenceDate}'>{
                <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Occurrence"/>,
                
               for $agent in $xmlAgents/csv/record
               where $agent/dcterms_identifier/text()=$depiction[1]/photographerCode/text()
               return (<dwciri:recordedBy rdf:resource="{$agent/iri/text()}"/>,
               <dwc:recordedBy>{$agent/dc_contributor/text()}</dwc:recordedBy>)
               ,

                <dsw:atEvent>
                    <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||$occurrenceDate||"eve"}'>{
                      <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Event"/>,
                      
                      if (string-length($occurrenceDate) = 10)
                      then (<dwc:eventDate rdf:datatype="http://www.w3.org/2001/XMLSchema#date">{$occurrenceDate}</dwc:eventDate>)
                      else (
                           if (string-length($occurrenceDate) = 4)
                           then (<dwc:eventDate rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">{$occurrenceDate}</dwc:eventDate>)
                           else (<dwc:eventDate>{$occurrenceDate}</dwc:eventDate>)
                           ),
                      
                        <dsw:locatedAt>
                           <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||$occurrenceDate||"loc"}'>{
                             <rdf:type rdf:resource="http://purl.org/dc/terms/Location"/>,
                             if ($orgRecord/dwc_decimalLatitude/text() != "")
                             then (
                                 <geo:lat>{$orgRecord/dwc_decimalLatitude/text()}</geo:lat>,
                                 <dwc:decimalLatitude rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">{$orgRecord/dwc_decimalLatitude/text()}</dwc:decimalLatitude>,
                                 <geo:long>{$orgRecord/dwc_decimalLongitude/text()}</geo:long>,
                                 <dwc:decimalLongitude rdf:datatype="http://www.w3.org/2001/XMLSchema#decimal">{$orgRecord/dwc_decimalLongitude/text()}</dwc:decimalLongitude>,
                                 <dwc:coordinateUncertaintyInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$depiction[1]/dwc_coordinateUncertaintyInMeters/text()}</dwc:coordinateUncertaintyInMeters>,
                                 <dwc:geodeticDatum>{$depiction[1]/dwc_geodeticDatum/text()}</dwc:geodeticDatum>
                                  )
                             else (),
                             if ($orgRecord/geo_alt/text() != "-9999")
                             then (
                               <geo:alt>{$orgRecord/geo_alt/text()}</geo:alt>,
                               <dwc:minimumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$orgRecord/geo_alt/text()}</dwc:minimumElevationInMeters>,
                               <dwc:maximumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$orgRecord/geo_alt/text()}</dwc:maximumElevationInMeters>
                                  )
                             else (),
                             <dwc:locality>{$depiction[1]/dwc_locality/text()}</dwc:locality>,
                             <dwc:georeferenceRemarks>{$orgRecord/dwc_georeferenceRemarks/text()}</dwc:georeferenceRemarks>,
                             <dwc:continent>{$depiction[1]/dwc_continent/text()}</dwc:continent>,
                             <dwc:countryCode>{$depiction[1]/dwc_countryCode/text()}</dwc:countryCode>,
                             <dwc:stateProvince>{$depiction[1]/dwc_stateProvince/text()}</dwc:stateProvince>,
                             <dwc:county>{$depiction[1]/dwc_county/text()}</dwc:county>,
                             if ($depiction[1]/dwc_informationWithheld/text() != "")
                             then <dwc:informationWithheld>{$depiction[1]/dwc_informationWithheld/text()}</dwc:informationWithheld>
                             else (),
                             if ($depiction[1]/dwc_dataGeneralizations/text() != "")
                             then <dwc:dataGeneralizations>{$depiction[1]/dwc_dataGeneralizations/text()}</dwc:dataGeneralizations>
                             else (),
                             <dwciri:inDescribedPlace rdf:resource="{'http://sws.geonames.org/'||$depiction[1]/geonamesAdmin/text()||'/'}"/>,   
                             if ($depiction[1]/geonamesOther/text() != "")
                             then <dwciri:inDescribedPlace rdf:resource="{'http://sws.geonames.org/'||$depiction[1]/geonamesOther/text()||'/'}"/>
                             else ()
                           }</rdf:Description>
                        </dsw:locatedAt>
                    }</rdf:Description>
                </dsw:atEvent>,
                ($depiction/dcterms_identifier ! <dsw:hasEvidence rdf:resource="{.}"/>)
              }</rdf:Description>              
               </dsw:hasOccurrence>),
      if ($orgRecord/dwc_collectionCode/text() != "")
      then (
           <!-- The LivingSpecimen serves as evidence for the Occurrence documenting itself as an Organism -->,
           <dsw:hasOccurrence>
               <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#occ"}'>{
               <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Occurrence"/>,
               <dsw:hasEvidence rdf:resource='{$orgRecord/dcterms_identifier/text()}'/>,
               <!-- dwc:recordedBy and the Event establishing the collection record would go here -->
               }</rdf:Description>
           </dsw:hasOccurrence>
            )
      else (),
              
              for $linkRecord in $xmlLinks/csv/record
              where $linkRecord/subjectIRI/text()=$orgRecord/dcterms_identifier/text()
              return (
                     element {$linkRecord/property/text()} 
                         {
                         <rdf:Description rdf:about="{$linkRecord/objectIRI/text()}">
                           <rdf:type rdf:resource="{$linkRecord/objectType/text()}"/>
                           <dcterms:description xml:lang="en">{$linkRecord/objectDescription/text()}</dcterms:description>
                         </rdf:Description>
                         }
                     )
              
              
      }</object>
    )
  }</insert>
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