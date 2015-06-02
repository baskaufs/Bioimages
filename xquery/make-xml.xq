xquery version "3.0";
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
(:let $textOrganisms := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/organisms-small.csv'/>)[2]:)
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })
(: When we implement Ken's output with pipe ("|") separators, the parse function will have to change to this:
let $xmlOrganisms := csv:parse($textOrganisms, map { 'header' : true(),'separator' : "|" })
:)

let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations.csv'/>)[2]
(:let $textDeterminations := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/determinations-small.csv'/>)[2]:)
let $xmlDeterminations := csv:parse($textDeterminations, map { 'header' : true(),'separator' : "|" })

let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names.csv'/>)[2]
(:let $textNames := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/names-small.csv'/>)[2]:)
let $xmlNames := csv:parse($textNames, map { 'header' : true(),'separator' : "|" })

let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu.csv'/>)[2]
(:let $textSensu := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/sensu-small.csv'/>)[2]:)
let $xmlSensu := csv:parse($textSensu, map { 'header' : true(),'separator' : "|" })

let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images.csv'/>)[2]
(:let $textImages := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/images-small.csv'/>)[2]:)
let $xmlImages := csv:parse($textImages, map { 'header' : true(),'separator' : "|" })

let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents.csv'/>)[2]
(:let $textAgents := http:send-request(<http:request method='get' href='https://raw.githubusercontent.com/baskaufs/Bioimages/master/agents-small.csv'/>)[2]:)
let $xmlAgents := csv:parse($textAgents, map { 'header' : true(),'separator' : "|" })

let $licenseDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/license.xml')
let $licenseCategory := $licenseDoc/license/category

let $stdViewDoc := fn:doc('https://raw.githubusercontent.com/baskaufs/Bioimages/master/stdview.xml')
let $viewCategory := $stdViewDoc/view/viewGroup/viewCategory

return (file:write(concat($rootPath,"\organisms.xml"),
<organisms>
{for $Organisms in $xmlOrganisms/csv/record
return ($Organisms)}
</organisms>
),
file:write(concat($rootPath,"\determinations.xml"),
<determinations>
{for $Determinations in $xmlDeterminations/csv/record
return ($Determinations)}
</determinations>
),
file:write(concat($rootPath,"\names.xml"),
<names>
{for $Names in $xmlNames/csv/record
return ($Names)}
</names>
),
file:write(concat($rootPath,"\sensu.xml"),
<sensu>
{for $Sensu in $xmlSensu/csv/record
return ($Sensu)}
</sensu>
),
file:write(concat($rootPath,"\images.xml"),
<images>
{for $Images in $xmlImages/csv/record
return ($Images)}
</images>
),
file:write(concat($rootPath,"\agents.xml"),
<agents>
{for $Agents in $xmlAgents/csv/record
return ($Agents)}
</agents>
)
    )
