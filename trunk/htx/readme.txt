                     
 euphoria\htx directory
 
 This directory is used by RDS to generate the .doc and .htm
 documentation files for all platforms, and to help build the 
 INNO installation file for DOS/Windows. The INNO script is 
 "euphoria.iss". INNO will write the Euphoria setup .exe file 
 to the euphoria\Setup directory (which you can create).
 
 To rebuild all .doc and .htm files from the .htx files, type: 
     
     docall
 
 To spell-check the ,htx files, type: 
     
     ex spell
 
 Junko Miura's documentation generator (contained in this directory)
 reads each .htx file and produces a .htm and a .doc from it.
 Some of the .doc files are then bundled into a single .doc file.
 This way, we can have HTML documentation, as well as plain text
 documentation without performing dual-maintenance. The generator
 understands simple HTML tags such as <BR> and <P> and can format
 the plain text accordingly. Most other tags it simply ignores.
 We have also added a few extra non-standard HTML tags of our 
 own invention to help us in certain areas, e.g. <_eucode>
 
 If you are interested in modifying the Euphoria documentation, or 
 making a better INNO installation file, you should add this directory 
 to your euphoria directory as euphoria\htx.

 Since 99% of users will not be interested in doing this, we have
 not tried to include this directory in the Euphoria installation
 package.
 
