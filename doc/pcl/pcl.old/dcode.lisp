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

#|

to do:

make *compile-dcodes-at-run-time-p* work by centralizing a facility for
calling the template constructor of a dcode

make this stuff compile faster

state transition table techology for compute-discriminator-code

|#


;;;
;;; Some support stuff for getting a hold of symbols that we need when
;;; building the discriminator codes.  Its ok for these to be interned
;;; symbols because we don't capture any user code in the scope in which
;;; these symbols are bound.
;;; 

(defvar *dcode-arg-symbols* ())

(defun dcode-arg-symbol (arg-number)
  (or (cdr (assoc arg-number *dcode-arg-symbols* :test #'=))
      (let ((new (cons arg-number
		       (intern (format nil "ARG-~D" arg-number)
			       *the-pcl-package*))))
	(push new *dcode-arg-symbols*)
	(cdr new))))

(eval-when (load) (dotimes (i 10) (dcode-arg-symbol (- 9 i))))

(defvar *dcode-wrapper-symbols* ())

(defun dcode-wrapper-symbol (arg-number)
  (or (cdr (assoc arg-number *dcode-wrapper-symbols* :test #'=))
      (let ((new (cons arg-number
		       (intern (format nil "WRAPPER-~D" arg-number)
			       *the-pcl-package*))))
	(push new *dcode-wrapper-symbols*)
	(cdr new))))

(eval-when (load) (dotimes (i 10) (dcode-wrapper-symbol (- 9 i))))




;;;
;;; Allocating, freeing, and flushing generic function caches.
;;;

(defun generic-function-cache-size (cache)
  (array-dimension (the simple-vector cache) 0))

(defmacro cache-lock-count (cache)
  `(%svref ,cache 0))

(defun make-generic-function-cache (size)
  (let ((new (make-array size :adjustable nil :initial-element nil)))
    (setf (cache-lock-count new) 0)
    new))

(defun flush-generic-function-caches-internal (cache)
  (without-interrupts 
    (fill (the simple-vector cache) nil)
    (setf (cache-lock-count cache) 0)))

(defvar *free-generic-function-caches*)

(eval-when (load eval)
  (let ((size 32)
	(index -1))
    (setq *free-generic-function-caches* (make-array size))
    (dotimes (i (/ size 2))
      (setf (svref *free-generic-function-caches* (incf index)) nil
	    (svref *free-generic-function-caches* (incf index)) 0))))

(defun get-generic-function-cache (size)
  (let* ((expt (floor (log size 2)))
	 (thread (* expt 2))
	 (count (1+ thread))
	 (existing nil))
    (when (>= count (array-dimension *free-generic-function-caches* 0) 2)
      (error "Generic function cache of unprecedented size returned."))
    (setq existing (svref *free-generic-function-caches* thread))
    (cond ((null existing)
	   (incf (svref *free-generic-function-caches* count))
	   (make-generic-function-cache size))
	  (t
	   (setf (svref *free-generic-function-caches* thread)
		 (svref existing 0))
	   (flush-generic-function-caches-internal existing)
	   existing))))

(defun free-generic-function-cache (cache)
  (let* ((size (array-dimension cache 0))
	 (expt (floor (log size 2)))
	 (thread (* expt 2))
	 (count (1+ thread)))
    (when (>= count (array-dimension *free-generic-function-caches* 0) 2)
      (error "Generic function cache of unprecedented size returned."))
    (setf (svref cache 0) (svref *free-generic-function-caches* thread))
    (setf (svref *free-generic-function-caches* thread) cache)))

;;;
;;; This is just for debugging and analysis.  It shows the state of the free
;;; generic function cache.
;;; 
(defun show-free-generic-function-caches ()
  (let* ((free-caches *free-generic-function-caches*)
	 (free-size (array-dimension free-caches 0)))
    (dotimes (expt (/ free-size 2))
      (let* ((thread (* expt 2))
	     (count  (1+ thread)))
	(unless (zerop (svref free-caches count))
	  (format t
		  "~&There are ~D cache~P of size ~D. (~D free)"
		  (svref free-caches count)
		  (svref free-caches count)
		  (expt 2 expt)
		  (let ((head (svref free-caches thread))
			(nfree 0))
		    (loop (when (null head) (return nfree))
			  (setq head (svref head 0))
			  (incf nfree)))))))))

(defun ensure-generic-function-cache (generic-function size)
  (let ((existing (generic-function-cache generic-function)))
    (cond ((null existing)
	   (setq existing (get-generic-function-cache size))
	   (setf (generic-function-cache generic-function) existing))
	  ((not (= (generic-function-cache-size existing) size))
	   (free-generic-function-cache existing)
	   (setq existing (get-generic-function-cache size))
	   (setf (generic-function-cache generic-function) existing)))
    existing))



(defun dcode-cache-miss
       (gf					;actual generic function
	tertiary-miss-fn			;function to call if the
						;scan of the next entries
						;also misses
	cache					;the cache
	size					;size of the cache in `words'
	mask					;the cache mask
	line-size				;line size in `words'
	nkeys					;number of keys per entry
	next-scan-limit				;The limit of next entries
						;to scan before declaring a
						;tertiary miss.  When filling
						;the cache, this controls how
						;many next slots to try before
						;declaring a cache miss.
	expandp					;If this is false, don't
						;expand the cache no matter
						;what.
	dcode-constructor			;Passed to EXPAND-DCODE-CACHE
	&rest wrappers-and-args)		;A list whose first NKEYS
						;elements are wrappers.  The
						;remaining elements are the
						;required arguments to the
						;function.

  (macrolet ((compute-mirror (loc)
	       `(- size line-size ,loc))
	     (compute-loc-from-line (line-loc)
	       `(compute-wrapper-cache-location-from-line
		  cache ,line-loc mask line-size nkeys)))
	       
    (tagbody
      restart
	 
	 (let* ((entries-have-value-p (%< nkeys line-size))
		;; Recompute the primary location for ourselves, since this
		;; version of the computation will do obsolete instance traps.
		;; It also side-effects the list of wrappers if there are any
		;; new wrappers as a result of obsolete traps.
		(primary (compute-wrapper-cache-location-1 mask
							   line-size
							   nkeys
							   wrappers-and-args))
		(mirror (compute-mirror primary))
		(free-next 0)
		(value nil))
	   
	   (labels ((fill-line (loc)
		      (let ((tail wrappers-and-args))
			(dotimes (i nkeys)
			  (setf (%svref cache (%+ i loc)) (pop tail)))
			(when entries-have-value-p
			  (setf (%svref cache (%+ nkeys loc)) value))))
		    
		    (copy-line (from to)
		      (dotimes (i nkeys)
			(setf (%svref cache (%+ to i))
			      (%svref cache (%+ from i))))
		      (when entries-have-value-p
			(setf (%svref cache (%+ nkeys to))
			      (%svref cache (%+ nkeys from)))))
		    
		    (fill-primary ()
		      (when (%svref cache primary) (displace-primary))
		      (fill-line primary))
	       
		    (displace-primary ()		 
		      (cond ((zerop mirror)
			     (copy-to-next primary))
			    ((null (%svref cache mirror))
			     (copy-line primary mirror))
			    (t
			     (let* ((mirror-contents-primary
				      (compute-loc-from-line primary)))
			       (cond ((zerop mirror-contents-primary)
				      ;; The contents of the mirror location
				      ;; are obsolete.  Drop it on the floor.
				      (copy-line primary mirror))
				     ((= mirror-contents-primary mirror)
				      ;; The mirror is the primary location
				      ;; of its contents.  Leave it there.
				      (copy-to-next primary))
				     (t
				      (copy-to-next mirror)
				      (copy-line primary mirror)))))))
		    
		    (copy-to-next (loc)
		      (do ((scan-loc (%mod (%+ primary line-size) size)
				     (%mod (%+ scan-loc line-size) size))
			   (limit next-scan-limit limit))
			  ((zerop limit)
			   (when expandp (expand-cache)))
			(unless (zerop scan-loc)
			  (unless (= scan-loc mirror)
				(when (or (%= scan-loc free-next)
					  (null (%svref cache scan-loc))
					  (not (dotimes (i nkeys)
						 (unless (zerop
							   (wrapper-cache-no
							     (%svref cache
								     (%+ i
									 scan-loc))))
						   (return t))))
					  (zerop
					    (compute-loc-from-line scan-loc)))
				  (return (copy-line loc scan-loc))))
			  (decf limit))))

		    (expand-cache ()
		      (setq cache (expand-dcode-cache gf
						      cache
						      size
						      line-size
						      nkeys
						      next-scan-limit
						      dcode-constructor)
			    size (generic-function-cache-size cache)
			    mask (make-wrapper-cache-mask (floor size
								 line-size))
			    primary (compute-wrapper-cache-location-1
				      mask
				      line-size
				      nkeys
				      wrappers-and-args)
			    mirror (compute-mirror primary)
			    expandp nil)))

	     
	     ;;
	     ;; First, get the actual value.  If this cache just has keys,
	     ;; and no values, we will use NIL as the value.
	     ;;
	     ;; First try to find it by scanning cache lines after primary.
	     ;; This scan stops when we reach next-scan-limit which is the
	     ;; maximimum number of next lines to try.
	     ;;
	     ;; If we find the element before the limit, great.  Otherwise,
	     ;; this is a tertiary cache miss.  Note that this doesn't cause
	     ;; a refill.   The refill will come later when we try to add
	     ;; this entry to the cache.  We use the variable FREE-NEXT to
	     ;; show that this next location is now up for grabs though.
	     ;;
	     (without-interrupts
	       (setq value 
		     (block scan-cache
		       (do ((try (%mod (%+ primary line-size) size)
				 (%mod (%+ try line-size) size))
			    (limit next-scan-limit limit))
			   ((zerop limit)
			    (return-from scan-cache
			      (prog2 (interrupts-on)
				     (apply tertiary-miss-fn
					    gf
					    (nthcdr nkeys
						    wrappers-and-args))
				     (interrupts-off))))
			 (unless (zerop try)	;The zero entry of the
						;cache is never used!
			   (let ((tail wrappers-and-args))
			     (unless (dotimes (i nkeys)
				       (unless (eq (%svref cache (%+ i try))
						   (pop tail))
					 (return t)))
			       (setq free-next try)
			       (return-from scan-cache
				 (and entries-have-value-p
				      (%svref cache (%+ nkeys try))))))
			   (decf limit)))))
	       (unless (or (eq value '..no-applicable-method..)
			   (symbolp value))
		 (let ((old-count (cache-lock-count cache)))
		   (setf (cache-lock-count cache)
			 (if (= old-count most-positive-fixnum)
			     1
			     (1+ old-count)))
		   (fill-primary)))
	       (return-from dcode-cache-miss value)))))))

;;;
;;; Just make a bigger cache and then use dcode-cache-miss in a hacked up
;;; way to fill the new cache from the old one.  This conses a bit, but it
;;; isn't so bad.  It could be fixed easily if someone wanted to.
;;; 
(defun expand-dcode-cache (generic-function
			   old-cache
			   old-size
			   line-size
			   nkeys
			   next-scan-limit
			   dcode-constructor)
  (let* ((new-size (* old-size 2))
	 (new-number-of-lines (floor new-size line-size))
	 (new-mask (make-wrapper-cache-mask new-number-of-lines))
	 (new-cache (get-generic-function-cache new-size))
	 (new-dcode nil)
	 (wrappers ())
	 (value nil))
    (flet ((collect-wrappers (loc)
	     (block collect-wrappers
	       (when (%svref old-cache loc)
		 (setq wrappers ())
		 (dotimes (i nkeys)
		   (let ((wrapper (%svref old-cache (+ i loc))))
		     (if (zerop (wrapper-cache-no wrapper))
			 ;; This wrapper is obsolete, we don't have an instance
			 ;; so there is no related trap.  Just drop this line
			 ;; on the floor.
			 (return-from collect-wrappers nil)
			 (push wrapper wrappers))))
		 (setq wrappers (nreverse wrappers)
		       value (and (< nkeys line-size)
				  (%svref old-cache (+ loc nkeys))))
		 t))))

      (flush-generic-function-caches-internal new-cache)

      (do ((old-location line-size (+ old-location line-size)))
	  ((= old-location old-size))
	(when (collect-wrappers old-location)
	  (apply #'dcode-cache-miss
		 generic-function
		 #'(lambda (&rest ignore)
		     (declare (ignore ignore))
		     value)
		 new-cache
		 new-size
		 new-mask
		 line-size
		 nkeys
		 next-scan-limit
		 nil				;Means don't allow another
						;expand while filling the
						;new cache.  This can only
						;happen in one pathological
						;case, but prevent it anyways.
		 dcode-constructor
		 wrappers)))
    
      (setq new-dcode (funcall dcode-constructor generic-function new-cache))
      (setf (generic-function-cache generic-function) new-cache)
      (install-discriminating-function generic-function new-dcode)
      (free-generic-function-cache old-cache)
      new-cache)))


;;;
;;; No methods??
;;;
(defun make-no-methods-dcode (generic-function)
  #'(lambda (&rest ignore)
      (declare (ignore ignore))
      (error "There are no methods on the generic-function ~S,~%~
              so it is an error to call it."
	     generic-function)))


;;;
;;; Default method only is pretty easy.
;;;
(defun make-default-method-only-dcode (generic-function)
  (cadar (generic-function-combined-methods generic-function)))


;;;
;;; In the case where all the methods on a generic function are either writers
;;; or readers, we can win by pulling the slot-lookup caching that the methods
;;; would do when they are called directly into the discriminator code and its
;;; cache.
;;; For this case, the generic function cache is used as follows:
;;;
;;;                  -------------------
;;;      .          |        .          |
;;;      .          |        .          |
;;;                 |                   |
;;;    class-i -->  | <wrapper for FOO> |
;;;    index-i -->  |        3          |
;;;                 |                   |
;;;      .          |        .          |
;;;      .          |        .          |
;;;                 |                   |
;;;    class-j -->  | <wrapper for BAR> |
;;;    index-j -->  |        1          |
;;;                 |                   |
;;;      .          |        .          |
;;;      .          |        .          |
;;;                 |                   |
;;;                  -------------------
;;;
;;;    It is a one key cache, the keys are the class-wrapper of the
;;;    specialized argument.  Writer methods only specialize the object
;;;    argument.
;;;
;;;
;;;

(defvar *all-std-class-accessors-default-number-of-cache-lines* 8)
(defvar *all-std-class-accessors-default-cache-mask* *8-cache-mask*)
(defvar *all-std-class-accessors-next-scan-limit* 4)
(defvar *all-std-class-accessors-max-cache-size* 64)

(defun make-all-std-class-readers-dcode (generic-function &optional cache)
  (let ((cache-size nil)
	(cache-mask nil))
    (if cache
	(setq cache-size (generic-function-cache-size cache)
	      cache-mask (make-wrapper-cache-mask (floor cache-size 2)))
	(progn
	  (setq cache-size
		(* *all-std-class-accessors-default-number-of-cache-lines* 2))
	  (setq cache-mask
		*all-std-class-accessors-default-cache-mask*)
	  (setq cache
		(ensure-generic-function-cache generic-function cache-size))))
    (funcall (get-templated-function-constructor 'all-std-class-readers-dcode
						 cache-size
						 cache-mask)
	     generic-function
	     cache
	     *all-std-class-accessors-next-scan-limit*)))

(defun make-all-std-class-writers-dcode (generic-function &optional cache)
  (let ((cache-size nil)
	(cache-mask nil))
    (if cache
	(setq cache-size (generic-function-cache-size cache)
	      cache-mask (make-wrapper-cache-mask (floor cache-size 2)))
	(progn
	  (setq cache-size
		(* *all-std-class-accessors-default-number-of-cache-lines* 2))
	  (setq cache-mask
		*all-std-class-accessors-default-cache-mask*)
	  (setq cache
		(ensure-generic-function-cache generic-function cache-size))))
    (funcall (get-templated-function-constructor 'all-std-class-writers-dcode
						 cache-size
						 cache-mask)
	     generic-function
	     cache
	     *all-std-class-accessors-next-scan-limit*)))

(define-function-template all-std-class-readers-dcode
			  (cache-size cache-mask)
			  '(.GENERIC-FUNCTION. .CACHE. .NEXT-SCAN-LIMIT.)
  (let ()
    `(function
       (lambda (arg)
	 (declare (optimize (speed 3) (safety 0)))
	 (let ((value nil)
	       (starting-lock-count (cache-lock-count .CACHE.)))
	   (all-std-class-accessors-dcode-internal
	     nil
	     index
	     ,cache-size
	     ,cache-mask
	     #'all-std-class-readers-tertiary-miss
	     #'make-all-std-class-readers-dcode
	     (progn
	       (setq value (%svref (iwmc-class-static-slots arg) index))
	       (if (eq value ',*slot-unbound*)
		   (go miss)
		   (return-from accessor-dcode value)))
	     (return-from accessor-dcode (slot-value arg index))))))))
		 

(define-function-template all-std-class-writers-dcode
			  (cache-size cache-mask)
			  '(.GENERIC-FUNCTION. .CACHE. .NEXT-SCAN-LIMIT.)
  (let ()
    `(function
       (lambda (new-value arg)
	 (declare (optimize (speed 3) (safety 0)))
	 (let ((starting-lock-count (cache-lock-count .CACHE.)))
	   (all-std-class-accessors-dcode-internal
	     t
	     index
	     ,cache-size
	     ,cache-mask
	     #'all-std-class-writers-tertiary-miss
	     #'make-all-std-class-writers-dcode
	     (setf (%svref (iwmc-class-static-slots arg) index) new-value)
	     (setf (slot-value arg index) new-value)))))))

(defmacro all-std-class-accessors-dcode-internal (writerp
						  index
						  cache-size
						  cache-mask
						  tertiary-miss
						  dcode-constructor
						  fast-form
						  slow-form)
  (let ((full-args (if writerp '(new-value arg) '(arg))))
    `(block accessor-dcode
       (macrolet ((r/w-cache-key () '(%svref .CACHE. location))
		  (r/w-cache-val () '(%svref .CACHE. (%1+ location))))

	 (let* ((wrapper (and (iwmc-class-p arg)
			      (iwmc-class-class-wrapper arg)))
		(location 0)
		(,index nil))
	   (declare (type fixnum location))
	   (if (null wrapper)
	       (no-applicable-method .GENERIC-FUNCTION. ,@full-args)
	       (tagbody
		 (setq location
		       (compute-wrapper-cache-location ,cache-mask 2 wrapper))
		 (cond ((eq (r/w-cache-key) wrapper)
			(setq ,index (r/w-cache-val))
			(go hit))
		       (t
			(setq location (%- (- ,cache-size 2) location))
			(cond ((eq (r/w-cache-key) wrapper)
			       (setq ,index (r/w-cache-val))
			       (go hit))
			      (t
			       (go miss)))))
	       
	      hit
		 (if (eq starting-lock-count (cache-lock-count .CACHE.))
		     (go hit-internal)
		     (go miss))

	      hit-internal
		 (return-from accessor-dcode ,fast-form)
	       
	      miss
		 (progn
		   (setq ,index
			 (dcode-cache-miss
			   .GENERIC-FUNCTION.
			   ,tertiary-miss
			   .CACHE.
			   ,cache-size
			   ,cache-mask
			   2			;line size
			   1			;nkeys
			   .NEXT-SCAN-LIMIT.
			   (< ,cache-size
			      *all-std-class-accessors-max-cache-size*)
			   ,dcode-constructor
			   wrapper
			   ,@full-args))
		   (cond ((eq ,index '..no-applicable-method..)
			  (return-from accessor-dcode
			    (no-applicable-method .GENERIC-FUNCTION.
						  ,@full-args)))
			 ((not (symbolp ,index))
			  (go hit-internal))
			 (t
			  (return-from accessor-dcode ,slow-form)))))))))))
  
(defun all-std-class-readers-tertiary-miss (generic-function arg)
  (let ((method (lookup-method-1 generic-function arg)))
    (if (null method)
	'..no-applicable-method..
	(let* ((wrapper (wrapper-of arg))
	       (class (wrapper-class wrapper))
	       (slot-name (reader/writer-method-slot-name method))
	       (slot-pos (all-std-class-readers-miss-1 class
						       wrapper
						       slot-name))
	       (slots (iwmc-class-static-slots arg)))
	  (if (and (not (null slot-pos))
		   (neq (svref slots slot-pos) *slot-unbound*))
	      slot-pos
	      slot-name)))))

(defun all-std-class-writers-tertiary-miss (generic-function new-value arg)
  (let ((method (lookup-method-1 generic-function new-value arg)))
    (if (null method)
	'..no-applicable-method..
	(let* ((wrapper (wrapper-of arg))
	       (class (wrapper-class wrapper))
	       (slot-name (reader/writer-method-slot-name method))
	       (slot-pos (all-std-class-readers-miss-1 class
						       wrapper
						       slot-name)))
	  (if (not (null slot-pos))
	      slot-pos
	      slot-name)))))

(defmethod all-std-class-readers-miss-1
	   ((class standard-class) wrapper slot-name)
  (instance-slot-position wrapper slot-name))


(defmacro pre-make-all-std-class-accessor-dcodes (&rest lines)
  (let ((forms ()))
    (dolist (nlines lines)
      (push (pre-make-all-std-class-accessors-1 nlines) forms))
    `(progn ,.forms)))

(defun pre-make-all-std-class-accessors-1 (nlines)
  (let ((cache-mask (make-wrapper-cache-mask nlines))
	(cache-size (* nlines 2)))
    `(progn
       (pre-make-templated-function-constructor all-std-class-readers-dcode
						,cache-size
						,cache-mask)       
       (pre-make-templated-function-constructor all-std-class-writers-dcode
						,cache-size
						,cache-mask))))


;;;
;;; In the case where there is only one method on a generic function, we can
;;; use a cache which has no values, only keys.  The existence of a set of
;;; keys in the cache means that that one method is in fact applicable.  The
;;; advantage to this kind of cache is that we can save cache space.
;;; 

(defvar *checking-dcode-default-number-of-cache-lines* 8)
(defvar *checking-dcode-default-next-scan-limit* 4)
(defvar *checking-dcode-max-cache-size* 256)

(defun checking-dcode-default-cache-size (nkeys)
  (declare (values size mask line-size))
  (let* ((nlines *checking-dcode-default-number-of-cache-lines*)
	 (line-size (compute-line-size nkeys))
	 (cache-size (* nlines line-size)))
    (values cache-size
	    (case nlines
	      ((8)  *8-cache-mask*)
	      ((16) *16-cache-mask*)
	      ((32) *32-cache-mask*)
	      (otherwise (make-wrapper-cache-mask nlines)))
	    line-size)))

(defun make-checking-dcode (generic-function &optional cache)
  (multiple-value-bind (required restp specialized-positions)
      (compute-discriminating-function-arglist-info generic-function)
    (let ((nkeys (length specialized-positions))
	  (cache-size nil)
	  (cache-mask nil)
	  (nlines nil)
	  (line-size nil))
      (cond ((null cache)
	     (multiple-value-setq (cache-size cache-mask line-size)
				  (checking-dcode-default-cache-size nkeys))
	     (setq cache
		   (ensure-generic-function-cache generic-function
						  cache-size)))
	    (t
	     (setq cache-size (generic-function-cache-size cache)
		   line-size (compute-line-size nkeys)
		   nlines (floor cache-size line-size)		   
		   cache-mask (case nlines
				((8)  *8-cache-mask*)
				((16) *16-cache-mask*)
				((32) *32-cache-mask*)
				(otherwise
				  (make-wrapper-cache-mask nlines))))))
      (funcall (get-templated-function-constructor 'checking-dcode
						   required
						   restp
						   specialized-positions
						   cache-size
						   cache-mask
						   line-size)
	       generic-function
	       cache
	       *checking-dcode-default-next-scan-limit*
	       (cadar (generic-function-combined-methods generic-function))))))

(defmacro pre-make-checking-dcode (specs)
  `(progn
     ,@(gathering ((forms (collecting)))
	 (dolist (spec specs)
	   (destructuring-bind (required restp specialized-positions . lines)
			       spec
	     (let* ((nkeys (length specialized-positions))
		    (line-size (compute-line-size nkeys)))
	       (dolist (nlines lines)
		 (let ((size (* nlines line-size))
		       (mask (make-wrapper-cache-mask nlines)))
		   (gather `(pre-make-templated-function-constructor
			      checking-dcode
			      ,required
			      ,restp
			      ,specialized-positions
			      ,size
			      ,mask
			      ,line-size)
			   forms)))))))))

(defun checking-dcode-tertiary-miss (generic-function &rest required-args)
  (if (not (null (apply #'lookup-method-2 generic-function required-args)))
      1
      '..no-applicable-method..))

(define-function-template checking-dcode (required
					  restp
					  specialized-positions
					  cache-size
					  cache-mask
					  line-size)
					 '(.GENERIC-FUNCTION.
					   .CACHE.
					   .NEXT-SCAN-LIMIT.
					   .METHOD-FUNCTION.)
  (let* ((nkeys (length specialized-positions))
	 (args (gathering ((args (collecting)))
		 (dotimes (i required)
		   (gather (dcode-arg-symbol i) args))))
         (wrapper-bindings (gathering ((bindings (collecting)))
			     (dolist (pos specialized-positions)
			       (gather (list (dcode-wrapper-symbol pos)
					     `(wrapper-of-2 ,(nth pos args)))
				       bindings))))
         (wrappers (mapcar #'car wrapper-bindings)))
    
    (flet ((make-call (fn &rest extra-args)
	     (when (eq fn 'probe) (setq fn '.METHOD-FUNCTION.))
	     (if restp
		 `(apply ,fn ,@extra-args ,@args rest-arg)
		 `(funcall ,fn ,@extra-args ,@args)))
	   (make-probe (loc)
	     `(and ,@(gathering1 (collecting)
		       (iterate ((wrapper (list-elements wrappers))
				 (key-no (interval :from 0)))
			 (gather1 `(eq (%svref .CACHE. (%+ ,loc ,key-no))
				      ,wrapper)))))))
      
      `(function
	 (lambda (,@args ,@(and restp '(&rest rest-arg)))
	   (declare (optimize (speed 3) (safety 0)))
	   #+genera-release-7-2
	   (declare (dbg:invisible-frame :clos-discriminator))
	   (let ((starting-lock-count (cache-lock-count .CACHE.))
		 ,.wrapper-bindings)
	     ,(make-caching-dcode-internal #'make-call
					   #'make-probe
					   '#'checking-dcode-tertiary-miss
					   wrappers
					   args
					   cache-size
					   cache-mask
					   line-size
					   nkeys
					   '*checking-dcode-max-cache-size*
					   '#'make-checking-dcode)))))))
    


;;;
;;; This is the case where there multiple methods.  In this case the values
;;; are the actual method function.
;;; 

(defvar *caching-dcode-default-number-of-cache-lines* 8)
(defvar *caching-dcode-default-next-scan-limit* 3)
(defvar *caching-dcode-max-cache-size* 256)

(defun caching-dcode-default-cache-size (nkeys)
  (declare (values size mask line-size))
  (let* ((nlines *caching-dcode-default-number-of-cache-lines*)
	 (line-size (compute-line-size (1+ nkeys)))
	 (cache-size (* nlines line-size)))
    (values cache-size
	    (case nlines
	      ((8)  *8-cache-mask*)
	      ((16) *16-cache-mask*)
	      ((32) *32-cache-mask*)
	      (otherwise (make-wrapper-cache-mask nlines)))
	    line-size)))

(defun make-caching-dcode (generic-function &optional cache)
  (multiple-value-bind (required restp specialized-positions)
      (compute-discriminating-function-arglist-info generic-function)
    (let ((nkeys (length specialized-positions))
	  (cache-size nil)
	  (cache-mask nil)
	  (nlines nil)
	  (line-size nil))
      (cond ((null cache)
	     (multiple-value-setq (cache-size cache-mask line-size)
				  (caching-dcode-default-cache-size nkeys))
	     (setq cache
		   (ensure-generic-function-cache generic-function
						  cache-size)))
	    (t
	     (setq cache-size (generic-function-cache-size cache)
		   line-size (compute-line-size (1+ nkeys))
		   nlines (floor cache-size line-size)		   
		   cache-mask (case nlines
				((8)  *8-cache-mask*)
				((16) *16-cache-mask*)
				((32) *32-cache-mask*)
				(otherwise
				  (make-wrapper-cache-mask nlines))))))
      (funcall (get-templated-function-constructor 'caching-dcode
						   required
						   restp
						   specialized-positions
						   cache-size
						   cache-mask
						   line-size)
	       generic-function
	       cache
	       *caching-dcode-default-next-scan-limit*))))

(defmacro pre-make-caching-dcode (specs)
  `(progn
     ,@(gathering ((forms (collecting)))
	 (dolist (spec specs)
	   (destructuring-bind (required restp specialized-positions . lines)
			       spec
	     (let* ((nkeys (length specialized-positions))
		    (line-size (compute-line-size (1+ nkeys))))
	       (dolist (nlines lines)
		 (let* ((size (* nlines line-size))
			(mask (make-wrapper-cache-mask nlines)))
		   (gather `(pre-make-templated-function-constructor
			      caching-dcode
			      ,required
			      ,restp
			      ,specialized-positions
			      ,size
			      ,mask
			      ,line-size)
			   forms)))))))))

(defun caching-dcode-tertiary-miss (generic-function &rest required-args)
  (or (apply #'lookup-method-2 generic-function required-args)
      '..no-applicable-method..))

(define-function-template caching-dcode (required
					 restp
					 specialized-positions
					 cache-size
					 cache-mask
					 line-size)
					'(.GENERIC-FUNCTION.
					  .CACHE.
					  .NEXT-SCAN-LIMIT.)
  (let* ((nkeys (length specialized-positions))
	 (args (gathering ((args (collecting)))
		 (dotimes (i required)
		   (gather (dcode-arg-symbol i) args))))
         (wrapper-bindings (gathering ((bindings (collecting)))
			     (dolist (pos specialized-positions)
			       (gather (list (dcode-wrapper-symbol pos)
					     `(wrapper-of-2 ,(nth pos args)))
				       bindings))))
         (wrappers (mapcar #'car wrapper-bindings)))
    
    (flet ((make-call (fn &rest extra-args)
	     (if restp
		 `(apply ,fn ,@extra-args ,@args rest-arg)
		 `(funcall ,fn ,@extra-args ,@args)))
	   (make-probe (loc)
	     `(and ,@(gathering1 (collecting)
		       (iterate ((wrapper (list-elements wrappers))
				 (key-no (interval :from 0)))
			 (gather1 `(eq (%svref .CACHE. (%+ ,loc ,key-no))
				      ,wrapper))))
		   (%svref .CACHE. (%+ ,loc ,(length wrappers))))))
      
      `(function
	 (lambda (,@args ,@(and restp '(&rest rest-arg)))
	   (declare (optimize (speed 3) (safety 0)))
	   #+genera-release-7-2
	   (declare (dbg:invisible-frame :clos-discriminator))
	   (let ((starting-lock-count (cache-lock-count .CACHE.))
		 ,.wrapper-bindings)
	     ,(make-caching-dcode-internal #'make-call
					   #'make-probe
					   '#'caching-dcode-tertiary-miss
					   wrappers
					   args
					   cache-size
					   cache-mask
					   line-size
					   nkeys
					   '*caching-dcode-max-cache-size*
					   '#'make-caching-dcode)))))))


(defun make-caching-dcode-internal (make-call
				    make-probe
				    tertiary-miss
				    wrappers
				    args
				    cache-size
				    cache-mask
				    line-size
				    nkeys
				    max-cache-size
				    dcode-constructor)

  `(prog ((probe nil)
	  (location (compute-wrapper-cache-location ,cache-mask
		     			            ,line-size
						    ,@wrappers)))
	 (declare (type fixnum location))
	 (tagbody
	   (if (setq probe ,(funcall make-probe 'location))
	       (go hit)
	       (progn
		 (setq location (%- ,(- cache-size line-size) location))
		 (if (setq probe ,(funcall make-probe 'location))
		     (go hit)
		     (go miss))))
	      
	hit
	   (if (eq (cache-lock-count .CACHE.) starting-lock-count)
	       (go hit-internal)
	       (go miss))

	hit-internal
	   (return ,(funcall make-call 'probe))

	miss
	   (progn
	     (setq probe (dcode-cache-miss .generic-function.
					   ,tertiary-miss
					   .CACHE.
					   ,cache-size
					   ,cache-mask
					   ,line-size
					   ,nkeys
					   .NEXT-SCAN-LIMIT.
					   (< ,cache-size ,max-cache-size)
					   ,dcode-constructor
					   ,@wrappers
					   ,@args))
		       
	     (if (eq probe '..no-applicable-method..)
		 (return ,(funcall make-call
				   '#'no-applicable-method
				   '.GENERIC-FUNCTION.))
		 (go hit-internal))))))
