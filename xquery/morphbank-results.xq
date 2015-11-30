xquery version "3.0";

let $localFilesFolderUnix := "c:/test"
let $localFilesFolderPC := "c:\test"

let $responseDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/morphbank-image-response-2015-11-29.xml'))
let $nl := "&#10;"  (: newline character :)

(:
*********** Main query *********
:)

return (
    file:write(concat($localFilesFolderPC,"\morphbank-ids.csv"),

for $id in $responseDoc//object/sourceId
return
concat($id/external/text(),"|","http://www.morphbank.net/?id=",$id/morphbank/text(),"&amp;imgType=jpeg",$nl)
               )
 ) 
