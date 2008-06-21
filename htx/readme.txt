<_init_comment>
<html>
<head><title>Euphoria Readme</title>
<_css>
</head>
<body>
<_width>

**{{{
 ---> <font color="#FF0099">Is this the latest version of Euphoria?</font>
      Visit:  a href="http://www.RapidEuphoria.com">http://www.RapidEuphoria.com</a>
      
 ---> To install/uninstall Euphoria, see a href="html/install.htm">install.htm</a>
      
 ---> <font color="#FF0099">What's new in this release?</font>
      See a href="html/relnotes.htm">relnotes.doc</a> 
}}}**

<_center><font face="Arial, Helvetica" color="#006633" size=+2>
<br>
                       Euphoria Programming Language<br>
                              version 4.0<br>
</font></_center>

&nbsp;<br>

<table border=0 cellspacing=2 cellpadding=2>

<_2clist
  name="<font face=\"Arial, Helvetica\" color=\"#003366\">Welcome to
   Euphoria! ...</font>"
  description="**<font face=\"Arial, Helvetica\" color=\"#FF0099\">E</font><font face=\"Arial, Helvetica\" color=\"#003366\">nd</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">U</font><font face=\"Arial, Helvetica\" color=\"#003366\">ser</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">P</font><font face=\"Arial, Helvetica\" color=\"#003366\">rogramming with</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">H</font><font face=\"Arial, Helvetica\" color=\"#003366\">ierarchical</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">O</font><font face=\"Arial, Helvetica\" color=\"#003366\">bjects for</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">R</font><font face=\"Arial, Helvetica\" color=\"#003366\">obust</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">I</font><font face=\"Arial, Helvetica\" color=\"#003366\">nterpreted</font>
<font face=\"Arial, Helvetica\" color=\"#FF0099\">A</font><font face=\"Arial, Helvetica\" color=\"#003366\">pplications</font>**"
>

</table>


 Euphoria has come a long way since v1.0 was released in July 1993. There are
 now thousands of users around the world. 
 There's an automated a href=http://www.OpenEuphoria.org/EUforum>
 **discussion forum**</a>, managed and moderated by a Euphoria 
 program, and supporting over 500 subscribers.
 The a href="http://www.RapidEuphoria.com">Euphoria Web site</a> contains
 over 1600 contributed **.**zip files packed with Euphoria source programs
 and library routines. Dozens of people have set up their own independent Web
 pages with Euphoria-related content.
 Euphoria has been used in a variety of
 <font color="#009999">**commercial programs**</font>. 
 The <font color="#CC3366">**Windows**</font> version has been used
 to create numerous <font color="#009999">**GUI, utility and
 Internet-related programs**</font>. 
 The <font color="#CC3366">**DOS**</font> version has been used to create
 many exciting <font color="#009999">**high-speed action games**</font>,
 complete with **Sound Blaster** sound effects.
 The
 <font color="#CC3366">**Linux**</font> and
 <font color="#CC3366">**FreeBSD**</font> versions have been used to
 write <font color="#009999">**X Windows GUI programs, Web-based (CGI) programs**</font>, and lots of 
 useful tools and utilities.



<font face="Arial, Helvetica" color="#FF0099" size=+1>
<br>

<_dul>Yet Another Programming Language?</_dul>

</font>

 Euphoria is a very-high-level programming language with several features that
 set it apart from the crowd:
<ul>
<li>
 Euphoria programs run on 
 <font color="#CC3366">**Windows**</font>,
 <font color="#CC3366">**DOS**</font>,
 <font color="#CC3366">**Linux**</font>, and
 <font color="#CC3366">**FreeBSD**</font>.

<li>
Euphoria is <font color="#CC0099">**free**</font> and 
            <font color="#CC0099">**open source**</font>.
The complete source code for the Euphoria interpreter, translator
and binder is included in the download package.

<li>
 The language is flexible, powerful, and easy to learn.

<li>
 There is no waiting for compiles and links - just edit and run. 

<li>
 You can create and distribute a royalty-free,
 <font color="#CC0099">**stand-alone .exe**</font> file.

<li>
 <font color="#CC0099">**Dynamic storage allocation**</font> is
 fundamental to Euphoria. Variables grow or shrink in size without the
 programmer having to worry about allocating and freeing chunks of memory.
 Elements of an array (Euphoria sequence) can be a dynamic mixture of
 different types and sizes of data.

<li>
 Euphoria provides <font color="#CC0099">**extensive run-time error
 checking**</font> for**:** out-of-bounds subscripts, uninitialized
 variables, bad parameter values for library routines, illegal value assigned
 to a variable, and many more. If something goes wrong you'll get a full error
 message, with a call traceback and a listing of variable values. 
 With other languages you'll typically get protection faults 
 with useless dumps of machine registers and addresses.


<li>
 The Euphoria interpreter is more than <font color="#CC0099">
 **30 times faster**</font> than either Perl or Python, and it's 
 considerably faster than all other interpreted languages, according to the 
 "Great Computer Language Shootout" benchmark (see demo\bench\bench.doc). 
 

<li>
 If that isn't enough, there's a **Euphoria To C Translator** that can 
 translate any Euphoria program to C, and boost your speed even more. 
 Why waste time debugging hand-coded C/C++? You can easily develop a Euphoria
 program, and then generate the C code.


<li>
 Euphoria programs are not constrained by any 640K memory restrictions
 for which MS-DOS is infamous. All versions of Euphoria let you use
 all the memory on your system, and if that isn't
 enough, a swap file on disk will provide additional virtual memory.

<li>
 An integrated, easy-to-use, <font color="#993333">**full-screen
 source-level debugger/tracer**</font> is included.

<li>
 Both an <font color="#993333">**execution-count profiler**</font>, and a
 <font color="#993333">**time profiler**</font> are available.

<li>
 There is a large and rapidly growing collection of excellent 3rd party
 programs and libraries, most with full source code. 

<li>
 RDS has developed an extremely flexible database 
 system (**EDS**) that is portable across all Euphoria platforms.

<li>
 The <font color="#CC3366">**WIN32**</font> implementation of Euphoria
 can access any WIN32 API routine, as well as C or  
 Euphoria routines in .DLL files. 
 A team of people has developed
 a Windows GUI library (**Win32Lib**), complete
 with a powerful Interactive Development Environment.
 You can design a user interface graphically, specify the
 Euphoria statements to be executed when someone clicks, 
 and the IDE will create a complete Euphoria program for you.
 There are Windows Euphoria libraries for Internet access, 
 3-D games, and many other application areas. 


<li>
 The <font color="#CC3366">**DOS32**</font> implementation of Euphoria
 on MS-DOS contains a built-in graphics library. If necessary, you can 
 access DOS software interrupts. You can call machine-code routines. 
 You can even
 set up your own hardware interrupt handlers. Many high-speed action
 games, complete with Sound Blaster sound effects, have been developed 100%
 in Euphoria, without the need for any machine code. 

<li>
 The <font color="#CC3366">**Linux**</font> and
 <font color="#CC3366">**FreeBSD**</font> implementations of Euphoria
 let you access C routines and variables in shared libraries, 
 for tasks ranging from graphics, to X windows GUI programming, to 
 Internet CGI programming. The good news is, you'll be 
 programming in Euphoria, not C.

</ul>



<font face="Arial, Helvetica" color="#FF0099" size=+1>
<br>

<_dul>Platforms and Products</_dul>

</font>

 Euphoria runs on four different platforms,
 <font color="#CC3366">**WIN32**</font>,
 <font color="#CC3366">**DOS32**</font>,
 <font color="#CC3366">**Linux**</font>, and
 <font color="#CC3366">**FreeBSD**</font>.
 
 
 This **Euphoria Interpreter, Translator and Binder** 
 package is free for anyone to use.
 
 
 Using the Euphoria **Binder** you can 
 <font color="#993333">**shroud**</font> 
 (encrypt) and <font color="#993333">**bind**</font> any Euphoria program 
 with a copy of the interpreter back-end, to create a
  <font color="#CC0099">**single, stand-alone, tamper-resistant
  .exe**</font> file for easy distribution. See a class="blue" href="html/bind.htm">**bind.doc**</a>)

 
 The **Euphoria To C Translator** converts any Euphoria program 
 into a stand-alone
 .exe file, but it has the added advantage of boosting the program's speed
 as well. To use it, you must have one of 7 free C compilers installed on
 your machine, but no knowledge of C is required. 


 The documentation contained in this package comes in both plain text and
 HTML form. The plain text (**.doc**) files can be viewed with any text
 editor, such as Windows NotePad or WordPad. The HTML (**.htm**) files
 can be viewed with your Web browser. A tool that we developed in Euphoria
 allows us to automatically generate both plain text and HTML files, from a
 common source. Thus the content of each file in the
 <font color="#5500FF">**doc**</font> subdirectory should be identical
 to the content of the corresponding file in the
 <font color="#5500FF">**html**</font> subdirectory, aside from the
 lack of links, fonts, colors, etc. See
 <font color="#5500FF">**doc\overview.doc**</font>
 (or a href="html/overview.htm">**html\overview.htm**</a>) for a summary
 of the documentation files.


 You can freely distribute the Euphoria interpreter, and any other files
 contained in this package, in whole or in part, so anyone can run a Euphoria
 program that you have developed. You are completely free to distribute 
 any Euphoria programs that you write.


 To run the <font color="#CC3366">**WIN32**</font> version
 of Euphoria, you need Windows 95 or any later version of Windows.
 It runs fine on XP.


 The <font color="#CC3366">**DOS32**</font> version will run on
 any version of Windows, and will also run on plain DOS
 on any 386 or higher processor. Contrary to popular opinion, DOS is
 not dead. You can run DOS Euphoria programs on Windows XP in a
 command prompt window.


 To run the <font color="#CC3366">**Linux**</font> version of Euphoria
 you need any reasonably up-to-date Linux distribution, that has libc6 or 
 later. For example, Red Hat 5.2 or later will work fine.


 To run the <font color="#CC3366">**FreeBSD**</font> version of Euphoria
 you need any reasonably up-to-date FreeBSD distribution. 



<font face="Arial, Helvetica" color="#FF0099" size=+1>
<br>

<_dul>Getting Started</_dul>

</font>

<table border=0 cellspacing=2 cellpadding=2>

<_2clist
  name="0."
  pos=7
  description="The Euphoria interpreter is an engine for running
  Euphoria programs. It does not have a fancy GUI interface. 
  When you are ready to do Windows GUI
  programming, you should download Judith Evans' IDE (written in open source
  Euphoria code). It will provide you with a very nice graphical
  environment for Windows programming. For most other programming,
  all you really need is an editor, such as NotePad."
 >

<_2clist
  name="1."
  pos=7
  description="After you install Euphoria, the documentation files will be in
   the <font color=\"#5500FF\">**doc**</font> and
   <font color=\"#5500FF\">**html**</font> directories.
a class=\"blue\" href=\"html/overview.htm\">**overview.doc**</a>
 gives an overview of the documentation.
 a href=\"html/refman.htm\">**refman.htm**</a> (or
 <font color=\"#5500FF\">**refman.doc**</font>) should be read first.
 If you want to search for information on any topic, type
 <font color=\"#993333\">**guru**</font>."
 >

<_2clist
  name="2."
  pos=7
  description="Have fun running the programs in the
   <font color=\"#5500FF\">**demo**</font> directory. Feel free to modify
   them, or run them in <font color=\"#993333\">**trace**</font> mode by
   adding:"
 >

<eucode>
        with trace
        trace(1)
</eucode>

<_2clist
  name=""
  pos=7
  description="as the first two lines in the **.ex** or **.exw** file."
 >

<_2clist
  name="3."
  pos=7
  description="Try typing in some simple statements and running them.
   You can use any text editor. Later you may want to use the Euphoria editor,
   <font color=\"#993333\">**ed**</font>, or download David Cuny's
   Euphoria editor from the
   a href=\"http://www.RapidEuphoria.com\">Euphoria Web site</a>.
   
   Don't be afraid to try things. Euphoria won't bite!"
 >

<_2clist
  name="4."
  pos=7
  description="See
a class=\"blue\" href=\"html/what2do.htm\">**what2do.doc**</a>
 for more ideas."
 >

<_2clist
  name="5."
  pos=7
  description="Visit the Euphoria Web site, download some files, and
   subscribe to the Euphoria **mailing list**."
 >

</table>


 If you are new to programming, and you find 
 a href="html/refman.htm">**refman.htm**</a>
 hard to follow, download
 **David Gay**'s interactive tutorial called //"A Beginner's Guide
 To Euphoria"//. It's in the Documentation section of our
 a href="http://www.RapidEuphoria.com/doc.htm">Archive</a>.

&nbsp;<br>
<center>
 <_ba><_ba><_ba> <font face="Arial, Helvetica" color="#003366" size=-1>If
 you have any trouble installing, see a class="blue" href="html/install.htm">
 install.doc</a></font> </_ba></_ba></_ba>
</center>


<hr>

<dl>
<dt>
 **<font face="Arial, Helvetica" color="#006633" size=-1>
 <_dul>Notice to Shareware Vendors:</_dul></font>**
<dd>
  <font face="Arial, Helvetica" size=-1>We encourage you to distribute
  this Euphoria Interpreter package. You can charge whatever you
  like for it. People can use Euphoria for as long as they like without
  obligation.</font>
</dl>

<hr>

<dl>
<dt>
 **<font face="Arial, Helvetica" color="#006633" size=-1>
 <_dul>DISCLAIMER:</_dul></font>**
<dd>
  <font face="Arial, Helvetica" size=-1>
  Euphoria is provided "as is" without warranty of any kind. In no event 
  shall Rapid Deployment Software be held liable for any damages 
  arising from the use of, or inability to use, this product.</font>
</dl>

<hr>

&nbsp;

</_width>
</body>
</html>

