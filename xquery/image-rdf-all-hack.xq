xquery version "3.0";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace rdfs="http://www.w3.org/2000/01/rdf-schema#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";
declare namespace dwc="http://rs.tdwg.org/dwc/terms/";
declare namespace xmp="http://ns.adobe.com/xap/1.0/";
declare namespace xmpRights="http://ns.adobe.com/xap/1.0/rights/";
declare namespace dsw="http://purl.org/dsw/";
declare namespace ac="http://rs.tdwg.org/ac/terms/";
declare namespace photoshop="http://ns.adobe.com/photoshop/1.0/";
declare namespace cc="http://creativecommons.org/ns#";
declare namespace xhv="http://www.w3.org/1999/xhtml/vocab#";
declare namespace mbank="http://www.morphbank.net/schema/morphbank#";
declare namespace exif="http://ns.adobe.com/exif/1.0/";
declare namespace Iptc4xmpExt="http://iptc.org/std/Iptc4xmpExt/2008-02-29/";
declare namespace foaf="http://xmlns.com/foaf/0.1/";
declare namespace geo="http://www.w3.org/2003/01/geo/wgs84_pos#";
declare namespace blocal="http://bioimages.vanderbilt.edu/rdf/local#";
(:
TODO: 
think about what last modified means (document generated vs. database record updated),
Is Bioimages http://biocol.org/urn:lsid:biocol.org:col:35115 ?
Fix DOCTYPE and XML declarations,
Add lastPublished file save
:)
(:
*********** Functions *********
:)
declare function local:county-units
($state as xs:string, $countryCode as xs:string) as xs:string
{
if ($countryCode = "US" or $countryCode = "CA")
then 
  if ($state = "Louisiana")
  then " Parish"
  else if ($state="Alaska")
        then " Borough"
        else " County"
else
  ""
};

declare function local:extension
($contentType as xs:string) as xs:string
{
if ($contentType="text/html")
then "htm"
else "rdf"
};

declare function local:substring-after-last
($string as xs:string?, $delim as xs:string) as xs:string?
{
  if (contains($string, $delim))
  then local:substring-after-last(substring-after($string, $delim),$delim)
  else $string
};

declare function local:head-content
($title as xs:string)
{
<meta content="text/html; charset=utf-8" http-equiv="Content-Type" />,
<meta name="viewport" content="width=320, initial-scale=1"/>,
<link rel="icon" type="image/vnd.microsoft.icon" href="../favicon.ico" />,
<link rel="apple-touch-icon" href="../logo.png" />,
<style type="text/css">@import "../composite-adj.css";</style>,
<title>{$title}</title>,
<link rel="meta" type="application/rdf+xml" title="RDF" href="http://bioimages.vanderbilt.edu/baskauf/91164.rdf" />,
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
"}</script>
};

declare function local:rdfa-page-metadata
($id as xs:string)
{
<div resource="{$id}.htm" typeof="foaf:Document WebPage" >
<span property="primaryImageOfPage about" resource="{$id}"/>
<span property="dateModified" content="{fn:current-dateTime()}"/>
</div>
};

declare function local:show-cameo
($dom as xs:string, $ns as xs:string, $img as xs:string, $fileName as xs:string)
{
<table border="0" cellspacing="0"><tr><td><a href="../index.htm"><img alt="home button" src="../logo.jpg" width="58" /></a></td><td valign="top"><a href="#" onclick='window.location.replace("../metadata.htm?{$ns}/{$img}/metadata/img");'>&#8239;Enable image database and site navigation</a></td></tr></table>,
<div id="replaceImage"><a property="contentUrl" href="{$dom}/gq/{$ns}/g{$fileName}"><img alt="Image {$dom}/lq/{$ns}/w{$fileName}" src="{$dom}/lq/{$ns}/w{$fileName}" /></a></div>,
<br />
};

declare function local:determination-info
($orgId as xs:string, $xmlDet, $xmlNam, $xmlSen, $xmlAge)
{
for $det in $xmlDet//record,
    $name in $xmlNam//record,
    $sensu in $xmlSen//record,
    $agent in $xmlAge//record
where $det/dsw_identified/text()=$orgId and $name/dcterms_identifier=$det/tsnID and $sensu/dcterms_identifier=$det/nameAccordingToID and $agent/dcterms_identifier=$det/identifiedBy
order by $det/dwc_dateIdentified/text() descending
return (
        <div>
<h2>{
      if ($name/dwc_taxonRank/text() = "species")
             then (<em>{$name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text()}</em>," ("||$name/dwc_vernacularName/text()||")")
             else 
               if ($name/dwc_taxonRank/text() = "genus")
               then (<em>{$name/dwc_genus/text()}</em>," ("||$name/dwc_vernacularName/text(),")")
               else 
                 if ($name/dwc_taxonRank/text() = "subspecies")
                 then (<em>{$name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text()}</em>," ssp. ",<em>{$name/dwc_infraspecificEpithet/text()}</em>, " (", $name/dwc_vernacularName/text(),")")
                 else
                   if ($name/dwc_taxonRank/text() = "variety")
                   then (<em>{$name/dwc_genus/text()||" "||$name/dwc_specificEpithet/text()}</em>," var. ",<em>{$name/dwc_infraspecificEpithet/text()}</em>, " (", $name/dwc_vernacularName/text(),")")
                   else ()
          }</h2>&#32;<h3>{$name/dwc_scientificNameAuthorship/text()}</h3>&#32;<h6>{
           if ($sensu/dcterms_identifier/text() != "nominal")
           then ("sec. "||$sensu/tcsSignature/text())
           else ("nominal concept")
          }</h6>
<br/>
common name: {$name/dwc_vernacularName/text()}<br/>
family: {$name/dwc_family/text()}<br/>
<h6><em>Identified </em>{$det/dwc_dateIdentified/text()}<em> by </em> <a href="{$agent/contactURL/text()}">{$agent/dc_contributor/text()}</a></h6><br/><br/>
        </div>
        )
};

declare function local:identifier-info
($dom as xs:string, $ns as xs:string, $img as xs:string)
{
<h5><em>Refer to this permanent identifier for the image:</em><br/>
<strong property="dcterms:identifier">{$dom}/{$ns}/{$img}</strong><br/><br/>
<em>Use this URL as a stable link to this image page:</em><br/><a href="{$img}.htm">{$dom}/{$ns}/{$img}.htm</a></h5>,
<br/>,
<br/>
};

declare function local:location-info
($record)
{
<h5><em>Location information for the occurrence documented by this image:</em></h5>,
<br/>,
<span property="contentLocation" resource="{$record/dcterms_identifier/text()}#loc" typeof="dcterms:Location Place">
{$record/dwc_locality/text()}, {$record/dwc_county/text()}, 
{$record/dwc_stateProvince/text()}, {$record/dwc_countryCode/text()}<br/>
<a property="geo" typeof="GeoCoordinates" target="top" href="http://maps.google.com/maps?output=classic&amp;q=loc:{$record/dwc_decimalLatitude/text()},{$record/dwc_decimalLongitude/text()}&amp;t=h&amp;z=16">
<span property="latitude">{$record/dwc_decimalLatitude/text()}</span>&#176; latitude,<span property="longitude">{$record/dwc_decimalLongitude/text()}</span>&#176; longitude</a>
</span>,
<h5>Coordinate uncertainty: about {$record/dwc_coordinateUncertaintyInMeters/text()} m</h5>,
<br/>,
<h6>{$record/dwc_georeferenceRemarks/text()}</h6>,
<br/>,
<br/>
};

declare function local:related-resources-info
($orgId as xs:string)
{
<h5><em>This image documents the organism which has the permanent identifier:</em></h5>,
<br/>,
<h6><strong property="about" typeof="dcterms:PhysicalResource" resource="{$orgId}">{$orgId}</strong></h6>,
<br/>,
<br/>,
<h5><em>Follow this link for additional images of the organism:</em><br/>
<a target="top" href="{$orgId}.htm">{$orgId}.htm</a></h5>,
<br/>,
<br/>
};

declare function local:intellectual-property-info
($dom as xs:string, $ns as xs:string,$img as xs:string,$record, $xmlAge,$license)
{
for $agent in $xmlAge//record
where $agent/dcterms_identifier=$record/photographerCode
return (
<h5><em>Intellectual property information about this image:</em></h5>,
<br/>,
<h6><em>Image creator: </em><a property="dcterms:creator creator" href="{$agent/contactURL/text()}" typeof="foaf:{$agent/type/text()} {$agent/type/text()}">
<span property="foaf:name">{$agent/dc_contributor/text()}</span></a>; <em>created on </em>
  <span property="dcterms:created dateCreated">{$record/dcterms_created/text()}</span><br/><br/></h6>
      ),

<h6><em>Rights statement: </em><span property="http://purl.org/dc/elements/1.1/rights">{$record/dc_rights/text()}</span><br/>
<a target="top" property="cc:license" href="{$license[@id=$record/usageTermsIndex/text()]/IRI/text()}" >{$license[@id=$record/usageTermsIndex/text()]/string/text()}<br/><img alt="license logo" src="{$license[@id=$record/usageTermsIndex/text()]/thumb/text()}"/></a><br/></h6>,

for $agent in $xmlAge//record
where $agent/dcterms_identifier=$record/owner
return (
<h6>
<div property="provider" resource="http://biocol.org/urn:lsid:biocol.org:col:35115" typeof="Organization"><span property="name" content="Bioimages"></span><span property="URL" content="http://bioimages.vanderbilt.edu/"></span></div>
<div property="thumbnail" resource="{$dom}/{$ns}/{$img}#tn" typeof="ImageObject"><span property="contentUrl" content="{$dom}/tn/{$ns}/t{$img}.jpg"></span></div>
<em>To cite this image, using the following credit line:</em><br/>
"{$record/photoshop_Credit/text()}" <em>If possible, link to the stable URL for this page.</em><br/><a target="top" href="{$agent/contactURL/text()}">Click this link for contact information about using this image</a><br/><br/>
</h6>
    )
};

declare function local:reference-info
($record, $xmlDet, $xmlSen)
{
<h5><em>Metadata last modified: </em>{$record/dcterms_modified/text()}<br/>
<a target="top" href="{$record/dcterms_identifier/text()}.rdf">RDF formatted metadata for this image</a><br/><br/></h5>,

for $det in $xmlDet//record,
    $sensu in $xmlSen//record
where $det/dsw_identified/text()=$record/foaf_depicts/text() and $sensu/dcterms_identifier=$det/nameAccordingToID
let $sensuScreen := $sensu/dcterms_identifier/text()
group by $sensuScreen
order by lower-case($sensu/tcsSignature/text())
return (
           if ($sensu/dcterms_identifier/text() != "nominal")
           then (<h6>{$sensu/tcsSignature/text()} =</h6>,
                <br/>,
                <h6>{$sensu/dc_creator/text()}, {$sensu/dcterms_created/text()}. {$sensu/dcterms_title/text()}. {$sensu/dc_publisher/text()}. </h6>,
                <br/>)
           else ()
      ),
<br/>
};

(: Note: I solved the problem of the escaping of essential javascript characters by putting all of the
problematic stuff into an external file and then loading it as a function, then calling the function. :)
declare function local:browser-optimize-script
($dom as xs:string, $ns as xs:string,$name as xs:string, $id, $sap)
{
<script src="../check-screen-size.js" type="text/javascript">//
</script>,
<script type="text/javascript">{"
hiresSAP='"||$sap||"'
imgIRI='"||$id||"'
imgSource='"||$dom||"/gq/"||$ns||"/g"||$name||"'
checkScreenSize(hiresSAP,imgIRI,imgSource);
"}</script>
};

declare function local:google-analytics-ping
()
{
<script type="text/javascript">{"
  (function(i,s,o,g,r,a,m){i['GoogleAnalyticsObject']=r;i[r]=i[r]||function(){
  (i[r].q=i[r].q||[]).push(arguments)},i[r].l=1*new Date();a=s.createElement(o),
  m=s.getElementsByTagName(o)[0];a.async=1;a.src=g;m.parentNode.insertBefore(a,m)
  })(window,document,'script','//www.google-analytics.com/analytics.js','ga');

  ga('create', 'UA-45642729-1', 'vanderbilt.edu');
  ga('send', 'pageview');
"}</script>
};

declare function local:rdf-basic-information
($id as xs:string, $ns as xs:string, $img as xs:string, $record, $xmlAge)
{
<rdf:type rdf:resource ="http://purl.org/dc/dcmitype/StillImage" />,
<dc:type>StillImage</dc:type>,
<dcterms:type rdf:resource ="http://purl.org/dc/dcmitype/StillImage" />,
<dcterms:identifier>{$id}</dcterms:identifier>,
<xmp:MetadataDate rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">{$record/dcterms_modified/text()}</xmp:MetadataDate>,

for $agent in $xmlAge//record
where $agent/dcterms_identifier=$record/photographerCode
return (
<dc:creator>{$agent/dc_contributor/text()}</dc:creator>,
<dcterms:creator rdf:resource="{$agent/iri/text()}"/>
    ),
    
<dcterms:created>{$record/dcterms_created/text()}</dcterms:created>,
<ac:providerLiteral>Bioimages http://bioimages.vanderbilt.edu/</ac:providerLiteral>,
<ac:provider rdf:resource="http://biocol.org/urn:lsid:biocol.org:col:35115"/>,
<dwc:collectionCode>{$ns}</dwc:collectionCode>,
<dwc:catalogNumber>{$img}</dwc:catalogNumber>
};

declare function local:rdf-intellectual-property-info
($id as xs:string, $mbank as xs:string, $record, $xmlAge, $license)
{
for $agent in $xmlAge//record
where $agent/dcterms_identifier=$record/owner
return (
<dc:rights xml:lang="en">{$record/dc_rights/text()}</dc:rights>,

if ($record/owner/text() != 'none')
then <xmpRights:Owner>{$agent/dc_contributor/text()}</xmpRights:Owner>
else (),

<photoshop:Credit xml:lang="en">{$record/photoshop_Credit/text()}</photoshop:Credit>,
<cc:license rdf:resource="{$license[@id=$record/usageTermsIndex/text()]/IRI/text()}"/>,
<xhv:license rdf:resource="{$license[@id=$record/usageTermsIndex/text()]/IRI/text()}"/>,
<dcterms:license rdf:resource="{$license[@id=$record/usageTermsIndex/text()]/IRI/text()}"/>,

if ($record/owner/text() != 'none')
then <dcterms:dateCopyrighted rdf:datatype="http://www.w3.org/2001/XMLSchema#gyear">{$record/dcterms_dateCopyrighted/text()}</dcterms:dateCopyrighted>
else(),

<xmpRights:UsageTerms xml:lang="en">{$license[@id=$record/usageTermsIndex/text()]/string/text()}</xmpRights:UsageTerms>,
<xmpRights:WebStatement>{$license[@id=$record/usageTermsIndex/text()]/IRI/text()}</xmpRights:WebStatement>,
<ac:licenseLogoURL>{$license[@id=$record/usageTermsIndex/text()]/thumb/text()}</ac:licenseLogoURL>,
<mbank:view>{$mbank}</mbank:view>,
<Iptc4xmpExt:CVterm rdf:resource ="http://bioimages.vanderbilt.edu/rdf/stdview{$record/view/text()}" />,
<dcterms:title xml:lang="en">{$record/dcterms_title/text()}</dcterms:title>,
<dcterms:description xml:lang="en">{$record/dcterms_description/text()}</dcterms:description>,

if ($record/ac_caption/text())
then <ac:caption>{$record/ac_caption/text()}</ac:caption>
else (),

<ac:attributionLinkURL>{$id}.htm</ac:attributionLinkURL>,

if ($record/owner/text() != 'none')
then <blocal:contactURL>{$agent/contactURL/text()}</blocal:contactURL>
else(),

<xmp:Rating>{$record/xmp_Rating/text()}</xmp:Rating>
      )
};

declare function local:rdf-relationships
($id, $organismId, $occurDate)
{
<foaf:isPrimaryTopicOf rdf:resource="{$id}.htm" />,
<foaf:isPrimaryTopicOf rdf:resource="{$id}.rdf" />,
<dsw:derivedFrom rdf:resource="{$organismId}" />,
<foaf:depicts rdf:resource="{$organismId}" />,
<dsw:evidenceFor rdf:resource="{$organismId}#{$occurDate}" />,
<ac:hasServiceAccessPoint rdf:resource="{$id}#bq" />,
<ac:hasServiceAccessPoint rdf:resource="{$id}#tn" />,
<ac:hasServiceAccessPoint rdf:resource="{$id}#lq" />,
<ac:hasServiceAccessPoint rdf:resource="{$id}#gq" />
};

declare function local:rdf-location
($record)
{
<geo:lat>{$record/dwc_decimalLatitude/text()}</geo:lat>,
<geo:long>{$record/dwc_decimalLongitude/text()}</geo:long>,
if ($record/geo_alt/text())
then <geo:alt>{$record/geo_alt/text()}</geo:alt>
else (),
<dwc:coordinateUncertaintyInMeters>{$record/dwc_coordinateUncertaintyInMeters/text()}</dwc:coordinateUncertaintyInMeters>,
<dwc:locality>{$record/dwc_locality/text()}</dwc:locality>,
<dwc:georeferenceRemarks>{$record/dwc_georeferenceRemarks/text()}</dwc:georeferenceRemarks>,
<dwc:countryCode>{$record/dwc_countryCode/text()}</dwc:countryCode>,
<dwc:stateProvince>{$record/dwc_stateProvince/text()}</dwc:stateProvince>,
<dwc:county>{$record/dwc_county/text()}</dwc:county>,
if ($record/dwc_informationWithheld/text())
then <dwc:informationWithheld>{$record/dwc_informationWithheld/text()}</dwc:informationWithheld>
else (),
if ($record/dwc_dataGeneralizations/text())
then <dwc:dataGeneralizations>{$record/dwc_dataGeneralizations/text()}</dwc:dataGeneralizations>
else (),
if ($record/dwc_occurrenceRemarks/text())
then <dwc:occurrenceRemarks>{$record/dwc_occurrenceRemarks/text()}</dwc:occurrenceRemarks>
else ()
};

declare function local:service-access-point
($dom, $ns, $img, $id, $type, $x, $y, $sap)
{
<rdf:Description rdf:about="{$id}#{$type}">
  <rdf:type rdf:resource ="http://rs.tdwg.org/ac/terms/ServiceAccessPoint" />
{
if ($type="bq")
then if ($sap!="")      (: This is really a hack fix when the BestQuality variant isn't online yet.  Really, the BestQuality variant just shouldn't be instantiated.  :)
     then 
    (  
    <ac:variantLiteral>Best Quality</ac:variantLiteral>,
    <ac:variant rdf:resource ="http://rs.tdwg.org/ac/terms/BestQuality" />,
    <ac:accessURI rdf:resource ="{$sap}" />,
    <exif:PixelXDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$x}</exif:PixelXDimension>,
    <exif:PixelYDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{$y}</exif:PixelYDimension>
    )
    else ()
else if ($type="tn")
        then (  
            <ac:variantLiteral>Thumbnail</ac:variantLiteral>,
            <ac:variant rdf:resource ="http://rs.tdwg.org/ac/terms/Thumbnail" />,
            <ac:accessURI rdf:resource ="{$dom}/tn/{$ns}/t{$img}" />,
            <exif:PixelXDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($x*local:calculate-shrink($x, $y, 100))}</exif:PixelXDimension>,
            <exif:PixelYDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($y*local:calculate-shrink($x, $y, 100))}</exif:PixelYDimension>
            )
            else if ($type="lq")
                then (  
                    <ac:variantLiteral>Lower Quality</ac:variantLiteral>,
                    <ac:variant rdf:resource ="http://rs.tdwg.org/ac/terms/LowerQuality" />,
                    <ac:accessURI rdf:resource ="{$dom}/lq/{$ns}/w{$img}" />,
                    <exif:PixelXDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($x*local:calculate-shrink($x, $y, 480))}</exif:PixelXDimension>,
                    <exif:PixelYDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($y*local:calculate-shrink($x, $y, 480))}</exif:PixelYDimension>
                    )
                else if ($type="gq")
                    then (  
                        <ac:variantLiteral>Good Quality</ac:variantLiteral>,
                        <ac:variant rdf:resource ="http://rs.tdwg.org/ac/terms/GoodQuality" />,
                        <ac:accessURI rdf:resource ="{$dom}/gq/{$ns}/g{$img}" />,
                        <exif:PixelXDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($x*local:calculate-shrink($x, $y, 1024))}</exif:PixelXDimension>,
                        <exif:PixelYDimension rdf:datatype="http://www.w3.org/2001/XMLSchema#int">{round($y*local:calculate-shrink($x, $y, 1024))}</exif:PixelYDimension>
                        )
                    else ()
}
  <dc:format>image/jpeg</dc:format>
</rdf:Description>
};

declare function local:calculate-shrink
($height as xs:integer, $width as xs:integer, $size as xs:integer) as xs:decimal
{
let $whRatio := $width div $height
let $imageMax := if ($whRatio > 1)then ($width) else ($height)
return ($size div $imageMax)
};

declare function local:rdf-document-metadata
($id, $modified)
{
<rdf:type rdf:resource ="http://xmlns.com/foaf/0.1/Document" />,
<dc:format>application/rdf+xml</dc:format>,
<dcterms:identifier>{$id}.rdf</dcterms:identifier>,
<dcterms:description xml:lang="en">RDF formatted description of the live organism image {$id}</dcterms:description>,
<dc:creator>Bioimages http://bioimages.vanderbilt.edu/</dc:creator>,
<dcterms:creator rdf:resource="http://biocol.org/urn:lsid:biocol.org:col:35115"/>,
<dc:language>en</dc:language>,
<dcterms:language rdf:resource="http://id.loc.gov/vocabulary/languages/eng"/>,
<dcterms:modified rdf:datatype="http://www.w3.org/2001/XMLSchema#dateTime">{$modified}</dcterms:modified>,
<rdfs:comment>Regardless of the license of the image, the metadata are licensed CC0 - No Rights Reserved</rdfs:comment>,
<cc:license rdf:resource="http://creativecommons.org/publicdomain/zero/1.0/"/>,
<xhv:license rdf:resource="http://creativecommons.org/publicdomain/zero/1.0/"/>,
<dcterms:license rdf:resource="http://creativecommons.org/publicdomain/zero/1.0/"/>,
<dcterms:references rdf:resource="{$id}"/>,
<foaf:primaryTopic rdf:resource="{$id}"/>
};

(:
*********** Set up local folders *********
Delete this section if serving file directly
:)

let $localFilesFolderUnix := "c:/test"

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\test"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)


(:
*********** Get data from GitHub *********
:)
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

let $licenseDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/license.xml')
let $licenseCategory := $licenseDoc/license/category

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

let $imagesToWriteDoc := file:read-text(concat('file:///',$localFilesFolderUnix,'/images-to-write.txt'))
let $xmlImagesToWrite := csv:parse($imagesToWriteDoc, map { 'header' : false() })

(:
*********** set up loop to write files for new records *********
Delete this section if serving the files directly
:)

return (file:write("c:\test\images.rdf",

<rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
xmlns:dc="http://purl.org/dc/elements/1.1/"
xmlns:dcterms="http://purl.org/dc/terms/"
xmlns:dwc="http://rs.tdwg.org/dwc/terms/"
xmlns:dwciri="http://rs.tdwg.org/dwc/iri/"
xmlns:owl="http://www.w3.org/2002/07/owl#"
xmlns:dsw="http://purl.org/dsw/"
xmlns:ac="http://rs.tdwg.org/ac/terms/"
xmlns:xmp="http://ns.adobe.com/xap/1.0/"
xmlns:xmpRights="http://ns.adobe.com/xap/1.0/rights/"
xmlns:Iptc4xmpExt="http://iptc.org/std/Iptc4xmpExt/2008-02-29/"
xmlns:photoshop="http://ns.adobe.com/photoshop/1.0/"
xmlns:cc="http://creativecommons.org/ns#"
xmlns:xhv="http://www.w3.org/1999/xhtml/vocab#"
xmlns:mbank="http://www.morphbank.net/schema/morphbank#"
xmlns:exif="http://ns.adobe.com/exif/1.0/"
xmlns:foaf="http://xmlns.com/foaf/0.1/"
xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
xmlns:blocal="http://bioimages.vanderbilt.edu/rdf/local#"
      >{


for $imgRecord in $xmlImages//record

  let $fileName := local:substring-after-last($imgRecord/dcterms_identifier/text(),"/")
  let $temp1 := substring-before($imgRecord/dcterms_identifier/text(),concat("/",$fileName))
  let $namespace := local:substring-after-last($temp1,"/")
  
  let $contentType := "application/rdf+xml" (: comment out "text/html" to write all RDF :)
  let $image := $fileName
let $domain := "http://bioimages.vanderbilt.edu"
let $iri := concat($domain,"/",$namespace,"/",$image)

return (

        <rdf:Description rdf:about="{$iri}">
          {local:rdf-basic-information($iri, $namespace, $image, $imgRecord, $xmlAgents)}
          {local:rdf-intellectual-property-info($iri, $viewCategory/stdview[@id=substring($imgRecord/view/text(),2)]/text(), $imgRecord, $xmlAgents, $licenseCategory)}
          {local:rdf-relationships($iri,$imgRecord/foaf_depicts/text(),substring($imgRecord/dcterms_created/text(),1,10))}
          {local:rdf-location($imgRecord)}
        
    </rdf:Description>
      ,
        
        let $accessPoints:=("bq","tn","lq","gq")
        for $ap in $accessPoints
        return (local:service-access-point($domain, $namespace, $imgRecord/fileName/text(), $iri, $ap, $imgRecord/exif_PixelXDimension/text(),$imgRecord/exif_PixelYDimension/text(), $imgRecord/ac_hasServiceAccessPoint/text() )
      ),
        <rdf:Description rdf:about="{$iri}.rdf">
          {local:rdf-document-metadata($iri, $imgRecord/dcterms_modified/text())}
      </rdf:Description>
)
     }</rdf:RDF>
       
    ) )