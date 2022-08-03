;;;-*-Mode:LISP; Package:(PCL Lisp 1000); Base:10; Syntax:Common-lisp -*-
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

(defmethod class-prototype ((c standard-class))
; (or (slot-value--class c 'prototype)
;     (put-slot--class c 'prototype (make-instance c)))
  (or (slot-value c 'prototype)
      (setf (slot-value c 'prototype) (allocate-instance c))))

;;;
;;; class-direct-methods
;;; class-direct-generic-functions
;;;
;;; direct-methods is the primary value we store, direct-generic-functions
;;; is a derivative value that we also maintain.  For performance reasons
;;; we don't always keep the direct-generic-functions value up to date.
;;; 

(defmethod class-direct-methods ((class standard-class))
; (slot-value--class class 'direct-methods)
  (slot-value class 'direct-methods))

(defmethod (setf class-direct-methods) (nv (class standard-class))
  (with-slots (direct-methods direct-generic-functions)
	      class
    (without-interrupts
      (setf direct-methods nv
	    direct-generic-functions ()))))

(defmethod class-direct-generic-functions ((class standard-class))
  (with-slots (direct-generic-functions)
	      class
    (or direct-generic-functions
	(setf direct-generic-functions
	      (gathering ((result (collecting-once)))
		(dolist (m (class-direct-methods class))
		  (gather (method-generic-function m) result)))))))

#|

A class is 'fully defined' iff its class precedence list can be computed. This
is true when it and all of its superclasses are defined.

A class is 'defined' when a defclass form which defines that class has been
defined.

A class is 'undefined' when no class by that name exists.

  (defclass forward-referenced-standard-class (class) ())

  (defmethod make-instance ..
  (defmethod compute-class-precedence-list ..
  (defmethod compatible..
  (defmethod class-for-redefinition ..




when something changes, we walk down the tree passing the following information

where the changes actually happened and what it was,
whether the class at this point in the tree is fully defined,
whether the class at this point in the tree used to be fully defined


|#



;;; There are 6 cases:
;;;   F  --  F    | + 2 cases because a fully defined class can
;;;   F  --  NF   | either have instances or not have instances
;;;   NF --  NF
;;;   NF --  F
;;;
;;; 

;; n cases
;;; 1   a fully-defined class changes, all its subclasses are also fully
;;;     defined.  Just have to propagate info.
;;; 2   fully defined class with instances is changed to become not
;;;     fully defined.
;;; 3 a class which is not fully defined becomes fully defined because
;;;    some other class far above it becomes fully defined.
;;; 4  a not fully defined class with some defined subclasses is changed.
;;; 
(defmethod PROPAGATE-CLASS-UPDATE ((class standard-class)
				   new-fully-defined-p
				   old-fully-defined-p
				   changed-class
				   &rest key-arguments	  ;hidden argument
				   &key (its-direct-superclasses () supers-p)
					(its-options () options-p)
					(its-direct-slots  () slots-p))
  (declare (ignore its-direct-superclasses its-options its-direct-slots))

  (let ((old-cpl (class-precedence-list class))
	(new-cpl ()))
    
    (when new-fully-defined-p
      (cond (supers-p
	     (setq new-cpl (compute-class-precedence-list class))
	     (setf (class-precedence-list class) new-cpl)
	     (clear-precedence-dag-cache)
	     (update-slots--class class)
	     (update-constructors class))
	    ((or options-p slots-p)
	     (update-slots--class class)
	     (update-constructors class))))
    
    
    ;; Propagate all the change information down through our subclasses.
    ;; For each subclass we also compute its new and old fully-defined-p
    ;; status.  The details of this computation are specific to PCL.
    (dolist (subclass (class-direct-subclasses class))
      (let ((sub-forward-referenced-supers
	      (class-forward-referenced-supers subclass))
	    sub-newly-defined-p
	    sub-oldly-defined-p)
	(cond ((null sub-forward-referenced-supers)
	       ;; The subclass used to be fully defined.  By definition,
	       ;; that means that we used to be fully defined.  It also
	       ;; means that if we just became not-fully-defined this
	       ;; subclass must now become not fully defined.
	       (setq sub-newly-defined-p new-fully-defined-p
		     sub-oldly-defined-p 't)
	       (when (not new-fully-defined-p)
		 (setf (class-forward-referenced-supers subclass) (list class))))
	      ((and (eq (car sub-forward-referenced-supers) class)
		    (null (cdr sub-forward-referenced-supers)))
	       ;; The only reason this subclass used to be not fully defined
	       ;; is because we used to be not fully defined.  That means
	       ;; that if we are still not fully defined so is this subclass
	       ;; and if we just became fully defined so does this subclass.
	       (setq sub-newly-defined-p new-fully-defined-p
		     sub-oldly-defined-p old-fully-defined-p)
	       (when new-fully-defined-p
		 (setf (class-forward-referenced-supers subclass) ())))
	      (t
	       ;; The general case is where there were multiple reasons
	       ;; why this subclass used to be not-fully-defined.  That
	       ;; means it stays not fully defined, but we may add or
	       ;; remove ourselves as a reason.
	       (setq sub-newly-defined-p nil
		     sub-oldly-defined-p nil)
	       (setf (class-forward-referenced-supers subclass)
		     (if new-fully-defined-p
			 (delete class sub-forward-referenced-supers)
			 (pushnew class sub-forward-referenced-supers)))))
	
	(apply #'propagate-class-update subclass
					sub-newly-defined-p
					sub-oldly-defined-p
					changed-class
					key-arguments)))
    
    (when new-fully-defined-p
      (cond (supers-p
	     (when (eq class changed-class)
	       (update-method-inheritance class
					  old-cpl
					  (class-precedence-list class)))))
      (setf (class-all-default-initargs class)
	    (collect-all-default-initargs class new-cpl)))
    
    ))

;;;
;;; These 3 definitions appears here for bootstrapping reasons.  Logically,
;;; they should be in the construct file.  For documentation purposes, a
;;; copy of these definitions appears in the construct file.  If you change
;;; one of the definitions here, be sure to change the copy there.
;;; 
(defvar *initialization-generic-functions*
	(list #'make-instance
	      #'default-initargs
	      #'allocate-instance
	      #'initialize-instance
	      #'shared-initialize))

(defmethod maybe-update-constructors
	   ((generic-function standard-generic-function)
	    (method standard-method))
  (when (memq generic-function *initialization-generic-functions*)
    (labels ((recurse (class)
	       (update-constructors class)
	       (dolist (subclass (class-direct-subclasses class))
		 (recurse subclass))))
      (recurse (car (method-type-specifiers method))))))

(defmethod update-constructors ((class standard-class))
  (dolist (cons (class-constructors class))
    (install-lazy-constructor-installer cons)))

  
(defun update-slots--class (class)
  (let* ((cpl (class-precedence-list class))
	 (local-slots (class-local-slots class))
	 (slots ())
	 (instance-slots ())
	 (class-slots ())
	 (inherited-class-slots ()))

    ;; If I saved accessor/reader prefixes somewhere, I could save time
    ;; here.  Also, if merge actually kept track of whether something
    ;; changed that would save time.
    
    (merge-accessor/reader-prefixes local-slots (class-options class))
;   (check-accessor/reader-compatibility local-slots)

    (setq slots (order-slotds class
			      (collect-slotds class local-slots cpl)
			      cpl))
  
    (dolist (slot slots)
      (let ((allocation (slotd-allocation slot)))
	(cond ((eq allocation :instance) (push slot instance-slots))
	      ((eq allocation class) (push slot class-slots))
	      ((classp allocation)   (push slot inherited-class-slots)))))
    (setq instance-slots (nreverse instance-slots)
	  class-slots (nreverse class-slots))
	  

    (update-slot-accessors--class class slots)
      
    ;; If there is a change in the shape of the instances then the
    ;; old class is now obsolete.  
    (let* ((new-instance-slots-layout (mapcar #'slotd-name instance-slots))
	   (owrapper (class-wrapper class))
	   (nwrapper ()))

      (cond ((null owrapper)
	     (setq nwrapper (make-class-wrapper class))
	     (setf (class-wrapper class) nwrapper))
	    ((not (equal new-instance-slots-layout
			 (wrapper-instance-slots-layout owrapper)))
	     ;; This will initialize the new wrapper to have the same state
	     ;; as the old wrapper.  It is slightly wasted work but the spec
	     ;; mandates that we call this generic function so that user
	     ;; methods can be informed that the instances have been made
	     ;; obsolete.	    
	     (make-instances-obsolete class)
	     (setq nwrapper (class-wrapper class)))
	    (t
	     (setq nwrapper owrapper)))
      
      (setf (class-no-of-instance-slots class) (length instance-slots))
      (setf (class-slots class) slots)
      (setf (class-wrapper class) nwrapper)
      (setf (wrapper-instance-slots-layout nwrapper)
	    new-instance-slots-layout)
      (setf (wrapper-class-slots nwrapper)
	    (gathering1 (collecting)
	      (dolist (slotd inherited-class-slots)
		(gather1 (assoc (slotd-name slotd)
				(wrapper-class-slots
				  (class-wrapper (slotd-allocation slotd))))))
	      (dolist (slotd class-slots)
		(gather1 (cons (slotd-name slotd)
			       (funcall (slotd-initfunction slotd)))))))
      )))

(defun update-slot-accessors--class (class slots)
  (update-slot-accessors--class-1 class
				  slots
				  (class-slots class)))

(defun update-slot-accessors--class-1 (class slotds old-slotds)
  (dolist (slotd slotds)
    (let* ((slot-name (slotd-name slotd))
	   (old-slotd (dolist (o old-slotds)
			(when (eq slot-name (slotd-name o)) (return o))))
	   (forcep (and old-slotd
			(not (equal (slotd-type old-slotd)
				    (slotd-type slotd)))))
;          (old-accessors (and old-slotd (slotd-accessors old-slotd)))
	   (old-readers (and old-slotd (slotd-readers old-slotd)))
	   (old-writers (and old-slotd (slotd-writers old-slotd))))
      (update-slot-accessors--class-2
	class slotd forcep (slotd-readers slotd) old-readers :reader)
      (update-slot-accessors--class-2
	class slotd forcep (slotd-writers slotd) old-writers :writer))))

(defun update-slot-accessors--class-2 (class slotd forcep new old acc/rea)
  (flet ((get-gf (name) (ensure-generic-function name)))

    (dolist (gf-name old)
      (when (or forcep (not (memq gf-name new)))
	(ecase acc/rea
	  (:reader
	    (remove-reader-method class slotd (get-gf gf-name)))
	  (:writer
	    (remove-writer-method class slotd (get-gf gf-name))))))

    (dolist (gf-name new)
      (when (or forcep (not (memq gf-name old)))
	(ecase acc/rea
	  (:reader
	    (add-reader-method class slotd (get-gf gf-name)))
	  (:writer
	    (add-writer-method class slotd (get-gf gf-name))
	    (when (and (listp gf-name)
		       (eq (car gf-name) 'setf))
	      (do-standard-defsetf-1 (cadr gf-name)))))))))


(defun collect-all-default-initargs (class cpl)
  (declare (ignore class))
  (labels ((walk (tail)
	     (if (null tail)
		 nil
		 (append (class-default-initargs (car tail))
			 (walk (cdr tail))))))
    (let ((initargs (walk cpl)))
      (delete-duplicates initargs :test #'eq :key #'car :from-end t))))

;;;
;;; CLASS-FOR-REDEFINITION old-class proto-class name ds-options slotds
;;; protocol: class definition
;;; 
;;; When a class is being defined, and a class with that name already exists
;;; a decision must be made as to what to use for the new class object, and
;;; whether to update the old class object.  For this, class-for-redefinition
;;; is called with the old class object, the prototype of the new class, and
;;; the name ds-options and slotds corresponding to the new definition.
;;; It should return the class object to use as the new definition.  It is
;;; OK for this to be old-class if that is appropriate.
;;; 
(defmethod class-for-redefinition ((old-class standard-class)
				   (proto-class standard-class)
				   name
				   local-supers
				   local-slot-slotds
				   extra)
  (declare (ignore name local-supers local-slot-slotds extra))
  old-class)

(defmethod update-method-inheritance ((class standard-class) old-cpl new-cpl)
  (flet ((reset-gfs (c)
	   (dolist (m (class-direct-methods c))
	     (let ((gf (method-generic-function m)))
	       (unless (memq gf *umi-gfs*)
		 (invalidate-generic-function gf)
		 (push gf *umi-gfs*)))))
	 (reset-some-gfs (c1 c2)
	   (let ((gfs1 ()))
	     (dolist (m (class-direct-methods c1))
	       (pushnew (method-generic-function m) gfs1))
	     (dolist (m (class-direct-methods c2))
	       (let ((gf (method-generic-function m)))
		 (when (and (memq gf gfs1)
			    (not (memq gf *umi-gfs*)))
		   (invalidate-generic-function gf)
		   (push gf *umi-gfs*)))))))	   
    (multiple-value-bind (appear disappear reorder)
	(reordered-classes old-cpl new-cpl)
      (dolist (a appear)
	(unless (memq a *umi-complete-classes*)
	  (reset-gfs a)
	  (push a *umi-complete-classes*)))
      (dolist (d disappear)
	(unless (memq d *umi-complete-classes*)
	  (reset-gfs d)
	  (push d *umi-complete-classes*)))
      (dolist (r reorder)
	(dolist (c1 r)
	  (dolist (c2 (memq c1 r))
	    (let ((temp nil))
	      (cond ((setq temp (assq c1 *umi-reorder*))
		     (unless (memq c2 temp)
		       (reset-some-gfs c1 c2)
		       (push c2 (cdr temp))))
		    ((setq temp (assq c2 *umi-reorder*))
		     (unless (memq c1 temp)
		       (reset-some-gfs c1 c2)
		       (push c1 (cdr temp))))
		    (t
		     (push (list c1 c2) *umi-reorder*))))))))))


(defun reordered-classes (old-cpl new-cpl)
  (let ((old (reverse old-cpl))
	(new (reverse new-cpl))
	(appear ())
	(disappear ())
	(reorder ()))
    (iterate ((ot (list-tails old))
	      (nt (list-tails new)))
      (unless (eq (car ot) (car nt))
	(return (setq old ot new nt))))
    (dolist (n new) (unless (memq n old) (push n appear)))
    (dolist (o old) (unless (memq o new) (push o disappear)))
    (iterate ((old-tail (list-tails old)))
      (let ((old-head (car old-tail))
	    (new-tail nil)
	    (change ()))
	(unless (or (memq old-head appear)
		    (memq old-head disappear)
		    (dolist (r reorder) (when (memq old-head r) (return 't))))
	  (setq new-tail (memq (car old-tail) new))
	  (dolist (ot old-tail)
	    (unless (or (memq ot disappear)
			(memq ot new-tail))
	      (push ot change)))
	  (when change (push (cons old-head change) reorder)))))
    (values appear disappear reorder)))

(defmethod collect-slotds ((class standard-class) local-slots cpl)    
  (let ((slots ()))
    (labels ((collect-one-class (local-slots pos)
	       (setq local-slots (copy-list local-slots))
	       ;; For each of the slots we have already found, get the
	       ;; slot description this class has for a slot by that
	       ;; name or NIL if this class has no direct-slot by that
	       ;; name.
	       (dolist (slot slots)
		 (let ((hit (dolist (ls local-slots)
			      (when (eq (slotd-name ls) (car slot))
				(return ls)))))
		   (when hit (setq local-slots (delq hit local-slots)))
		   (push hit (cdr slot))))
	       ;; For any remaining direct-slots this class has, create
	       ;; a new entry in slots.  Add a bunch of trailing NILs
	       ;; to the entry to represent the classes that didn't
	       ;; have direct slots for this slot.
	       (dolist (ls local-slots)
		 (push (list* (slotd-name ls)
			      ls
			      (make-list pos :initial-element nil))
		       slots)))
	     (collect-cpl (cpl-tail)
	       (cond ((null cpl-tail) 0)
		     (t
		      (let ((pos (1+ (collect-cpl (cdr cpl-tail)))))
			(collect-one-class (class-local-slots (car cpl-tail))
					   pos)
			pos)))))

      (collect-one-class local-slots (collect-cpl (cdr cpl)))

      
      ;; Now use compute-effective-slotd to condense all the slot
      ;; descriptions for slots of the same name into one slot
      ;; description for that slot.
      (mapcar #'(lambda (descriptions)
		  (compute-effective-slotd class (cdr descriptions)))
	      slots))))

(defmethod order-slotds ((class standard-class) slotds cpl)
  (let ((superclass-slots (reverse (mapcar #'class-slots (cdr cpl)))))
    (flet ((superclass-slot-ordering (slotd)
	     ;; If a slot with this name appears in one of our supers,
	     ;; return two values:
	     ;;   1  the class-slots of the most general class this
	     ;;      slot appears in
	     ;;   2  a tail of the first value such that the its
	     ;;      first element is the relevant slotd
	     ;;
	     ;; The way to think of these two values is that they specify
	     ;; the first class which included this slot AND the position
	     ;; within instances of that class the slot appeared.
	     ;;
	     (dolist (order superclass-slots)
	       (let ((p (member slotd order
				:test #'(lambda (a b)
					  (and (eq (slotd-name a)
						   (slotd-name b))
					       (eq (slotd-allocation a)
						   (slotd-allocation b)))))))
		 (when p (return (values order p)))))))
      (sort slotds
	#'(lambda (x y)
	    (cond ((eq (slotd-allocation x) (slotd-allocation y))
		   (let (x-class-slots x-tail y-class-slots y-tail)
		     (multiple-value-setq (x-class-slots x-tail)
					  (superclass-slot-ordering x))
		     (multiple-value-setq (y-class-slots y-tail)
					  (superclass-slot-ordering y))
		     (cond ((null y-class-slots) 't)
			   ((null x-class-slots) 'nil)
			   ((eq x-class-slots y-class-slots)
			    (tailp y-tail x-tail))
			   (t
			    (memq y-class-slots
				  (memq x-class-slots
					superclass-slots))))))
		  ((eq (slotd-allocation x) ':instance) 't)
		  (t nil)))))))

(defmethod COMPUTE-EFFECTIVE-SLOTD ((class standard-class) slotds)
  (let* ((unsupplied *slotd-unsupplied*)
	 (name unsupplied)
	 (keyword unsupplied)
	 (initfunction unsupplied)
	 (initform unsupplied)
	 (initargs nil)
	 (allocation unsupplied)
	 (type unsupplied)
;	 (accessors (and (car slotds)
;			 (slotd-accessors (car slotds))))
	 (readers   (and (car slotds)
			 (slotd-readers (car slotds))))
	 (writers   (and (car slotds)
			 (slotd-writers (car slotds)))))

    (dolist (slotd slotds)
      (when slotd
	(when (eq name unsupplied)
	  (setq name (slotd-name slotd)
		keyword (slotd-keyword slotd)))
	(when (eq initform unsupplied)
	  (setq initform (slotd-initform slotd))
	  (setq initfunction (slotd-initfunction slotd)))
	(when (eq allocation unsupplied)
	  (setq allocation (slotd-allocation slotd)))
	(setq initargs (append (slotd-initargs slotd) initargs))
	(let ((slotd-type (slotd-type slotd)))
	  (setq type (cond ((eq type unsupplied) slotd-type)
			   ((eq slotd-type unsupplied) type)
			   ((subtypep type slotd-type) type)
			   (t `(and ,type ,slotd-type)))))))
    
;   (when (eq initform unsupplied)
;     (setq initfunction nil))
    (when (eq type unsupplied)
      (setq type 't))
    (when (eq allocation unsupplied)
      (setq allocation :instance))
    
    (make-slotd class
		:name name
		:keyword keyword
		:initform initform
		:initfunction initfunction
		:initargs initargs
		:allocation allocation
		:type type
;		:accessors accessors
		:readers readers
		:writers writers)))




;;;
;;; compute-class-precedence-list
;;;
(defmethod compute-class-precedence-list ((root standard-class))
  (compute-std-cpl root))

;;;
;;; Knuth section 2.2.3 has some interesting notes on this.
;;; 
;;; What appears here is basically the algorithm presented there.
;;;
;;; The key idea is that we use class-precedence-description (CPD) structures
;;; to store the precedence information as we proceed.  The CPD structure for
;;; a class stores two critical pieces of information:
;;; 
;;;  - a count of the number of "reasons" why the class can't go
;;;    into the class precedence list yet.
;;;    
;;;  - a list of the "reasons" this class prevents others from
;;;    going in until after it
;;
;;; A "reason" is essentially a single local precedence constraint.  If a
;;; constraint between two classes arises more than once it generates more
;;; than one reason.  This makes things simpler, linear, and isn't a problem
;;; as long as we make sure to keep track of each instance of a "reason".
;;;
;;; This code is divided into three phases.
;;; 
;;;  - the first phase simply generates the CPD's for each of the class
;;;    and its superclasses.  The remainder of the code will manipulate
;;;    these CPDs rather than the class objects themselves.  At the end
;;;    of this pass, the CPD-SUPERS field of a CPD is a list of the CPDs
;;;    of the direct superclasses of the class.
;;;
;;;  - the second phase folds all the local constraints into the CPD
;;;    structure.  The CPD-COUNT of each CPD is built up, and the
;;;    CPD-AFTER fields are augmented to include precedence constraints
;;;    from the CPD-SUPERS field and from the order of classes in other
;;;    CPD-SUPERS fields.
;;;
;;;    After this phase, the CPD-AFTER field of a class includes all the
;;;    direct superclasses of the class plus any class that immediately
;;;    follows the class in the direct superclasses of another.  There
;;;    can be duplicates in this list.  The CPD-COUNT field is equal to
;;;    the number of times this class appears in the CPD-AFTER field of
;;;    all the other CPDs.
;;;
;;;  - In the third phase, classes are put into the precedence list one
;;;    at a time, with only those classes with a CPD-COUNT of 0 being
;;;    candidates for insertion.  When a class is inserted , every CPD
;;;    in its CPD-AFTER field has its count decremented.
;;;
;;;    In the usual case, there is only one candidate for insertion at
;;;    any point.  If there is more than one, the specified tiebreaker
;;;    rule is used to choose among them.
;;;    

(defstruct (class-precedence-description
	     (:conc-name nil)
	     (:print-function (lambda (obj str depth)
				(declare (ignore depth))
				(format str
					"#<CPD ~S ~D>"
					(class-name (cpd-class obj))
					(cpd-count obj))))
	     (:constructor make-cpd ()))
  (cpd-class  nil)
  (cpd-supers ())
  (cpd-after  ())
  (cpd-count  0))

(defun compute-std-cpl (class)
  (let ((supers (class-local-supers class)))
    (cond ((null supers)			;First two branches of COND
	   (list class))			;are implementing the single
	  ((null (cdr supers))			;inheritance optimization.
	   (cons class (compute-std-cpl (car supers))))
	  (t
	   (multiple-value-bind (all-cpds nclasses)
	       (compute-std-cpl-phase-1 class supers)
	     (compute-std-cpl-phase-2 all-cpds)
	     (compute-std-cpl-phase-3 class all-cpds nclasses))))))

(defvar *compute-std-cpl-class->entry-table-size* 60)

(defun compute-std-cpl-phase-1 (class supers)
  (let ((nclasses 0)
	(all-cpds ())
	(table (make-hash-table :size *compute-std-cpl-class->entry-table-size*
				:test #'eq)))
    (labels ((get-cpd (c)
	       (or (gethash c table)
		   (setf (gethash c table) (make-cpd))))
	     (walk (c supers)
	       (if (forward-referenced-class-p c)
		   (cpl-forward-referenced-class-error class c)
		   (let ((cpd (get-cpd c)))
		     (unless (cpd-class cpd)	;If we have already done this
						;class before, we can quit.
		       (setf (cpd-class cpd) c)
		       (incf nclasses)
		       (push cpd all-cpds)
		       (setf (cpd-supers cpd) (mapcar #'get-cpd supers))
		       (dolist (super supers)
			 (walk super (class-local-supers super))))))))
      (walk class supers)
      (values all-cpds nclasses))))

(defun compute-std-cpl-phase-2 (all-cpds)
  (dolist (cpd all-cpds)
    (let ((supers (cpd-supers cpd)))
      (when supers
	(setf (cpd-after cpd) (nconc (cpd-after cpd) supers))
	(incf (cpd-count (car supers)) 1)
	(do* ((t1 supers t2)
	      (t2 (cdr t1) (cdr t1)))
	     ((null t2))
	  (incf (cpd-count (car t2)) 2)
	  (push (car t2) (cpd-after (car t1))))))))

(defun compute-std-cpl-phase-3 (class all-cpds nclasses)
  (let ((candidates ())
	(next-cpd nil)
	(rcpl ()))
    ;;
    ;; We have to bootstrap the collection of those CPD's that
    ;; have a zero count.  Once we get going, we will maintain
    ;; this list incrementally.
    ;; 
    (dolist (cpd all-cpds)
      (when (zerop (cpd-count cpd)) (push cpd candidates)))

    
    (loop
      (when (null candidates)
	;;
	;; If there are no candidates, and enough classes have been put
	;; into the precedence list, then we are all done.  Otherwise
	;; it means there is a consistency problem.
	(if (zerop nclasses)
	    (return (reverse rcpl))
	    (cpl-inconsistent-error class all-cpds)))
      ;;
      ;; Try to find the next class to put in from among the candidates.
      ;; If there is only one, its easy, otherwise we have to use the
      ;; famous RPG tiebreaker rule.  There is some hair here to avoid
      ;; having to call DELETE on the list of candidates.  I dunno if
      ;; its worth it but what the hell.
      ;; 
      (setq next-cpd
	    (if (null (cdr candidates))
		(prog1 (car candidates)
		       (setq candidates ()))
		(block tie-breaker		      
		  (dolist (c rcpl)
		    (let ((supers (class-local-supers c)))
		      (if (memq (cpd-class (car candidates)) supers)
			  (return-from tie-breaker (pop candidates))
			  (do ((loc candidates (cdr loc)))
			      ((null (cdr loc)))
			    (let ((cpd (cadr loc)))
			      (when (memq (cpd-class cpd) supers)
				(setf (cdr loc) (cddr loc))
				(return-from tie-breaker cpd))))))))))
      (decf nclasses)
      (push (cpd-class next-cpd) rcpl)
      (dolist (after (cpd-after next-cpd))
	(when (zerop (decf (cpd-count after)))
	  (push after candidates))))))

;;;
;;; Support code for signalling nice error messages.
;;;

(defun cpl-error (class format-string &rest format-args)
  (error "While computing the class precedence list of the class ~A.~%~A"
	  (if (class-name class)
	      (format nil "named ~S" (class-name class))
	      class)
	  (apply #'format nil format-string format-args)))
	  

(defun cpl-forward-referenced-class-error (class forward-class)
  (flet ((class-or-name (class)
	   (if (class-name class)
	       (format nil "named ~S" (class-name class))
	       class)))
    (let ((names (mapcar #'class-or-name
			 (cdr (find-superclass-chain class forward-class)))))
      (cpl-error class
		 "The class ~A is a forward referenced class.~@
                  The class ~A is ~A."
		 (class-or-name forward-class)
		 (class-or-name forward-class)
		 (if (null (cdr names))
		     (format nil
			     "a direct superclass of the class ~A"
			     (class-or-name class))
		     (format nil
			     "reached from the class ~A by following~@
                              the direct superclass chain through: ~A~
                              ~%  ending at the class ~A"
			     (class-or-name class)
			     (format nil
				     "~{~%  the class ~A,~}"
				     (butlast names))
			     (car (last names))))))))

(defun find-superclass-chain (bottom top)
  (labels ((walk (c chain)
	     (if (eq c top)
		 (return-from find-superclass-chain (nreverse chain))
		 (dolist (super (class-local-supers c))
		   (walk super (cons super chain))))))
    (walk bottom (list bottom))))


(defun cpl-inconsistent-error (class all-cpds)
  (let ((reasons (find-cycle-reasons all-cpds)))
    (cpl-error class
      "It is not possible to compute the class precedence list because~@
       there ~A in the local precedence relations.~@
       ~A because:~{~%  ~A~}."
      (if (cdr reasons) "are circularities" "is a circularity")
      (if (cdr reasons) "These arise" "This arises")
      (format-cycle-reasons (apply #'append reasons)))))

(defun format-cycle-reasons (reasons)
  (flet ((class-or-name (cpd)
	   (let ((class (cpd-class cpd)))
	     (if (class-name class)
		 (format nil "named ~S" (class-name class))
		 class))))
    (mapcar
      #'(lambda (reason)
	  (ecase (caddr reason)
	    (:super
	      (format
		nil
		"the class ~A appears in the supers of the class ~A"
		(class-or-name (cadr reason))
		(class-or-name (car reason))))
	    (:in-supers
	      (format
		nil
		"the class ~A follows the class ~A in the supers of the class ~A"
		(class-or-name (cadr reason))
		(class-or-name (car reason))
		(class-or-name (cadddr reason))))))      
      reasons)))

(defun find-cycle-reasons (all-cpds)
  (let ((been-here ())           ;List of classes we have visited.
	(cycle-reasons ()))
    
    (labels ((chase (path)
	       (if (memq (car path) (cdr path))
		   (record-cycle (memq (car path) (nreverse path)))
		   (unless (memq (car path) been-here)
		     (push (car path) been-here)
		     (dolist (after (cpd-after (car path)))
		       (chase (cons after path))))))
	     (record-cycle (cycle)
	       (let ((reasons ()))
		 (do* ((t1 cycle t2)
		       (t2 (cdr t1) (cdr t1)))
		      ((null t2))
		   (let ((c1 (car t1))
			 (c2 (car t2)))
		     (if (memq c2 (cpd-supers c1))
			 (push (list c1 c2 :super) reasons)
			 (dolist (cpd all-cpds)
			   (when (memq c2 (memq c1 (cpd-supers cpd)))
			     (return
			       (push (list c1 c2 :in-supers cpd) reasons)))))))
		 (push (nreverse reasons) cycle-reasons))))
      
      (dolist (cpd all-cpds)
	(unless (zerop (cpd-count cpd))
	  (chase (list cpd))))

      cycle-reasons)))



(defmethod compute-method-inheritance-list ((class standard-class)
					    local-supers)
  (declare (ignore local-supers))
  (compute-class-precedence-list class))

(defmethod compatible-meta-class-change-p (class proto-new-class)
  (eq (class-of class) (class-of proto-new-class)))

(defmethod check-super-metaclass-compatibility ((class t) (new-super t))
  (unless (eq (class-of class) (class-of new-super))
    (error "The class ~S was specified as a~%super-class of the class ~S;~%~
            but the meta-classes ~S and~%~S are incompatible."
	   new-super class (class-of new-super) (class-of class))))

(defun classp (x)
  (and (iwmc-class-p x) (typep--class x 'standard-class)))

(defun forward-referenced-class-p (x)
  (and (iwmc-class-p x) (typep--class x 'forward-referenced-class)))


;;;
;;; make-instances-obsolete can be called by user code.  It will cause the
;;; next access to the instance (as defined in 88-002R) to trap through the
;;; update-instance-for-redefined-class mechanism.
;;; 
(defmethod make-instances-obsolete ((class standard-class))
  (let ((owrapper (class-wrapper class))
	(nwrapper (make-class-wrapper class)))
      (setf (wrapper-instance-slots-layout nwrapper)
	    (wrapper-instance-slots-layout owrapper))
      (setf (wrapper-class-slots nwrapper)
	    (wrapper-class-slots owrapper))
      (setf (class-wrapper class) nwrapper)
      (invalidate-wrapper owrapper)))

;;;
;;; This method definition appears at the end of the file high.lisp
;;; where is is possible to have it.
;;; 
;(defmethod make-instances-obsolete ((class symbol))
;  (make-instances-obsolete (find-class class)))

;;;
;;; obsolete-instance-trap is the internal trap that is called when we see
;;; an obsolete instance.  The times when it is called are:
;;;   - when the instance is involved in method lookup
;;;   - when attempting to access a slot of an instance
;;;
;;; It is not called by class-of, wrapper-of, or any of the low-level instance
;;; access macros.
;;;
;;; Of course these times when it is called are an internal implementation
;;; detail of PCL and are not part of the documented description of when the
;;; obsolete instance update happens.  The documented description is as it
;;; appears in 88-002R.
;;;
;;; This has to return the new wrapper, so it counts on all the methods on
;;; obsolete-instance-trap-internal to return the new wrapper.  It also does
;;; a little internal error checking to make sure that the traps are only
;;; happening when they should, and that the trap methods are computing
;;; apropriate new wrappers.
;;; 
(defun obsolete-instance-trap (wrapper instance)
  (unless (zerop (wrapper-cache-no wrapper))
    (error "Internal error.~@
            Got an OBSOLETE-INSTANCE-TRAP, but wrapper-cache-no isn't 0."))
  (let ((new-wrapper (obsolete-instance-trap-internal (wrapper-class wrapper)
						      wrapper
						      instance)))
    (when (zerop (wrapper-cache-no new-wrapper))
      (error "Internal Error.~@
              wrapper-cache-no is still 0 after OBSOLETE-INSTANCE-TRAP."))
    new-wrapper))

;;;
;;; local  --> local        transfer 
;;; local  --> shared       discard
;;; local  -->  --          discard
;;; shared --> local        transfer
;;; shared --> shared       discard
;;; shared -->  --          discard
;;;  --    --> local        added
;;;  --    --> shared        --
;;; 
(defmacro obsolete-instance-trap-1 (wrapper-fetcher slots-fetcher)
  `(let* ((guts (allocate-instance class))
	  (nwrapper (class-wrapper class))
	  (olayout (wrapper-instance-slots-layout owrapper))
	  (nlayout (wrapper-instance-slots-layout nwrapper))
	  (oslots (,slots-fetcher instance))
	  (nslots (,slots-fetcher guts))
	  (oclass-slots (wrapper-class-slots owrapper))
	  (added ())
	  (discarded ())
	  (plist ()))

     ;; Go through all the old local slots.
     (iterate ((oslot (list-elements olayout))
	       (opos (interval :from 0)))
       (let ((npos (posq oslot nlayout)))
	 (if npos
	     (setf (svref nslots npos) (svref oslots opos))
	     (progn (push oslot discarded)
		    (setf (getf plist oslot) (svref oslots opos))))))

     ;; Go through all the old shared slots.
     (iterate ((oclass-slot-and-val (list-elements oclass-slots)))
       (let ((name (car oclass-slot-and-val))
	     (val (cdr oclass-slot-and-val)))
	 (let ((npos (posq name nlayout)))
	   (if npos
	       (setf (svref nslots npos) (cdr oclass-slot-and-val))
	       (progn (push name discarded)
		      (setf (getf plist name) val))))))

     ;; Go through all the new local and shared slots to compute
     ;; the added slots.
     (dolist (nslot nlayout)
       (unless (or (memq nslot olayout)
		   (assq nslot oclass-slots))
	 (push nslot added)))

     (without-interrupts
       (setf (,wrapper-fetcher instance) nwrapper)
       (setf (,slots-fetcher instance) nslots))

     (update-instance-for-redefined-class instance
					  added
					  discarded
					  plist)
     nwrapper))

(defmethod obsolete-instance-trap-internal ((class standard-class)
					    owrapper
					    instance)
  (obsolete-instance-trap-1 iwmc-class-class-wrapper
			    iwmc-class-static-slots))

(defmethod obsolete-instance-trap-internal ((class funcallable-standard-class)
					    owrapper
					    instance)
  (obsolete-instance-trap-1 funcallable-instance-wrapper
			    funcallable-instance-static-slots))



;;;
;;;
;;;
(defmacro change-class-internal (wrapper-fetcher slots-fetcher)
  `(let* ((old-class (class-of instance))
	  (copy (allocate-instance old-class))
	  (guts (allocate-instance new-class))
	  (new-wrapper (,wrapper-fetcher guts))
	  (old-wrapper (class-wrapper old-class))
	  (old-layout (wrapper-instance-slots-layout old-wrapper))
	  (new-layout (wrapper-instance-slots-layout new-wrapper))
	  (old-slots (,slots-fetcher instance))
	  (new-slots (,slots-fetcher guts))
	  (old-class-slots (wrapper-class-slots old-wrapper)))

    ;;
    ;; "The values of local slots specified by both the class Cto and
    ;; Cfrom are retained.  If such a local slot was unbound, it remains
    ;; unbound."
    ;;     
    (iterate ((new-slot (list-elements new-layout))
	      (new-position (interval :from 0)))
      (let ((old-position (position new-slot old-layout :test #'eq)))
	(when old-position
	  (setf (svref new-slots new-position)
		(svref old-slots old-position)))))

    ;;
    ;; "The values of slots specified as shared in the class Cfrom and
    ;; as local in the class Cto are retained."
    ;;
    (iterate ((slot-and-val (list-elements old-class-slots)))
      (let ((position (position (car slot-and-val) new-layout :test #'eq)))
	(when position
	  (setf (svref new-slots position) (cdr slot-and-val)))))

    ;; Make the copy point to the old instance's storage, and make the
    ;; old instance point to the new storage.
    (without-interrupts
      (setf (,slots-fetcher copy) old-slots)
      
      (setf (,wrapper-fetcher instance) new-wrapper)
      (setf (,slots-fetcher instance) new-slots))

    (update-instance-for-different-class copy instance)
    instance))

(defmethod change-class ((instance object)
			 (new-class standard-class))
  (unless (iwmc-class-p instance)
    (error "Can't change the class of ~S to ~S~@
            because it isn't already an instance whose metaclass is~%~S."
	   instance
	   new-class
	   'standard-class))
  (change-class-internal iwmc-class-class-wrapper
			 iwmc-class-static-slots))

(defmethod change-class ((instance object)
			 (new-class funcallable-standard-class))
  (unless (funcallable-instance-p instance)
    (error "Can't change the class of ~S to ~S~@
            because it isn't already an instance whose metaclass is~%~S."
	   instance
	   new-class
	   'funcallable-standard-class))
  (change-class-internal funcallable-instance-wrapper
			 funcallable-instance-static-slots))


;in high.lisp
;(defmethod change-class ((instance t) (new-class symbol))
;  (change-class instance (find-class symbol)))





(defun named-object-print-function (instance stream
				    &optional (extra nil extra-p))
  (declare (ignore depth))
  (printing-random-thing (instance stream)
    (if extra-p					
	(format stream "~A ~S ~:S"
		(capitalize-words (class-name (class-of instance)))
		(slot-value-or-default instance 'name)
		extra)
	(format stream "~A ~S"
		(capitalize-words (class-name (class-of instance)))
		(slot-value-or-default instance 'name)))))
