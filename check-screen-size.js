function checkScreenSize(hiresSAP,imgIRI,imgSource)
     {
document.getElementById("paste").setAttribute("class", browser); // set css for browser type
notPortableDevice=((screen.availWidth > 500) || (screen.availHeight > 500));  //enable highres image for big screen
if (notPortableDevice)
 {
 document.getElementById('replaceImage').innerHTML='<a href="'+hiresSAP+'"><img alt="'+imgIRI+'" src="'+imgSource+'" /></a>'; 
 }
     }
