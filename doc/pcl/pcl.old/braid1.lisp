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
;;; The meta-braid.

(in-package 'pcl)

(eval-when (compile load eval)

(defun early-collect-inheritance (class-name)
  (declare (values slots cpl direct-subclasses))
  (multiple-value-bind (slots cpl)
      (early-collect-inheritance-1 class-name)
    (values slots
            cpl
	    (gathering ((subs (collecting)))
	      (dolist (defclass *early-defclass-forms*)
		(when (memq class-name (caddr defclass))
		   (gather (cadr defclass) subs)))))))

(defun early-collect-inheritance-1 (class-name)
  (let ((defclass (find class-name *early-defclass-forms* :key #'cadr)))
    (unless defclass
      (error "~S is not a class in *early-defclass-forms*." class-name))
    (destructuring-bind (includes slots . options) (cddr defclass)
      (when options
	(unless (and (equal options '((:metaclass built-in-class)))
		     (eq class-name 'symbol))
	  (error "options not supported in *early-defclass-forms*.")))
      (when (cdr includes)
        (error "multiple supers not allowed in *early-defclass-forms*."))
      (if includes
          (multiple-value-bind (super-slots super-cpl)
              (early-collect-inheritance-1 (car includes))
            (values (append super-slots slots)
                    (cons class-name super-cpl)))
          (values slots
                  (list class-name))))))

(defvar *std-class-slots* (early-collect-inheritance 'standard-class))

(defvar *std-slotd-slots* (early-collect-inheritance 'standard-slot-description))

;(defconstant class-instance-slots-position
;             (position 'instance-slots *std-class-slots* :key #'car))

;(defconstant slotd-name-position
;             (position 'name *std-slotd-slots* :key #'car))

);eval-when


;;; CLASS-INSTANCE-SLOTS and SLOTD-NAME have to be defined specially!
;;;
;;; They cannot be defined using slot-value-using-class like all the other
;;; accessors are.  This is because slot-value-using-class itself must call
;;; CLASS-INSTANCE-SLOTS and SLOTD-NAME to do the slot access.
;;;
;;; This 'bottoming out' of the run-time slot-access code will be replaced
;;; by a corresponding bootstrapping constraint when permutation vectors
;;; happen.
;;;
;;; The defsetfs for these set-xxx functions are in defs.
;;; 
;(defun class-instance-slots (class)
;  (get-static-slot--class class
;                          (%convert-slotd-position-to-slot-index
;                            class-instance-slots-position)))
;
;(defun |SETF CLASS-INSTANCE-SLOTS| (new-value class)
;  (setf (get-static-slot--class class
;                                (%convert-slotd-position-to-slot-index
;                                  class-instance-slots-position))
;        new-value))

(defun slotd-name (slotd)
  (slot-value slotd 'name)
; (get-static-slot--class slotd
;                         (%convert-slotd-position-to-slot-index
;                            slotd-name-position))
  )

(defun SETF\ SLOTD-NAME (new-value slotd)
  (setf (slot-value slotd 'name) new-value)
; (setf (get-static-slot--class slotd
;                               (%convert-slotd-position-to-slot-index
;                                 slotd-name-position))
;       new-value)
  )



;;;
;;; bootstrap-get-slot and bootstrap-set-slot are used to access and change
;;; the values of slots during bootstrapping.  During bootstrapping, there
;;; are only two kinds of objects whose slots we need to access, CLASSes
;;; and SLOTDs.  The first argument to these functions tells whether the
;;; object is a CLASS or a SLOTD.
;;; 
(defun bootstrap-get-slot (type object slot-name)
  (svref (iwmc-class-static-slots object)
	 (bootstrap-slot-index type slot-name)))

(defun bootstrap-set-slot (type object slot-name new-value)
  (setf (svref (iwmc-class-static-slots object)
	       (bootstrap-slot-index type slot-name))
        new-value))

(defun bootstrap-slot-index (type slot-name)
  (let ((position 0)
        (slots (ecase type
                 (class *std-class-slots*)
                 (slotd *std-slotd-slots*))))
    ;; This loop is a hand coded version of:
    ;; 
    ;;   (setq position (position slot-name slots :key #'car))
    ;;   
    (loop (cond ((eq (caar slots) slot-name) (return t))
                ((null slots) (error "~S not found" slot-name))
                (t (pop slots) (incf position))))
    position))


;;;
;;; bootstrap-meta-braid
;;;   
(defun bootstrap-meta-braid ()
  (let* ((std-class-size (length *std-class-slots*))
         (std-class (%allocate-instance--class std-class-size))
         (std-class-wrapper (make-class-wrapper std-class))
	 (built-in-class (%allocate-instance--class std-class-size))
	 (built-in-class-wrapper (make-class-wrapper built-in-class))
	 (std-slotd (%allocate-instance--class  std-class-size))
         (std-slotd-wrapper (make-class-wrapper std-slotd)))
    ;;
    ;; First, make a class object for each of the early classes.
    ;; 
    (dolist (early-defclass *early-defclass-forms*)
      (let* ((name (cadr early-defclass))
             (class (case name
                      (standard-class std-class)
                      (standard-slot-description std-slotd)
		      (built-in-class built-in-class)
                      (otherwise
			(%allocate-instance--class std-class-size)))))
        (setf (iwmc-class-class-wrapper class)
	      (if (eq name 'symbol) built-in-class-wrapper std-class-wrapper))
        (setf (find-class name) class)
	(when (eq name 't)
	  (setq *the-class-t* class))
	(when (eq name 'object)
	  (setq *the-class-object* class))
	(when (eq name 'symbol)
	  (setq *the-class-symbol* class))))

    ;;
    ;; Now go back and initialize those classes.
    ;; 
    (dolist (early-defclass *early-defclass-forms*)      
      (multiple-value-bind (slots cpl direct-subclasses)
          (early-collect-inheritance (cadr early-defclass))
        (let* ((name (cadr early-defclass))
               (includes (caddr early-defclass))
               (local-slots (cadddr early-defclass))
               (class (find-class name))
               (wrapper
		 (cond ((eq class std-class) std-class-wrapper)
		       ((eq class std-slotd) std-slotd-wrapper)
		       ((eq class built-in-class) built-in-class-wrapper)
		       (t (make-class-wrapper class))))
               (proto nil))

	  (dolist (slot slots)
	    (unless (eq (getf (cdr slot) :allocation :instance) :instance)
	      (error "Slot allocation ~S not supported in bootstrap.")))
	  
	  (setf (wrapper-instance-slots-layout wrapper)
		(mapcar #'car slots))
	  (setf (wrapper-class-slots wrapper)
		())
          
          (setq proto (%allocate-instance--class (length slots)))
          (setf (iwmc-class-class-wrapper proto) wrapper)

	  (setq local-slots (bootstrap-parse-slots local-slots
                                                   std-slotd-wrapper))
          (setq slots (bootstrap-parse-slots slots
					     std-slotd-wrapper))

          (bootstrap-initialize class name includes local-slots
                                slots cpl direct-subclasses
                                wrapper proto)
	  (unless (memq name '(symbol t))
	    (inform-type-system-about-class class name))

          (dolist (slotd local-slots)
            (bootstrap-accessor-definitions
              name
              (bootstrap-get-slot 'slotd slotd 'name)
              (bootstrap-get-slot 'slotd slotd 'readers)
              (bootstrap-get-slot 'slotd slotd 'writers))))))))

(defun bootstrap-accessor-definitions (class-name slot-name readers writers)
  (let ((reader-constructor
	  (get-templated-function-constructor 'reader-function--std))
	(writer-constructor
	  (get-templated-function-constructor 'writer-function--std)))
    (flet ((do-reader-definition (reader)
	     (add-method
	       (ensure-generic-function reader)
	       (make-a-method
		 'standard-reader-method
		 ()
		 (list class-name)
		 (list class-name)
		 (funcall reader-constructor slot-name)
		 "automatically generated reader method"
		 slot-name)))
	   (do-writer-definition (writer)
	     (add-method
	       (ensure-generic-function writer)
	       (make-a-method
		 'standard-writer-method
		 ()
		 (list 'new-value class-name)
		 (list 't class-name)
		 (funcall writer-constructor slot-name)
		 "automatically generated writer method"
		 slot-name))))
      (dolist (reader readers)
	(do-reader-definition reader))
      (dolist (writer writers)
	(do-writer-definition writer)))))
          
(defun bootstrap-initialize
       (c name includes local-slots slots cpl subs wrapper proto)
  (flet ((classes (names) (mapcar #'find-class names)))
    (bootstrap-set-slot 'class c 'name name)
    (bootstrap-set-slot 'class c 'options nil)
    (bootstrap-set-slot 'class c 'class-precedence-list (classes cpl))
    (bootstrap-set-slot 'class c 'local-supers (classes includes))
    (bootstrap-set-slot 'class c 'local-slots local-slots)
    (bootstrap-set-slot 'class c 'direct-subclasses (classes subs))
    (bootstrap-set-slot 'class c 'direct-methods ())
    (bootstrap-set-slot 'class c 'no-of-instance-slots (length slots))
    (bootstrap-set-slot 'class c 'slots slots)
    (bootstrap-set-slot 'class c 'wrapper wrapper)
    (bootstrap-set-slot 'class c 'direct-generic-functions ())
    (bootstrap-set-slot 'class c 'prototype proto)
    (bootstrap-set-slot 'class c 'forward-referenced-supers ())
    (bootstrap-set-slot 'class c 'constructors ())
    (bootstrap-set-slot 'class c 'all-default-initargs ())))

(defun bootstrap-parse-slots (slots std-slotd-wrapper)
  (mapcar #'(lambda (slot) (bootstrap-parse-slot slot std-slotd-wrapper))
          slots))

(defun bootstrap-parse-slot (slot std-slotd-wrapper)
  (let ((slotd (%allocate-instance--class (length *std-slotd-slots*))))
    (setf (iwmc-class-class-wrapper slotd) std-slotd-wrapper)
    (let ((name (pop slot))
          (initform nil)
	  (initfunction nil)
	  (initargs nil)
	  (readers ())
	  (writers ())
          (type 't))
      (loop (when (null slot) (return t))
            (ecase (car slot)
              (:initform
		(setq initform (cadr slot))
		(setq initfunction
		      (case initform
			((nil) #'false)
			((t)   #'true)
			((0)   #'zero)
			(otherwise
			  #'(lambda () (eval initform))))))
	      (:initarg
		(push (cadr slot) initargs))
              (:accessor (push (cadr slot) readers)
			 (push `(setf ,(cadr slot)) writers))
              (:reader   (push (cadr slot) readers))
              (:writer   (push (cadr slot) writers))
              (:type (setq type (cadr slot))))
            (setq slot (cddr slot)))
      (bootstrap-set-slot 'slotd slotd 'name name)
      (bootstrap-set-slot 'slotd slotd 'keyword (make-keyword name))
      (bootstrap-set-slot 'slotd slotd 'initform initform)
      (bootstrap-set-slot 'slotd slotd 'initfunction initfunction)
      (bootstrap-set-slot 'slotd slotd 'initargs initargs)
      (bootstrap-set-slot 'slotd slotd 'readers readers)
      (bootstrap-set-slot 'slotd slotd 'writers writers)
      (bootstrap-set-slot 'slotd slotd 'allocation ':instance)
      (bootstrap-set-slot 'slotd slotd 'type type)
      slotd)))



(defun class-of (x) (#.*class-of* x))

(defun wrapper-of (x) (#.*wrapper-of* x))

(eval-when (eval load)
  (clrhash *find-class*)
  (bootstrap-meta-braid))


;;;
;;;
;;;
(defmethod print-object ((instance t) stream)
  (printing-random-thing (instance stream)
    (let ((name (class-name (class-of instance))))
      (if name
	  (format stream "~S" name)
	  (format stream "Instance")))))

(defmethod print-object ((class standard-class) stream)
  (named-object-print-function class stream))

(defmethod print-object ((slotd standard-slot-description) stream)
  (named-object-print-function slotd stream))


;;;
(defmethod shared-initialize :after ((class standard-class)
				     slot-names
				     &key name
					  local-supers
					  local-slots)
  (declare (ignore slot-names))
  (setf (slot-value class 'name) name
	(slot-value class 'local-supers) local-supers
	(slot-value class 'local-slots) local-slots))

(defmethod shared-initialize :after ((slotd standard-slot-description)
				     slot-names
				     &key name
					  keyword	;***
					  initform
					  initfunction
					  initargs 
					  allocation
					  type
					  readers
					  writers)
  (declare (ignore slot-names))
  (setf (slot-value slotd 'name) name
	(slot-value slotd 'keyword) keyword	        ;***
	(slot-value slotd 'initform) initform
	(slot-value slotd 'initfunction) initfunction
	(slot-value slotd 'initargs) initargs 
	(slot-value slotd 'allocation) allocation
	(slot-value slotd 'type) type
	(slot-value slotd 'readers) readers
	(slot-value slotd 'writers) writers))