xquery version "3.0";
declare default element namespace "http://purl.org/rss/1.0/";
declare namespace rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace dc="http://purl.org/dc/elements/1.1/";
declare namespace dcterms="http://purl.org/dc/terms/";

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
let $nothing := file:create-dir(concat($rootPath,"\rdf"))

(:
*********** Get data from GitHub *********
:)
let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms.csv'/>)[2]
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

(:
*********** Main query *********
:)

return (

      file:write(concat($rootPath,"\rdf\images.rss"),
        <rdf:RDF 
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:dcterms="http://purl.org/dc/terms/"
        >{
            <channel rdf:about="http://bioimages.vanderbilt.edu/rdf/images.rss">
                <title>Images in the Bioimages database</title>
                <link>http://bioimages.vanderbilt.edu/</link>
                <description>This channel provides an RDF link to all images in the database so that they can be discovered by Linked Data clients.</description>
                <dcterms:isReferencedBy rdf:resource="http://bioimages.vanderbilt.edu/index.rdf"/>
                <items><rdf:Seq>{
                        for $img in $xmlImages//*:record
                        order by $img/*:dcterms_modified descending
                        return (
                               <rdf:li rdf:resource="{$img/*:dcterms_identifier/text()}"/>
                               )
             }</rdf:Seq></items>
           </channel>,
          
          for $img in $xmlImages//*:record
          order by $img/*:dcterms_modified descending
          return (
                 <item rdf:about="{$img/*:dcterms_identifier/text()}">
                   <title>{$img/*:dcterms_description/text()}</title>
                   <link>{$img/*:dcterms_identifier/text()}</link>
                   <dc:date>{$img/*:dcterms_modified/text()}</dc:date>
                 </item>
                 )

        }</rdf:RDF>
         )
        ,

      file:write(concat($rootPath,"\rdf\individuals.rss"),
        <rdf:RDF xmlns:rss="http://purl.org/rss/1.0/"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:dcterms="http://purl.org/dc/terms/"
        >{
            <channel rdf:about="http://bioimages.vanderbilt.edu/rdf/individuals.rss">
                <title>Individual organisms in the Bioimages database</title>
                <link>http://bioimages.vanderbilt.edu/</link>
                <description>This channel provides an RDF link to all organisms in the database so that they can be discovered by Linked Data clients.</description>
                <dcterms:isReferencedBy rdf:resource="http://bioimages.vanderbilt.edu/index.rdf"/>
                <items><rdf:Seq>{
                        for $org in $xmlOrganisms//*:record
                        order by $org/*:dcterms_modified descending
                        return (
                               <rdf:li rdf:resource="{$org/*:dcterms_identifier/text()}"/>
                               )
             }</rdf:Seq></items>
           </channel>,
          
          for $org in $xmlOrganisms//*:record
          order by $org/*:dcterms_modified descending
          return (
                 <item rdf:about="{$org/*:dcterms_identifier/text()}">
                   <title>{concat("Organism with GUID: ",$org/*:dcterms_identifier/text())}</title>
                   <link>{$org/*:dcterms_identifier/text()}</link>
                   <dc:date>{$org/*:dcterms_modified/text()}</dc:date>
                 </item>
                 )

        }</rdf:RDF>
         )

)