xquery version "3.0";
declare default element namespace "http://www.sitemaps.org/schemas/sitemap/0.9";

(:
*********** Set up local folders *********
:)

(: Create root folder if it doesn't already exist. :)
let $rootPath := "c:\bioimages"
(: "file:create-dir($dir as xs:string) as empty-sequence()" will create a directory or do nothing if it already exists :)
let $nothing := file:create-dir($rootPath)

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

return 
(
        file:write(concat($rootPath,"\sitemap.xml"),
        <urlset>{
          for $org in $xmlOrganisms//*:record
          order by $org/*:dcterms_modified descending
          return (
                 <url>
                   <loc>{$org/*:dcterms_identifier/text()}</loc>
                   <lastmod>{$org/*:dcterms_modified/text()}</lastmod>
                 </url>
                 ),
          for $img in $xmlImages//*:record
          order by $img/*:dcterms_modified descending
          return (
                 <url>
                   <loc>{$img/*:dcterms_identifier/text()}</loc>
                   <lastmod>{$img/*:dcterms_modified/text()}</lastmod>
                 </url> 
                 )
        }</urlset>
      )
)