# loops
Repository for LOOPS environment running in Medley
Not ready for prime time: 
still in process of cleaning up and starting to test.

Directories:

* system -- the Loops core system
   ```
   (CNDIR "your/loops/system")
   (FILESLOAD LOADLOOPS)
   (LOADLOOPS)
    ```

**But note that** if you are using the default Medley sysout, you will be in the `XCL` 
(Xerox Common Lisp) environment, where the above won't work. The right thing to do is
to switch to the `INTERLISP` environment. To do this, right-button the desktop, mouse 
to the `EXEC` item, mouse out to the right, and choose `INTERLISP`. You will be prompted
to position a new executive window, which will be in the `INTERLISP` environment.

However, if you do all this, the above spell still won't work, for reasons which seem 
to imply that `LOADLOOPS` expects an `XCL` environment. If you now switch to your `XCL`
executive window, which you probably still have open, and invoke:

``` lisp
   (IL:LOADLOOPS)
```

Loops will load correctly.

The wrong thing to do, which also works is, from within the `XCL` executive window in
a fresh copy of the Medley sysout:

``` lisp
   (IL:CNDIR "your/loops/system")
   (IL:FILESLOAD LOADLOOPS)
   (IL:LOADLOOPS)
```

This will load the compiled version.

To verify that Loops has indeed loaded and is working, right click on the desktop. An 
item should have been added to the menu, `Loops Logo`; drive out to the right on this item 
and you should see a submenu with items `Browse Class` and `Browse File`. A message will 
appear in the prompt window (black background) "Please tell me the name of the root object"
Enter `Object`, and you should be prompted to position the class browser.

Loading the sources with (LOADLOOPS NIL 'SOURCE) first fails.

LOADLOOPS doesn't seem to load the files in the same order as they appear in LOOPSFILES. 

`(for X in (REVERSE FILELST) when (INFILEP X) do (LOAD X 'PROP))`

will load sources with functions as EXPR properties without overriding compiled versions.



* library
  * (FILESLOAD GAUGELOADER) (LOADGAUGES) to load gauges
     These files are loaded by Truckin so you don't need to do this

  * (FILESLOAD LOOPSMS) to load masterscope enhancements 
     Check out the 'docs' directory
   * LOOPSVCOPY


* users
  * CONVERSION-AIDS (for converting from older versions of Loops)
  * LOOPSBACKWARDS (?)
   * LOOPSMIXIN (?)

* users/rules  -- used by Truckin, several files

* truckin -- the truckin demo
   * truckin/players

To load:
  ```
  conn your/loops/truckin
  (FILESLOAD TRUCKINLOAD)
  (LoadTruckin)
  ```

It will ask if you want to load Players. Say yes.

This ends with a note to load any other players and
```
   (_ ($ Truckin) New)
   (_ PlayerInterface BeginGame)
```

The first returns 
```
#,($& Truckin (|GC^VD84]T1.0.0.TO>| . 1247)
```
or some such, which I assume is some representation of a unique ID.
The Second though seems to create players with name NIL.


There are a number of issues already about loading loops and getting Truckin running again, but I thought I'd start with where things are in a 'lmm-loops' branch of the loops repo.

Newly imported and not vetted:

* doc directory
Contains files, manuals, packing instructions, emails discussing PCL and CommonLoops and/or CLOS.... need to sort out.

* test directory
Contains test and timing information... also need to sort out.


## History

## Files moved to OBSOLETE
* INIT seems to be a copy of JDS INIT file (needed SAMEDIR :smile:)
* Files LOOPS and LOOPS-INSTALL: these seem to be mainly about loading from floppies and copying files around. 

In Library
* LOTSMAP ??
*  MASTERSCOPE, MSANALYZE, MSCOMMON, MSPARSE (these seem to be the same as the versions in medley/library or their ancestors, not a fork).

In users>

* There were files named LOOPSRULES* that were renamed to RULES but the files with the longer names were still there. Patched all references


## Files updated recently

* Everything CL:COMPILE-FILEd (old DFASLs were for previous Medley versions)
* LOADLOOPS (non-essential changes)
  * Puzzle: \TopLevelTtyWindow is Common Lisp window even if you're running in a different exec; WITHOUT-PAGEHOLD should be defined/used everywhere
  * GAUGELOADER had comment in the middle of Interlisp VARS (not allowed)
  * 

## Files different between 1.1 and 2.0 release

## Other glitches

* Some READMACROS are established during loadup and COMPAREDIRECTORIES doesn't work unless it's loaded.

* somewhere the variable 'space' is declared a CONSTANT and compiling LOOPSBROWSE complained. The workaround for now was to change 'space' to 'spaces' in \Place-Menu-Group-In-Window. For some reason this wounds up adding an extra NIL inside a DEFCLASS (I think).

## Comparing to previous released Loops

```
(FILESLOAD GITFNS)
(CDBROWSER (COMPAREDIRECTORIES "git-loops/system/" "envos/xd0e/release/loops/2.0/src"))
(CDBROWSER (COMPAREDIRECTORIES "git-loops/library/" "envos/xd0e/release/loops/2.0/library-src/"))
(CDBROWSER (COMPAREDIRECTORIES "git-loops/users/" "envos/xd0e/release/loops/2.0/users/"))
(CDBROWSER (COMPAREDIRECTORIES "git-loops/truckin/" "envos/xd0e/release/loops/2.0/truckin-src/"))
```
![image](https://user-images.githubusercontent.com/1116587/182531792-9fce4755-1ae7-418d-9a2e-3f6b54eef609.png)


## Remaining problems

Now trying to figure out why there are three methods on TRUCKIN which are defined as 'FNS' and not as METHODS:   GameClass.New, GameMasterMeta.New and GameObject.NewInstance.

It might be some kind of initialization problem -- you apparently can't define a method until you define the class. But loading TRUCKIN seems to let me define GameClass.New, but not GameMasterMeta.New (turn the LAMBDA into a METH GlameClass New, change the arglist by removing 'self'. Haven't tried setting GameObject.NewInstance.

I can get TRUCKIN to load; can't compile-file without removing those three names from TRUCKINFNS or addin them to DONTCOMPILEFNS.

Can't run them interpreted either?


