;;; -*- Mode:LISP; Package:(PCL Lisp 1000); Base:10.; Syntax:Common-lisp -*-
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
;;; This is the 1100 (Xerox version) of the file portable-low.
;;;

(in-package 'pcl)

(defmacro load-time-eval (form)
  `(il:LOADTIMECONSTANT ,form))

  ;;   
;;;;;; Memory block primitives.
  ;;

; what I have done is to replace all calls to il:\\RPLPTR with a call to
; RPLPTR (in the PCL) package.  RPLPTR is a version which does some error
; checking and then calls il:\\RPLPTR.  As follows:

;(defun rplptr (block index value)
;  (if (< index (* (il:\\#blockdatacells block) 2))
;      (il:\\rplptr block index value)
;      (error "bad args to rplptr")))

;(defmacro make-memory-block (size &optional area)
;  `(il:\\allocblock ,size T))
;
;(defmacro memory-block-ref (block offset)
;  `(il:\\GETBASEPTR ,block (* ,offset 2)))
;
;(defsetf memory-block-ref (memory-block offset) (new-value)
;  `(il:\\rplptr ,memory-block (* ,offset 2) ,new-value))
;
;(defmacro memory-block-size (block)
;  ;; this returns the amount of memory allocated for the block --
;  ;; it may be larger than size passed at creation
;  `(il:\\#BLOCKDATACELLS ,block))
;
;(defmacro clear-memory-block (block start &optional times)
;  (let ((base (make-symbol "BLOCK")))
;    `(let ((,base ,block))
;       (do ((end ,(if times `(* (+ ,start ,times) 2)
;                            `(* (il:\\#BLOCKDATACELLS ,base) 2)))
;            (index (* ,start 2) (+ index 2)))
;	      ((= index end))
;	    (il:\\RPLPTR ,base index nil)))))

;;;
;;; make the pointer from an instance to its class wrapper be an xpointer.
;;; this prevents instance creation from spending a lot of time incrementing
;;; the large refcount of the class-wrapper.  This is safe because there will
;;; always be some other pointer to the wrapper to keep it around.
;;; 
#+Xerox-Medley
(defstruct (iwmc-class (:predicate iwmc-class-p)
		        (:conc-name %iwmc-class-)
		        (:constructor %%allocate-instance--class ())
			(:fast-accessors t)
		        (:print-function %print-iwmc-class))
  (class-wrapper nil :type il:fullxpointer)
  (static-slots nil))

#+Xerox-Lyric
(eval-when (eval load compile)
  (il:datatype iwmc-class
	       ((class-wrapper il:fullxpointer)
	        static-slots))

  (xcl:definline iwmc-class-p (x)
    (typep x 'iwmc-class))

  (xcl:definline %%allocate-instance--class ()
    (il:create iwmc-class))

  (xcl:definline %iwmc-class-class-wrapper (x) 
    (il:fetch (iwmc-class class-wrapper) il:of x))

  (xcl:definline %iwmc-class-static-slots (x) 
    (il:fetch (iwmc-class static-slots) il:of x))

  (xcl:definline set-%iwmc-class-class-wrapper (x value) 
    (il:replace (iwmc-class class-wrapper) il:of x il:with value))

  (xcl:definline set-%iwmc-class-static-slots (x value) 
    (il:replace (iwmc-class static-slots) il:of x il:with value))

  (defsetf %iwmc-class-class-wrapper set-%iwmc-class-class-wrapper)

  (defsetf %iwmc-class-static-slots set-%iwmc-class-static-slots)

  (il:defprint 'iwmc-class '%print-iwmc-class)

  )

(defun %print-iwmc-class (instance &optional stream depth)
  ;; See the IRM, section 25.3.3.  Unfortunatly, that documentation is
  ;; not correct.  In particular, it makes no mention of the third argument.
  (cond ((streamp stream)
	 ;; Use the standard PCL printing method, then return T to tell
	 ;; the printer that we have done the printing ourselves.
	 (print-iwmc-class instance stream depth)
	 t)
	(t 
	 ;; Internal printing (again, see the IRM section 25.3.3). 
	 ;; Return a list containing the string of characters that
	 ;; would be printed, if the object were being printed for
	 ;; real.
	 (list (with-output-to-string (stream)
		 (print-iwmc-class instance stream depth))))))

  ;;   
;;;;;; Static slot storage primitives
  ;;   

;;;
;;; Once everything sees to work, uncomment this back into play and remove
;;; the * 2 in the other places.
;;;
;(eval-when (compile load eval)
;  (if nil ;if this is T, then %convert-slotd-position-to-slot-index
;          ;will do the multiplication.  Otherwise it will happen at
;          ;at each access.  This is on an easy switch like this to
;          ;make it easier to debug the code that caches the converted
;          ;index.
;      (progn (defmacro convert-to-index-1 (i) `(* ,i 2))
;	     (defmacro convert-to-index-2 (i) i))
;      (progn (defmacro convert-to-index-1 (i) i)
;	     (defmacro convert-to-index-2 (i) `(* ,i 2))))
;  )
;
;(defmacro %convert-slotd-position-to-slot-index (slotd-position)
;  `(convert-to-index-1 ,slotd-position))
;
;(defmacro %allocate-static-slot-storage--class (no-of-slots)
;  `(let* ((size ,no-of-slots)
;          (block (IL:\\ALLOCBLOCK size t)))
;     (do ((index 0 (+ index 1))
;          (offset 0 (+ offset 2)))
;	 ((= index size) block)
;     (il:\\RPLPTR block offset *slot-unbound*))))
;
;(defmacro %static-slot-storage-slot-value--class (static-slot-storage
;						slot-index)
;  `(IL:\\GETBASEPTR ,static-slot-storage (convert-to-index-2 ,slot-index)))
;
;(defsetf %static-slot-storage-slot-value--class
;	 (static-slot-storage slot-index)
;	 (new-value)
;  `(IL:\\RPLPTR ,static-slot-storage
;		(convert-to-index-2 ,slot-index)
;		,new-value))



  ;;   
;;;;;; FUNCTION-ARGLIST
  ;;

(defun function-arglist (x)
  ;; Xerox lisp has the bad habit of returning a symbol to mean &rest, and
  ;; strings instead of symbols.  How silly.
  (let ((arglist (il:arglist x)))
    (when (symbolp arglist)
      ;; This could be due to trying to extract the arglist of an interpreted
      ;; function (though why that should be hard is beyond me).  On the other
      ;; hand, if the function is compiled, it helps to ask for the "smart"
      ;; arglist.
      (setq arglist 
	    (if (consp (symbol-function x))
		(second (symbol-function x))
		(il:arglist x t))))
    (if (symbolp arglist)
	;; Probably never get here, but just in case
	(list '&rest 'rest)
	;; Make sure there are no strings where there should be symbols
	(if (some #'stringp arglist)
	    (mapcar #'(lambda (a) (if (symbolp a) a (intern a))) arglist)
	    arglist))))


  ;;   
;;;;;; Generating CACHE numbers
  ;;

;(defmacro symbol-cache-no (symbol mask)
;  (if (constantp mask)
;    `(logand (il:llsh (il:\\loloc ,symbol) 2)
;	     ,(logand (il:llsh #o17777 2) mask))
;    `(logand (il:llsh (logand #o17777 (il:\\loloc ,symbol)) 2) ,mask)))

(defmacro object-cache-no (object mask)
  `(logand (il:\\loloc ,object) ,mask))

  ;;   
;;;;;; printing-random-thing-internal
  ;;

(defun printing-random-thing-internal (thing stream)
  (let ((*print-base* 8))
    (princ (il:\\hiloc thing) stream)
    (princ "," stream)
    (princ (il:\\loloc thing) stream)))

(defun record-definition (name type &optional parent-name parent-type)
  (declare (ignore type parent-name))
  ())




;;;
;;; FSC-LOW uses this too!
;;;
(eval-when (compile load eval)
  (il:datatype il:compiled-closure (il:fnheader il:environment))

  (il:blockrecord closure-overlay ((funcallable-instance-p il:flag)))  

  )

(defun compiled-closure-fnheader (compiled-closure)
  (il:fetch (il:compiled-closure il:fnheader) il:of compiled-closure))

(defun set-compiled-closure-fnheader (compiled-closure nv)
  (il:replace (il:compiled-closure il:fnheader) il:of compiled-closure nv))

(defsetf compiled-closure-fnheader set-compiled-closure-fnheader)

;;;
;;; In Lyric, and until the format of FNHEADER changes, getting the name from
;;; a compiled closure looks like this:
;;; 
;;; (fetchfield '(nil 4 pointer)
;;;             (fetch (compiled-closure fnheader) closure))
;;;
;;; Of course this is completely non-robust, but it will work for now.  This
;;; is not the place to go into a long tyrade about what is wrong with having
;;; record package definitions go away when you ship the sysout; there isn't
;;; enough diskspace.
;;;             
(defun set-function-name-1 (fn new-name uninterned-name)
  (cond ((typep fn 'il:compiled-closure)
	 (il:\\rplptr (compiled-closure-fnheader fn) 4 new-name)
	 (when (and (consp uninterned-name)
		    (eq (car uninterned-name) 'method))
	   (let ((debug (si::compiled-function-debugging-info fn)))
	     (when debug (setf (cdr debug) uninterned-name)))))
	(t nil))
  fn)
