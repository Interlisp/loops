;;;-*-Mode:LISP; Package: PCL; Base:10; Syntax:Common-lisp -*-
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

#|

get rid of load-method-1 and friends, replace it with calls to add-method etc.

rename make-method

replace options with qualifiers everywhere

replace specifiers with specializers everywhere

method-class option of gf

hack-method-body option

expand-defmethod and expand-defmethod-setf  
  (have to make make-specializable'd too!!)



would like to be able to construct lexical environments as part of expand-defmethod-body and expand-defmethod-setf-body.

make-method --->> make-std-method

|#

  ;;   
;;;;;; Methods
  ;;

(eval-when (compile load eval)
  (mapcar #'eval *methods-defclass-forms*))

(defun generic-function-p (x) (typep x 'standard-generic-function))

(defun method-p (x) (typep x 'standard-method))

(defun standard-reader-method-p (x) (typep x 'standard-reader-method))
(defun standard-writer-method-p (x) (typep x 'standard-writer-method))

(defmethod (setf method-function) (nv (method standard-method))
  (setf (slot-value method 'function) nv)
  (let ((gf (method-generic-function method)))
    (when gf
      (notice-methods-change gf))))

;;;
;;; This method has to be defined by hand!  Don't try to define it using
;;; :accessor or :reader.  It can't be an automatically generated reader
;;; method because that would break the way the special discriminator
;;; code which uses this feature works.
;;; 
(defmethod reader/writer-method-slot-name ((m standard-reader/writer-method))
 ;(slot-value--class m 'slot-name)
  (slot-value m 'slot-name))


(defmethod print-object ((method standard-method) stream)
  (printing-random-thing (method stream)
    (let ((generic-function (method-generic-function method))
	  (class-name (capitalize-words (class-name (class-of method)))))
      (format stream "~A ~S ~{~S ~}~:S"
	      class-name
	      (and generic-function (generic-function-name generic-function))
	      (method-qualifiers method)
	      (unparse-specializers method)))))

(defmethod print-object ((generic-function standard-generic-function) stream)
  (named-object-print-function
    generic-function
    stream
    (list (length (generic-function-methods generic-function)))))


(defmethod shared-initialize :after ((method standard-method)
				     slot-names
				     &key qualifiers
					  arglist
					  type-specifiers
					  function
					  documentation)
  (declare (ignore slot-names))
  (setf (slot-value method 'qualifiers) qualifiers
	(slot-value method 'arglist) arglist
	(slot-value method 'type-specifiers) type-specifiers
	(slot-value method 'function) function
	(slot-value method 'documentation) documentation))

(defmethod shared-initialize :after ((method standard-reader/writer-method)
				     slot-names
				     &key slot-name)
  (declare (ignore slot-names))
  (setf (slot-value method 'slot-name) slot-name))
  

(defmethod shared-initialize :after ((gfun standard-generic-function)
				     slot-names
				     &key name 
;		                          argument-precedence-order
;		                          declarations
;		                          documentation
;		                          method-combination
					  method-class)
  (declare (ignore slot-names))
  (setf (slot-value gfun 'name) name
	(slot-value gfun 'method-class) method-class))

(defmethod remove-named-method (generic-function-name argument-specifiers
						      &optional extra)
  (let ((generic-function ())
	(method ()))
    (cond ((or (null (fboundp generic-function-name))
	       (not (generic-function-p
		      (setq generic-function
			    (symbol-function generic-function-name)))))
	   (error "~S does not name a generic-function."
		  generic-function-name))
	  ((null (setq method (get-method generic-function
					  extra
					  (parse-specializers
					    argument-specifiers)
					  nil)))
	   (error "There is no method for the generic-function ~S~%~
                   which matches the argument-specifiers ~S."
		  generic-function
		  argument-specifiers))
	  (t
	   (remove-method generic-function method)))))



(defvar *individual-specializer-methods* (make-hash-table :test #'eql))

(defmethod ADD-METHOD-ON-SPECIALIZER ((method standard-method) specializer)
  (cond ((classp specializer)
	 (pushnew method (class-direct-methods specializer)))
	((and (listp specializer)
	      (eq (car specializer) 'eql))
	 (let ((ind (cadr specializer)))
	   (pushnew method (gethash ind *individual-specializer-methods*))))
	(t
	 (error "Internal Error -- don't understand ~S as a specializer."
		specializer))))

(defmethod REMOVE-METHOD-ON-SPECIALIZER ((method standard-method) specializer)
  (cond ((classp specializer)
	 (setf (class-direct-methods specializer)
	       (delete method (class-direct-methods specializer))))
	((and (listp specializer)
	      (eq (car specializer) 'eql))
	 (let ((ind (cadr specializer)))
	   (setf (gethash ind *individual-specializer-methods*)
		 (delete method
			 (gethash ind *individual-specializer-methods*)))))
	(t
	 (error "Internal Error -- don't understand ~S as a specializer."
		specializer))))

	
(defun make-specializable (function-name &key (arglist nil arglistp))
  (cond ((not (null arglistp)))
	((not (fboundp function-name)))
	((fboundp 'function-arglist)
	 ;; function-arglist exists, get the arglist from it.
	 (setq arglist (function-arglist function-name)))
	(t
	 (error
	   "The :arglist argument to make-specializable was not supplied~%~
            and there is no version of FUNCTION-ARGLIST defined for this~%~
            port of Portable CommonLoops.~%~
            You must either define a version of FUNCTION-ARGLIST (which~%~
            should be easy), and send it off to the Portable CommonLoops~%~
            people or you should call make-specializable again with the~%~
            :arglist keyword to specify the arglist.")))
  (let ((original (and (fboundp function-name)
		       (symbol-function function-name)))
	(generic-function (make-instance 'standard-generic-function
					 :name function-name))
	(nrequireds 0))
    (if (generic-function-p original)
	original
	(progn
	  (dolist (arg arglist)
	    (if (memq arg lambda-list-keywords)
		(return)
		(incf nrequireds)))
	  (setf (symbol-function function-name) generic-function)
	  (set-function-name generic-function function-name)
	  (when arglistp
	    (setf (generic-function-pretty-arglist generic-function) arglist))
	  (when original
	    (add-named-method function-name
			      ()
			      (make-list nrequireds :initial-element 't)
			      arglist
			      original))
	  generic-function))))

;;;
;;; This is based on the rules of method lambda list congruency defined in
;;; the spec.  The lambda list it constructs is the pretty union of the
;;; lambda lists of all the methods.  It doesn't take method applicability
;;; into account at all yet.
;;; 
(defmethod generic-function-pretty-arglist
	   ((generic-function standard-generic-function))
  (let ((methods (generic-function-methods generic-function))
	(arglist ()))      
    (when methods
      (multiple-value-bind (required optional rest key allow-other-keys)
	  (method-pretty-arglist (car methods))
	(dolist (m (cdr methods))
	  (multiple-value-bind (method-key-keywords method-allow-other-keys method-key)
	      (function-keywords m)
	    ;; we've modified function-keywords to return what we want as
	    ;;  the third value, no other change here.
	    (declare (ignore method-key-keywords))
	    (setq key (union key method-key))
	    (setq allow-other-keys (or allow-other-keys
				       method-allow-other-keys))))
	(when allow-other-keys
	  (setq arglist '(&allow-other-keys)))
	(when key
	  (setq arglist (nconc (list '&key) key arglist)))
	(when rest
	  (setq arglist (nconc (list '&rest rest) arglist)))
	(when optional
	  (setq arglist (nconc (list '&optional) optional arglist)))
	(nconc required arglist)))))

(defmethod function-keywords ((method standard-method))
  (flet ((get-keyword-from-arg (arg)
	   (if (listp arg)
	       (if (listp (car arg))
		   (caar arg)
		   (make-keyword (car arg)))
	       (make-keyword arg))))
    (let ((keys ())
	  (syms ()) 			; also collect the args themselves
	  (allow-other-keys nil)
	  (state nil))
      (dolist (arg (method-arglist method))
	(if (memq arg lambda-list-keywords)
	    (case arg
	      (&key              (setq state 'key))
	      (&allow-other-keys (setq allow-other-keys 't)))
	    (when (eq state 'key)
	      (push (get-keyword-from-arg arg)
		    keys)
	      (push (if (listp arg)	; collect the args, too.
			(if (listp (car arg))
			    (caar arg)
			    (car arg))
			arg) syms))))
      ;; return the collected keyword *ARGS* as third value.
      (values (reverse keys) allow-other-keys (reverse syms)))))

(defmethod method-pretty-arglist ((method standard-method))
  (let ((required ())
	(optional ())
	(rest nil)
	(key ())
	(allow-other-keys nil)
	(state 'required)
	(arglist (method-arglist method)))
    (dolist (arg arglist)
      (cond ((eq arg '&optional)         (setq state 'optional))
	    ((eq arg '&rest)             (setq state 'rest))
	    ((eq arg '&key)              (setq state 'key))
	    ((eq arg '&allow-other-keys) (setq allow-other-keys 't))
	    ((memq arg lambda-list-keywords))
	    (t
	     (ecase state
	       (required (push arg required))
	       (optional (push arg optional))
	       (key      (push arg key))
	       (rest     (setq rest arg))))))
    (values (nreverse required)
	    (nreverse optional)
	    rest
	    (nreverse key)
	    allow-other-keys)))

(defun real-get-method (generic-function qualifiers specializers
					 &optional (errorp t))
  (let ((hit (dolist (method (generic-function-methods generic-function))
	       (when (method-equal method qualifiers specializers)
		 (return method)))))
    (cond (hit hit)
	  ((null errorp) nil)
	  (t
	   (error "No method on ~S with qualifiers ~:S and specializers ~:S."
		  generic-function qualifiers specializers)))))

(defmethod method-equal ((method standard-method) qualifiers specializers)
  (and (equal qualifiers (method-qualifiers method))
       (equal specializers (method-type-specifiers method))))


(defmethod generic-function-default-method
	   ((generic-function standard-generic-function))
  (dolist (m (generic-function-methods generic-function))
    (when (every #'(lambda (x) (eq x *the-class-t*))
		 (method-type-specifiers m))
      (return m))))

  ;;   
;;;;;; 
  ;;



(defun flush-generic-function-caches (generic-function)
  (let ((cache (generic-function-cache generic-function)))
    (when cache (flush-generic-function-caches-internal cache))))

(defmethod update-discriminator-code
	   ((generic-function standard-generic-function))
  (install-discriminating-function
    generic-function (compute-discriminator-code generic-function)))

(defmethod install-discriminating-function
	   ((generic-function standard-generic-function) function)
  (set-funcallable-instance-function generic-function function)
  (setf (generic-function-discriminator-code generic-function) function))

(defmethod compute-discriminator-code ((generic-function
					 standard-generic-function))
  (compute-discriminator-code-1 generic-function))
  
(defun compute-discriminator-code-1 (generic-function)
  (let ((combined (generic-function-combined-methods generic-function))
	(methods (generic-function-methods generic-function))
	(std-class (find-class 'standard-class))
	(t-class *the-class-t*)
	(r/w nil))
    (cond ((null combined)
	   (make-no-methods-dcode generic-function))
	  ((and (null (cdr combined))
		(every #'(lambda (x) (eq x t-class)) (caar combined)))
           (make-default-method-only-dcode generic-function))
	  ((not
	     (dolist (m methods)
	       (let* ((specls (method-type-specifiers m))
		      (spec0 (car specls))
		      (spec1 (cadr specls)))
		 (cond ((and (memq r/w '(nil r))
			     (standard-reader-method-p m)
			     (not (listp spec0))
			     (if (symbolp spec0)
				 (and (neq spec0 'standard-generic-function)
				      (neq spec0 'generic-function))
				 (eq (class-of spec0) std-class)))
			(setq r/w 'r))
		       ((and (memq r/w '(nil w))
			     (standard-writer-method-p m)
			     (not (listp spec1))
			     (if (symbolp spec1)
				 (and (neq spec1 'standard-generic-function)
				      (neq spec1 'generic-function))
				 (eq (class-of spec1) std-class)))
			(setq r/w 'w))
		       (t
			(return t))))))
	   (if (eq r/w 'r)
	       (make-all-std-class-readers-dcode generic-function) 
	       (make-all-std-class-writers-dcode generic-function)))
	  ((null (cdr combined))
	   (make-checking-dcode generic-function))
          (t
           (make-caching-dcode generic-function)))))

(defun lookup-method-1 (generic-function &rest args)
  (apply #'lookup-method-internal generic-function
	 (slot-value--fsc generic-function 'methods)
	 #'(lambda (x)
	     (slot-value--std x 'type-specifiers))
	 args))

(defun lookup-method-2 (generic-function &rest args)
  (cadr (apply #'lookup-method-internal
	       generic-function
	       (slot-value--fsc generic-function 'combined-methods)
	       #'car
	       args)))
;;;
;;;
;;;

(defvar *lookup-method1* (make-array (min 128. call-arguments-limit)))
(defvar *lookup-method2* (make-array (min 128. call-arguments-limit)))

(defmacro get-class (i a)
  (once-only (i a)
    `(or (svref classes ,i)
	 (get-class-1 classes ,i ,a))))

(defmacro get-cpl (i a)
  (once-only (i a)
    `(or (svref cpls ,i)
	 (get-cpl-1 cpls classes ,i ,a))))

(defun get-class-1 (classes i a)
  (setf (svref classes i) (class-of-1 a)))

(defun get-cpl-1 (cpls classes i a)
  (setf (svref cpls i)
	(slot-value--std (or (svref classes i)	  ;Partial inline code
			     (get-class-1 classes i a)) ;for get-class.
			 'class-precedence-list)))
  

(defun lookup-method-internal (generic-function methods key &rest args)
  (declare (ignore generic-function))
  (let* (
;        (order (slot-value--fsc generic-function 'dispatch-order))
	 (cpls *lookup-method1*)
	 (classes *lookup-method2*)
	 (most-specific-method nil)
	 (most-specific-specializers ())
	 (specializers ()))
    (without-interrupts
      (let ((i 0))
	(dolist (a args)
	  (progn a)
	  (when (> i 128)
	    (error "The PCL method lookup mechanism can only handle 128~%~
                    specialized arguments to a generic function."))
	  (setf (svref cpls i) nil
		(svref classes i) nil)
	  (incf i)))
	
      (dolist (method methods)
	(setq specializers (funcall key method))
	(unless (iterate ((specializer (list-elements specializers))
			  (i (interval :from 0))
			  (arg (list-elements args)))
		  (specializer-case specializer
		    (:eql (error "Shouldn't get an EQL specializer here."))
		    (:class 
		      (unless (or (eq specializer *the-class-t*)
				  (memq specializer (get-cpl i arg)))
			(return t)))))
	  (if (null most-specific-method)
	      (setq most-specific-method method
		    most-specific-specializers specializers)
	      (iterate ((old-spec (list-elements most-specific-specializers))
			(new-spec (list-elements specializers))
			(arg (list-elements args))
			(i (interval :from 0)))
		(cond ((eq old-spec new-spec))
		      ((memq old-spec (memq new-spec (get-cpl i arg)))
		       (return
			 (setq most-specific-method method
			       most-specific-specializers specializers)))
		      (t
		       (return nil)))))))
      most-specific-method
      )))

;;;
;;; Compute various information about a generic-function's arglist by looking
;;; at the argument lists of the methods.  The hair for trying not to use
;;; &rest arguments lives here.
;;;  The values returned are:
;;;    number-of-required-arguments
;;;       the number of required arguments to this generic-function's
;;;       discriminating function
;;;    &rest-argument-p
;;;       whether or not this generic-function's discriminating
;;;       function takes an &rest argument.
;;;    specialized-argument-positions
;;;       a list of the positions of the arguments this generic-function
;;;       specializes (e.g. for a classical generic-function this is the
;;;       list: (1)).
;;;
(defmethod compute-discriminating-function-arglist-info
	   ((generic-function standard-generic-function))
  (declare (values number-of-required-arguments
                   &rest-argument-p
                   specialized-argument-postions))
  (let ((number-required nil)
        (restp nil)
        (specialized-positions ())
	(methods (generic-function-methods generic-function)))
    (dolist (method methods)
      (multiple-value-setq (number-required restp specialized-positions)
        (compute-discriminating-function-arglist-info-internal
	  generic-function method number-required restp specialized-positions)))
    (values number-required restp (sort specialized-positions #'<))))

(defun compute-discriminating-function-arglist-info-internal
       (generic-function method number-of-requireds restp
	specialized-argument-positions)
  (declare (ignore generic-function))
  (let ((requireds 0))
    ;; Go through this methods arguments seeing how many are required,
    ;; and whether there is an &rest argument.
    (dolist (arg (method-arglist method))
      (cond ((eq arg '&aux) (return))
            ((memq arg '(&optional &rest &key))
             (return (setq restp t)))
	    ((memq arg lambda-list-keywords))
            (t (incf requireds))))
    ;; Now go through this method's type specifiers to see which
    ;; argument positions are type specified.  Treat T specially
    ;; in the usual sort of way.  For efficiency don't bother to
    ;; keep specialized-argument-positions sorted, rather depend
    ;; on our caller to do that.
    (iterate ((type-spec (list-elements (method-type-specifiers method)))
              (pos (interval :from 0)))
      (unless (eq type-spec *the-class-t*)
	(pushnew pos specialized-argument-positions)))
    ;; Finally merge the values for this method into the values
    ;; for the exisiting methods and return them.  Note that if
    ;; num-of-requireds is NIL it means this is the first method
    ;; and we depend on that.
    (values (min (or number-of-requireds requireds) requireds)
            (or restp
		(and number-of-requireds (/= number-of-requireds requireds)))
            specialized-argument-positions)))

(defun make-discriminating-function-arglist (number-required-arguments restp)
  (nconc (gathering ((args (collecting)))
           (iterate ((i (interval :from 0 :below number-required-arguments)))
             (gather (intern (format nil "Discriminating Function Arg ~D" i))
		     args)))
         (when restp
               `(&rest ,(intern "Discriminating Function &rest Arg")))))

(defmethod no-applicable-method (generic-function &rest args)
  (error "No matching method for the generic-function ~S,~@
          when called with arguments ~S."
	 generic-function args))




(defun real-remove-method (generic-function method)
  (remove-method-internal generic-function method)
  (notice-methods-change generic-function)
  (maybe-update-constructors generic-function method)
  generic-function)

(defun remove-method-internal (generic-function method)
  (setf (method-generic-function method) nil)
  (setf (generic-function-methods generic-function)
	(delq method (generic-function-methods generic-function)))
  (dolist (specializers (method-type-specifiers method))
    (remove-method-on-specializer method specializers)))
  

(defun real-add-named-method (generic-function-name
			      qualifiers
			      specializers
			      lambda-list
			      function
			      &rest other-initargs)
  ;; What about changing the class of the generic-function if there is
  ;; one.  Whose job is that anyways.  Do we need something kind of
  ;; like class-for-redefinition?
  (let* ((generic-function
	   (ensure-generic-function generic-function-name
				    :lambda-list lambda-list))
	 (specs (parse-specializers specializers))
;	 (existing (get-method generic-function qualifiers specs nil))
	 (proto (method-prototype-for-gf generic-function-name))
	 (new (apply #'make-instance (class-of proto)
				     :qualifiers qualifiers
				     :type-specifiers specs
				     :arglist lambda-list
				     :function function
				     other-initargs)))
;   (when existing (remove-method generic-function existing))
    (add-method generic-function new)))


(defun real-add-method (generic-function method)
  (let* ((specializers (method-type-specifiers method))
	 (qualifiers (method-qualifiers method))
	 (existing (get-method generic-function qualifiers specializers nil)))
    (when existing
      (remove-method-internal generic-function existing))    
    (setf (method-generic-function method) generic-function)
    (pushnew method (generic-function-methods generic-function))
    (dolist (specializer specializers)
      (add-method-on-specializer method specializer))
    (notice-methods-change generic-function)    
    (maybe-update-constructors generic-function method)
    method))

(defmethod invalidate-generic-function ((gf standard-generic-function))
  (notice-methods-change gf))

(defvar *invalid-generic-functions-on-stack* ())

(defun notice-methods-change (generic-function)
  (let ((old-discriminator-code
	  (generic-function-discriminator-code generic-function)))
    (if (null old-discriminator-code)		   ;This happens sometimes
						   ;during bootstrapping.
	(notice-methods-change-1 generic-function)
	;; Install a lazy evaluation discriminator code updator as the
	;; funcallable-instance function of the generic function.  When
	;; it is called, it will update the discriminator code of the
	;; generic function, unless it is inside a recursive call to
	;; the generic function in which case it will call the old
	;; version of the discriminator code for the generic function.
	;;
	;; Note that because this closure will be the discriminator code
	;; of a generic function it must be careful about how it changes
	;; the discriminator code of that same generic function.  If it
	;; isn't careful, it could change its closure variables out from
	;; under itself.
	;;
	;; In order to prevent this we take a simple measure:  we just
	;; make sure that it doesn't try to reference its own closure
	;; variables after it makes the dcode change.  This is done by
	;; having notice-methods-change-2 do the work of making the
	;; change AND calling the actual generic function (a closure
	;; variable) over.  This means that at the time the dcode change
	;; is made, there is a pointer to the generic function on the
	;; stack where it won't be affected by the change to the closure
	;; variables.
	;;
	(set-funcallable-instance-function
	  generic-function
	  #'(lambda (&rest args)
	      #+Genera
	      (declare (dbg:invisible-frame :clos-internal))
	      (if (memq generic-function *invalid-generic-functions-on-stack*)
		  (apply old-discriminator-code args)
		  (notice-methods-change-2 generic-function args)))))))

(defun notice-methods-change-2 (generic-function args)
  #+Genera
  (declare (dbg:invisible-frame :clos-internal))
  (let ((*invalid-generic-functions-on-stack*
	  (cons generic-function
		*invalid-generic-functions-on-stack*)))
    (notice-methods-change-1 generic-function)
    (apply generic-function args)))

(defun notice-methods-change-1 (generic-function)
  (setf (generic-function-combined-methods generic-function)
	(compute-combined-methods generic-function))
  (update-discriminator-code generic-function)
  (flush-generic-function-caches generic-function)
  (setf (generic-function-valid-p generic-function) t))

(defun compute-applicable-methods-internal (gf args)
  (let* ((valid-p (slot-value--fsc gf 'valid-p))
	 (combin
	   (if valid-p
	       (slot-value--fsc gf 'combined-methods)
	       (if (memq gf *invalid-generic-functions-on-stack*)
		   (compute-combined-methods gf)
		   (let ((*invalid-generic-functions-on-stack*
			   (cons gf *invalid-generic-functions-on-stack*)))
		     (notice-methods-change-1 gf)
		     (slot-value--fsc gf 'combined-methods)))))
	 (lookup (apply #'lookup-method-internal gf combin #'car args)))
    (if (cdddr lookup)
	(eql-method-runtime-internal args (caddr lookup) (cadddr lookup))
	(caddr lookup))))