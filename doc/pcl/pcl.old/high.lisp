;;;-*-Mode:LISP; Package:(PCL (LISP WALKER)); Base:10; Syntax:Common-lisp -*-
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
;;; Non-Bootstrap stuff
;;;

(in-package 'pcl)

(defmethod check-super-metaclass-compatibility ((c standard-class)
						(f forward-referenced-class))
  't)

(defmethod class-for-redefinition ((existing-class forward-referenced-class)
				   (proto-class standard-class)
				   name
				   supers
				   slots
				   options)
  (declare (ignore name supers slots options))
  (change-class existing-class (class-of proto-class))
  existing-class)




;;;
;;;
;;;

;(defclass built-in-class (standard-class)
;     ((class-precedence-list
;	:initform (list *the-class-t*))))

(defmethod inform-type-system-about-class ((class built-in-class) name)
  (declare (ignore name)))

(defmethod allocate-instance ((class built-in-class) &rest initargs)
  (declare (ignore initargs))
  (error "Attempt to make an instance of the built-in class ~S.~@
          It is not possible to make instance of built-in classes with~@
          allocate-instance."
	 class))

(defmethod check-super-metaclass-compatibility ((bic built-in-class)
						(new-super standard-class))
  (or (eq new-super (find-class 't))
      (error "~S cannot have ~S as a super.~%~
              The only meta-class STANDARD-CLASS class that a built-in~%~
              class can have as a super is the class T."
	     bic new-super)))


(defmethod check-super-metaclass-compatibility ((class built-in-class)
						(new-super built-in-class))
  't)

(defmethod check-super-metaclass-compatibility
	   ((built-in built-in-class)
	    (new-super forward-referenced-class))
  't)


(eval-when (compile load eval)
  
(defvar *built-in-classes*
	'((number            (t))
	  (complex           (number))
	  (float             (number))
	  (rational          (number))
	  (integer           (rational))
	  (ratio             (rational))

	  (sequence          (t))	
	  (list              (sequence))
	  (cons              (list))

	  (array             (t))
	  (vector            (array sequence))
	  (string            (vector))
	  (bit-vector        (vector))
	  
	  (character         (t))
	  
	  (symbol            (t))	      ;defined by hand in BRAID
	  (null              (symbol list))))

(defvar *built-in-class-symbols* ())
(defvar *built-in-wrapper-symbols* ())

(defun get-built-in-class-symbol (class-name)
  (or (cadr (assq class-name *built-in-class-symbols*))
      (let ((symbol (intern (format nil
				    "*THE-CLASS-~A*"
				    (symbol-name class-name))
			    *the-pcl-package*)))
	(push (list class-name symbol) *built-in-class-symbols*)
	symbol)))

(defun get-built-in-wrapper-symbol (class-name)
  (or (cadr (assq class-name *built-in-wrapper-symbols*))
      (let ((symbol (intern (format nil
				    "*THE-WRAPPER-OF-~A*"
				    (symbol-name class-name))
			    *the-pcl-package*)))
	(push (list class-name symbol) *built-in-wrapper-symbols*)
	symbol)))

(defun define-built-in-classes ()
  ;; First make sure that all the supers listed in *built-in-class-lattice*
  ;; are themselves defined by *built-in-class-lattice*.  This is just to
  ;; check for typos and other sorts of brainos.
  ;; 
  ;; At the same time make sure the subtype relationship specified here in
  ;; *built-in-class-lattice* agrees with the subtype relationship in this
  ;; Lisp.
  (dolist (e *built-in-classes*)
    (dolist (super (cadr e))
      (unless (or (eq super 't)
		  (assq super *built-in-classes*))
	(error "In *built-in-classes*: ~S has ~S as a super,~%~
                but ~S is not itself a class in *built-in-classes*."
	       (car e) super super))))

  ;; Now use add-named-class to define the built-in class as specified.
  ;; 
  (let ((proto (class-prototype (find-class 'built-in-class))))
    (dolist (e *built-in-classes*)
      (let ((name (car e))
	    (supers (cadr e)))
	(unless (eq name 'symbol)
	  (add-named-class proto name supers () ())
	  (let ((class-symbol (get-built-in-class-symbol name))
		(wrapper-symbol (get-built-in-wrapper-symbol name))
		(class (find-class name)))
	    (set class-symbol class)
	    (set wrapper-symbol (class-wrapper class))))))

    (set (get-built-in-wrapper-symbol 't)
	 (class-wrapper *the-class-t*))
    (set (get-built-in-wrapper-symbol 'symbol)
	 (class-wrapper *the-class-symbol*))))

(define-built-in-classes)

)

(eval-when (compile eval)

(defun make-built-in-class-subs ()
  (mapcar #'(lambda (e)
	      (let ((class (car e))
		    (class-subs ()))
		(dolist (s *built-in-classes*)
		  (when (memq class (cadr s)) (pushnew (car s) class-subs)))
		(cons class class-subs)))
	  (cons '(t) *built-in-classes*)))

(defun make-built-in-class-tree ()
  (let ((subs (make-built-in-class-subs)))
    (labels ((descend (class)
	       (cons class (mapcar #'descend (cdr (assq class subs))))))
      (descend 't))))

(defun make-built-in-wrapper-of-body ()
  (make-built-in-wrapper-of-body-1 (make-built-in-class-tree)
				   'x
				   #'get-built-in-wrapper-symbol))

(defun make-built-in-class-of-body ()
  (make-built-in-wrapper-of-body-1 (make-built-in-class-tree)
				   'x
				   #'get-built-in-class-symbol))


(defun make-built-in-wrapper-of-body-1 (tree var get-symbol)
  (let ((*specials* ()))
    (declare (special *specials*))
    (let ((inner (make-built-in-wrapper-of-body-2 tree var get-symbol)))
      `(locally (declare (special .,*specials*)) ,inner))))

(defun make-built-in-wrapper-of-body-2 (tree var get-symbol)
  (declare (special *specials*))
  (let ((symbol (funcall get-symbol (car tree))))
    (push symbol *specials*)
    (let ((sub-tests
	    (mapcar #'(lambda (x)
			(make-built-in-wrapper-of-body-2 x var get-symbol))
		    (cdr tree))))
      `(and (typep ,var ',(car tree))
	    ,(if sub-tests
		 `(or ,.sub-tests ,symbol)
		 symbol)))))
)


(defun built-in-wrapper-of (x)
  #.(make-built-in-wrapper-of-body))

(defun built-in-class-of (x)
  #.(make-built-in-class-of-body))




;;;
;;;
;;;
(defmethod describe-class (class-or-class-name
			  &optional (stream *standard-output*))
  (flet ((pretty-class (class) (or (class-name class) class)))
    (if (symbolp class-or-class-name)
	(describe-class (find-class class-or-class-name) stream)
	(let ((class class-or-class-name))
	  (format stream
		  "~&The class ~S is an instance of class ~S."
		  class
		  (class-of class))
	  (format stream "~&Name:~23T~S~%~
			    Class-Precedence-List:~23T~S~%~
                            Local-Supers:~23T~S~%~
                            Direct-Subclasses:~23T~S"
		  (class-name class)
		  (mapcar #'pretty-class (class-class-precedence-list class))
		  (mapcar #'pretty-class (class-local-supers class))
		  (mapcar #'pretty-class (class-direct-subclasses class)))
	  class))))

(defmethod slots-to-inspect ((class standard-class) (object object))
  (class-slots class))

(defun describe-instance (object &optional (stream t))
  (let* ((class (class-of object))
	 (slotds (slots-to-inspect class object))
	 (max-slot-name-length 0)
	 (instance-slotds ())
	 (class-slotds ())
	 (other-slotds ()))
    (flet ((adjust-slot-name-length (name)
	     (setq max-slot-name-length
		   (max max-slot-name-length
			(length (the string (symbol-name name))))))
	   (describe-slot (name value &optional (allocation () alloc-p))
	     (if alloc-p
		 (format stream
			 "~% ~A ~S ~VT  ~S"
			 name allocation (+ max-slot-name-length 7) value)
		 (format stream
			 "~% ~A~VT  ~S"
			 name max-slot-name-length value))))
      ;; Figure out a good width for the slot-name column.
      (dolist (slotd slotds)
	(adjust-slot-name-length (slotd-name slotd))
	(case (slotd-allocation slotd)
	  (:instance (push slotd instance-slotds))
	  (:class  (push slotd class-slotds))
	  (otherwise (push slotd other-slotds))))
      (setq max-slot-name-length  (min (+ max-slot-name-length 3) 30))
      (format stream "~%~S is an instance of class ~S:" object class)

      (when instance-slotds
	(format stream "~% The following slots have :INSTANCE allocation:")
	(dolist (slotd (nreverse instance-slotds))
	  (describe-slot (slotd-name slotd)
			 (slot-value-or-default object (slotd-name slotd)))))

      (when class-slotds
	(format stream "~% The following slots have :CLASS allocation:")
	(dolist (slotd (nreverse class-slotds))
	  (describe-slot (slotd-name slotd)
			 (slot-value-or-default object (slotd-name slotd)))))

      (when other-slotds 
	(format stream "~% The following slots have allocation as shown:")
	(dolist (slotd (nreverse other-slotds))
	  (describe-slot (slotd-name slotd)
			 (slot-value-or-default object (slotd-name slotd))
			 (slotd-allocation slotd))))
      (values))))

(eval-when (compile load eval)
  (make-specializable 'describe
		      :arglist #-Lispm '(object)
		               #+Lispm '(object &optional no-complaints)))

(defmethod describe
	   #-Lispm ((object object))
	   #+Lispm ((object object) &optional no-complaints)
  #+Lispm
  (declare (ignore no-complaints))
  (describe-instance object))

(defmethod describe
	   #-Lispm ((class standard-class))
	   #+Lispm ((class standard-class) &optional no-complaints)
  #+Lispm
  (declare (ignore no-complaints))
  (describe-class class))


;;;
;;; trace-method and untrace-method accept method specs as arguments.  A
;;; method-spec should be a list like:
;;;   (<generic-function-spec> qualifiers* (specializers*))
;;; where <generic-function-spec> should be either a symbol or a list
;;; of (SETF <symbol>).
;;;
;;;   For example, to trace the method defined by:
;;;
;;;     (defmethod foo ((x spaceship)) 'ss)
;;;
;;;   You should say:
;;;
;;;     (trace-method '(foo (spaceship)))
;;;
;;;   You can also provide a method object in the place of the method
;;;   spec, in which case that method object will be traced.
;;;
;;; For untrace-method, if an argument is given, that method is untraced.
;;; If no argument is given, all traced methods are untraced.
;;;

(defvar *traced-methods* ())

(defun trace-method (spec &rest options)
  (multiple-value-bind (gf method name)
      (parse-method-or-spec spec)
    (pushnew method *traced-methods*)
    (trace-method-internal gf method name options)
    method))

(defun untrace-method (&optional spec)  
  (flet ((untrace-it (m)
	   (let ((untrace (memq m *traced-methods*)))
	     (if untrace
		 (multiple-value-bind (gf method spec)
		     (parse-method-or-spec m)
		   (declare (ignore gf method))
		   (eval `(untrace ,spec))
		   (setf (method-function method) (symbol-function spec)))
		 (error "~S is not a traced method?" m)))))
    (cond ((not (null spec))
	   (multiple-value-bind (gf method)
	       (parse-method-or-spec spec)
	     (declare (ignore gf))
	     (when (method-generic-function method)
	       (untrace-it method)
	       (setq *traced-methods* (delete method *traced-methods*))
	       (list method))))
	  (t
	   (dolist (m *traced-methods*)
	     (untrace-it m))
	   (prog1 *traced-methods*
		  (setq *traced-methods* ()))))))

(defun trace-method-internal (gf method name options)
  (declare (ignore gf))
  (let ((function (method-function method)))
    (eval `(untrace ,name))    
    (setf (symbol-function name) function)
    (eval `(trace ,name ,@options))
    (setf (method-function method) (symbol-function name))))




(defun compile-method (spec)
  (multiple-value-bind (gf method name)
      (parse-method-or-spec spec)
    (declare (ignore gf))
    (compile name (method-function method))
    (setf (method-function method) (symbol-function name))))

(defmacro undefmethod (&rest args)
  #+(or (not :lucid) :lcl3.0)
  (declare (arglist name {method-qualifier}* specializers))
  `(undefmethod-1 ',args))

(defun undefmethod-1 (args)
  (multiple-value-bind (gf method)
      (parse-method-or-spec args)
    (when (and gf method)
      (remove-method gf method)
      method)))



;(defmethod mki ((class-name symbol) &rest initargs)
;  (apply #'mki (find-class class-name) initargs))

;(defmethod make-instance ((class-name symbol) &rest initargs)
;  (apply #'make-instance (find-class class-name) initargs))

(defmethod change-class ((instance t) (new-class symbol))
  (change-class instance (find-class new-class)))

(defmethod make-instances-obsolete ((class symbol))
  (make-instances-obsolete (find-class class)))




(defclass eql-specializer-class (standard-class)
     ((object :initarg :object
	      :reader eql-specializer-class-object)))

(defmethod print-object ((class eql-specializer-class) stream)
  (named-object-print-function class
			       stream
			       (eql-specializer-class-object class)))

(defmethod check-super-metaclass-compatibility ((class eql-specializer-class)
						(super t))
  't)