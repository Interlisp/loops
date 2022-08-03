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
;;; Permutation vectors.
;;;

(in-package 'pcl)

;;;
;;; This file basically defines 3 functions.  These functions are the
;;; interface to the method loading and method lookup code for interning
;;; slot lists and looking up permutation vectors.
;;;
;;; Intern-Slot-Lists:
;;;   list of slot accesses  --> interned-slot-lists
;;;
;;; At load time the lists of slots the method accesses is interned.  The
;;; format of that list is as follows:
;;;   ((slot-name-1 slot-name-2 slot-name-3 ...)
;;;    (slot-name-1 slot-name-2 slot-name-3 ...)
;;;    .
;;;    .
;;;    .)
;;;
;;; Each sublist represents the slot accesses of the corresponding argument
;;; of the method.  The entries in the permutation vector come from the order
;;; of slots gotten by appending each of the sublists.
;;; 
;;; Given a method like:
;;;
;;;    (defmethod foo ((p position) (l line))
;;;      (slot-value p 'x)
;;;      (slot-value p 'y)
;;;      (slot-value l 'end1))
;;;
;;; The slots-lists is: ((x y) (end1))
;;; The entries in the permutation vector for the three slots accesses are
;;; 0, 1, and 2 respectively.
;;; 
;;;
;;;
;;; Lookup-PV: interned-slot-list, wrapper1, wrapper2 .. --> PV
;;;
;;; Given an interned slot list and a corresponding number of class wrappers,
;;; this function finds the appropriate permutation vector to use.  This is
;;; implemented using several caches, and bottoms out to a mechanism which
;;; interns the permutation vectors to make sure there is only one permutation
;;; vector with a given set of elements.
;;; 


;;;
;;; There is a hell of a lot of knowledge in the next 7 definitions.
;;;
;;; This is where we make sure that no wrapper cache number will ever have
;;; all 0's in all the bits that a mask lets through.  This is what makes
;;; the whole scheme of setting a wrapper's cache number to 0 to cause
;;; access to the instances to trap work.
;;; 
(eval-when (eval compile load)

(defconstant wrapper-cache-favored-line-size 2)
(defconstant wrapper-cache-minimum-lines 8)
(defconstant wrapper-cache-minimum-mask
	     (make-cache-mask (* wrapper-cache-favored-line-size
				 wrapper-cache-minimum-lines)
			      wrapper-cache-favored-line-size))

(defvar *last-wrapper-cache-no* 0)

)

(defun get-next-wrapper-cache-no ()
  (let ((n (incf *last-wrapper-cache-no* wrapper-cache-favored-line-size)))
    (cond ((>= n most-positive-fixnum)
	   (setq *last-wrapper-cache-no* 0)
	   (get-next-wrapper-cache-no))
	  ((zerop (logand wrapper-cache-minimum-mask n))
	   (get-next-wrapper-cache-no))
	  (t n))))

(defun make-wrapper-cache-mask (number-of-lines)
  (make-cache-mask (* number-of-lines wrapper-cache-favored-line-size)
		   wrapper-cache-favored-line-size))

(defvar  *8-cache-mask* (make-wrapper-cache-mask 8))
(defvar *16-cache-mask* (make-wrapper-cache-mask 16))
(defvar *32-cache-mask* (make-wrapper-cache-mask 32))
(defvar *64-cache-mask* (make-wrapper-cache-mask 64))

(defmacro shift-wrapper-cache-location (location line-size)
  `(%ash ,location
	 ,(if (constantp line-size)
	      (- (integer-length (eval line-size))
		 (integer-length wrapper-cache-favored-line-size))
	      `(%- (integer-length (the fixnum ,line-size))
		   ,(integer-length wrapper-cache-favored-line-size)))))

(defmacro compute-line-size (nelements)
  `(expt 2 (ceiling (log ,nelements 2))))

;;;
;;; The rules for computing a wrapper-cache location from a set of wrappers
;;; are moderately complex, and extremely important.  The entire obsoleting
;;; mechanism depends on these rules, as does the strategy used by the cache
;;; lookup and miss code.
;;;
;;;
(defmacro compute-wrapper-cache-location (mask line-size &rest wrappers)
  (unless (and (numberp mask) (numberp line-size))
    (error "Using compute-wrapper-cache-location improperly.~@
            The mask and line-size arguments must be unquoted numbers."))
  ;; Convert the wrapper forms into forms which will fetch the wrapper's
  ;; cache number.  That is the basis from which we will work.
  (let* ((cache-no-forms
	   (mapcar #'(lambda (w) `(wrapper-cache-no ,w)) wrappers))
	 (last-cache-no-form (car (last cache-no-forms))))
    (if (null (cdr wrappers))
	;; The (comparatively) simple case.  There is only one number
	;; to work with, so all we need to do is mask it against the
	;; mask, and shift it as need be.
	`(shift-wrapper-cache-location (%logand ,mask ,(car cache-no-forms))
				       ,line-size)
	(let ((test-wrapper-obsolescence-forms
		(mapcar #'(lambda (form)
			    `(let ((.cache-no. ,form))
			       (if (%zerop .cache-no.)
				   (return-from obsolete-wrapper-detected 0)
				   (progn 
				     (setq .location. (%logxor .location.
							       .cache-no.))
				     ,(and (neq form last-cache-no-form)
					   '(setq .location.
						  (%* .location. 2)))))))
			cache-no-forms)))
	  `(let ((.location. 0))
	     (block obsolete-wrapper-detected
	       ,@test-wrapper-obsolescence-forms
	       (setq .location. (%logand ,mask .location.))
	       (if (zerop .location.)
		   ,line-size
		   (shift-wrapper-cache-location .location. ,line-size))))))))


;;;
;;; This is a very special functional version of the above.  It is used by
;;; some of the cache miss functions to compute the location of the entry
;;; they are about to store.  This generates obsolete instance traps.  If
;;; it does generate such a trap, it returns NIL to indicate that the
;;; wrappers must be recomputed.
;;; 
;;; 
(defun compute-wrapper-cache-location-1
       (mask line-size nkeys wrappers-and-args)
  (flet ((do-obsolete-trap (wrapper)
	   (let* ((args (nthcdr nkeys wrappers-and-args))
		  (tail (memq wrapper wrappers-and-args))
		  (new-wrapper nil))
	     (dolist (arg args)
	       (when (eq (wrapper-of arg) wrapper)
		 (setq new-wrapper (obsolete-instance-trap wrapper arg))))
	     (wrapper-cache-no (setf (car tail) new-wrapper)))))

    (if (%= nkeys 1)
	(let* ((wrapper (car wrappers-and-args))
	       (number (wrapper-cache-no wrapper)))
	  (when (%zerop number)
	    (setq number (do-obsolete-trap wrapper)))
	  (shift-wrapper-cache-location (%logand mask number) line-size))
	(let ((location 0)
	      (tail-of-wrappers wrappers-and-args))
	  (dotimes (i nkeys)
	    (let* ((wrapper (pop tail-of-wrappers))
		   (number (wrapper-cache-no wrapper)))
	      (when (%zerop number)
		(setq number (do-obsolete-trap wrapper)))
	      (setq location (%* location 2))
	      (setq location (%logxor location number))))
	  (setq location (%logand mask location))
	  (if (%zerop location)
	      line-size
	      (shift-wrapper-cache-location location line-size))))))


;;;
;;; A more specialized version of the above, which is used by all-std-class
;;; reader and writer miss code.
;;; 
(defun compute-wrapper-cache-location-2 (mask wrapper object)
  (let* ((number (wrapper-cache-no wrapper)))
    (when (zerop number)
      (setq wrapper (obsolete-instance-trap wrapper object)
	    number (wrapper-cache-no wrapper)))
    (shift-wrapper-cache-location (%logand mask number) 2)))

;;;
;;; If this comes across a wrapper whose cache-no is 0, it doesn't actually
;;; do the trap.  It can't because it doesn't have the actual argument, and
;;; it doesn't make sense for it to do so because this is just an entry we
;;; have stumbled across.
;;;
;;; It does return 0 to encourage the cache maintenance code to displace in
;;; that case as a way of licensing the cache filling code to displace the
;;; entry.
;;; 
(defun compute-wrapper-cache-location-from-line
       (cache location mask line-size nkeys)
  (if (%= nkeys 1)
      (shift-wrapper-cache-location
	(%logand mask (wrapper-cache-no (%svref cache location)))
	line-size)
      (let ((contents-location 0))
	(dotimes (i nkeys)
	  (setq contents-location (%* 2 contents-location))
	  (let ((wrapper-no (wrapper-cache-no (%svref cache (%+ i location)))))
	    (if (%zerop wrapper-no)
		(return-from compute-wrapper-cache-location-from-line 0)
		(setq contents-location
		      (%logxor contents-location wrapper-no)))))
	(if (zerop contents-location)
	    line-size
	    (shift-wrapper-cache-location (%logand mask contents-location)
					  line-size)))))




(defmacro instance-slot-position (wrapper slot-name)
  `(let ((pos 0))
     (block loop
       (dolist (sn (wrapper-instance-slots-layout ,wrapper))
	 (when (eq ,slot-name sn) (return-from loop pos))
	 (incf pos)))))



;;;
;;; This code frequently has to intern lists each of whose elements can be
;;; interned by a separate function.  It is as if it was interning lists of
;;; symbols.  INTERN-LIST-TABLES are the abstraction used for this.
;;;
;;; Right now, intern-list-tables are implemented using simple trees.  This
;;; could certainly be changed to be more efficient.
;;; 
;;; The name of the table is purely for decorative purposes.
;;;
;;; The intern-element-fn is the function which should be called
;;; to intern each element of the list.
;;; 
(defun make-intern-list-table (name intern-element-fn coerce-to-val-fn)
  (list 'intern-list-table name intern-element-fn coerce-to-val-fn ()))

(defun intern-in-list-table (table value)
  (let ((intern-element-fn (caddr table))
	(coerce-to-val-fn (cadddr table)))
    (labels ((intern-1 (tree tail)
	       (let* ((element (funcall intern-element-fn (car tail)))
		      (subtree (assq element (cddr tree))))
		 (if (null subtree)
		     (let ((subtree (list element nil)))
		       (nconc tree (list subtree))
		       (intern-1 tree tail))
		     (if (null (cdr tail))
			 (or (cadr subtree)
			     (setf (cadr subtree)
				   (apply coerce-to-val-fn
					  (mapcar intern-element-fn value))))
			 (intern-1 subtree (cdr tail)))))))
      (intern-1 (cddddr table) value))))



;;;
;;; The symbolics Compiler's refusal to compile functions that appear inside
;;; of let at top level makes this all have to be written backwards.
;;; 
(defvar *intern-slot-lists-1* (make-hash-table :test #'equal :size 500))

(defun intern-slot-lists-1 (slot-name-list)	;intern single list
  (if (null slot-name-list)			;of slot names
      ()
      (or (gethash slot-name-list *intern-slot-lists-1*)
	  (setf (gethash slot-name-list *intern-slot-lists-1*)
		slot-name-list))))

(defun intern-slot-lists-2 (&rest elements)
  (cons (make-memory-block (compute-primary-pv-cache-size elements))
	(copy-list elements)))

(defvar *intern-slot-lists*
	(make-intern-list-table '*intern-slot-lists*
				#'intern-slot-lists-1
				#'intern-slot-lists-2))

(defun intern-slot-lists (slot-name-lists)
  ;; Because PCL's eval-when control is so losing, we can sometimes get
  ;; called with an already interned slot list.  Have to detect that case
  ;; and not try to intern it again since the format of an interned slot
  ;; lost and an uninterned slot list is different.
  (if (listp (car slot-name-lists))
      (intern-in-list-table *intern-slot-lists* slot-name-lists)
      slot-name-lists))




(defun lookup-pv (isl &rest wrappers-and-instances)
  (let ((tail wrappers-and-instances))
    (cond ((null tail)
	   (error "No classes passed to lookup-pv."))
	  ((null (progn (pop tail) (pop tail) tail))
	   (apply #'lookup-pv-1 isl wrappers-and-instances))
	  ((null (progn (pop tail) (pop tail) tail))
	   (apply #'lookup-pv-2 isl wrappers-and-instances))
	  ((null (progn (pop tail) (pop tail) tail))
	   (apply #'lookup-pv-3 isl wrappers-and-instances))
	  (t
	   (apply #'lookup-pv-n isl wrappers-and-instances)))))

;;;
;;; *pv-cache-1* is used for the one class case.  
;;; 
(defvar *pv-cache-1-size* 1024)
(defvar *pv-cache-1-mask* (make-cache-mask *pv-cache-1-size* 3))
(defvar *pv-cache-1* (make-array *pv-cache-1-size*))
(defun lookup-pv-1 (isl w0 i0)
  (let* ((cache *pv-cache-1*)
	 (mask *pv-cache-1-mask*)
	 (offset (%logand mask
			  (%logxor (object-cache-no isl mask)
				   (validate-wrapper i0 w0)))))
    (without-interrupts
      (if (and (eq (%svref cache offset) isl)
	       (eq (%svref cache (%1+ offset)) w0))
	  (aref cache (%+ offset 2))
	  (let ((pv nil))
	    (interrupts-on)
	    (setq pv (lookup-pv-miss isl w0))
	    (interrupts-off)
	    (setf (%svref cache offset) isl)
	    (setf (%svref cache (%1+ offset)) w0)
	    (setf (%svref cache (%+ offset 2)) pv))))))

;;;
;;; *pv-cache-2* is used for the two class case.  
;;; 
(defvar *pv-cache-2-size* 1024)
(defvar *pv-cache-2-mask* (make-cache-mask *pv-cache-2-size* 4))
(defvar *pv-cache-2* (make-array *pv-cache-2-size*))
(defun lookup-pv-2 (isl w0 i0 w1 i1)
  (let* ((cache *pv-cache-2*)
	 (mask *pv-cache-2-mask*)
	 (offset (%logand mask
			  (%logxor (object-cache-no isl mask)
				   (validate-wrapper i0 w0)
				   (validate-wrapper i1 w1)))))
    (without-interrupts
      (if (and (eq (%svref cache offset) isl)
	       (eq (%svref cache (%1+ offset)) w0)
	       (eq (%svref cache (%+ offset 2)) w1))
	  (aref cache (%+ offset 3))
	  (let ((pv nil))
	    (interrupts-on)
	    (setq pv (lookup-pv-miss isl w0 w1))
	    (interrupts-off)
	    (setf (%svref cache offset) isl)
	    (setf (%svref cache (%1+ offset)) w0)
	    (setf (%svref cache (%+ offset 2)) w1)
	    (setf (%svref cache (%+ offset 3)) pv))))))

;;;
;;; *pv-cache-3* is used for the three class case.  
;;; 
(defvar *pv-cache-3-size* 2048)
(defvar *pv-cache-3-mask* (make-cache-mask *pv-cache-3-size* 5))
(defvar *pv-cache-3* (make-array *pv-cache-3-size*))
(defun lookup-pv-3 (isl w0 i0 w1 i1 w2 i2)
  (let* ((cache *pv-cache-3*)
	 (mask *pv-cache-3-mask*)
	 (offset (%logand mask
			  (%logxor (object-cache-no isl mask)
				   (validate-wrapper i0 w0)
				   (validate-wrapper i1 w1)
				   (validate-wrapper i2 w2)))))
    (without-interrupts
      (if (and (eq (%svref cache offset) isl)
	       (eq (%svref cache (%1+ offset)) w0)
	       (eq (%svref cache (%+ offset 2)) w1)
	       (eq (%svref cache (%+ offset 3)) w2))
	  (aref cache (%+ offset 4))
	  (let ((pv nil))
	    (interrupts-on)
	    (setq pv (lookup-pv-miss isl w0 w1 w2))
	    (interrupts-off)
	    (setf (%svref cache offset) isl)
	    (setf (%svref cache (%1+ offset)) w0)
	    (setf (%svref cache (%+ offset 2)) w1)
	    (setf (%svref cache (%+ offset 3)) w2)
	    (setf (%svref cache (%+ offset 4)) pv))))))

;;;
;;; *pv-cache-n* is used when there are more than three classes. Each cache
;;; entry has three elements.
;;;  - the ISL
;;;  - a list of class wrappers
;;;  - the permutation vector
;;;
;;; The offset into the cache is computed by xoring the object-cache-no of
;;; the ISL with the wrapper-cache-no's of the wrappers.
;;; 
(defvar *pv-cache-n* (make-array 1024))
(defvar *pv-cache-n-mask* (make-cache-mask 1024 3))

(defun lookup-pv-n (isl &rest wrappers-and-instances)
  (let* ((cache *pv-cache-n*)
	 (mask *pv-cache-n-mask*)
	 (offset (object-cache-no isl mask)))
    (doplist (wrapper instance) 	;Slight abuse of this macro,
	     wrappers-and-instances     ;but what the hell.
      (setq offset (boole boole-xor
			  offset
			  (validate-wrapper instance wrapper))))
    (setq offset (%logand mask offset))
    (without-interrupts
      (if (and (eq (%svref cache offset) isl)
	       (let ((cached-wrappers (%svref cache (+ offset 1)))
		     (tail wrappers-and-instances))
		 (loop (cond ((neq (car cached-wrappers)
				   (car tail))
			      (return nil))
			     ((or (null cached-wrappers)
				  (null tail))
			      (return t))
			     (t
			      (setq cached-wrappers (cdr cached-wrappers)
				    tail (cddr tail)))))))
	  (%svref cache (+ offset 2))
	  (progn
	    (interrupts-on)
	    (let* ((wrappers (gathering ((ws (collecting)))
			       (doplist (w i)
					wrappers-and-instances
				 (progn i)
				 (gather w ws))))
		   (pv (apply #'lookup-pv-miss isl wrappers)))
	      (interrupts-off)
	      (setf (%svref cache offset) isl
		    (%svref cache (+ offset 1)) wrappers
		    (%svref cache (+ offset 2)) pv)))))))


(defun lookup-pv-miss (isl &rest wrappers)
  (let ((pv ()))
    (dolist (slots (cdr isl))
      (when slots
	(when (null wrappers)
	  (error "Fewer classes than indicated by the isl."))
	(let ((class (wrapper-class (pop wrappers))))
	  (setq pv (lookup-pv-miss-1 class slots pv)))))
    (when wrappers
      (error "More classes than indicated by the isl."))
    (intern-pv (reverse pv))))

(defmethod lookup-pv-miss-1 ((class standard-class) slots pv)
  ;; *** Later this wants to fetch the cached info from
  ;; *** the class wrapper.
  (let ((wrapper (class-wrapper class)))
    (dolist (slot slots)
      (push (instance-slot-position wrapper slot) pv))
    pv))



(defvar *intern-pv*
	(make-intern-list-table '*intern-pv*
				#'identity
				#'(lambda (&rest elts)
				    (apply #'make-permutation-vector elts))))

(defun intern-pv (elements)
  (intern-in-list-table *intern-pv* elements))

(defun make-permutation-vector (&rest elements)
  (make-array (length elements) :initial-contents elements))




(defun can-optimize-access (var env)
  (declare (values required-parameter class))
  (let ((required-parameter?
	  (or (caddr (variable-declaration 'variable-rebinding var env))
	      var))
	(class-name nil)
	(class nil))
    (and required-parameter?
	 (setq class-name (variable-class required-parameter? env))
	 (setq class (find-class class-name nil))
	 (values required-parameter? class))))

(defmethod OPTIMIZE-SLOT-VALUE ((class standard-class) form)
  (destructuring-bind (ignore instance slot-name)
		      form
    `(standard-instance-access ,instance
			       ',(reduce-constant slot-name))))

(defmethod OPTIMIZE-SET-SLOT-VALUE ((class standard-class) form)
  (destructuring-bind (ignore instance slot-name new-value)
		      form
    `(standard-instance-access ,instance
			       ',(reduce-constant slot-name)
			       ,new-value)))


(defun optimize-standard-instance-access (class parameter form slots)
  ;; Returns an optimized form corresponding to FORM.  Optimized forms
  ;; are interned on SLOTS, a nested alist, so they can be side effected
  ;; later to put in their pv-offsets.
  (destructuring-bind (ignore instance slot-name . new)
		      form
    (setq slot-name (reduce-constant slot-name))
    (let ((entry (assq parameter slots)))
      (if (null entry)
	  (error "Can't optimize instance access because there is no entry~@
                  for this class in the required parameters of this method.~@
                  There is an inconsistency in the method body optimization~@
                  data structures.  Report this as a bug.")
	  (let ((slot-entry (assq slot-name (cdr entry))))
	    (unless slot-entry
	      (push (setq slot-entry (list slot-name)) (cdr entry)))
	    (let ((optimized-form
		    `(,(optimize-standard-instance-access-internal class)
		      ,instance ',slot-name ,@new)))
	      (progn (push optimized-form (cdr slot-entry))
		     optimized-form)))))))


(defmethod optimize-standard-instance-access-internal ((class standard-class))
  'std-instance-access-pv)

(defun sort-slots-into-isl (slots)
  (let ((pv-offset -1))
    (mapcar
      #'(lambda (s)
	  (mapcar #'(lambda (e)
		      (incf pv-offset)
		      ;; side effect the walked-lambda form, specifically
		      ;; convert the symbol argument to the optimized
		      ;; instance access to the correct offset into the PV
		      (dolist (form (cdr e))
			(setf (cadr (caddr form)) pv-offset))
		      (car e))
		  (cdr s)))
      (mapcar #'(lambda (s)
		  (cons (car s)
			(sort (cdr s)
			      #'(lambda (a b)
				  (string-lessp (symbol-name (car a))
						(symbol-name (car b)))))))
	      slots))))

(defvar *primary-pv-cache-multiple* 16)

(defun compute-primary-pv-cache-size (isl)
  (let ((n-classes 0))
    (dolist (i isl)
      (when i (incf n-classes)))
    (min (* n-classes  *primary-pv-cache-multiple*)
	 (* wrapper-cache-favored-line-size
	    wrapper-cache-minimum-lines))))

(defun add-pv-binding (method-body plist required-parameters specializers)
  (flet ((parameter-class (param)
	   (iterate ((req (list-elements required-parameters))
		     (spec (list-elements specializers)))
	     (when (eq param req) (return spec)))))
    (let* ((isl (getf plist :isl))
	   (n-classes 0)
	   (cache-size (compute-primary-pv-cache-size isl))
	   (wrapper-var-pool '(w1 w2 w3 w4 w5 w6 w7 w8 w9))
	   (isl-cache-symbol (make-symbol "isl-cache")))
      (nconc plist (list :isl-cache-symbol isl-cache-symbol))
      
      (multiple-value-bind (wrapper-bindings
			    wrapper-vars
			    wrappers-and-parameters
			    eq-tests)
	  (gathering ((bindings (collecting))
		      (vars (collecting))
		      (w+p (collecting))
		      (eqs (collecting)))
	    (iterate ((slots (list-elements isl))
		      (param (list-elements required-parameters)))
	      (when slots
		(let ((class (find-class (parameter-class param) nil))
		      (var (or (pop wrapper-var-pool) (gensym))))
		  (gather var vars)
		  (gather var w+p)
		  (gather param w+p)
		  (gather `(,var (,(wrapper-fetcher  class) ,param)) bindings)
		  (gather `(eq ,var
			       (%svref .cache. ,(make-%+ '.offset. n-classes)))
			  eqs)
		  (incf n-classes)))))

	(let* ((line-size (compute-line-size (1+ n-classes)))
	       (number-of-lines (/ cache-size line-size))
	       (mask (make-wrapper-cache-mask number-of-lines)))
	  `((let ((.isl. (locally 
			   (declare (special ,isl-cache-symbol))
			   ,isl-cache-symbol))
		  (.pv. nil))
	      (setq .pv.
		    (let* ((.cache. (car .isl.))
			   ,@wrapper-bindings
			   (.offset.
			     (compute-wrapper-cache-location ,mask
							     ,line-size
							     ,@wrapper-vars)))
		      (declare (type simple-vector .cache.)
			       (type fixnum .offset.))
		      (if (and ,@eq-tests)
			  (%svref .cache. ,(make-%+ '.offset. n-classes))
			  (primary-pv-cache-miss .isl.
						 .offset.
						 ,@wrappers-and-parameters))))
	      .,method-body)))))))

(defmethod wrapper-fetcher ((class standard-class))
  'iwmc-class-class-wrapper)

(defmethod slots-fetcher ((class standard-class))
  'iwmc-class-static-slots)

(defmethod raw-instance-allocator ((class standard-class))
  '%%allocate-instance--class)

(defun primary-pv-cache-miss (isl offset &rest wrappers-and-instances)
  (let ((pv (apply #'lookup-pv isl wrappers-and-instances))
	(cache (car isl)))
    (without-interrupts
      (do ((wrappers wrappers-and-instances (cddr wrappers))
	   (i 0 (1+ i)))
	  ((null wrappers)
	   (setf (memory-block-ref cache (+ offset i)) pv))
	(setf (memory-block-ref cache (+ offset i)) (car wrappers))))))

(define-walker-template std-instance-access-pv)
(define-walker-template fsc-instance-access-pv)

(defmacro std-instance-access-pv
	  (instance pv-offset &optional (new-value nil nvp))
  (std-instance-access-pv-internal 'iwmc-class-static-slots
				   instance
				   pv-offset
				   nvp
				   new-value))

(defmacro fsc-instance-access-pv
	  (instance pv-offset &optional (new-value nil nvp))
  (std-instance-access-pv-internal 'funcallable-instance-static-slots
				   instance
				   pv-offset
				   nvp
				   new-value))

(defun std-instance-access-pv-internal
       (slots-fetcher instance pv-offset nvp new-value)
  (if nvp
      (once-only (new-value)
	`(let ((.index. (memory-block-ref .pv. ,pv-offset)))
	   (if (null .index.)
	       (pv-access-trap ,instance ,pv-offset .isl. ,new-value)
	       (setf (%svref (,slots-fetcher ,instance) .index.) ,new-value))))
      `(let ((.temp. (memory-block-ref .pv. ,pv-offset)))
	 (if (or (null .temp.)
		 (eq (setq .temp. (%svref (,slots-fetcher ,instance) .temp.))
		     ',*slot-unbound*))
	     (pv-access-trap ,instance ,pv-offset .isl.)
	     .temp.))))

(defun pv-access-trap (instance offset isl &optional (new-value nil nvp))
  (let* ((i 0)
	 (slot-name
	  (block lookup-slot-name
	    (dolist (per-class-slots (cdr isl))
	      (dolist (slot per-class-slots)
		(if (= i offset)
		    (return-from lookup-slot-name slot)
		    (incf i)))))))
    (when (null slot-name)
      (error "Internal Error:~@
              Unable to determine the name of the slot from the PV-OFFSET~@
              and the ISL.  This results from inconsistency between the~@
              PV-OFFSET this access was told to use and the ISL for the~@
              method."))
    (if nvp
	(setf (slot-value-using-class (class-of instance) instance slot-name)
	      new-value)
	(slot-value-using-class (class-of instance) instance slot-name))))
