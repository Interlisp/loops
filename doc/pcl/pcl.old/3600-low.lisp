;;; -*- Mode:LISP; Package:(PCL Lisp 1000); Base:10.; Syntax:Common-lisp; Patch-File: Yes -*-
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
;;; This is the 3600 version of the file portable-low.
;;;

(in-package 'pcl)

#+IMach						;On the I-Machine these are
(eval-when (compile load eval)			;faster than the versions
						;that use :test #'eq.  
(defmacro memq (item list) `(member ,item ,list))
(defmacro assq (item list) `(assoc ,item ,list))
(defmacro rassq (item list) `(rassoc ,item ,list))
(defmacro delq (item list) `(delete ,item ,list))
(defmacro posq (item list) `(position ,item ,list))

)

compiler::
(defoptimizer (cl:the the-just-gets-in-the-way-of-optimizers) (form)
  (matchp form
    (('cl:the type subform)
     (ignore type)
     subform)
    (* form)))

(defmacro %ash (x count)
  (if (and (constantp count) (zerop (eval count)))
      x
      `(the fixnum (ash (the fixnum ,x ) ,count))))

;;;
;;;
;;;

(defmacro without-interrupts (&body body)
  `(let ((outer-scheduling-state si:inhibit-scheduling-flag)
	 (si:inhibit-scheduling-flag t))
     (macrolet ((interrupts-on  ()
		  '(when (null outer-scheduling-state)
		     (setq si:inhibit-scheduling-flag nil)))
		(interrupts-off ()
		  '(setq si:inhibit-scheduling-flag t)))
       (progn outer-scheduling-state)
       ,.body)))

;;;
;;;   WHEN                       EXPANDS-TO
;;;   compile to a file          (#:EVAL-AT-LOAD-TIME-MARKER . <form>)
;;;   compile to core            '<result of evaluating form>
;;;   not in compiler at all     (progn <form>)
;;;
;;; Believe me when I tell you that I don't know why it is I need both a
;;; transformer and an optimizer to get this to work.  Believe me when I
;;; tell you that I don't really care why either.
;;;
(defmacro load-time-eval (form)
  ;; The interpreted definition of load-time-eval.  This definition
  ;; never gets compiled.
  (let ((value (gensym)))
    `(multiple-value-bind (,value)
	 (progn ,form)
       ,value)))

(compiler:deftransformer (load-time-eval optimize-load-time-eval) (form)
  (compiler-is-a-loser-internal form))

(compiler:defoptimizer (load-time-eval transform-load-time-eval) (form)
  (compiler-is-a-loser-internal form))

(defun compiler-is-a-loser-internal (form)  
  ;; When compiling a call to load-time-eval the compiler will call
  ;; this optimizer before the macro expansion.
  (if zl:compiler:(and (boundp '*compile-function*) ;Probably don't need
						    ;this boundp check
						    ;but it can't hurt.
		       (funcall *compile-function* :to-core-p))
      ;; Compiling to core.
      ;; Evaluate the form now, and expand into a constant
      ;; (the result of evaluating the form).
      `',(eval (cadr form))
      ;; Compiling to a file.
      ;; Generate the magic which causes the dumper compiler and loader
      ;; to do magic and evaluate the form at load time.
      `',(cons compiler:eval-at-load-time-marker (cadr form))))

  ;;   
;;;;;; Memory Block primitives.
  ;;   


(defmacro make-memory-block (size &optional area)
  `(make-array ,size :area ,area))

(defmacro memory-block-ref (block offset)	;Don't want to go faster yet.
  `(aref ,block ,offset))

(defvar class-wrapper-area)
(eval-when (load eval)
  (si:make-area :name 'class-wrapper-area
		:room t
		:gc :static))

(eval-when (compile load eval)
  (remprop '%%allocate-instance--class 'inline))

(eval-when (compile load eval)
  
(scl:defflavor iwmc-class
	((wrapper nil)
	 (static-slots nil))
	()
  (:constructor %%allocate-instance--class())
  :ordered-instance-variables)

(defvar *iwmc-class-flavor* (flavor:find-flavor 'iwmc-class))

)

#-imach
(scl:defsubst pcl-%instance-flavor (instance)
  (declare (compiler:do-not-record-macroexpansions))
  (sys::%make-pointer sys:dtp-array
		      (sys:%p-contents-as-locative
			(sys:follow-structure-forwarding instance))))

#+imach
(scl:defsubst pcl-%instance-flavor (instance)
  (sys:%instance-flavor instance))

(scl::defsubst iwmc-class-p (x)
  (and (sys:instancep x)
       (eq (pcl-%instance-flavor x) (load-time-eval *iwmc-class-flavor*))))

(scl:defmethod (:print-self iwmc-class) (stream depth slashify)
  (declare (ignore slashify))
  (print-iwmc-class scl:self stream depth))

(defmacro %iwmc-class-class-wrapper (iwmc-class)
  `(sys:%instance-ref ,iwmc-class 1))

(defmacro %iwmc-class-static-slots (iwmc-class)
  `(sys:%instance-ref ,iwmc-class 2))

(scl:compile-flavor-methods iwmc-class)

  ;;   
;;;;;; Cache No's
  ;;  

;(zl:defsubst symbol-cache-no (symbol mask)
;  (logand (si:%pointer symbol) mask))		    

;(compiler:defoptimizer (symbol-cache-no fold-symbol-cache-no) (form)
;  (if (and (constantp (cadr form))		                    
;	   (constantp (caddr form)))
;      `(load-time-eval (logand (si:%pointer ,(cadr form)) ,(caddr form)))
;      form))

(defmacro object-cache-no (object mask)
  `(logand (si:%pointer ,object) ,mask))

  ;;   
;;;;;; printing-random-thing-internal
  ;;
(defun printing-random-thing-internal (thing stream)
  (format stream "~O" (si:%pointer thing)))

  ;;   
;;;;;; function-arglist
  ;;
;;;
;;; This is hard, I am sweating.
;;; 
(defun function-arglist (function) (zl:arglist function t))

(defun function-pretty-arglist (function) (zl:arglist function))

(defvar dbg:*closure-names* (make-hash-table :test #'eq :size 500))

(defun set-function-name-1 (fn ignore new-name)
  (cond ((or (funcallable-instance-p fn)
	     (si:lexical-closure-p fn))
	 (let ((env (si:lexical-closure-environment fn)))
	   (setf (gethash env dbg:*closure-names*) new-name)))	   
	((compiled-function-p fn)
	 (let* ((cca (si:compiled-function-cca fn))
		(debug
		  #-imach (si:%p-contents-offset cca 2)
		  #+imach (sys:cca-extra-info cca)))
	   (setf (car debug) new-name)))
	((and (listp fn)
	      (eq (car fn) 'si:digested-lambda))
	 (let ((debug (caddr fn)))
	   (setf (caddr fn) (cons new-name (cdr debug))))))
  fn)

(defun record-definition (type spec &rest args)
  (declare (ignore args))
  (case type
   (method (si:record-source-file-name spec 'method))
   (class (si:record-source-file-name spec 'defclass))))

;;;
;;; define a function spec which we use for defmethod and defmethod-setf
;;; method functions.  See code for the expansion of defmethod(-setf).
;;; This also allows us to make compiler-warnings nice, make who-calls work
;;; nicely and all sorts of other wonderful things.  This implementation
;;; could use performance tuning, but note that all that slows down is
;;; loading of defmethods and using the tools like who-calls, parts of the
;;; debugger and stuff like that.
;;; 
(defvar *method-fdefs* (make-hash-table :test #'eq :size 500))
(defvar *method-setf-fdefs* (make-hash-table :test #'equal :size 500))

(si:define-function-spec-handler method (op spec &optional arg1 arg2)
  (if (eq op 'sys:validate-function-spec)
      (and (let ((gspec (cadr spec)))
	     (or (symbolp gspec)
		 (and (listp gspec)
		      (eq (car gspec) 'setf)
		      (symbolp (cadr gspec))
		      (null (cddr gspec)))))
	   (let ((tail (cddr spec)))
	     (loop (cond ((null tail) (return nil))
			 ((listp (car tail)) (return t))
			 ((atom (pop tail)))			 
			 (t (return nil))))))
      (let ((table (if (listp (cadr spec))
		       *method-setf-fdefs*
		       *method-fdefs*))
	    (key (if (listp (cadr spec))
		     (cons (cadadr spec) (cddr spec))
		     (cdr spec))))
	(case op
	  ((si:fdefinedp si:fdefinition)
	   (gethash key table nil))
	  (si:fundefine
	    (remhash key table))
	  (si:fdefine
	    (setf (gethash key table) arg1))
	  (otherwise
	    (si:function-spec-default-handler op spec arg1 arg2))))))


(eval-when (load eval)
  (setf
    (get 'defmethod      'zwei:definition-function-spec-type) 'defun
    (get 'defmethod-setf 'zwei:definition-function-spec-type) 'defun
    (get 'method 'si:definition-type-name) "method"
    (get 'method 'si:definition-type-name) "method"

    (get 'declass 'zwei:definition-function-spec-type) 'defclass
    (get 'defclass 'si:definition-type-name) "Class"
    (get 'defclass 'zwei:definition-function-spec-finder-template) '(0 1))
  )

;;; The variable zwei::*sectionize-line-lookahead* controls how many lines the parser
;;;  is willing to look ahead while trying to parse a definition.  Even 2 lines is enough
;;;  for just about all cases, but there isn't much overhead, and 10 should be enough
;;;  to satisfy pretty much everyone... but feel free to change it.
;;;        - MT 880921
zwei:
(defvar *sectionize-line-lookahead* 10)

zwei:
(DEFMETHOD (:SECTIONIZE-BUFFER MAJOR-MODE :DEFAULT)
	   (FIRST-BP LAST-BP BUFFER STREAM INT-STREAM ADDED-COMPLETIONS)
  ADDED-COMPLETIONS ;ignored, obsolete
  (WHEN STREAM
    (SEND-IF-HANDLES STREAM :SET-RETURN-DIAGRAMS-AS-LINES T))
  (INCF *SECTIONIZE-BUFFER*)
  (LET ((BUFFER-TICK (OR (SEND-IF-HANDLES BUFFER :SAVE-TICK) *TICK*))
	OLD-CHANGED-SECTIONS)
    (TICK)
    ;; Flush old section nodes.  Also collect the names of those that are modified, they are
    ;; the ones that will be modified again after a revert buffer.
    (DOLIST (NODE (NODE-INFERIORS BUFFER))
      (AND (> (NODE-TICK NODE) BUFFER-TICK)
	   (PUSH (LIST (SECTION-NODE-FUNCTION-SPEC NODE)
		       (SECTION-NODE-DEFINITION-TYPE NODE))
		 OLD-CHANGED-SECTIONS))
      (FLUSH-BP (INTERVAL-FIRST-BP NODE))
      (FLUSH-BP (INTERVAL-LAST-BP NODE)))
    (DO ((LINE (BP-LINE FIRST-BP) (LINE-NEXT INT-LINE))
	 (LIMIT (BP-LINE LAST-BP))
	 (EOFFLG)
	 (ABNORMAL T)
	 (DEFINITION-LIST NIL)
	 (BP (COPY-BP FIRST-BP))
	 (FUNCTION-SPEC)
	 (DEFINITION-TYPE)
	 (STR)
	 (INT-LINE)
	 (first-time t)
	 (future-line)				; we actually read into future line
	 (future-int-line)
	 (PREV-NODE-START-BP FIRST-BP)
	 (PREV-NODE-DEFINITION-LINE NIL)
	 (PREV-NODE-FUNCTION-SPEC NIL)
	 (PREV-NODE-TYPE 'HEADER)
	 (PREVIOUS-NODE NIL)
	 (NODE-LIST NIL)
	 (STATE (SEND SELF :INITIAL-SECTIONIZATION-STATE)))
	(NIL)
      ;; If we have a stream, read another line.
      (when (AND STREAM (NOT EOFFLG))
	(let ((lookahead (if future-line 1 *sectionize-line-lookahead*)))
	  (dotimes (i lookahead)		; startup lookahead
	    (MULTIPLE-VALUE (future-LINE EOFFLG)
	      (LET ((DEFAULT-CONS-AREA *LINE-AREA*))
		(SEND STREAM ':LINE-IN LINE-LEADER-SIZE)))
	    (IF future-LINE (SETQ future-INT-LINE (FUNCALL INT-STREAM ':LINE-OUT future-LINE)))
	    (when first-time
	      (setq first-time nil)
	      (setq line future-line)
	      (setq int-line future-int-line))
	    (when eofflg
	      (return)))))

      (SETQ INT-LINE LINE)

      (when int-line
	(MOVE-BP BP INT-LINE 0))		;Record as potentially start-bp for a section

      ;; See if the line is the start of a defun.
      (WHEN (AND LINE
		 (LET (ERR)
		   (MULTIPLE-VALUE (FUNCTION-SPEC DEFINITION-TYPE STR ERR STATE)
		     (SEND SELF ':SECTION-NAME INT-LINE BP STATE))
		   (NOT ERR)))
	(PUSH (LIST FUNCTION-SPEC DEFINITION-TYPE) DEFINITION-LIST)
	(SECTION-COMPLETION FUNCTION-SPEC STR NIL)
	;; List methods under both names for user ease.
	(LET ((OTHER-COMPLETION (SEND SELF ':OTHER-SECTION-NAME-COMPLETION
				      FUNCTION-SPEC INT-LINE)))
	  (WHEN OTHER-COMPLETION
	    (SECTION-COMPLETION FUNCTION-SPEC OTHER-COMPLETION NIL)))
	(LET ((PREV-NODE-END-BP (BACKWARD-OVER-COMMENT-LINES BP ':FORM-AS-BLANK)))
	  ;; Don't make a section node if it's completely empty.  This avoids making
	  ;; a useless Buffer Header section node. Just set all the PREV variables
	  ;; so that the next definition provokes the *right thing*
	  (UNLESS (BP-= PREV-NODE-END-BP PREV-NODE-START-BP)
	    (SETQ PREVIOUS-NODE
		  (ADD-SECTION-NODE PREV-NODE-START-BP
				    (SETQ PREV-NODE-START-BP PREV-NODE-END-BP)
				    PREV-NODE-FUNCTION-SPEC PREV-NODE-TYPE
				    PREV-NODE-DEFINITION-LINE BUFFER PREVIOUS-NODE
				    (IF (LOOP FOR (FSPEC TYPE) IN OLD-CHANGED-SECTIONS
					      THEREIS (AND (EQ PREV-NODE-FUNCTION-SPEC FSPEC)
							   (EQ PREV-NODE-TYPE TYPE)))
					*TICK* BUFFER-TICK)
				    BUFFER-TICK))
	    (PUSH PREVIOUS-NODE NODE-LIST)))
	(SETQ PREV-NODE-FUNCTION-SPEC FUNCTION-SPEC
	      PREV-NODE-TYPE DEFINITION-TYPE
	      PREV-NODE-DEFINITION-LINE INT-LINE))
      ;; After processing the last line, exit.
      (WHEN (OR #+ignore EOFFLG (null line) (AND (NULL STREAM) (EQ LINE LIMIT)))
	;; If reading a stream, we should not have inserted a CR
	;; after the eof line.
	(WHEN STREAM
	  (DELETE-INTERVAL (FORWARD-CHAR LAST-BP -1 T) LAST-BP T))
	;; The rest of the buffer is part of the last node
	(UNLESS (SEND SELF ':SECTION-NAME-TRIVIAL-P)
	  ;; ---oh dear, what sort of section will this be? A non-empty HEADER
	  ;; ---node.  Well, ok for now.
	  (PUSH (ADD-SECTION-NODE PREV-NODE-START-BP LAST-BP
				  PREV-NODE-FUNCTION-SPEC PREV-NODE-TYPE
				  PREV-NODE-DEFINITION-LINE BUFFER PREVIOUS-NODE
				  (IF (LOOP FOR (FSPEC TYPE) IN OLD-CHANGED-SECTIONS
					    THEREIS (AND (EQ PREV-NODE-FUNCTION-SPEC FSPEC)
							 (EQ PREV-NODE-TYPE TYPE)))
				      *TICK* BUFFER-TICK)
				  BUFFER-TICK)
		NODE-LIST)
	  (SETF (LINE-NODE (BP-LINE LAST-BP)) (CAR NODE-LIST)))
	(SETF (NODE-INFERIORS BUFFER) (NREVERSE NODE-LIST))
	(SETF (NAMED-BUFFER-WITH-SECTIONS-FIRST-SECTION BUFFER) (CAR (NODE-INFERIORS BUFFER)))
	(SETQ ABNORMAL NIL)			;timing windows here
	;; Speed up completion if enabled.
	(WHEN SI:*ENABLE-AARRAY-SORTING-AFTER-LOADS*
	  (SI:SORT-AARRAY *ZMACS-COMPLETION-AARRAY*))
	(SETQ *ZMACS-COMPLETION-AARRAY*
	      (FOLLOW-STRUCTURE-FORWARDING *ZMACS-COMPLETION-AARRAY*))
	(RETURN
	  (VALUES 
	    (CL:SETF (ZMACS-SECTION-LIST BUFFER)
		     (NREVERSE DEFINITION-LIST))
	    ABNORMAL))))))




(defun (:property defmethod zwei::definition-function-spec-parser) (bp)
  (zwei:parse-pcl-defmethod-for-zwei bp nil))

(defun (:property defmethod-setf zwei::definition-function-spec-parser) (bp)
  (zwei:parse-pcl-defmethod-for-zwei bp t))


;;;  Previously, if a source file in a PCL-based package contained what looks
;;; like flavor defmethod forms (i.e. an (IN-PACKAGE 'non-pcl-package) form
;;; appears at top level, and then a flavor-style defmethod form) appear, the
;;; parser would break.
;;;
;;; Now, if we can't parse the defmethod form, we send it to the flavor
;;; defmethod parser instead.
;;; 
;;; Also now supports multi-line arglist sectionizing.
;;;
zwei:
(defun parse-pcl-defmethod-for-zwei (bp-after-defmethod setfp)
  (block parser
    (flet ((barf (&optional (error t))
	     (return-from parser
	       (cond ((eq error :flavor)
		      (funcall (get 'flavor:defmethod
				    'zwei::definition-function-spec-parser)
			       bp-after-defmethod))
		     (t
		      (values nil nil nil error))))))
      (let ((bp-after-generic (forward-sexp bp-after-defmethod))
	    (qualifiers ())
	    (specializers ())
	    (spec nil)
	    (ignore1 nil)
	    (ignore2 nil))
	(when bp-after-generic
	  (multiple-value-bind (generic error-p)
	      (read-fspec-item-from-interval bp-after-defmethod
					     bp-after-generic)
	    (if error-p
		(barf)				; error here is really bad.... BARF!
		(progn
		  (when (listp generic)
		    (if (and (symbolp (car generic))
			     (string-equal (cl:symbol-name (car generic)) "SETF"))
			(setq generic (second generic)	; is a (setf xxx) form
			      setfp t)
			(barf :flavor)))	; make a last-ditch-effort with flavor parser
		  (let* ((bp1 bp-after-generic)
			 (bp2 (forward-sexp bp1)))
		      (cl:loop
			 (if (null bp2)
			     (barf :more)	; item not closed - need another line!
			     (multiple-value-bind (item error-p)
				 (read-fspec-item-from-interval bp1 bp2)
			       (cond (error-p (barf))	;
				     ((listp item)
				      (setq qualifiers (nreverse qualifiers))
				      (cl:multiple-value-setq (ignore1
								ignore2
								specializers)
					(pcl::parse-specialized-lambda-list item))
				      (setq spec (pcl::make-method-spec 
						   (if setfp
						       `(cl:setf ,generic)
						       generic)
						   qualifiers
						   specializers))
				      (return (values spec
						      'defun
						      (string-interval
							bp-after-defmethod
							bp2))))
				     (t (push item qualifiers)
					(setq bp1 bp2
					      bp2 (forward-sexp bp2))))))))))))))))

(defun zwei:pcl-method-indentation (BP1 BP LASTPAREN lastsexp space-width sym)
  (declare (ignore sym space-width lastsexp))
  (let* ((ipt bp1)
	 (nsexps (do* ((sbp (zwei:forward-char lastparen 1)
			    (zwei:forward-sexp sbp 1 nil 0 bp))
		       (count 0))
		      ((null sbp) count)
		   (let* ((sbp1 (zwei:forward-over zwei:*whitespace-chars* sbp bp))
			  (ch (zwei:bp-char sbp1)))
		     (when (zwei:bp-= sbp1 bp)
		       (return count))
		     (when (= count 1)
		       (setf ipt sbp1))         ; should this be a copy-bp?
		     (unless (char-equal ch #\:)
		       (incf count))))))
    (case nsexps
      ((0 1) (values bp1 nil 2))
      ((2) (values ipt nil 0))
      (t (values bp1 nil 2)))))

(zwei:defindentation (defmethod . zwei:pcl-method-indentation))

;;;
;;; Teach zwei that when it gets the name of a generic function as an argument
;;; it should edit all the methods of that generic function.  This works for
;;; ED as well as meta-point.
;;;
(zl:advise (flavor:method :SETUP-FUNCTION-SPECS-TO-EDIT zwei:ZMACS-EDITOR)
	   :around
	   setup-function-specs-to-edit-advice
	   ()
  (let ((old-definitions (cadddr arglist))
	(new-definitions ())
	(new nil))
    (dolist (old old-definitions)
      (setq new (setup-function-specs-to-edit-advice-1 old))
      (push (or new (list old)) new-definitions))
    (setf (cadddr arglist) (apply #'append (reverse new-definitions)))
    :do-it))

(defun setup-function-specs-to-edit-advice-1 (spec)
  (and (or (symbolp spec)
	   (and (listp spec) (eq (car spec) 'setf)))
       (gboundp spec)
       (generic-function-p (gdefinition spec))
       (mapcar #'(lambda (m)
		   (make-method-spec spec
				     (method-qualifiers m)
				     (unparse-specializers
				       (method-type-specifiers m))))
	       (generic-function-methods (gdefinition spec)))))

