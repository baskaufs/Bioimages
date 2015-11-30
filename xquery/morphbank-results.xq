xquery version "3.0";

(: let $localFilesFolderUnix := "c:/test" :)
let $localFilesFolderPC := "c:\test"

let $uri := "http://services.morphbank.net/mbsvc3/request?method=changes&amp;objecttype=Image&amp;keywords=&amp;geolocated=true&amp;firstResult=0&amp;user=&amp;group=Bioimages&amp;change=&amp;lastDateChanged=&amp;numChangeDays=30&amp;id=&amp;taxonName=&amp;format=svc"
let $responseDoc :=  fn:doc($uri)

(:let $responseDoc := fn:doc(concat('file:///',$localFilesFolderUnix,'/morphbank-image-response-2015-11-29.xml')) :)
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
