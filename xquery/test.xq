  let $json-ld := fetch:text("http://api.dp.la/v2/items?q=" || "weasel" || "&amp;api_key=52d3a87465eb77a9b3d632cadd85c9e3" )
  let $xml-data := json:parse($json-ld)
     let $images :=
     for $obj in ($xml-data/json/docs/_)
     let $isShownAt := $obj//isShownAt/text()
     let $title := ($obj//title[@type="array"]/_/text(), $obj//originalRecord/titleInfo/title/text())
     let $object := ($obj//_0040thumbnail/text(),$obj/object/text())
 return <li>{$title}<br/><a href="{$isShownAt}"><img src="{$object}"/></a></li>
   return
   <html>
      <head>
        <title>DPLA Data</title>
      </head>
      <body>
        <p>
          <ul>{$images}</ul>
        </p>
      </body>
</html>