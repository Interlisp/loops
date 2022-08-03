# loops
Repository for LOOPS environment running in Medley
Not ready for prime time: 
still in process of cleaning up and starting to test.

Directories so far

* system -- the Loops core system
   ```
   (CNDIR "your/loops/system")
   (FILESLOAD LOADLOOPS)
   (LOADLOOPS)
    ```
* library
  * (FILESLOAD GAUGELOADER) (LOADGAUGES) to load gauges (loaded by Truckin)
  * (FILESLOAD LOOPSMS) to load masterscope enhancements  (no documentation yet)
   * LOOPSVCOPY (? not used)

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

There are a number of issues already about loading loops and getting Truckin running again, but I thought I'd start with where things are in a 'lmm-loops' branch of the loops repo.

## Files moved to OBSOLETE
* INIT seems to be a copy of JDS INIT file (needed SAMEDIR :smile:)
* Files LOOPS and LOOPS-INSTALL: these seem to be mainly about loading from floppies and copying files around. 

In Library
* LOTSMAP ??
*  MASTERSCOPE, MSANALYZE, MSCOMMON, MSPARSE (these seem to be the same as the versions in medley/library or their ancestors, not a fork).

In users>
* There were files named LOOPSRULES* that were renamed to RULES but the files with the longer names were still there. Patched all references
*  
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

Now trying to figure out why there are three methods on TRUCKIN which are defined as 'FNS'
and not as METHODS:   GameClass.New, GameMasterMeta.New and GameObject.NewInstance.

It might be some kind of initialization problem -- you apparently can't define a method until you define the class. But loading TRUCKIN seems to let me define GameClass.New, but not GameMasterMeta.New (turn the LAMBDA into a METH GlameClass New, change the arglist by removing 'self'. Haven't tried setting GameObject.NewInstance.

I can get TRUCKIN to load; can't compile-file without removing those three names from TRUCKINFNS.
Can't run them interpreted either.

