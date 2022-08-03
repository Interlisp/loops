;;;-*-Mode:LISP; Package:(PCL (LISP WALKER) 1000); Base:10; Syntax:Common-lisp -*-
;;;
;;; *************************************************************************
;;; Copyright (c) 1985, 1986, 1987, 1988 Xerox Corporation.
;;; All rights reserved.
;;;
;;; Use and copying of this software and preparation of derivative works
;;; based upon this software are permitted.  Any distribution of this
;;; software or derivative works must comply with all applicable United
;;; States export control laws.
;;; 
;;; This software is made available AS IS, and Xerox Corporation makes no
;;; warranty about the software, its performance or its conformity to any
;;; specification.
;;; 
;;; Any person obtaining a copy of this software is requested to send their
;;; name and post office or electronic mail address to:
;;;   CommonLoops Coordinator
;;;   Xerox PARC
;;;   3333 Coyote Hill Rd.
;;;   Palo Alto, CA 94304
;;; (or send Arpanet mail to CommonLoops-Coordinator.pa@Xerox.arpa)
;;;
;;; Suggestions, comments and requests for improvements are also welcome.
;;; *************************************************************************
;;;
;;; This file contains portable versions of low-level functions and macros
;;; which are ripe for implementation specific customization.  None of the
;;; code in this file *has* to be customized for a particular Common Lisp
;;; implementation. Moreover, in some implementations it may not make any
;;; sense to customize some of this code.
;;;
;;; But, experience suggests that MOST Common Lisp implementors will want
;;; to customize some of the code in this file to make PCL run better in
;;; their implementation.  The code in this file has been separated and
;;; heavily commented to make that easier.
;;;
;;; Implementation-specific version of this file already exist for:
;;; 
;;;    Symbolics 3600 family       3600-low.lisp
;;;    Lucid Lisp                  lucid-low.lisp
;;;    Xerox 1100 family           xerox-low.lisp
;;;    ExCL (Franz)                excl-low.lisp
;;;    Kyoto Common Lisp           kcl-low.lisp
;;;    Vaxlisp                     vaxl-low.lisp
;;;    CMU Lisp                    cmu-low.lisp
;;;    H.P. Common Lisp            hp-low.lisp
;;;    Golden Common Lisp          gold-low.lisp
;;;    Ti Explorer                 ti-low.lisp
;;;    
;;;
;;; These implementation-specific files are loaded after this file.  Because
;;; none of the macros defined by this file are used in functions defined by
;;; this file the implementation-specific files can just contain the parts of
;;; this file they want to change.  They don't have to copy this whole file
;;; and then change the parts they want.
;;;
;;; If you make changes or improvements to these files, or if you need some
;;; low-level part of PCL re-modularized to make it more portable to your
;;; system please send mail to CommonLoops.pa@Xerox.com.
;;;
;;; Thanks.
;;; 

(in-package 'pcl)

;;;
;;; Primitive run time operations.
;;;
;;; The PCL runtime has some critical code sequences whose performance is
;;; critical to the performance of any program written in PCL.  These code
;;; sequences are the ones which do various kinds of cache lookups and PCL
;;; instance accesses.
;;;
;;; To get the maximum performance out of any PCL port, the following low
;;; level runtime operations should be implemented for that port.  The
;;; definitions should be put in the front of that port's xxx-low file.
;;;
;;; The intention is that these operations should be implemented by the
;;; simplest possible machine instruction that implements them.  No error
;;; checking of arguments need be done at all.  PCL guarantees that the
;;; arguments will be of the correct type, and that no array bounds errors
;;; will occur.
;;;
;;; *** Remaining issues:
;;; ***  access to iwmc-class components
;;; ***  funcalling without type checking
;;; ***
;;; 

(defmacro %logand (&rest args)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    ,(reduce-variadic-to-binary 'logand args -1 t 'fixnum)))

(defmacro %logxor (&rest args)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    ,(reduce-variadic-to-binary 'logxor args 0 t 'fixnum)))

(defmacro %+ (&rest args)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    ,(reduce-variadic-to-binary '+ args 0 t 'fixnum)))

(defmacro %- (x y)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    (the fixnum (- (the fixnum ,x) (the fixnum ,y)))))

(defmacro %* (&rest args)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    ,(reduce-variadic-to-binary '* args 1 t 'fixnum)))

(defmacro %/ (x y)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    (the fixnum (/ (the fixnum ,x) (the fixnum ,y)))))

(defmacro %1+ (x)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    (the fixnum (1+ (the fixnum ,x)))))

(defmacro %1- (x)
  `(locally (declare (optimize (speed 3) (safety 0)))
	    (the fixnum (1- (the fixnum ,x)))))

(defmacro %zerop (x)
  `(zerop (the fixnum ,x)))

(defmacro %= (x y)
  `(= (the fixnum ,x) (the fixnum ,y)))

(defmacro %< (x y)
  `(< (the fixnum ,x) (the fixnum ,y)))

(defmacro %> (x y)
  `(> (the fixnum ,x) (the fixnum ,y)))

(defmacro %ash (x count)
  `(the fixnum (ash (the fixnum ,x ) ,count)))

(defmacro %mod (number divisor)
  `(mod (the fixnum ,number) (the fixnum ,divisor)))

(defmacro %floor (number divisor)
  `(floor (the fixnum ,number) (the fixnum ,divisor)))

(defmacro %svref (vector index)
  `(locally (declare (optimize (speed 3) (safety 0))
		     (inline svref))
	    (svref (the simple-vector ,vector) (the fixnum ,index))))

(defsetf %svref (vector index) (new-value)
  `(locally (declare (optimize (speed 3) (safety 0))
		     (inline svref))
     (setf (svref (the simple-vector ,vector) (the fixnum ,index))
	   ,new-value)))

(defun make-%+ (x constant)
  (check-type constant fixnum "a fixnum")
  (cond ((zerop constant) x)
	((= constant 1) `(%1+ ,x))
	(t `(%+ ,constant ,x))))

;;;
;;; This support function may be useful for ports which are redefining
;;; the primitive math and logic operations.
;;; 
(defun reduce-variadic-to-binary
       (binary-op args default identity-with-one-argument-p type)
  (labels ((bin (args)
 	     (if (null (cdr args))
 		 `(the ,type ,(car args))
 		 `(the ,type (,binary-op (the ,type ,(car args))
					 ,(bin (cdr args)))))))
    (cond ((null args)
	   `(the ,type ,default))
	  ((and identity-with-one-argument-p
		(null (cdr args)))
	   `(the ,type ,(car args)))
	  (t (bin args)))))



;;;
;;; without-interrupts
;;; 
;;; OK, Common Lisp doesn't have this and for good reason.  But For all of
;;; the Common Lisp's that PCL runs on today, there is a meaningful way to
;;; implement this.  WHAT I MEAN IS:
;;;
;;; I want the body to be evaluated in such a way that no other code that is
;;; running PCL can be run during that evaluation.  I agree that the body
;;; won't take *long* to evaluate.  That is to say that I will only use
;;; without interrupts around relatively small computations.
;;;
;;; INTERRUPTS-ON should turn interrupts back on if they were on.
;;; INTERRUPTS-OFF should turn interrupts back off.
;;; These are only valid inside the body of WITHOUT-INTERRUPTS.
;;;
;;; OK?
;;;
(defmacro without-interrupts (&body body)
  `(macrolet ((interrupts-on () ())
	      (interrupts-off () ()))
     (progn ,.body)))


;;;
;;; Memory Blocks (array-like blocks of memory)
;;; 
;;; The portable implementation of memory-blocks is as arrays.
;;;
;;; The area argument to make-memory-block is based on the area feature of
;;; LispM's.  As it is used in PCL that argument will always be an unquoted
;;; symbol.  So a call to make-memory-block will look like:
;;;     (make-memory-block 100 class-wrapper-area)
;;; This allows any particular implementation of make-memory-block to look at
;;; the symbol at compile time (macroexpand time) and know where the memory-
;;; block should be consed.  Currently the only values ever used as the area
;;; argument are:
;;; 
;;;    CLASS-WRAPPER-AREA        used when making a class-wrapper
;;;
;;; NOTE:
;;;     It is perfectly legitimate for an implementation of make-memory-block
;;;     to ignore the area argument.  It only exists to try to improve paging
;;;     performance in systems which do allow control over where memory is
;;;     allocated.
;;; 
(defmacro make-memory-block (size &optional area)
  (declare (ignore area))
  `(make-array ,size :initial-element nil))

;(defmacro memory-block-size (block)
;  `(array-dimension ,block 0))

(defmacro memory-block-ref (block offset)
  `(locally
     (declare (optimize (speed 3) (safety 0))
	      (inline svref))
     (svref (the simple-vector ,block) (the fixnum ,offset))))

(defsetf memory-block-ref (block offset) (new-value)
  `(locally
     (declare (optimize (speed 3) (safety 0)))
     (setf (svref (the simple-vector ,block) (the fixnum ,offset))
	   ,new-value)))

(eval-when (compile load eval)

(defun make-cache-mask (size &optional (words-per-entry 2))
  (let ((offset-mask 1) 
	(entry-mask 1))
	
    (loop (when (>= offset-mask size) (return))
	  (setq offset-mask (* offset-mask 2)))

    (loop (when (>= entry-mask words-per-entry) (return))
	  (setq entry-mask (* entry-mask 2)))

    (logxor (1- offset-mask)
	    (1- entry-mask))))

(defmacro make-memory-block-mask (size &optional (words-per-entry 2))
  (warn "make-memory-block-mask is obsolete use make-cache-mask")
  `(make-cache-mask ,size ,words-per-entry))

)

;;;
;;; clear-memory-block sets all the slots of a memory block to nil starting
;;; at start.  This really shouldn't be a macro, it should be a function.
;;; It has to be a macro because otherwise its call to memory-block-ref will
;;; get compiled before people get a chance to change memory-block-ref.
;;; This argues one of:
;;;  - this should be a function in another file.  No, it belongs here.
;;;  - Common Lisp should have defsubst.  Probably
;;;  - Implementors should take (proclaim '(inline xxx)) more seriously.
;;;  
(defmacro clear-memory-block (block start &optional times)
  (once-only (block)
    `(do ((end ,(if times `(+ ,start ,times) `(length ,block)))
	  (index ,start (+ index 1)))
	 ((= index end))
       (setf (memory-block-ref ,block index) nil))))

  ;;   
;;;;;; CLASS-OF
  ;;
;;;
;;; *class-of* is the lisp code for the definition of class-of.
;;; *wrapper-of* is the lisp code for the definition of wrapper-of.
;;;
;;; The definition of *class-of* and *wrapper-of* is used in the braid1.lisp
;;; file to actually define these functions.  Having the actually compilation
;;; of these functions happen later allows macros which have not yet been
;;; defined or which are going to be redefined to appear later.
;;;
;;; All such macros must be defined before braid1.lisp is compiled.
;;; 
;;; The definition for built-in-class-of and built-in-class-wrapper appear
;;; in high.lisp.
;;; 
(defvar *class-of*
	'(lambda (x)
	   (or (and (iwmc-class-p x)
		    (wrapper-class (iwmc-class-class-wrapper x)))
	       (and (funcallable-instance-p x)
		    (funcallable-instance-class x))
	       (built-in-class-of x)
	       (error "Can't determine class of ~S" x))))

(defvar *wrapper-of*
	'(lambda (x)
	   (or (and (iwmc-class-p x)
		    (iwmc-class-class-wrapper x))
	       (and (funcallable-instance-p x)
		    (funcallable-instance-wrapper x))
	       (built-in-wrapper-of x)
	       (error "Can't determine class of ~S" x))))

(defun built-in-wrapper-of (x)                                  ;Bootstrapping
  (and (symbolp x) (class-wrapper (find-class 'symbol))))

(defun built-in-class-of (x)			                ;Bootstrapping
  (and (symbolp x) (find-class 'symbol)))

(defmacro class-of-1 (x)
  (once-only (x)
    `(or (and (iwmc-class-p ,x)
	      (wrapper-class (iwmc-class-class-wrapper ,x)))
	 (and (funcallable-instance-p ,x)
	      (funcallable-instance-class ,x))
	 (class-of ,x))))

(defmacro wrapper-of-1 (x)
  (once-only (x)
    `(or (and (iwmc-class-p ,x)
	      (iwmc-class-class-wrapper ,x))
	 (and (funcallable-instance-p ,x)
	      (funcallable-instance-wrapper ,x))
	 (wrapper-of ,x))))

(defmacro wrapper-of-2 (x)
  (once-only (x)
    `(or (and (iwmc-class-p ,x)
	      (iwmc-class-class-wrapper ,x))
	 (wrapper-of ,x))))

  ;;
;;;;;;  Very Low-Level representation of instances with meta-class class.
  ;;
;;; As shown below, an instance with meta-class class (iwmc-class) is a three
;;; *slot* structure.
;;;   
;;; 
;;;                                             /------["Class"]
;;;                  /-------["Class Wrapper"  /  <slot-and-method-cache>]
;;;                 /
;;;  Instance--> [ / , \  ,  \ ]
;;;                     \     \
;;;                      \     \---[Instance Slot Storage Block]
;;;                       \
;;;                        \-------[Dynamic Slot plist]
;;;
;;; Instances with meta-class class point to their class indirectly through
;;; the class's class wrapper (each class has one class wrapper, not each
;;; instance).  This is done so that all the extant instances of a class can
;;; have the class they point to changed quickly.  See change-class.
;;;
;;; Static-slots are a 1-d-array-like structure.
;;; The default PCL implementation is as a memory block as described above.
;;; Particular ports are free to change this to a lower-level block of memory
;;; type structure. Once again, the accessor for static-slots storage doesn't
;;; need to do bounds checking, and static-slots structures don't need to be
;;; able to change size.  This is because new slots are added using the
;;; dynamic slot mechanism, and if the class changes or the class of the
;;; instance changes a new static-slot structure is allocated (if needed).
;;
;;; Dynamic-slots are a plist-like structure.
;;; The default PCL implementation is as a plist.
;;;
;;; *** Put a real discussion here of where things should be consed.
;;;  - if all the class wrappers in the world are on the same page that
;;;    would be good because during method lookup we only use the wrappers
;;;    not the classes and once a slot is cached, we only use the wrappers
;;;    too.  So a page of just wrappers would stay around all the time and
;;;    you would never have to page in the classes at least in "tight" loops.
;;;

(defstruct (iwmc-class (:predicate iwmc-class-p)
		       (:conc-name %iwmc-class-)
		       (:constructor %%allocate-instance--class ())
		       (:print-function print-iwmc-class))
  (class-wrapper nil)
  (static-slots nil))

(defmacro iwmc-class-class-wrapper (x) `(%iwmc-class-class-wrapper ,x))
(defmacro iwmc-class-static-slots (x) `(%iwmc-class-static-slots ,x))

(defun print-iwmc-class (instance stream depth) ;This is a temporary definition
  (declare (ignore depth))		        ;used mostly for debugging the
  (printing-random-thing (instance stream)      ;bootstrapping code.
    (format stream "instance ??")))

(defmacro %allocate-instance--class (no-of-slots)
  `(let ((iwmc-class (%%allocate-instance--class)))
     (%allocate-instance--class-1 ,no-of-slots iwmc-class)
     iwmc-class))

(defmacro %allocate-instance--class-1 (no-of-slots instance)
  (once-only (instance)
    `(progn 
       (setf (iwmc-class-static-slots ,instance)
	     (%allocate-static-slot-storage--class ,no-of-slots)))))

;;;
;;; This is the value that we stick into a slot to tell us that it is unbound.
;;; It may seem gross, but for performance reasons, we make this an interned
;;; symbol.  That means that the fast check to see if a slot is unbound is to
;;; say (EQ <val> '..SLOT-UNBOUND..).  That is considerably faster than looking
;;; at the value of a special variable.  Be careful, there are places in the
;;; code which actually use ..slot-unbound.. rather than this variable.  So
;;; much for modularity
;;; 
(defvar *slot-unbound* '..slot-unbound..)

(defmacro %allocate-static-slot-storage--class (no-of-slots)
  `(make-array ,no-of-slots :initial-element *slot-unbound*))


(defmacro class-of--class (iwmc-class)
  `(wrapper-class (iwmc-class-class-wrapper ,iwmc-class)))


;;;
;;; class wrappers
;;;
;;;
(eval-when (compile load eval)

(defconstant class-wrapper-size 4
  "The number of elements of a class wrapper.")

)


(defmacro make-class-wrapper (class)
  `(let ((wrapper (make-memory-block ,class-wrapper-size)))
     (setf (wrapper-cache-no wrapper) (get-next-wrapper-cache-no))
     (setf (wrapper-class wrapper) ,class)
     wrapper))

;;;
;;; The order these appear in is important.  Specifically, when we are after
;;; the wrapper, we are usually in a hurry.  Putting it in slot 0 may avoid
;;; the need for an extra addition (is this ever true in practise?).
;;; 
(defmacro wrapper-cache-no (wrapper)
  `(the fixnum (memory-block-ref ,wrapper 0)))

(defmacro wrapper-instance-slots-layout (wrapper)
  `(memory-block-ref ,wrapper 1))

(defmacro wrapper-class-slots (wrapper)
  `(memory-block-ref ,wrapper 2))

(defmacro wrapper-class (wrapper)
  `(memory-block-ref ,wrapper 3))


;;; This is new
(defmacro validate-wrapper (instance-var wrapper-var)	;HAS to be a macro!
						        ;So that xxx-low file
						        ;can redefine macros
						        ;we use.
  (check-type instance-var symbol "the variable storing the instance")
  (check-type wrapper-var symbol "the variable storing the wrapper")
  `(let ((.cache-no. (wrapper-cache-no ,wrapper-var)))
     (when (zerop .cache-no.)
       (setq ,wrapper-var (obsolete-instance-trap ,wrapper-var ,instance-var)
	     .cache-no. (wrapper-cache-no ,wrapper-var)))
     .cache-no.))

(defmacro invalidate-wrapper (wrapper)
  `(setf (wrapper-cache-no ,wrapper) 0))


  ;;   
;;;;;; Generating CACHE numbers
  ;;
;;; These macros should produce a CACHE number for their first argument
;;; masked to fit in their second argument.  A useful cache number is just
;;; the symbol or object's memory address.  The memory address can either
;;; be masked to fit the mask or folded down with xor to fit in the mask.
;;; See some of the other low files for examples of how to implement these
;;; macros. Except for their illustrative value, the portable versions of
;;; these macros are nearly worthless.  Any port of CommonLoops really
;;; should redefine these to be faster and produce more useful numbers.

;(defvar *warned-about-symbol-cache-no* nil)
(defvar *warned-about-object-cache-no* nil)

;(defmacro symbol-cache-no (symbol mask)
;  (unless *warned-about-symbol-cache-no*
;    (setq *warned-about-symbol-cache-no* t)
;    (warn
;      "Compiling PCL without having defined an implementation-specific~%~
;       version of SYMBOL-CACHE-NO.  This is likely to have a significant~%~
;       effect on slot-access performance.~%~
;       See the definition of symbol-cache-no in the file low to get an~%~
;       idea of how to implement symbol-cache-no."))
;  `(logand (sxhash ,symbol) ,mask))

(defmacro object-cache-no (object mask)
  (declare (ignore object))
  (unless *warned-about-object-cache-no*
    (setq *warned-about-object-cache-no* t)
    (warn
      "Compiling PCL without having defined an implementation-specific~%~
       version of OBJECT-CACHE-NO.  This effectively disables method.~%~
       lookup caching.  See the definition of object-cache-no in the file~%~
       low to get an idea of how to implement object-cache-no."))
  `(logand 0 ,mask))

  ;;   
;;;;;; FUNCTION-ARGLIST
  ;;
;;; Given something which is functionp, function-arglist should return the
;;; argument list for it.  PCL does not count on having this available, but
;;; MAKE-SPECIALIZABLE works much better if it is available.  Versions of
;;; function-arglist for each specific port of pcl should be put in the
;;; appropriate xxx-low file. This is what it should look like:
;(defun function-arglist (function)
;  (<system-dependent-arglist-function> function))

(defun function-pretty-arglist (function)
  (declare (ignore function))
  ())

(defsetf function-pretty-arglist set-function-pretty-arglist)

(defun set-function-pretty-arglist (function new-value)
  (declare (ignore function))
  new-value)

;;;
;;; set-function-name
;;; When given a function should give this function the name <new-name>.
;;; Note that <new-name> is sometimes a list.  Some lisps get the upset
;;; in the tummy when they start thinking about functions which have
;;; lists as names.  To deal with that there is set-function-name-intern
;;; which takes a list spec for a function name and turns it into a symbol
;;; if need be.
;;;
;;; When given a funcallable instance, set-function-name MUST side-effect
;;; that FIN to give it the name.  When given any other kind of function
;;; set-function-name is allowed to return new function which is the 'same'
;;; except that it has the name.
;;;
;;; In all cases, set-function-name must return the new (or same) function.
;;; 
(defun set-function-name (function new-name)
  (declare (notinline set-function-name-1 intern-function-name))
  (set-function-name-1 function
		       (intern-function-name new-name)
		       new-name))

(defun set-function-name-1 (function new-name uninterned-name)
  (declare (ignore new-name uninterned-name))
  function)

(defun intern-function-name (name)
  (cond ((symbolp name) name)
	((listp name)
	 (intern (let ((*package* *the-pcl-package*)
		       (*print-case* :upcase)
		       (*print-gensym* 't))
		   (format nil "~S" name))
		 *the-pcl-package*))))


;;;
;;; COMPILE-LAMBDA
;;;
;;; This is like the Common Lisp function COMPILE.  In fact, that is what
;;; it ends up calling.  The difference is that it deals with things like
;;; watching out for recursive calls to the compiler or not calling the
;;; compiler in certain cases or allowing the compiler not to be present.
;;;
;;; This starts out with several variables and support functions which 
;;; should be conditionalized for any new port of PCL.  Note that these
;;; default to reasonable values, many new ports won't need to look at
;;; these values at all.
;;;
;;; *COMPILER-PRESENT-P*        NIL means the compiler is not loaded
;;;
;;; *COMPILER-SPEED*            one of :FAST :MEDIUM or :SLOW
;;;
;;; *COMPILER-REENTRANT-P*      T   ==> OK to call compiler recursively
;;;                             NIL ==> not OK
;;;
;;; function IN-THE-COMPILER-P  returns T if in the compiler, NIL otherwise
;;;                             This is not called if *compiler-reentrant-p*
;;;                             is T, so it only needs to be implemented for
;;;                             ports which have non-reentrant compilers.
;;;
;;;
(defvar *compiler-present-p* t)

(defvar *compiler-speed*
	#+(or KCL IBCL GCLisp) :slow
	#-(or KCL IBCL GCLisp) :fast)

(defvar *compiler-reentrant-p*
	#+(and (not XKCL) (or KCL IBCL)) nil
	#-(and (not XKCL) (or KCL IBCL)) t)

(defun in-the-compiler-p ()
  #+(and (not xkcl) (or KCL IBCL))compiler::*compiler-in-use*
  )

(defun compile-lambda (lambda &optional (desirability :fast))
  (cond ((null *compiler-present-p*)
	 (compile-lambda-uncompiled lambda))
	((and (null *compiler-reentrant-p*)
	      (in-the-compiler-p))
	 (compile-lambda-deferred lambda))
	((eq desirability :fast)
	 (compile nil lambda))
	((and (eq desirability :medium)
	      (member *compiler-speed* '(:fast medium)))
	 (compile nil lambda))
	((and (eq desirability :slow)
	      (eq *compiler-speed* ':fast))
	 (compile nil lambda))
	(t
	  (compile-lambda-uncompiled lambda))))

(defun compile-lambda-uncompiled (uncompiled)
  #'(lambda (&rest args) (apply uncompiled args)))

(defun compile-lambda-deferred (uncompiled)
  (let ((compiled nil))
    #'(lambda (&rest args)
	(if compiled
	    (apply compiled args)
	    (if (in-the-compiler-p)
		(apply uncompiled args)
		(progn (setq compiled (compile nil uncompiled))
		       (apply compiled args)))))))


  ;;   
;;;;;; Templated functions
  ;;   
;;; In CommonLoops there are many program-generated functions which
;;; differ from other, similar program-generated functions only in the
;;; values of certain in-line constants.
;;;
;;; A prototypical example is the family of discriminating functions used by
;;; classical generic functions.  For all classical generic-functions which
;;; have the same number of required arguments and no &rest argument, the
;;; discriminating function is the same, except for the value of the
;;; "in-line" constants (the cache and generic-function).
;;;
;;; Naively, whenever we want one of these functions we have to produce and
;;; compile separate lambda. But this is very expensive, instead what we
;;; would like to do is copy the existing compiled code and replace the
;;; values of the inline constants with the right new values.
;;;
;;; Templated functions provide a nice interface to this abstraction of
;;; copying an existing compiled function and replacing certain constants
;;; with others.  Templated functions are based on the assumption that for
;;; any given CommonLisp one of the following is true:
;;;   Either:
;;;     Funcalling a lexical closure is fast, and lexical variable access
;;;     is as fast (or about as fast) in-line constant access.  In this
;;;     case we implement templated functions as lexical closures closed
;;;     over the constants we want to change from one instance of the
;;;     templated function to another.
;;;   Or:
;;;     Code can be written to take a compiled code object, copy it and
;;;     replace references to certain in-line constants with references
;;;     to other in-line constants.
;;;
;;; Actually, I believe that for most Lisp both of the above assumptions are
;;; true.  For certain lisps the explicit copy and replace scheme *may be*
;;; more efficient but the lexical closure scheme is completely portable and
;;; is likely to be more efficient since the lexical closure it returns are
;;; likely to share compiled code objects and only have separate lexical
;;; environments.
;;;
;;; Another thing to notice about templated functions is that they provide
;;; the modularity to support special objects which a particular
;;; implementation's low-level function-calling code might know about.   As
;;; an example, when a classical discriminating function is created, the
;;; code says "make a classical discriminating function with 1 required
;;; arguments". It then uses whatever comes back from the templated function
;;; code as the the discriminating function So, a particular port can easily
;;; make this return any sort of special data structure instead of one of
;;; the lexical closures the portable implementation returns.
;;;
(defvar *templated-function-types* ())
(defmacro define-function-template (name
				    template-parameters
				    instance-parameters
				    &body body)
  `(eval-when (compile load eval)
     (pushnew ',name *templated-function-types*)
     ;; Get rid of all the cached constructors.
     (setf (get ',name 'templated-fn-constructors) ())
     ;; Now define the constructor constructor.
     (setf (get ',name 'templated-fn-params)
	   (list* ',template-parameters ',instance-parameters ',body))
     (setf (get ',name 'templated-fn-constructor-constructor)
	   ,(make-templated-function-constructor-constructor
	      template-parameters instance-parameters body))))

(defun reset-templated-function-types ()
  (dolist (type *templated-function-types*)
    (setf (get type 'templated-fn-constructors) ())))

(defun get-templated-function-constructor (name &rest template-parameters)
  (setq template-parameters (copy-list template-parameters)) ;Groan.
  (let ((existing (assoc template-parameters
			 (get name 'templated-fn-constructors)
			 :test #'equal)))
    (if existing
	(progn (setf (nth 3 existing) t)	;Mark this constructor as
						;having been used.
	       (cadr existing))			;And return the actual
						;constructor.
	(let ((new-constructor
		(apply (get name 'templated-fn-constructor-constructor)
		       template-parameters)))
	  (push (list template-parameters new-constructor 'made-on-the-fly t)
		(get name 'templated-fn-constructors))
	  new-constructor))))

(defmacro pre-make-templated-function-constructor (name
						   &rest template-parameters)
  (setq template-parameters (copy-list template-parameters))	;Groan.
  `(pre-make-templated-function-constructor-internal ,name
						     'pre-made
						     ,template-parameters))

(defmacro compile-templated-function-constructors ()
  (let ((forms ()))
    (dolist (type *templated-function-types*)
      (dolist (e (get type 'templated-fn-constructors))
	(unless (eq (caddr e) 'pre-made)
	  (push `(pre-make-templated-function-constructor-internal ,type
								   'compiled
								   ,(car e))
		forms))))
    `(eval-when (load) ,.forms)))

(defmacro precompile-random-code-segments ()
  '(progn 
     (compile-templated-function-constructors)
     (compile-effective-method-templates)
     ))

(defmacro pre-make-templated-function-constructor-internal
	  (name pre-make-id template-parameters)
  (let* ((params (get name 'templated-fn-params))
	 (template-params (car params))
	 (instance-params (cadr params))
	 (body (cddr params))
	 #+Genera
	 (dummy-fn-name (gensym))
	 (form 
	   (progv template-params
		  template-parameters
	    `(let ((entry
		     (or (assoc ',template-parameters 
				(get ',name 'templated-fn-constructors)
				:test #'equal)
			 (let ((new-entry
				 (list ',template-parameters () () ())))
			   (push new-entry
				 (get ',name 'templated-fn-constructors))
			   new-entry))))
	       (setf (caddr entry) ,pre-make-id)
	       (setf (cadr entry)
		     (function (lambda ,(eval instance-params)
				 ,(eval (cons 'progn body)))))))))
    ;;
    ;; This one may be superfluous.
    ;; 
    #+Genera
    `(progn (defun ,dummy-fn-name () ,form)
	    (,dummy-fn-name))
    #-Genera
    form))

(defvar *compile-templated-function-constructor-constructor* 'compile-lambda)

(defun dont-compile (lambda &optional desirability)
  (declare (ignore desirability))
  lambda)

(defun compile-templated-function-constructor-constructors (compilep)
  (reset-templated-function-types)
  (setq *compile-templated-function-constructor-constructor*
	(if compilep
	    'compile-lambda
	    'dont-compile)))

(defun make-templated-function-constructor-constructor (template-params
							instance-params
							body)
  (let ((cc `(function
	       (lambda ,template-params
		 (,*compile-templated-function-constructor-constructor*
		  (list 'lambda ,instance-params ,@body))))))
    cc))

(defun show-templated-function-types ()
  (dolist (type *templated-function-types*)
    (format t "~%Type: ~S" type)
    (dolist (c (get type 'templated-fn-constructors))
      (format t "~&  ~S ~30T~S ~35T~S" (car c) (cadddr c) (caddr c)))))



(defun record-definition (type spec &rest args)
  (declare (ignore type spec args))
  ())
