xquery version "3.0";
declare namespace dcterms="http://purl.org/dc/terms/";

let $localFilesFolderPC := "c:\test"
let $lastPublished := fn:current-dateTime()
return (file:write(concat($localFilesFolderPC,"\last-published.xml"),
<body>
<dcterms:modified>{$lastPublished}</dcterms:modified>
</body>
))