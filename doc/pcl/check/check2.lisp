;;;-*-Mode:LISP; Package: PCL; Base:10; Syntax:Common-lisp -*-
;;;
;;; *************************************************************************
;;; Copyright (c) 1985, 1986, 1987, 1988, 1989 Xerox Corporation.
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

(in-package "PCL")

;;;
;;; This file contains:
;;;   * almost friendly code to check to see if these new
;;;     definitions will screw a given system
;;;
;;; This file is designed to be compiled and loaded in the 12/7/88
;;; version of PCL.  Attempting to load it into later versions of
;;; PCL can cause bad surprises
;;; 
;;; These are special stuff for computing the changes that will be
;;; caused by new implementation of compute-class-precedence-list
;;; and standard-method-combination in the next version of PCL
;;;
;;; check program for new cpl and combination-points implementations
;;; to use
;;; (1) load 12/7/88 version of PCL by (pcl:load-pcl)
;;; (2) load the program you want to analyze
;;; (3) compile and load check1.lisp and check2.lisp
;;; (4) call (pcl::check-precedence)
;;;

;;;
;;; This first part is basically lifted from gather.lisp.
;;; 

(defun collect-pcl-external-symbols ()
  (gathering ((result (collecting)))
    (do-external-symbols (s *the-pcl-package*) (gather s result))))

(defvar *pcl-external-symbols* (collect-pcl-external-symbols))

(defvar *the-lisp-package* (find-package 'lisp))

(defvar *generic-functions* ())
(defvar *classes* ())
(defvar *methods* ())

(defvar *metaobjects* ())

(defun gather-metaobjects (&optional (scope :user))
  (check-type scope
	      (or (member :user :all :pcl :clos) package)
	      "A PACKAGE or one of the symbols :user :all :pcl :clos")
  (setq *generic-functions* ()
	*classes* ()
	*methods* ())
  (labels ((walk (class)
	     (when (gatherp class scope)
	       (pushnew class *classes*)
	       (pushnew class *metaobjects*))
	     (dolist (m (class-direct-methods class))
	       (when (gatherp m scope)
		 (pushnew m *methods*)
		 (pushnew m *metaobjects*))
	       (let ((gf (method-generic-function m)))
		 (when (and gf (gatherp gf scope))
		   (pushnew gf *generic-functions*)
		   (pushnew gf *metaobjects*))))
	     (dolist (sub (class-direct-subclasses class))
	       (walk sub))))
    (walk (find-class 't))
    (format t
	    "~&~D Classes, ~D Generic Functions, ~D Methods."
	    (length *classes*)
	    (length *generic-functions*)
	    (length *methods*))))

(defmethod gatherp ((class standard-class) scope)
  (let* ((name (class-name class))
	 (package (and name (symbolp name) (symbol-package name))))
    (if (or (null package) (neq (find-class name nil) class))
	t
	(gatherp-internal name package scope))))

(defmethod gatherp ((method standard-method) scope)
  (let ((generic-function (method-generic-function method)))
    (and generic-function
	 (gatherp generic-function scope))))

(defmethod gatherp ((gf standard-generic-function) scope)
  (let* ((name (generic-function-name gf))
	 (specp (cond ((null name) nil)
		      ((symbolp name) 'symbol)
		      ((and (listp name)
			    (eq (car name) 'setf)
			    (null (cddr name)))
		       'setf)
		      (t nil)))
	 (package (ecase specp
		    (symbol (symbol-package name))
		    (setf (symbol-package (cadr name)))
		    ((nil) nil))))
    (if (or (null specp) (not (gboundp name)) (neq (gdefinition name) gf))
	t
	(gatherp-internal name package scope))))

		      
(defun gatherp-internal (name package scope)
  (case scope
    (:user (and (neq package *the-pcl-package*)
		(neq package *the-lisp-package*)))
    (:pcl (eq package *the-pcl-package*))
    (:clos (or (eq package *the-lisp-package*)
	       (memq name *pcl-external-symbols*)))
    (:all t)
    (otherwise (eq package scope))))


;;;
;;; Here is the check program
;;;
(defvar *changed-classes* ())
(defvar *changed-generic-functions* ())

(defvar *eql-gfs* ())
(defvar *specializer-error-gfs* ())
(defvar *non-standard-qualifier-gfs* ())

(defun check-precedence (&optional (scope :all))
  (let ((*classes* ())
	(*generic-functions* ())
	(*methods* ())
	(*metaobjects* ())
	(*changed-classes* ())
	(*changed-generic-functions* ())
	(*eql-gfs* ())
	(*specializer-error-gfs* ())
	(*non-standard-qualifier-gfs* ()))
    (format t "~%Phase 1: Gathering metaobjects...~%")
    (gather-metaobjects scope)
    (format t "~%~%Phase 2: Analyzing...~%")
    (gather-changed-metaobjects)
    (cond ((or *eql-gfs* *specializer-error-gfs* *non-standard-qualifier-gfs*
	       *changed-classes* *changed-generic-functions*)
	   ;we do have some change
	   (format t "~%Phase 3: Description of effects of new precedence computation...~%")
	   (when *eql-gfs*
	     (warn-eql-gfs))
	   (when *specializer-error-gfs*
	     (warn-specializer-error-gfs))
	   (when *non-standard-qualifier-gfs*
	     (warn-non-standard-qualifier-gfs))
	   (when *changed-generic-functions*
	     (warn-generic-function-change))
	   (when *changed-classes*
	     (warn-class-change)))
	  (t
	   ;we don't have any chage
	   (format t "~%No differences found.")))))

;;;
;;; gather changed objects by checking check the *classes*'s cpl
;;; and *generic-functions*'s combination-points
;;;
(defun gather-changed-metaobjects ()
  (dolist (class *classes*)
    (unless (equal (compute-class-precedence-list class)
		   (compute-std-cpl class))
      (push class *changed-classes*)))
  (labels ((point-lessp (p1 p2)
	     (cond ((eq p1 p2) nil)
		   ((eq (car p1) (car p2))
		    (point-lessp (cdr p1) (cdr p2)))
		   (t
		    (member (car p2) (member (car p1) *classes*)))))
	   (sort-points (points)
	     (sort points #'(lambda (p1 p2)
			      (point-lessp (car p1) (car p2))))))

    ;; set *eql-gfs*, *non-standard-qualifier-gfs*,
    ;; *specializer-error-gfs* and *generic-functions*
    (precheck-generic-functions)

    (let ((old-sorted-points ())
	  (new-sorted-points ()))
      (dolist (generic-function *generic-functions*)
	(push (sort-points (compute-combination-points generic-function))
	      old-sorted-points))

      ;; We need to make sure we are computing new combination-points
      ;; by using new cpl
      (unwind-protect 
	   (progn
	     (dolist (class *classes*)
	       (setf (class-precedence-list class)
		     (compute-std-cpl class)))
	     (dolist (generic-function *generic-functions*)
	       (push (sort-points
		       (*compute-combination-points generic-function))
		     new-sorted-points)))
	(dolist (class *classes*)
	  (setf (class-precedence-list class)
		(compute-class-precedence-list class))))

      (iterate ((old-sort (list-elements (nreverse old-sorted-points)))
		(new-sort (list-elements (nreverse new-sorted-points)))
		(generic-function (list-elements *generic-functions*)))
	  (unless (same-method-order-p old-sort new-sort)
	    (push (list generic-function old-sort new-sort)
		  *changed-generic-functions*))))))

;(defun sort-methods-by-qualifiers (methods)
;  (stable-sort methods
;	       #'(lambda (one another)
;		   (and (equal (method-type-specifiers one)
;			       (method-type-specifiers another))
;			(string-lessp (prin1-to-string
;					(method-qualifiers one))
;				      (prin1-to-string
;					(method-qualifiers another)))))))

;;;
;;; check over the all points and if the order of methods of all points
;;; are same it returns t
;;;
(defun same-method-order-p (old-points new-points)
  (unless (eql (length old-points) (length new-points))
    (return-from same-method-order-p nil))
  (iterate ((old-p-m (list-elements old-points))
	    (new-p-m (list-elements new-points)))
    (unless (and (equal (car old-p-m)
			(car new-p-m))
		 (same-method-order-p-1 (cadr old-p-m)
					(cadr new-p-m)))
      (return-from same-method-order-p nil)))
  t)

;;;
;;; check two lists of methods each other and if the order of methods
;;; are same it returns t
;;;
(defun same-method-order-p-1 (order-1 order-2)
  (dolist (qualifiers '(() (:before) (:after) (:around)))
    (let ((methods-1 ())
	  (methods-2 ()))
      (dolist (m1 order-1)
	(when (equal (method-qualifiers m1) qualifiers)
	  (push m1 methods-1)))
      (dolist (m2 order-2)
	(when (equal (method-qualifiers m2) qualifiers)
	  (push m2 methods-2)))
      (unless (equal methods-1 methods-2)
	(return-from same-method-order-p-1 nil))))
  t)

;;;
;;; This check program cannot analyze the behavior of generic functions
;;; which contain EQL methods.  The following generic functions warned by
;;; this function should be checked by hand.
;;;
;;; If you have any generic functions such as all methods in this generic
;;; function have all EQL specailizers, you also need to check these by hand.
;;; This check program doesn't say anything because the gather program cannot
;;; gather these kinds of methods and generic functions
;;;
(defun warn-eql-gfs ()
  (format t
	  "~%This program cannot analyze the behavior of generic functions~%~
           which contain EQL methods.  The following generic functions~%~
           should be checked by hand:~%~%")
  (dolist (gf *eql-gfs*)
    (format t
	    "    ~S~%"
	    (generic-function-name gf)))
  (format t
	  "~%Keep in mind that in 12/7/88 and older versions of PCL,~%~
           EQL methods did not interact properly with method combination.~%~
           In the next version of PCL, this will work properly.~%~
           ~%***~%"))

;;;
;;; 12/7/88 version of PCL only supports standard-method-combination.  This
;;; check program only handle standart method combination.
;;;
(defun warn-non-standard-qualifier-gfs ()
  (format t
	  "~%This program cannot analyze the behavior of generic functions~%~
           which using non-standard method combination.  The following~%~
           generic functions should be checked by hand:~%~%")
  (dolist (gf *non-standard-qualifier-gfs*)
    (format t
	    "    ~S~%"
	    (generic-function-name gf)))
  (format t
	  "~%***~%"))

;;;
;;; wanrs the bugs in your method definitions
;;;
(defun warn-specializer-error-gfs ()
  (format t
	  "~%The following generic functions have methods with a different~%~
           number of parameter specializers.  This program cannot analyze~%~
           the behavior of such generic functions.  A future version of~%~
           PCL will signal an error in such cases.~%~%")
  (dolist (gf *specializer-error-gfs*)
    (format t
	    "    ~S~%"
	    (generic-function-name gf)))
  (format t
	  "~%***~%"))

;;;
;;; The check program only works on generic functions filitered by this
;;; precheck.
;;;
(defun precheck-generic-functions ()
  (let ((eql-gfs ())
	(non-standard-qualifier-gfs ())
	(specializer-error-gfs ())
	(other-gfs ()))
    (dolist (gf *generic-functions*)
      (let* ((methods (generic-function-methods gf))
	     (no-of-spec-params
	      (length (method-type-specifiers (car methods)))))
	(block next-gf
	  (dolist (method methods)
	    (let ((specl (method-type-specifiers method))
		  (qualifiers (method-qualifiers method)))
	      (when (neq (length specl) no-of-spec-params)
		(push gf specializer-error-gfs)
		(return-from next-gf))
	      (unless (or (cadr qualifiers)
			  (memq (car qualifiers)
				'(() :before :after :around)))
		(push gf non-standard-qualifier-gfs)
		(return-from next-gf))
	      (dolist (spec specl)
		(specializer-case spec
		   (:eql (push gf eql-gfs)
			 (return-from next-gf))
		   (:class nil)))))
	  (push gf other-gfs))))
    (setq *eql-gfs* eql-gfs
	  *non-standard-qualifier-gfs* non-standard-qualifier-gfs
	  *specializer-error-gfs* specializer-error-gfs
	  *generic-functions* other-gfs)))

;;;
;;; warns the changes of generic functions
;;;

(defun warn-generic-function-change ()
  (dolist (gf-and-points *changed-generic-functions*)
    (destructuring-bind (gf old-points new-points)
			gf-and-points
      (multiple-value-bind (different missing extra)
	                   (compute-point-diffs old-points new-points)
	;; check specializers to make sure
	(warn-point-diffs gf old-points new-points different missing extra)))))

(defun warn-point-diffs (gf old-points new-points different missing extra)
  (dolist (d different)
    (warn-gf-difference gf (caar d)
			(compute-gf-difference (cadar d) (cadadr d))))
  (dolist (m missing)
    (let ((old-super-point
	   (get-super-point old-points
			    (car m)
			    #'compute-class-precedence-list))
	  (new-super-point
	   (get-super-point new-points
			    (car m)
			    #'compute-std-cpl)))
      (if (same-method-order-p-1
	    (cadr m)
	    (cadr old-super-point))
	  (warn-gf-redundant-point gf m :old)
	  (or (same-method-order-p-1 (cadr m)
				     (cadr new-super-point))
	      (warn-gf-difference gf (car m)
				  (compute-gf-difference
				    (cadr m)
				    (cadr new-super-point)))))))
  (dolist (e extra)
    (let ((old-super-point
	   (get-super-point old-points
			    (car e)
			    #'compute-class-precedence-list))
	  (new-super-point
	   (get-super-point new-points
			    (car e)
			    #'compute-std-cpl)))
      (if (same-method-order-p-1 (cadr e)
				 (cadr new-super-point))
	  (warn-gf-redundant-point gf e :new)
	  (or (same-method-order-p-1 (cadr e)
				     (cadr old-super-point))
	      (warn-gf-difference gf (car e)
				  (compute-gf-difference
				    (cadr old-super-point)
				    (cadr e))))))))

(defun warn-gf-redundant-point (gf p-m old-or-new)
  (declare (ignore gf p-m old-or-new))
  ;; This is the codes for debugging the new implementation
  ;; of compute-std-cpl, *compute-combination-points and check program
;  (ecase old-or-new
;    (:old (format t "~%Generic function ~S had a redundant point~%~
;                     This is now fixed in the new implementation"
;	  (generic-function-name gf)))
;    (:new (format t "~%Generic function ~S has a redundant point~%~
;                     This is not a real error but should be fixed"
;		  (Generic-function-name gf))))
;  (format t "~%point:  ~S"
;	  (mapcar #'class-name (car p-m)))
;  (format t "~%method: ~S~%"
;	  (mapcar #'(lambda (method)
;		      (mapcar #'class-name
;			      (method-type-specifiers method)))
;		  (cadr p-m)))
  )

(defun warn-gf-difference (gf point changes)
  (iterate ((qualifier (list-elements '(before after around primary)))
	    (change (list-elements changes)))
    (unless (eq change t)
      (let ((o-result (car change))
	    (n-result (cadr change)))
	(cond ((and (null o-result)
		    (null n-result)))
	      ((null o-result)
	       (format t
		       "~%~%~
                When generic-function ~S is called with instance~P of:~%~
                ~S~%~
                The ~A method~P ~S ~A not applicable in old implementation~%~
                Now, the method~P ~A applicable in new implementation"
		       (generic-function-name gf)
		       (length point)
		       (mapcar #'class-name point)
		       qualifier
		       (length n-result)
		       n-result
		       (is-or-are n-result)
		       (length n-result)
		       (is-or-are n-result)))
	      ((null n-result)
	       (format t
		       "~%~%~
                  When generic-function ~S is called with instance~P of:~%~
                  ~S~%~
                  The ~A method~P ~S ~A applicable in old implementation~%~
                  Now, the method~P ~A not applicable in new implementation"
		       (generic-function-name gf)
		       (length point)
		       (mapcar #'class-name point)
		       qualifier
		       (length o-result)
		       o-result
		       (is-or-are o-result)
		       (length o-result)
		       (is-or-are o-result)))
	      (t 
	       (format t
		       "~%~%~
                  When generic-function ~S is called with instance~P of:~%~
                  ~S~%~
                  Order of ~A method~P has changed~%~
                  Old order of method~P is:~%~
                  ~S~%~
                  New order of method~P is:~%~
                  ~S"
		       (generic-function-name gf)
		       (length point)
		       (mapcar #'class-name point)
		       qualifier
		       (length o-result)
		       (length o-result)
		       o-result
		       (length n-result)
		       n-result)))))))

(defun is-or-are (sequence)
  (if (eq (length sequence) 1)
      "is"
      "are"))
  
(defun separate-methods (ordered-methods)
  (let ((before  ())
	(after   ())
	(around  ())
	(primary ()))
    (dolist (m ordered-methods)
      (let ((qualifiers (method-qualifiers m))
	    (spec (mapcar #'class-name
			  (method-type-specifiers m))))
	(cond ((memq ':before qualifiers) (push spec before))
	      ((memq ':after  qualifiers) (push spec after))
	      ((memq ':around  qualifiers) (push spec around))
	      (t
	       (push spec primary)))))
    (values before
	    (nreverse after)
	    (nreverse around)
	    (nreverse primary))))

(defun compute-gf-difference (o-methods n-methods)
  (multiple-value-bind (old-before old-after old-around old-primary)
      (separate-methods o-methods)
    (multiple-value-bind (new-before new-after new-around new-primary)
	(separate-methods n-methods)
      (list (compute-gf-difference-1 old-before new-before)
	    (compute-gf-difference-1 old-after new-after)
	    (compute-gf-difference-1 old-around new-around)
	    (compute-gf-difference-1 old-primary new-primary)))))
	      

(defun compute-gf-difference-1 (old new)
  (if (equal old new)
      t
      (list (subseq old
		    (mismatch old new :test #'equal)
		    (mismatch old new :test #'equal :from-end t))
	    (subseq new
		    (mismatch old new :test #'equal)
		    (mismatch old new :test #'equal :from-end t)))))
	   
(defun get-super-point
    (points point &optional (compute-fn #'compute-std-cpl))
  (let ((list-of-cpl (mapcar #'(lambda (spec)
				 (funcall compute-fn spec))
			     point))
	(result-so-far ()))
    (dolist (p-m points)
      (block next-point
	(let ((p (car p-m))
	      (label ()))
	  (if (equal p point)
	      (return-from next-point)
	      (iterate ((class (list-elements p))
			(cpl (list-elements list-of-cpl)))
		(let ((foundp (memq class cpl)))
		  (if foundp
		      (push (length foundp) label)
		      (return-from next-point)))))
	  (setq label (nreverse label))
	  (if result-so-far
	      (when (list-greater-p label (cdr result-so-far))
		(setq result-so-far (cons p-m label)))
	      (setq result-so-far (cons p-m label))))))
    (if result-so-far
	(car result-so-far))))

(defun list-greater-p (label label-so-far)
  (let ((number (car label))
	(number-so-far (car label-so-far)))
    (cond ((> number number-so-far)
	   t)
	  ((= number number-so-far)
	   (list-greater-p (cdr label) (cdr label-so-far))))))

;;;
;;; compute the different points for each changed generic functiuons
;;; 
(defun compute-point-diffs (old-points new-points)
  (let ((different ())
	(missing old-points)
	(extra ()))
    (dolist (new-point new-points)
      (let ((old-point (find (car new-point) old-points :key #'car
							:test #'equal)))
	(if old-point
	    (progn
	      (unless (same-method-order-p-1 (cadr old-point)
					     (cadr new-point))
		(push (list old-point new-point) different))
	      (setq missing (remove old-point missing :test #'equal)))
	    (push new-point extra))))
    (values different missing extra)))

;;;
;;; warn changed classes(cpl, default-initargs and slots[initform/initargs/
;;;                                                      allocation/type]
(defun warn-class-change ()
  (dolist (class *changed-classes*)
    (let ((old-cpl (compute-class-precedence-list class))
	  (new-cpl (compute-std-cpl class)))
      (multiple-value-bind (old new)
	                   (compute-cpl-difference old-cpl new-cpl)
	(format t "~%~%Class ~S's class-precedence-list has changed~%~
                   Old order: ~S~%~
                   New order: ~S"
		(class-name class)
		old
		new))

      (let ((old-default (collect-all-default-initargs class old-cpl))
	    (new-default (collect-all-default-initargs class new-cpl)))
	(when (iterate ((old (list-elements old-default))
			(new (list-elements new-default)))
		(unless (and (eq (car old)
				 (car new))
			     (equal (caddr old)
				    (caddr new)))
		  (return t)))
	  (multiple-value-bind (o-result n-result)
	                       (compute-initarg-difference old-default
							   new-default)
	    (warn-initarg-difference class o-result n-result))))

      (let ((old-slotds (collect-slotds class
					(class-local-slots class)
					old-cpl))
	    (new-slotds (collect-slotds class
					(class-local-slots class)
					new-cpl)))
	(multiple-value-bind (different missing extra)
	                     (compute-slotd-diffs old-slotds new-slotds)
	  (warn-slotd-diffs class different missing extra))))))

(defun compute-cpl-difference (old-cpl new-cpl)
  (gathering ((old (collecting))
	      (new (collecting)))
    (iterate ((o (list-elements old-cpl))
	      (n (list-elements new-cpl)))
      (unless (equal o n)
	(gather (class-name o) old)
	(gather (class-name n) new)))))

(defun compute-initarg-difference (old-default new-default)
  (gathering ((o-result (collecting))
	      (n-result (collecting)))
    (iterate ((o-default (list-elements old-default))
	      (n-default (list-elements new-default)))
      (unless (and (eq (car o-default) (car n-default))
		   (equal (caddr o-default) (caddr n-default)))
	(gather o-default o-result)
	(gather n-default n-result)))))

(defun warn-initarg-difference (class old-default new-default)
  (format t "~%Default initargs for class ~S also changed~%~
             Old: ~S~%~
             New: ~S"
	  (class-name class)
	  (mapcar #'(lambda (old)
		      (cons (car old) (cddr old)))
		  old-default)
	  (mapcar #'(lambda (new)
		      (cons (car new) (cddr new)))
		  new-default)))

(defun compute-slotd-diffs (old-slotds new-slotds)
  (let ((different ())
	(missing old-slotds)
	(extra ()))
    (dolist (new-slotd new-slotds)
      (let ((old-slotd (find-slotd (slotd-name new-slotd) old-slotds)))
	(if old-slotd
	    (progn (unless (slotd-equal old-slotd new-slotd)
		     (push (list old-slotd new-slotd) different))
		   (setq missing (remove old-slotd missing)))
	    (push new-slotd extra))))
    (values different missing extra)))

(defun slotd-equal (one another)
  (flet ((initarg-equal (args1 args2)
	   (and (eql (length args1)
		     (length args2))
		(not (dolist (arg1 args1)
		       (unless (memq arg1 args2)
			 (return t)))))))
    (and (equal (slotd-initform one)
		(slotd-initform another))
	 (initarg-equal (slotd-initargs one)
			(slotd-initargs another))
	 (eq (slotd-allocation one)
	     (slotd-allocation another))
	 (equal (slotd-type one)
		(slotd-type another)))))

(defun warn-slotd-diffs (class different missing extra)
  (when (or different missing extra)
    (format t "~%Slot information for class ~S has changed"
	    (class-name class))
    (dolist (d different)
      (multiple-value-bind (initform initargs allocation type)
                           (compute-slotd-difference (car d) (cadr d))
	(warn-slotd-difference (class-name class) (slotd-name (car d))
			       initform initargs allocation type)))
    (dolist (m missing)
      (format t "~%slot named ~S for class ~S has disappeared by cpl change"
	      (slotd-name m)
	      (class-name class)))
    (dolist (e extra)
      (format t "~%slot named ~S for class ~S is added by cpl change"
	      (slotd-name e)
	      (class-name class)))))

(defun compute-slotd-difference (old-slotd new-slotd)
  (let ((initform ())
	(initargs ())
	(allocation ())
	(type ()))
    (unless (equal (slotd-initform old-slotd)
		   (slotd-initform new-slotd))
      (setq initform (list (slotd-initform old-slotd)
			   (slotd-initform new-slotd))))
    (unless (equal (slotd-initargs old-slotd)
		   (slotd-initargs new-slotd))
      (setq initargs (list (slotd-initargs old-slotd)
			   (slotd-initargs new-slotd))))
    (unless (equal (slotd-allocation old-slotd)
		   (slotd-allocation new-slotd))
      (setq allocation (list (slotd-allocation old-slotd)
			     (slotd-allocation new-slotd))))
    (unless (equal (slotd-type old-slotd)
		   (slotd-type new-slotd))
      (setq type (list (slotd-type old-slotd)
		       (slotd-type new-slotd))))
    (values initform initargs allocation type)))

(defun warn-slotd-difference
    (class-name slot-name initform initargs allocation type)
  (format t "~%slot named ~S of class ~S has changed by cpl change:"
	  slot-name
	  class-name)
  (if initform
      (format t "~%initform has changed from ~S to ~S"
	      (car initform)
	      (cadr initform)))
  (if initargs
      (format t "~%initargs has changed from ~S to ~S"
	      (car initargs)
	      (cadr initargs)))
  (if allocation
      (format t "~%allocation has changed from ~S to ~S"
	      (car allocation)
	      (cadr allocation)))
  (if type
      (format t "~%type has changed from ~S to ~S"
	      (car type)
	      (cadr type))))
;
;(defun class-name-or-eql-spec (spec)
;  (if (listp spec)
;      spec
;      (class-name spec)))
