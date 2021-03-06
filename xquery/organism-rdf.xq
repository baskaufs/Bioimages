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

declare namespace functx = "http://www.functx.com";
declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;
 
 declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

(: Note: this function depends on EXPath Binary Module 1.0, which might not be implemented by all processors.  It works in BaseX :)
declare function local:flag-test($flag as xs:string, $test as xs:string) as xs:boolean
{
  let $binFlag := bin:from-octets(xs:int($flag)) (: This contains all of the set bits for a suppress flag :)
  let $binTest := bin:from-octets(xs:int($test)) (: This is the flag bit or bits to be tested :)
  return $binTest = bin:and($binFlag, $binTest)  (: perform a binary AND against the test bit mask and return TRUE if the masked flag equals the test bit or bits :)
};

declare function local:clean-suppress-flag($flag as xs:string?) as xs:string
{
  if (string-length($flag) = 0)
  then "0"
  else $flag
};

(:------------------------------------------------:)
let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "j:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|"})

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true(),'separator' : "|" })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true(),'separator' : "|" })

let $organismsToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/organisms-to-write.txt'))
let $xmlOrganismsToWrite := csv:parse($organismsToWriteDoc, map { 'header' : false() })

for $orgRecord in $xmlOrganisms/csv/record, $organismsToWrite in distinct-values($xmlOrganismsToWrite/csv/record/entry)
where $orgRecord/dcterms_identifier/text() = $organismsToWrite
let $fileName := local:substring-after-last($orgRecord/dcterms_identifier/text(),"/")
let $temp := substring-before($orgRecord/dcterms_identifier/text(),concat("/",$fileName))
let $namespace := local:substring-after-last($temp,"/")
let $filePath := concat($rootPath,"\", $namespace,"\", $fileName,".rdf")
return (file:create-dir(concat($rootPath,"\",$namespace)), file:write($filePath,
<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:dcterms="http://purl.org/dc/terms/"
xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
xmlns:dsw="http://purl.org/dsw/"
xmlns:xmp="http://ns.adobe.com/xap/1.0/"
xmlns:foaf="http://xmlns.com/foaf/0.1/"
xmlns:tc="http://rs.tdwg.org/ontology/voc/TaxonConcept#"
xmlns:txn="http://lod.taxonconcept.org/ontology/txn.owl#"
xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
xmlns:blocal="http://bioimages.vanderbilt.edu/rdf/local#"
>
      <rdf:Description rdf:about="{$orgRecord/dcterms_identifier/text()}">{
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
        
        (: If suppress field is empty, set the flag to "0" :)
        let $suppressFlag := local:clean-suppress-flag($depiction/suppress/text())
        
        (: If the suppress flag includes the 2's place bit, then use the part of the organismRemarks before the first period as the occurrence date instead of the date from the image metadata, e.g. for specimen photos :)
        let $occurrenceDate :=
            if (local:flag-test($suppressFlag,"2"))
            then substring-before($depiction/dwc_occurrenceRemarks/text(),'.')
            else substring($depiction/dcterms_created/text(),1,10)
        
        group by $occurrenceDate
        (: If the occurrence date includes a "/" character for a date range, use only first part for hash :)
        return (<dsw:hasOccurrence>
              <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||functx:substring-before-if-contains($occurrenceDate,"/")}'>{
                <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Occurrence"/>,
                <dsw:occurrenceOf rdf:resource='{$orgRecord/dcterms_identifier/text()}'/>,

                if ($depiction[1]/dwc_occurrenceRemarks/text() != "")
                then if (local:flag-test(local:clean-suppress-flag($depiction[1]/suppress/text()),"2"))
                     then
                     (
                     <dwc:occurrenceRemarks>{substring-after($depiction[1]/dwc_occurrenceRemarks/text(),'.')}</dwc:occurrenceRemarks>
                     )
                     else 
                     (
                     <dwc:occurrenceRemarks>{$depiction[1]/dwc_occurrenceRemarks/text()}</dwc:occurrenceRemarks>
                     )
                else (),
                
               for $agent in $xmlAgents/csv/record
               where $agent/dcterms_identifier/text()=$depiction[1]/photographerCode/text()
               return (<dwciri:recordedBy rdf:resource="{$agent/iri/text()}"/>,
               <dwc:recordedBy>{$agent/dc_contributor/text()}</dwc:recordedBy>)
               ,

                <dsw:atEvent>
                    <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||functx:substring-before-if-contains($occurrenceDate,"/")||"eve"}'>{
                      <rdf:type rdf:resource="http://rs.tdwg.org/dwc/terms/Event"/>,
                      
                      if (string-length($occurrenceDate) = 10)
                      then (<dwc:eventDate rdf:datatype="http://www.w3.org/2001/XMLSchema#date">{$occurrenceDate}</dwc:eventDate>)
                      else (
                           if (string-length($occurrenceDate) = 4)
                           then (<dwc:eventDate rdf:datatype="http://www.w3.org/2001/XMLSchema#gYear">{$occurrenceDate}</dwc:eventDate>)
                           else (<dwc:eventDate>{$occurrenceDate}</dwc:eventDate>)
                           ),
                      
                        <dsw:locatedAt>
                           <rdf:Description rdf:about='{$orgRecord/dcterms_identifier/text()||"#"||functx:substring-before-if-contains($occurrenceDate,"/")||"loc"}'>{
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
                             if ($orgRecord/geo_alt/text() != "")
                             then (
                               <geo:alt>{fn:round($orgRecord/geo_alt/text())}</geo:alt>,
                               <dwc:minimumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{fn:round($orgRecord/geo_alt/text())}</dwc:minimumElevationInMeters>,
                               <dwc:maximumElevationInMeters rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{fn:round($orgRecord/geo_alt/text())}</dwc:maximumElevationInMeters>
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
      <!--Identifications applied to the organism-->,
        for $detRecord in $xmlDeterminations/csv/record,
            $nameRecord in $xmlNames/csv/record,
            $sensuRecord in $xmlSensu/csv/record
        where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
        (: Note: the determinations must be saved in order of descending dateIdentified in order for them to be displayed correctly on the pages that display dynamically by Javascript :)
        order by $detRecord/dwc_dateIdentified/text() descending
        return <dsw:hasIdentification><rdf:Description rdf:about="{$orgRecord/dcterms_identifier/text()||"#"||$detRecord/dwc_dateIdentified/text()||$detRecord/identifiedBy/text()}">{
                  if (lower-case($nameRecord/dwc_taxonRank/text()) = "species")
                  then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                  else 
                    if (lower-case($nameRecord/dwc_taxonRank/text()) = "genus")
                    then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                    else 
                      if (lower-case($nameRecord/dwc_taxonRank/text()) = "subspecies")
                      then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" ssp. "||$nameRecord/dwc_infraspecificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                      else
                        if (lower-case($nameRecord/dwc_taxonRank/text()) = "variety")
                        then <dcterms:description xml:lang="en">Determination of {$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()||" var. "||$nameRecord/dwc_infraspecificEpithet/text()||" sec. "||$sensuRecord/tcsSignature/text()}</dcterms:description>
                        else ()
                  ,
                  <rdf:type rdf:resource ="http://rs.tdwg.org/dwc/terms/Identification" />,
                  <dsw:identifies rdf:resource='{$orgRecord/dcterms_identifier/text()}'/>,
                  if ($detRecord/dwc_identificationRemarks/text() != "")
                  then <dwc:identificationRemarks>{$detRecord/dwc_identificationRemarks/text()}</dwc:identificationRemarks>
                  else (),
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
                  
                  <dwc:taxonRank>{lower-case($nameRecord/dwc_taxonRank/text())}</dwc:taxonRank>,
                  <dwc:vernacularName xml:lang="en">{$nameRecord/dwc_vernacularName/text()}</dwc:vernacularName>,
                  <dwc:scientificNameAuthorship>{$nameRecord/dwc_scientificNameAuthorship/text()}</dwc:scientificNameAuthorship>,
                  <dwc:scientificName>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</dwc:scientificName>,
                  if ($sensuRecord/dcterms_identifier/text() != "nominal")
                  then <dwc:nameAccordingTo>{$sensuRecord/dc_creator/text()||", "||$sensuRecord/dcterms_created/text()||". "||$sensuRecord/dcterms_title/text()||". "||$sensuRecord/dc_publisher/text()||"."}</dwc:nameAccordingTo>
                  else (),
                  <blocal:secundumSignature>{$sensuRecord/tcsSignature/text()}</blocal:secundumSignature>,
                  
                  if ($sensuRecord/dcterms_identifier/text() = "nominal")
                  then
                        if (string-length($nameRecord/ubioID/text()) = 0)
                        then ()
                        else
                          <dwciri:toTaxon><dwc:Taxon>{
                              <tc:hasName rdf:resource="urn:lsid:ubio.org:namebank:{$nameRecord/ubioID/text()}"/>
                          }</dwc:Taxon></dwciri:toTaxon>
                  else
                        if (string-length($nameRecord/ubioID/text()) = 0)
                        then
                          <dwciri:toTaxon><dwc:Taxon>{
                               <tc:accordingTo rdf:resource="{$sensuRecord/iri/text()}" />
                          }</dwc:Taxon></dwciri:toTaxon>
                        else 
                          <dwciri:toTaxon><dwc:Taxon>{
                              <tc:hasName rdf:resource="urn:lsid:ubio.org:namebank:{$nameRecord/ubioID/text()}"/>,
                              <tc:accordingTo rdf:resource="{$sensuRecord/iri/text()}" />
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
              
              
      }</rdf:Description>
       <rdf:Description rdf:about="{$orgRecord/dcterms_identifier/text()||".rdf"}">{
            <rdf:type rdf:resource ="http://xmlns.com/foaf/0.1/Document" />,
            <dc:format>application/rdf+xml</dc:format>,
            <dcterms:identifier>{$orgRecord/dcterms_identifier/text()||".rdf"}</dcterms:identifier>,
            <dcterms:description xml:lang="en">RDF formatted description of the organism {$orgRecord/dcterms_identifier/text()}</dcterms:description>,
            <dc:creator>bioimages.vanderbilt.edu</dc:creator>,
            <dcterms:creator rdf:resource="http://biocol.org/urn:lsid:biocol.org:col:35115"/>,
            <dc:language>en</dc:language>,
            <dcterms:language rdf:resource="http://id.loc.gov/vocabulary/iso639-2/eng"/>,
            <dcterms:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">{fn:current-dateTime()}</dcterms:modified>,
            <dcterms:references rdf:resource="{$orgRecord/dcterms_identifier/text()}"/>,
            <foaf:primaryTopic rdf:resource="{$orgRecord/dcterms_identifier/text()}"/>
       }</rdf:Description></rdf:RDF>
))