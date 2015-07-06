# XQuery files used to publish Bioimages

Note: these queries get the source data from pipe-delineated text files on the Bioimages GitHub site.  They currently assume the presence of some files in directories that are hard-coded into the queries.  The default input directory is c:\test and the default output directory for the website files is c:\bioimages .

It takes a very long time (many minutes) for some of these queries to execute due to the large size of the source data files. It's best to start the batch file and get a cup of coffee.

The following lists the query files and their use:

----------

**modified-organism-file.xq** 

Determines which organism records need to be rewritten based on whether lastModified dates are more recent than the last time the website was published.  The IRIs of the organisms are written into the file organisms-to-write.txt .

----------

**organism-html.xq**

Generates the static XHTML web pages for organisms whose IRIs are present in organisms-to-write.txt .

----------

**organism-rdf.xq**

Generates the static RDF/XML files for organisms whose IRIs are present in organisms-to-write.txt .

----------
**images.xq**

Generates the static XHTML web pages and RDF/XML files for organisms whose IRIs are present in images-to-write.txt . **Note: because of the large size of the image source file, this query may cause an out of memory error for computers with less than 8 GB of memory.  It cannot be run from the BaseX GUI without generating an out of memory error.**

----------
**index-rss.xq**

Generates the RSS index files for organisms and images so that semantic clients can crawl the site and discover which RDF files have changed since some date.  


----------
**index-sitemap.xq**

Generates the sitemap.xml file web bots can crawl the site and discover which XHTML files have changed since some date.

----------
**make-xml.xq**

Generates the local XML index files needed for the Javascript to generate the site files dynamically.

----------
**save-published-date.xq**

Saves the current dateTime in the file last-published.xml to record the time when the site was published.


----------
**ToDo**

Need to hack the modified-organism-file.xq query to determine which image files need to be re-written based on the lastModified dates.

Check on identificationRemarks.  They aren't displayed on static pages and for individuals on javascript-generated page. Missing <br/> on javascript image page.

----------
**generate.bat**

NOTE: at the moment, this doesn't work well.
 
Batch file to run sequentially the queries that generate site files using BaseX from the command line.  It does not currently run the queries that determine which files have been modified and need to be published.  Make sure that the folder containing basex.bat is in the PATH. 
