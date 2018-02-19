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

(: TODO This does not do anything with links.csv :)

declare namespace functx = "http://www.functx.com";
declare function functx:substring-before-if-contains
  ( $arg as xs:string? ,
    $delim as xs:string )  as xs:string? {

   if (contains($arg,$delim))
   then substring-before($arg,$delim)
   else $arg
 } ;
 
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

declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

declare function local:get-taxon-name-markup
($det as element()+,$name as element()+,$sensu as element()+,$orgID as xs:string)
{
   for $detRecord in $det,
    $nameRecord in $name,
    $sensuRecord in $sensu
  where $detRecord/dsw_identified=$orgID and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
  order by $detRecord/dwc_dateIdentified/text() descending
  let $organismScreen := $detRecord/dsw_identified/text()
  group by $organismScreen
  return if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "species")
         then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," ("||$nameRecord[1]/dwc_vernacularName/text()||")")
         else 
           if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "genus")
           then (<em>{$nameRecord[1]/dwc_genus/text()}</em>," sp. ("||$nameRecord[1]/dwc_vernacularName/text(),")")
           else 
             if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "subspecies")
             then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," ssp. ",<em>{$nameRecord[1]/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord[1]/dwc_vernacularName/text(),")")
             else
               if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "variety")
               then (<em>{$nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()}</em>," var. ",<em>{$nameRecord[1]/dwc_infraspecificEpithet/text()}</em>, " (", $nameRecord[1]/dwc_vernacularName/text(),")")
               else ()
};

declare function local:get-taxon-name-clean
($det as element()+,$name as element()+,$sensu as element()+,$orgID as xs:string)
{
   for $detRecord in $det,
    $nameRecord in $name,
    $sensuRecord in $sensu
  where $detRecord/dsw_identified=$orgID and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
  order by $detRecord/dwc_dateIdentified/text() descending
  let $organismScreen := $detRecord/dsw_identified/text()
  group by $organismScreen
  return if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "species")
         then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" ("||$nameRecord[1]/dwc_vernacularName/text()||")")
         else 
           if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "genus")
           then ($nameRecord[1]/dwc_genus/text()||" sp. ("||$nameRecord[1]/dwc_vernacularName/text(),")")
           else 
             if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "subspecies")
             then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" ssp. "||$nameRecord/dwc_infraspecificEpithet/text()||" (", $nameRecord[1]/dwc_vernacularName/text(),")")
             else
               if (lower-case($nameRecord[1]/dwc_taxonRank/text()) = "variety")
               then ($nameRecord[1]/dwc_genus/text()||" "||$nameRecord[1]/dwc_specificEpithet/text()||" var. "||$nameRecord[1]/dwc_infraspecificEpithet/text()||" (", $nameRecord[1]/dwc_vernacularName/text(),")")
               else ()
};

declare function local:get-cameo-filename
($cameoID,$image) as xs:string
{
if ($cameoID != "")
then
  for $cameo in $image
  where $cameo/dcterms_identifier/text()=$cameoID
  return $cameo/fileName/text() 
else ""
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

(:--------------------------------------------------------:)

let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|" })

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]
let $xmlSensu := csv:parse($textSensu, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]
let $xmlAgents := csv:parse($textAgents, map { 'header' : true(),'separator' : "|" })

let $textTourButtons := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/tour-buttons.csv'/>)[2]
let $xmlTourButtons := csv:parse($textTourButtons, map { 'header' : true(),'separator' : "|" })

let $textLinks := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/links.csv'/>)[2]
let $xmlLinks := csv:parse($textLinks, map { 'header' : true(),'separator' : "|" })

let $organismsToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/organisms-to-write.txt'))
let $xmlOrganismsToWrite := csv:parse($organismsToWriteDoc, map { 'header' : false() })

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

for $orgRecord in $xmlOrganisms/csv/record, $organismsToWrite in distinct-values($xmlOrganismsToWrite/csv/record/entry)
where $orgRecord/dcterms_identifier/text() = $organismsToWrite
let $taxonNameClean := local:get-taxon-name-clean($xmlDeterminations/csv/record,$xmlNames/csv/record,$xmlSensu/csv/record,$orgRecord/dcterms_identifier/text() )
let $taxonNameMarkup := local:get-taxon-name-markup($xmlDeterminations/csv/record,$xmlNames/csv/record,$xmlSensu/csv/record,$orgRecord/dcterms_identifier/text() )
let $fileName := local:substring-after-last($orgRecord/dcterms_identifier/text(),"/")
let $temp1 := substring-before($orgRecord/dcterms_identifier/text(),concat("/",$fileName))
let $namespace := local:substring-after-last($temp1,"/")
let $filePath := concat($rootPath,"\", $namespace,"\", $fileName,".htm")
let $tempQuoted1 := '"Image of organism" title="Image of organism" src="'
let $tempQuoted2 := '" height="'
let $tempQuoted3 := '"/>'

(: Note: $cameoFileName will be the empty string if there is no value for $orgRecord/cameo :)
let $cameoFileName := local:get-cameo-filename($orgRecord/cameo/text(),$xmlImages/csv/record)

let $cameoLocalID := local:substring-after-last($orgRecord/cameo/text(),"/")
let $temp2 := substring-before($orgRecord/cameo/text(),concat("/",$cameoLocalID))
let $cameoNamespace := local:substring-after-last($temp2,"/")
let $googleMapString := "http://maps.google.com/maps?output=classic&amp;q=loc:"||$orgRecord/dwc_decimalLatitude/text()||","||$orgRecord/dwc_decimalLongitude/text()||"&amp;t=h&amp;z=16"
let $qrCodeString := "http://chart.apis.google.com/chart?chs=100x100&amp;cht=qr&amp;chld=|1&amp;chl=http%3A%2F%2Fbioimages.vanderbilt.edu%2F"||$namespace||"%2F"||$fileName||".htm"
let $loadDatabaseString := 'window.location.replace("../metadata.htm?'||$namespace||'/'||$fileName||'/metadata/ind");'
return (file:create-dir(concat($rootPath,"\",$namespace)), file:write($filePath,
<html>{
  <head>
    <meta content="text/html; charset=utf-8" http-equiv="Content-Type" />
    <meta name="viewport" content="width=320, initial-scale=1" />
    <link rel="icon" type="image/vnd.microsoft.icon" href="../favicon.ico" />
    <link rel="apple-touch-icon" href="../logo.png" />
    <style type="text/css">
    {'@import "../composite-adj.css";'}
    </style>
    <title>An individual instance of {$taxonNameClean}</title>
    <link rel="meta" type="application/rdf+xml" title="RDF" href="http://bioimages.vanderbilt.edu/kaufmannm/ke129.rdf" />
    <script type="text/javascript">{"
      // Determine if the device is an iPhone, iPad, or a regular browser
      if (navigator.userAgent.indexOf('iPad')!=-1)
       {browser='iPad';}
      else
       {
       if (navigator.userAgent.indexOf('iPhone')!=-1)
         {browser='iPhone';}
       else
         {browser='computer';}
       }
    "}
    </script>
  </head>,
  <body vocab="http://schema.org/" prefix="dcterms: http://purl.org/dc/terms/ foaf: http://xmlns.com/foaf/0.1/">{
    <div resource="{$orgRecord/dcterms_identifier/text()||'.htm'}" typeof="foaf:Document WebPage" >
      <span property="about" resource="{$orgRecord/dcterms_identifier/text()}"></span>
      <span property="dateModified" content="{fn:current-dateTime()}"></span>
    </div>,

    <div id="paste" resource="{$orgRecord/dcterms_identifier/text()}" typeof="dcterms:PhysicalResource">{
      
      if ($xmlTourButtons/csv/record[organism_iri=$orgRecord/dcterms_identifier/text()])
      then (
      <table>{

      for $buttonSet in $xmlTourButtons/csv/record
      where $buttonSet/organism_iri=$orgRecord/dcterms_identifier
      return (
        <tr>{
          if ($buttonSet/previous_iri/text() != "")
          then (
                <td>{
                  <a href="{$buttonSet/previous_iri/text()}">
                    <img alt="previous button" src="{$buttonSet/previous_button_image/text()}" height="58" />
                  </a>
                }</td>
               )
          else (),
          <td>
            <a href="{$buttonSet/home_iri/text()}">
              <img alt="tour home button" src="{$buttonSet/home_button_image/text()}" height="58" />
            </a>
          </td>,
          <td>
            <a href="{$buttonSet/tour_iri/text()}">
              <img alt="tour page button" src="{$buttonSet/tour_button_image/text()}" height="58" />
            </a>
          </td>,
          if ($buttonSet/next_iri/text() != "")
          then (
                <td>{
                  <a href="{$buttonSet/next_iri/text()}">
                    <img alt="next button" src="{$buttonSet/next_button_image/text()}" height="58" />
                  </a>
                }</td>
               )
          else ()
        }</tr>
      )

      }</table>,
      <br/>
        )
      else (),
      
      <span>An individual instance of {$taxonNameMarkup}</span>,
      <br/>,

      if ($cameoFileName != "")
      then (
            <a href="../{$cameoNamespace}/{$cameoLocalID}.htm"><span id="orgimage"><img alt="Image of organism" title="Image of organism" src="../lq/{$cameoNamespace}/w{$cameoFileName}" /></span></a>,
            <br/>
           )
      else (),

      <h5>Permanent unique identifier for this particular organism:</h5>,
      <br/>,
      <h5><strong property="dcterms:identifier">{$orgRecord/dcterms_identifier/text()}</strong></h5>,
      <br/>,
      <br/>,
      
      if ($orgRecord/notes/text() != "")
      then (
            <h3><strong>Notes:</strong></h3>,
            <br/>,
            fn:parse-xml($orgRecord/notes/text()),
            <br/>
           )
      else (),
      
      <table>
        <tr>
          <td><a href="../index.htm"><img alt="home button" src="../logo.jpg" height="88" /></a></td>
          <td><a target="top" href="{$googleMapString}"><img alt="FindMe button" src="../findme-button.jpg" height="88" /></a></td>
          <td><img src="{$qrCodeString}" alt="QR Code" /></td>
        </tr>
      </table>,
      <br/>,
(: It doesn't seem to be a problem that the quotes in the onclick value get escaped :)
      <h5><a href="#" onclick='{$loadDatabaseString}'>&#8239;Load database and switch to thumbnail view</a>
      </h5>,
      <br/>,
      <br/>,
      <h5>
        <em>Use this stable URL to link to this page:</em>
        <br/>
        <a href="{$fileName||'.htm'}">http://bioimages.vanderbilt.edu/{$namespace}/{$fileName}.htm</a>
      </h5>,
      <br/>,
      <br/>,
      if ($orgRecord/dwc_collectionCode/text() != "")
      then (
           for $agent in $xmlAgents/csv/record
           where $agent/dcterms_identifier=$orgRecord/dwc_collectionCode
           return (<h5>This organism is a living specimen that is part of the&#8239;
           <a href="{$agent/contactURL/text()}">{$agent/dc_contributor/text()}</a>
           &#8239;with the local identifier {$orgRecord/dwc_catalogNumber/text()}.</h5>,<br/>,
              <br/>)
           )
      else (),

      <h5><em>This particular organism is believed to have </em><strong>{$orgRecord/dwc_establishmentMeans/text()}</strong> <em>means of establishment</em>.</h5>,
      <br/>,

      <h5><em>This organismal entity has the scope: </em><strong>{$orgRecord/dwc_organismScope/text()}</strong>.</h5>,
      <br/>,

      if ($orgRecord/dwc_organismName/text() != "")
      then (
            <h5><em>It has the name </em>&quot;<strong>{$orgRecord/dwc_organismName/text()}</strong>&quot;.</h5>,<br/>
           )
      else (),

      if ($orgRecord/dwc_organismRemarks/text() != "")
      then (
            <h5><em>Remarks:</em><strong>{$orgRecord/dwc_organismRemarks/text()}</strong></h5>,<br/>
           )
      else (),

      <br/>,
      <h3><strong>Identifications:</strong></h3>,
      <br/>,
      for $detRecord in $xmlDeterminations/csv/record,
          $nameRecord in $xmlNames/csv/record,
          $sensuRecord in $xmlSensu/csv/record
      where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $nameRecord/dcterms_identifier=$detRecord/tsnID and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
      order by $detRecord/dwc_dateIdentified/text() descending
      return (
      <h2>{
      if (lower-case($nameRecord/dwc_taxonRank/text()) = "species")
             then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>)
             else 
               if (lower-case($nameRecord/dwc_taxonRank/text()) = "genus")
               then (<em>{$nameRecord/dwc_genus/text()}</em>," sp.")
               else 
                 if (lower-case($nameRecord/dwc_taxonRank/text()) = "subspecies")
                 then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>," ssp. ",<em>{$nameRecord/dwc_infraspecificEpithet/text()}</em>)
                 else
                   if (lower-case($nameRecord/dwc_taxonRank/text()) = "variety")
                   then (<em>{$nameRecord/dwc_genus/text()||" "||$nameRecord/dwc_specificEpithet/text()}</em>," var. ",<em>{$nameRecord/dwc_infraspecificEpithet/text()}</em>)
                   else ()
        }</h2>,
        <span> </span>,
        <h3>{$nameRecord/dwc_scientificNameAuthorship/text()}</h3>,
         if ($sensuRecord/dcterms_identifier/text() != "nominal")
         then (<h6>sec. {$sensuRecord/tcsSignature/text()}</h6>)
         else (<h6>nominal concept</h6>),
        <br/>,
        <span>common name: {$nameRecord/dwc_vernacularName/text()}</span>,
        <br/>,
        <span>family: {$nameRecord/dwc_family/text()}</span>,
        <br/>,
        <h6>{
          <em>Identified </em>,
          <span>{$detRecord/dwc_dateIdentified/text()}</span>,
          <em> by </em>,
          for $agentRecord in $xmlAgents/csv/record
          where $agentRecord/dcterms_identifier=$detRecord/identifiedBy
          return <a href="{$agentRecord/contactURL/text()}">{$agentRecord/dc_contributor/text()}</a>
        }</h6>,
        if ($detRecord/dwc_identificationRemarks/text())
        then (<br/>,<span>Identification remarks: {$detRecord/dwc_identificationRemarks/text()}</span>)
        else (),
        <br/>,
        <br/>
      ),
      
      <h3><strong>Location:</strong></h3>,
      <br/>,
      
      for $depiction in $xmlImages/csv/record
      where $depiction/foaf_depicts=$orgRecord/dcterms_identifier
      let $organismID := $orgRecord/dcterms_identifier
      group by $organismID
      return (            
        <span>{$depiction[1]/dwc_locality/text()}, {$depiction[1]/dwc_county/text()}, {$depiction[1]/dwc_stateProvince/text()}, {$depiction[1]/dwc_countryCode/text()}</span>,
        <br/>,
        <span>Click on these geocoordinates to load a map showing the location: </span>,
        <a target="top" href="http://maps.google.com/maps?output=classic&amp;q=loc:{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;t=h&amp;z=16">{$orgRecord/dwc_decimalLatitude/text()}&#176;, {$orgRecord/dwc_decimalLongitude/text()}&#176;</a>,
        <br/>,
        <h6>Coordinate uncertainty about:  {$depiction[1]/dwc_coordinateUncertaintyInMeters/text()}  m.  </h6>,
        if ($orgRecord/geo_alt/text() != "")
        then (
              <h6>Altitude: {$orgRecord/geo_alt/text()} m.  </h6>
             )
        else (),
        <br/>,
        <h6>{$orgRecord/dwc_georeferenceRemarks/text()}</h6>,
        <br/>,        
        <img src="http://maps.googleapis.com/maps/api/staticmap?center={$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;zoom=14&amp;size=300x300&amp;markers=color:green%7C{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;sensor=false"/>,
        <img src="http://maps.googleapis.com/maps/api/staticmap?center={$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;maptype=hybrid&amp;zoom=18&amp;size=300x300&amp;markers=color:green%7C{$orgRecord/dwc_decimalLatitude/text()},{$orgRecord/dwc_decimalLongitude/text()}&amp;sensor=false"/>,
        <br/>,
        <br/>
      ),
      
      <strong>Occurrences were recorded for this particular organism on the following dates:</strong>,
      <br/>,
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
      return (
        (: If the occurrence date includes a "/" character for a date range, use only first part for id :)
        <a id="{functx:substring-before-if-contains($occurrenceDate,"/")}">{$occurrenceDate}</a>,

        if ($depiction[1]/dwc_occurrenceRemarks/text() != "")
        then if (local:flag-test(local:clean-suppress-flag($depiction[1]/suppress/text()),"2"))
              then
             (
               <h6> <em>Remarks:</em> {substring-after($depiction[1]/dwc_occurrenceRemarks/text(),'.')}</h6>
             )
             else 
             (
               <h6> <em>Remarks:</em> {$depiction[1]/dwc_occurrenceRemarks/text()}</h6>               
             )
        else (),
        
        <br/>
        ),
        <br/>,
        
      <strong>The following images document this particular organism.</strong>,
      <br/>,
      <span> Click on a thumbnail to view the image and its metadata.</span>,
      <a href="#" onclick='window.location.replace("../metadata.htm?{$namespace}/{$fileName}/metadata/ind");'>Load database and enable navigation by taxon and organism.</a>,
      <br/>,
      <br/>,
      <table border="1" cellspacing="0">{
        <tr><td>Image</td><td>View</td></tr>,
        for $depiction in $xmlImages/csv/record, $viewCat in $viewCategory
        where $depiction/foaf_depicts=$orgRecord/dcterms_identifier and $viewCat/stdview/@id = substring($depiction/view/text(),2)
        order by substring($depiction/view/text(),2)
        
        let $imgID := $depiction/dcterms_identifier/text()
        let $thumbNamespace := local:substring-after-last(substring-before($imgID,concat("/",local:substring-after-last($imgID,"/"))),"/")
        let $thumbFilePath := concat("../tn/", $thumbNamespace,"/t", $depiction/fileName/text())
        
        return (
                <tr>{
                  <td>{
                    <a href="{$imgID}.htm"><img src="{$thumbFilePath}" /></a>
                  }</td>,
                  <td>{data($viewCat/@name)||" - "||data($viewCat/stdview[@id=substring($depiction/view/text(),2)]/@name)}</td>
                }</tr>
               )
      }</table>,
      <br/>,

      for $detRecord in $xmlDeterminations/csv/record, $sensuRecord in $xmlSensu/csv/record
      where $detRecord/dsw_identified=$orgRecord/dcterms_identifier and $sensuRecord/dcterms_identifier=$detRecord/nameAccordingToID
      let $sensuScreen := $sensuRecord/dcterms_identifier/text()
      group by $sensuScreen
      order by lower-case($sensuRecord/tcsSignature/text())
      return (
           if ($sensuRecord/dcterms_identifier/text() != "nominal")
           then (<h6>{$sensuRecord/tcsSignature/text()} =</h6>,
                <br/>,
                <h6>{$sensuRecord/dc_creator/text()}, {$sensuRecord/dcterms_created/text()}. {$sensuRecord/dcterms_title/text()}. {$sensuRecord/dc_publisher/text()}. </h6>,
                <br/>)
           else ()
          ),
      <br/>,
      <h5>{
        <em>Metadata last modified: </em>,
        <span>{fn:current-dateTime()}</span>,
        <br/>,
        <a target="top" href="{$orgRecord/dcterms_identifier/text()||'.rdf'}">RDF formatted metadata for this organism</a>,
        <br/>
      }</h5>
    }</div>,
    <script type="text/javascript">{'
    document.getElementById("paste").setAttribute("class", browser); // set css for browser type
    '}</script>,
    <script type="text/javascript">{"
      (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
      (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
      m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
      })(window,document,'script','//www.google-analytics.com/analytics.js','ga');
    
      ga('create', 'UA-45642729-1', 'vanderbilt.edu');
      ga('send', 'pageview');
    "}</script>
  }</body>
}</html>
))
