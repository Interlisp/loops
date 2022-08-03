;;;-*-Mode:LISP; Package:(PCL LISP 1000); Base:10; Syntax:Common-lisp -*-
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

(in-package 'pcl)

(proclaim '(special *the-class-t* *the-class-object*
		    *the-class-t* *the-class-vector* *the-class-symbol*
		    *the-class-string* *the-class-sequence*
		    *the-class-rational* *the-class-ratio*
		    *the-class-number* *the-class-null* *the-class-list*
		    *the-class-integer* *the-class-float* *the-class-cons*
		    *the-class-complex* *the-class-character*
		    *the-class-bit-vector* *the-class-array*))

(defvar *early-defclass-forms*
  '(

    (defclass t () ())

    (defclass object (t) ())

    (defclass class (object) ())

    (defclass standard-class (class)
	 ((name
	    :initform nil
	    :accessor class-name)
	  (class-precedence-list
	    :initform ()
	    :accessor class-precedence-list
	    :accessor class-class-precedence-list)
	  (local-supers
	    :initform ()
	    :accessor class-local-supers)
	  (local-slots
	    :initform ()
	    :accessor class-local-slots)
	  (direct-subclasses
	    :initform ()
	    :accessor class-direct-subclasses)
	  (direct-methods
	    :initform ()
;	    :accessor class-direct-methods        ;This is defined by hand
	                                          ;during bootstrapping.
	    )
	  (forward-referenced-supers
	    :initform ()
	    :accessor class-forward-referenced-supers)
	  (no-of-instance-slots
	    :initform 0
	    :accessor class-no-of-instance-slots)
	  (slots
	    :initform ()
	    :accessor class-slots)
	  (wrapper
	    :initform nil
	    :accessor class-wrapper)
	  (direct-generic-functions
	    :initform ())			;Reader for this is defined
						;by hand.
						;There is no writer for this
						;since this value is derived
						;from direct-methods.
	  (prototype
	    :initform nil)
	  (options
	    :initform ()
	    :accessor class-options)
	  (constructors
	    :initform ()
	    :accessor class-constructors)
	  
	  (all-default-initargs
	    :initform ()
	    :accessor class-all-default-initargs)))

    
    (defclass forward-referenced-class (standard-class) ())

    (defclass built-in-class (standard-class) ())

    (defclass symbol (t) () (:metaclass built-in-class))

    (defclass standard-slot-description (object)
	 ((name
	    :initform nil
;	    :accessor slotd-name                ;This is defined by hand
						;during bootstrapping.
	    )
	  (keyword
	    :initform nil
	    :accessor slotd-keyword)
	  (initform
	    :initform *slotd-unsupplied*
	    :accessor slotd-initform)
	  (initfunction
	    :initform *slotd-unsupplied*
	    :accessor slotd-initfunction)
	  (readers
	    :initform nil
	    :accessor slotd-readers)
	  (writers
	    :initform nil
	    :accessor slotd-writers)
	  (initargs
	    :initform nil
	    :accessor slotd-initargs)
	  (allocation
	    :initform nil
	    :accessor slotd-allocation)
	  (type
	    :initform nil
	    :accessor slotd-type)
	  (documentation
	    :initform ""
	    :accessor slotd-documentation)))
      

    ))

(defvar *fsc-defclass-forms*
  '((defclass funcallable-standard-class (standard-class)
      ())))

(defvar *methods-defclass-forms*
  '(
    
      
    (defclass standard-method ()
	 ((function
	    :initform nil
	    :reader method-function)
	  (generic-function
	    :initform nil
	    :accessor method-generic-function)
	  (type-specifiers
	    :initform ()
	    :accessor method-type-specifiers)
	  (arglist
	    :initform ()
	    :accessor method-arglist)
	  (qualifiers
	    :initform ()
	    :accessor method-qualifiers)
	  (documentation
	    :initform nil
	    :accessor method-documentation)))

    (defclass standard-reader/writer-method (standard-method)
	 ((slot-name :initform nil))
      ;; There is a hand coded reader method for this which appears
      ;; in the beginning of methods.  See the comment there.
      ;(:reader-prefix reader/writer-method)
      )

    (defclass standard-reader-method (standard-reader/writer-method) ())
    (defclass standard-writer-method (standard-reader/writer-method) ())
    
    (defclass standard-generic-function ()
        ((name
	   :initform nil
	   :accessor generic-function-name)
	 (methods
	   :initform ()
	   :accessor generic-function-methods)
	 (discriminator-code
	   :initform ()
	   :accessor generic-function-discriminator-code)
	 (classical-method-table
	   :initform nil
	   :accessor generic-function-classical-method-table)
	 (combined-methods
	   :initform nil
	   :accessor generic-function-combined-methods)
	 (cache
	   :initform ()
	   :accessor generic-function-cache)
	 (valid-p
	   :initform nil
	   :accessor generic-function-valid-p)
	 (pretty-arglist
	   :initform ()
	   :accessor generic-function-pretty-arglist)
	 (method-class
	   :initform (find-class 'standard-method)
	   :accessor generic-function-method-class)
	 (dispatch-order
	   :initform :default
	   :accessor generic-function-dispatch-order)
	 )
      (:metaclass funcallable-standard-class))
    
    ))


;;;
;;; Convert a function name to its standard setf function name.  We don't
;;; use non-symbolic "function-specs" yet because we keep hoping they will
;;; go away.
;;;
(eval-when (compile load eval)

(defvar *setf-function-names* (make-hash-table :size 200 :test #'eq))

(defun get-setf-function-name (name)
  (or (gethash name *setf-function-names*)
      (setf (gethash name *setf-function-names*)
	    (intern (let ((*package* *the-pcl-package*)
			  (*print-case* :upcase)
			  (*print-gensym* 't))
		      (format nil "~A ~S" 'setf name))
		    *the-pcl-package*))))

);eval-when

;;;
;;; Call this to define a setf macro for a function with the same behavior as
;;; specified by the SETF function cleanup proposal.  Specifically, this will
;;; cause: (SETF (FOO a b) x) to expand to (|SETF FOO| x a b).
;;;
;;; do-standard-defsetf is a macro interface for use at top-level in files.
;;; do-standard-defsetf-1 is a functional interface.
;;; 

(defmacro do-standard-defsetf (function-name)
  (let ((setf-function-name (get-setf-function-name function-name)))
    #-TI
    `(defsetf ,function-name (&rest accessor-args) (new-value)
       `(,',setf-function-name ,new-value ,@accessor-args))
    #+TI
    `(define-setf-method ,function-name (&rest accessor-args)
       (let ((tempvars (mapcar #'(lambda (ignore) (gensym)) accessor-args))
	     (storevar (gensym)))
	 (values tempvars
		 accessor-args
		 (list storevar)
		 `(,',setf-function-name ,storevar ,@tempvars)
		 `(,',function-name ,@tempvars))))))

(defun do-standard-defsetf-1 (generic-function-name)
  (let* ((setf-name (get-setf-function-name generic-function-name)))
    (do-defsetf generic-function-name
		'(&rest accessor-args)	      
		'(new-value)
		``(,',setf-name ,new-value ,@accessor-args))))

(defun do-defsetf (access store-or-args &optional store-vars &rest body)
  (let #+Genera ((si:inhibit-fdefine-warnings t))
       #-Genera ()
    #+Lispm (setq body (copy-list body))
    (if body
	(eval #-TI
	      `(defsetf ,access ,store-or-args ,store-vars ,@body)
	      #+TI ; assume store-or-args is (&rest accessor-args)
	      `(define-setf-method ,access ,store-or-args
		 (let ((tempvars (mapcar #'(lambda (ignore) (gensym))
					 ,(second store-or-args)))
		       (storevar (gensym)))
		   (values tempvars
			   ,(second store-or-args)
			   (list storevar)
			   (let ((,(first store-vars) storevar)
				 (,(second store-or-args) tempvars))
			     ,@body)
			   `(,',access ,@tempvars)))))
	(eval `(defsetf ,access ,store-or-args)))))


;;;
;;; Random defsets that will be able to go away once the cleanup proposal
;;; to standardize a default behavior for setf is implemented.
;;;
(defmacro do-standard-defsetfs (&rest function-names)
  `(progn ,.(mapcar #'(lambda (fn) `(do-standard-defsetf ,fn))
		    function-names)))

(do-standard-defsetfs method-function-plist
		      method-function-get
		      get-setf-function
		      gdefinition
		      class-options
		      class-instance-slots
		      slotd-name
		      slot-value--std
		      slot-value--fsc
		      slot-value-using-class
		      )


;;;
;;; make-setf-method-lambda-list is used by any part of PCL that has to
;;; construct the lambda-list of a setf-method from an access lambda list
;;; and a new value lambda list.  This function is not a documented part
;;; part of CLOS, because it is so simple, but it is a documented part of
;;; PCL because of the error-checking it provides.
;;; 
(defun make-setf-method-lambda-list (access-lambda-list new-value-lambda-list)
  (when (or (cdr new-value-lambda-list)
	    (memq (car new-value-lambda-list) lambda-list-keywords))
    (error "The new-value lambda-list is only allowed to contain one~%~
            argument, and it must be a required argument.~%~
            The new-value lambda-list ~S is illegal."
	   new-value-lambda-list))
  (append new-value-lambda-list access-lambda-list))



;;;
;;; This is like fdefinition on the Lispm.  If Common Lisp had something like
;;; function specs I wouldn't need this.  On the other hand, I don't like the
;;; way this really works so maybe function specs aren't really right either?
;;; 
;;; I also don't understand the real implications of a Lisp-1 on this sort of
;;; thing.  Certainly some of the lossage in all of this is because these
;;; SPECs name global definitions.
;;;
;;; Note that this implementation is set up so that an implementation which
;;; has a 'real' function spec mechanism can use that instead and in that way
;;; get rid of setf generic function names.
;;;
(defmacro parse-gspec (spec
		       (non-setf-var . non-setf-case)
		       (setf-var . setf-case))
  (declare (indentation 1 1))
  (once-only (spec)
    `(cond ((symbolp ,spec)
	    (let ((,non-setf-var ,spec)) ,@non-setf-case))
	   ((and (listp ,spec)
		 (eq (car ,spec) 'setf)
		 (symbolp (cadr ,spec)))
	    (let ((,setf-var (cadr ,spec))) ,@setf-case))
	   (t
	    (error
	      "Can't understand ~S as a generic function specifier.~%~
               It must be either a symbol which can name a function or~%~
               a list like ~S, where the car is the symbol ~S and the cadr~%~
               is a symbol which can name a generic function."
	      ,spec '(setf <foo>) 'setf)))))

;;;
;;; If symbol names a function which is traced or advised, return the
;;; unadvised, traced etc. definition.  This lets me get at the generic
;;; function object even when it is traced.
;;;
(defun unencapsulated-fdefinition (symbol)
  #+Lispm (si:fdefinition (si:unencapsulate-function-spec symbol))
  #+Lucid (lucid::get-unadvised-procedure (symbol-function symbol))
  #+excl  (or (excl::encapsulated-basic-definition symbol)
	      (symbol-function symbol))
  #+xerox (il:virginfn symbol)
  
  #-(or Lispm Lucid excl Xerox) (symbol-function symbol))

;;;
;;; If symbol names a function which is traced or advised, redefine
;;; the `real' definition without affecting the advise.
;;;
(defun fdefine-carefully (symbol new-definition)
  #+Lispm (si:fdefine symbol new-definition t t)
  #+Lucid (let ((lucid-common-lisp::*redefinition-action* nil))
	    (setf (symbol-function symbol) new-definition))
  #+excl  (setf (symbol-function symbol) new-definition)
  #+xerox (let ((advisedp (member symbol il:advisedfns :test #'eq))
                (brokenp (member symbol il:brokenfns :test #'eq)))
	    ;; In XeroxLisp (late of envos) tracing is implemented
	    ;; as a special case of "breaking".  Advising, however,
	    ;; is treated specially.
            (xcl:unadvise-function symbol :no-error t)
            (xcl:unbreak-function symbol :no-error t)
            (setf (symbol-function symbol) new-definition)
            (when brokenp (xcl:rebreak-function symbol))
            (when advisedp (xcl:readvise-function symbol)))

  #-(or Lispm Lucid excl Xerox)
  (setf (symbol-function symbol) new-definition)
  
  new-definition)

(defun gboundp (spec)
  (parse-gspec spec
    (name (fboundp name))
    (name (fboundp (get-setf-function-name name)))))

(defun gmakunbound (spec)
  (parse-gspec spec
    (name (fmakunbound name))
    (name (fmakunbound (get-setf-function-name name)))))

(defun gdefinition (spec)
  (parse-gspec spec
    (name (or (macro-function name)		;??
	      (unencapsulated-fdefinition name)))
    (name (unencapsulated-fdefinition (get-setf-function-name name)))))

(defun SETF\ GDEFINITION (new-value spec)
  (parse-gspec spec
    (name (fdefine-carefully name new-value))
    (name (fdefine-carefully (get-setf-function-name name) new-value))))

(defun get-setf-function (name)
  (gdefinition `(setf ,name)))

(defun SETF\ GET-SETF-FUNCTION (new-value name)
  (setf (gdefinition name) new-value))



(defun do-satisfies-deftype (name predicate)
  (let* ((specifier `(satisfies ,predicate))
	 (expand-fn #'(lambda (&rest ignore)
			(declare (ignore ignore))
			specifier)))
    ;; Specific ports can insert their own way of doing this.  Many
    ;; ports may find the expand-fn defined above useful.
    ;;
    (or #+:Genera
	(setf (get name 'deftype) expand-fn)
	#+(and :Lucid (not :Prime))
	(system::define-macro `(deftype ,name) expand-fn nil)
	#+ExCL
	(setf (get name 'excl::deftype-expander) expand-fn)
	#+:coral
	(setf (get name 'ccl::deftype-expander) expand-fn)

	;; This is the default for ports for which we don't know any
	;; better.  Note that for most ports, providing this definition
	;; should just speed up class definition.  It shouldn't have an
	;; effect on performance of most user code.
	(eval `(deftype ,name () '(satisfies ,predicate))))))

(defun make-type-predicate-name (class-name)
  (intern (format nil
		  "~A ~A  predicate"
		  (package-name (symbol-package class-name))
		  class-name
		  *the-pcl-package*)))


;;;
;;; Do the defsetfs for accessors defined by defclass's in the bootstrap.
;;; These have to be here because we want to be able to compile setfs of
;;; calls to those accessors before we have actually been able to evaluate
;;; those defclass forms.
;;;
(defun define-early-setfs-and-type-predicates ()
  (dolist (forms-var '(*early-defclass-forms*
		       *fsc-defclass-forms*
		       *methods-defclass-forms*))
    (dolist (defclass (eval forms-var))
      (destructuring-bind (ignore name supers slots . options)
			  defclass
	(unless (memq name '(t symbol))
	  (do-satisfies-deftype name (make-type-predicate-name name)))
	
	(dolist (slot slots)
	  (let ((slot-options (cdr slot)))
	    (loop (when (null slot-options) (return t))
		  (when (memq (car slot-options) '(:accessor :writer))
		    (do-standard-defsetf-1 (cadr slot-options)))
		  (setq slot-options (cddr slot-options)))))

	(dolist (option options)
	  (when (and (listp option)
		     (eq (car option) :accessor-prefix))
	    (setq option (cadr option))
	    (dolist (slot slots)
	      (if (null option)
		  (do-standard-defsetf-1 (car slot))
		  (do-standard-defsetf-1
		    (symbol-append (symbol-name option)
				   (symbol-name (car slot))))))))))))


(eval-when (load eval)
  (define-early-setfs-and-type-predicates))

;;;
;;; Extra little defsetfs which we need now.
;;; 

(defsetf slot-value set-slot-value)

(defsetf slot-value-always (object slot-name &optional default) (new-value)
  `(put-slot-always ,object ,slot-name ,new-value))

(pushnew 'class *variable-declarations*)
(pushnew 'variable-rebinding *variable-declarations*)

(defun variable-class (var env)
  (caddr (variable-declaration 'class var env)))


;;;
;;; This is used by combined methods to communicate the next methods to
;;; the methods they call.  This variable is captured by a lexical variable
;;; of the methods to give it the proper lexical scope.
;;; 
(defvar *next-methods* nil)

(defvar *not-an-eql-specializer* '(not-an-eql-specializer))

(defvar *umi-gfs*)
(defvar *umi-complete-classes*)
(defvar *umi-reorder*)


;;;
;;; This little macro requires one case for each of the currently defined
;;; kinds of specializers.  At macroexpansion time it will signal an error
;;; if an unsupplied case is found.  At runtime, it assumes the specializer
;;; argument is a legal specializer.  This means there is no error checking
;;; at all at runtime.
;;; 
(defmacro specializer-case (specializer &body cases)
  (flet ((find-case (key)
	   (let ((case (assq key cases)))
	     (and case (cdr case)))))
    (once-only (specializer)
      `(if (consp ,specializer)
	   (progn . ,(find-case :eql))
	   (progn . ,(find-case :class))))))

(defmacro specializer-ecase (specializer &body cases)
  (flet ((find-case (key)
	   (let ((case (assq key cases)))
	     (if case
		 (cdr case)
		 (error "~S case not found." key)))))
    (once-only (specializer)
      `(cond ((not (consp ,specializer))
	      . ,(find-case :class))
	     ((and (consp ,specializer)
		   (eq (car ,specializer) 'eql)
		   (null (cddr ,specializer)))
	      . ,(find-case :eql))
	     (t (error "~S is not a valid specializer."))))))

(defmacro specializer-cross-case (specializer-1 specializer-2 &body cases)
  (let ((otherwise (cdr (assq t cases))))
    (flet ((find-case (key)
	     (or (cdr (assq key cases))
		 (if otherwise
		     '((.specializer-cross-case-otherwise.))
		     (error "~S case not found." key)))))
      (once-only (specializer-1 specializer-2)
	`(flet ((.specializer-cross-case-otherwise. () . ,otherwise))
	   (specializer-ecase ,specializer-1
	     (:eql   (specializer-ecase ,specializer-2
		       (:eql   . ,(find-case :eql-eql))
		       (:class . ,(find-case :eql-class))))
	     (:class (specializer-ecase ,specializer-2
		       (:eql   . ,(find-case :class-eql))
		       (:class . ,(find-case :class-class))))))))))

(defun specializer-eq (a b)
  (specializer-cross-case a b
    (:eql-eql     (eq (cadr a) (cadr b)))
    (:class-class (eq a b))
    (t nil)))
  
(defun specializer-assoc (specializer alist)
  (assoc specializer alist :test #'specializer-eq))

(defun sub-specializer-p (x y)
  (specializer-cross-case y x
    (:eql-eql     (eql (cadr x) (cadr y)))
    (:eql-class   nil)
    (:class-eql   (memq y (class-precedence-list (class-of (cadr x)))))
    (:class-class (memq y (class-precedence-list x)))))
