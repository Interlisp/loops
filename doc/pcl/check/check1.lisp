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
;;;   * a new definition of compute-combination-point
;;;   * a new definition of compute-class-precedence-list
;;;
;;; This file is designed to be compiled and loaded in the 12/7/88
;;; version of PCL.  Attempting to load it into later versions of
;;; PCL can cause bad surprises.
;;;

;from miscellaneous places

(defun forward-referenced-class-p (x)
  (typep--class x 'forward-referenced-class))


;from defs.lisp

;;;
;;; This little macro requires one case for each of the currently defined
;;; kinds of specializers.  At macroexpansion time it will signal an error
;;; if an unsupplied case is found.  At runtime, it assumes the specializer
;;; argument is a legal specializer.  This means there is no error checking
;;; at all at runtime.
;;; 
(defmacro specializer-case (specializer &body cases)
  (flet ((find-case (key)
	   (or (cdr (assq key cases))
	       (error "~S case not found." key))))
    (once-only (specializer)
      `(if (listp ,specializer)
	   (progn . ,(find-case :eql))
	   (progn . ,(find-case :class))))))

(defmacro specializer-cross-case (specializer-1 specializer-2 &body cases)
  (let ((otherwise (cdr (assq t cases))))
    (flet ((find-case (key)
	     (or (cdr (assq key cases))
		 (if otherwise
		     '((.specializer-cross-case-otherwise.))
		     (error "~S case not found." key)))))
      (once-only (specializer-1 specializer-2)
	`(flet ,(and otherwise
		     `((.specializer-cross-case-otherwise. () . ,otherwise)))
	   (specializer-case ,specializer-1
	     (:eql   (specializer-case ,specializer-2
		       (:eql   . ,(find-case :eql-eql))
		       (:class . ,(find-case :eql-class))))
	     (:class (specializer-case ,specializer-2
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

;;;
;;;
;;;

;;;
;;; This code operates on a special kind of tree called a cptree (combination
;;; point tree).  A cptree is just a cpnode.  The cpnode contains the actual
;;; data stored at the cpnode, called the entry, and the subnodes.  This code
;;; doesn't define a special structure type for cpnodes.  It does define an
;;; abstraction for them though.
;;;
;;; The WALK-CPNODE and MAP-NODE functions are useful for operating on entire
;;; trees.
;;; 
;;;  WALK-CPNODE applies the <function> argument to the entry of each cpnode
;;;              in the tree.  It proceeds in depth first order.  If at any 
;;;              point, the call to <function> returns non-nil, the walk is
;;;              terminated.
;;;
;;;  MAP-CPNODE  is like walk-cpnode except that it builds up a new tree.
;;;              The resultant tree has the same structure as the <node>
;;;              argument.  The node-entry at each node of the new tree
;;;              is the result of calling <function> on the corresponding
;;;              node-entry in the old tree.
;;;
;;;              If at any point, the second value returned by <function>
;;;              is non-nil, the walk is terminated.  In this case, the
;;;              result tree will have the same structure as the part of
;;;              input tree that was walked.
;;;
;;;
;;;   Some places in the code depend on CPNODEs being disjoint from lists.
;;; 
(defmacro make-cpnode (entry subnodes)
  `(let ((.new-node. (make-array 2)))
     (setf (cpnode-entry .new-node.)     ,entry
	   (cpnode-subnodes .new-node.) ,subnodes)
     .new-node.))

(defmacro cpnode-entry (node)    `(svref ,node 0))
(defmacro cpnode-subnodes (node) `(svref ,node 1))

(defun walk-cpnode (node function)
  (funcall function (cpnode-entry node))
  (dolist (subnode (cpnode-subnodes node)) (walk-cpnode subnode function)))

(defun map-cpnode (node function)
  (make-cpnode (funcall function (cpnode-entry node))
	       (mapcar #'(lambda (subnode) (map-cpnode subnode function))
		       (cpnode-subnodes node))))

;;;
;;; Arrange for all of this to indent nicely in ZWEI.  Its amazingly stupid
;;; that this has to be evaluated after the functions are defined, but that
;;; is the way it goes.
;;; 
#+Genera
(progn
  (zwei:defindentation (walk-cpnode 1 2))
  (zwei:defindentation (map-cpnode 1 2)))

;;;
;;; These entry types are used by code in combin.lisp to compute the so-called
;;; combination points of a generic function.  The full documentation for
;;; them appears there.  They are defined here for the obvious reason.
;;;

;;;
;;; point tree entries are used internally by CROSS-COLUMNS.
;;; 
(defmacro make-point-entry (classes partial-method-order)
  `(vector ,classes ,partial-method-order nil ()))

(defmacro point-entry-classes    (point-entry) `(svref ,point-entry 0))
(defmacro point-entry-pmo        (point-entry) `(svref ,point-entry 1))
(defmacro point-entry-flag       (point-entry) `(svref ,point-entry 2))
(defmacro point-entry-cross-info (point-entry) `(svref ,point-entry 3))


;;;
;;; This entry type is used in the result of compute-columns.
;;; 
(defmacro make-column-entry (class pmo)
  `(vector ,class ,pmo nil))

(defmacro column-entry-class (column-entry) `(svref ,column-entry 0))
(defmacro column-entry-pmo   (column-entry) `(svref ,column-entry 1))
(defmacro column-entry-flag  (column-entry) `(svref ,column-entry 2))

;;;
;;; The result of compute-precedence-dag is a tree with this entry type.
;;; 
(defmacro make-cpd-entry (class precedence)
  `(vector ,class ,precedence nil))

(defmacro cpd-entry-class             (cpd-entry) `(svref ,cpd-entry 0))
(defmacro cpd-entry-precedence        (cpd-entry) `(svref ,cpd-entry 1))
(defmacro cpd-entry-multiple-supers-p (cpd-entry) `(svref ,cpd-entry 2))

;;;
;;; This entry type is used internally by compute-precedence-dag and friends.
;;; No entry with this type is ever returned by that function.
;;;
(defmacro make-cpdi-entry (class precedence)
  `(vector ,class ,precedence 0 () 'kept))

(defmacro cpdi-entry-class      (cpdi-entry) `(svref ,cpdi-entry 0))
(defmacro cpdi-entry-precedence (cpdi-entry) `(svref ,cpdi-entry 1))
(defmacro cpdi-entry-count      (cpdi-entry) `(svref ,cpdi-entry 2))
(defmacro cpdi-entry-supers     (cpdi-entry) `(svref ,cpdi-entry 3))
(defmacro cpdi-entry-status     (cpdi-entry) `(svref ,cpdi-entry 4))


;from combin.lisp

;;;
;;;
;;;
(defun *compute-combination-points (generic-function)
  (let ((methods (generic-function-methods generic-function)))
    (if (null (cdr methods))
	(list (list (method-type-specifiers (car methods)) methods))
	(let* ((precedence
		 ;; ***                                                    ***
		 ;; *** stupidly compute this for now.  Also have to fix   ***
		 ;; *** the lexical function inverse-precedence when this  ***
		 ;; *** is fixed                                           ***
		 ;; ***                                                    ***
		 (gathering1 (collecting)
		   (iterate ((i (interval :from 0))
			     (a (list-elements
				  (method-type-specifiers (car methods)))))
		     (progn a)
		     (gather1 i))))
	       (specializers (mapcar #'method-type-specifiers methods))
	       (columns (compute-columns specializers methods precedence)))
	  (cross-columns columns methods)))))

(defun cross-columns (columns all-methods)
  (cross-columns-main t (car columns) (cdr columns) all-methods))

(defun cross-columns-main (all-t-left-of-here first rest all-methods)
  (if (null rest)
      (cross-columns-null-rest all-t-left-of-here first all-methods)
      (let ((recurse
	      (cross-columns-main (and all-t-left-of-here (eq first 't))
				  (car rest)
				  (cdr rest)
				  all-methods)))
	(if (eq first 't)
	    (cond (all-t-left-of-here
		   (dolist (point recurse) (push *the-class-t* (car point)))
		   recurse)
		  (t
		   (let ((flag (list nil)))
		     (walk-cpnode recurse
			#'(lambda (point-entry)
			    (unless (eq (point-entry-flag point-entry) flag)
			      (setf (point-entry-flag point-entry) flag)
			      (push *the-class-t*
				    (point-entry-classes point-entry))))))
		   recurse))
	    (let ((points (full-on-column-cross first recurse)))
	      (if all-t-left-of-here
		  (progn (dolist (p points) (setf (cadr p)
						  (pmo->total (cadr p))))
			 points)
		  (rebuild-combination-tree-from-points points)))))))

(defun cross-columns-null-rest (all-t-left-of-here first-column all-methods)
  (if (eq first-column 't)
      (if all-t-left-of-here
	  `((,*the-class-t*) ,all-methods)
	  (make-cpnode (make-point-entry (list *the-class-t*) all-methods)
		       ()))
      (if all-t-left-of-here
	  ;; In this case, we can just return a list of combination
	  ;; points, a point tree isn't needed.  Note that this also
	  ;; catches the case where there is only one column.
	  (gathering1 (collecting)
	    (walk-cpnode first-column		;Convert from a column tree
	       #'(lambda (column-entry)		;to actual points
		   (unless (column-entry-flag column-entry)
		     (setf (column-entry-flag column-entry) t) 
		     (let ((class (column-entry-class column-entry))
			   (pmo (column-entry-pmo column-entry)))
		       (when pmo
			 (gather1 `((,class) ,(pmo->total pmo)))))))))
	  ;;
	  ;; Need to make a tree because someone to the `left' of this
	  ;; column will need to do a full-on cross with it.
	  ;;
	  (map-cpnode first-column		;Convert from a column tree
	     #'(lambda (column-entry)		;to a combination point tree.
		 (let ((been-here (column-entry-flag column-entry)))
		   (if (and (neq been-here nil)
			    (neq been-here t))
		       been-here
		       (let* ((class (column-entry-class column-entry))
			      (pmo (column-entry-pmo column-entry))
			      (new-entry (make-point-entry (list class)
							   pmo)))
			 (setf (column-entry-flag column-entry) new-entry)
			 new-entry))))))))


(defun full-on-column-cross (column point)
  (cross-column-with-point column point)
  (cross-point-with-column point column))

(defun cross-column-with-point (column point)
  (labels ((walk-column (cnode)
	     (let* ((centry (cpnode-entry cnode))
		    (cpmo   (column-entry-pmo centry)))
	       (unless (eq (column-entry-flag centry) 'been-here)
		 (setf (column-entry-flag centry) 'been-here)
		 (when cpmo (walk-point centry cpmo point t t))
		 (dolist (subnode (cpnode-subnodes cnode))
		   (walk-column subnode)))))
	   (walk-point (centry cpmo pnode super-crossed-pmo super-ppmo)
	     (let* ((pentry (cpnode-entry pnode))
		    (ppmo (point-entry-pmo pentry))
		    (force nil)
		    (crossed-pmo nil))
	       (unless (eq (point-entry-flag pentry) centry)	;Been here?
		 (setf (point-entry-flag pentry) centry)
		 (setq crossed-pmo (cross-pmos cpmo ppmo))
		 (setq force (equal ppmo super-ppmo))
		 (when (or force
			   (and crossed-pmo
				(not (equal crossed-pmo super-crossed-pmo))))
		   (setq super-crossed-pmo crossed-pmo)
		   (push (list centry force crossed-pmo)
			 (point-entry-cross-info pentry)))
		 (dolist (subnode (cpnode-subnodes pnode))
		   (walk-point centry cpmo subnode super-crossed-pmo ppmo))))))
    (walk-column column)))

(defun cross-point-with-column (point column)
  (gathering1 (collecting)
    (labels ((walk-point (pnode)
	       (let* ((pentry   (cpnode-entry pnode))
		      (pclasses (point-entry-classes pentry)))
		 (unless (eq (point-entry-flag pentry) 'been-here)
		   (setf (point-entry-flag pentry) 'been-here)
		   (walk-column pentry pclasses column t t)
		   (dolist (subnode (cpnode-subnodes pnode))
		     (walk-point subnode)))))
	     (walk-column (pentry pclasses cnode super-crossed-pmo super-cpmo)
	       (let* ((centry (cpnode-entry cnode))
		      (cclass (column-entry-class centry))
		      (cpmo   (column-entry-pmo centry)))
		 (unless (eq (column-entry-flag centry) pentry)	;Been here?
		   (setf (column-entry-flag centry) pentry)
		   (destructuring-bind (nil force crossed-pmo)
				       (assq centry
					     (point-entry-cross-info pentry))
		     (when (and crossed-pmo
				(or force 
				    (not (equal crossed-pmo super-crossed-pmo))
				    (equal super-cpmo cpmo)))
		       (setq super-crossed-pmo crossed-pmo)
		       (gather1 (list (cons cclass pclasses) crossed-pmo)))
		     (dolist (subnode (cpnode-subnodes cnode))
		       (walk-column
			 pentry pclasses subnode super-crossed-pmo cpmo)))))))
      (walk-point point))))

(defun rebuild-combination-tree-from-points (points)
  (labels ((insert-node (tree node entry methods)
	     (let ((subtrees (cpnode-subnodes tree))
		   (farther-down-p nil)
		   (between-here-and-sub-p nil))
	       ;;
	       ;; First try to stick it down below one of our subtrees.
	       ;; Note that it can go below more than one of our subtrees.
	       ;; 
	       (dolist (sub subtrees)
		 (when (eq sub node) (return-from insert-node t))
		 (when (pmo-sub-p methods
				  (point-entry-pmo (cpnode-entry sub)))
		   (setq farther-down-p t)
		   (insert-node sub node entry methods)))
	       ;;
	       ;; Now try to put it between us and a subtree.
	       ;; 
	       (dolist (sub subtrees)
		 (when (and (pmo-sub-p (point-entry-pmo (cpnode-entry sub)) 
				       methods)
			    (not (equal (point-entry-pmo (cpnode-entry sub)) 
				       methods)))
		   (setf (cpnode-subnodes tree)
			 (remove sub (cpnode-subnodes tree)))
		   (push node (cpnode-subnodes tree))
		   (push sub (cpnode-subnodes node))
		   (setq between-here-and-sub-p t)))
	       ;;
	       ;; If it couldn't go below any of our subs, and it couldn't
	       ;; go between us and a sub, then it must just be a sub of
	       ;; us.  Do that.
	       ;; 
	       (unless (or farther-down-p between-here-and-sub-p)
		 (push node (cpnode-subnodes tree))))))
    (let* ((t-point
	     (or (dolist (p points)
		   (when (every #'(lambda (x) (eq x *the-class-t*)) (car p))
		     (setq points (delete p points))
		     (return p)))
		 (list (make-list (length (caar points))
				  :initial-element *the-class-t*)
		       ())))
	   (result (make-cpnode (make-point-entry (car t-point) (cadr t-point))
				())))
      
      (dolist (point points)
	(let* ((entry (make-point-entry (car point) (cadr point)))
	       (node  (make-cpnode entry ())))
	  (insert-node result node entry (cadr point))))
      result)))


;;;
;;; Returns a list of trees with entry type COLUMN-ENTRY.  Each tree in the
;;; list is the column combination for one column of the generic function.
;;; The list is in the same order as the precedence.  As a special case, if
;;; all the specializers of a column are T, the value for that column will
;;; be the symbol T.
;;;
;;; Each column is a fresh column since the COLUMN-ENTRY-FLAG field of the
;;; entries is intended to be modified by our caller.
;;;

(defun compute-columns (specializers methods precedence)
  (gathering1 (collecting)
    (dolist (n precedence)
      (gather1 (compute-one-column n specializers methods)))))

(defun compute-one-column (n specializers methods)
  (let* ((all-t-p t)
	 (specls
	   (mapcar #'(lambda (specializer-list)
		       (let ((specl (nth n specializer-list)))
			 (unless (eq specl *the-class-t*) (setq all-t-p nil))
			 specl))
		   specializers)))
    (if all-t-p
	't
	(compute-one-column-internal specls methods))))

(defun compute-one-column-internal (specializers methods)
  (let ((been-here-alist ()))
    ;; CONVERT-1 actually converts a node and recurses.  CONVERT
    ;; deals with sharing in the result DAG by keeping track of
    ;; whether a node in the precedence has been visited before.
    (labels ((convert (cpd-node)
	       (let ((cpd-entry (cpnode-entry cpd-node))
		     (cpd-subnodes (cpnode-subnodes cpd-node)))
		 (if (cpd-entry-multiple-supers-p cpd-entry)
		     ;;
		     ;; Since this node has multiple supers, it is possible
		     ;; to visit it more than once.  Deal with the multiple
		     ;; visits stuff.  Note, have to maintain the separate
		     ;; alist because we aren't allowed to mutate precedence
		     ;; dags.
		     ;; 
		     (let ((been-here (assq cpd-node been-here-alist)))
		       (if been-here
			   (cdr been-here)
			   (let ((new-node
				   (convert-1 cpd-entry cpd-subnodes)))
			     (push (cons cpd-node new-node) been-here-alist)
			     new-node)))
		     ;;
		     ;; No multiple supers means charge ahead!
		     ;; 
		     (convert-1 cpd-entry cpd-subnodes))))
	     
	     (convert-1 (cpd-entry cpd-subnodes)
	       (make-cpnode (make-column-entry
			      (cpd-entry-class cpd-entry)
			      (precedence->pmo (cpd-entry-precedence cpd-entry)
					       specializers
					       methods))
			    (mapcar #'convert cpd-subnodes))))
      (convert (compute-precedence-dag specializers)))))


;;;
;;; Random useful functions for manipulating partial method orders.
;;;
;;; A partial method order is just a set of methods which are ordered by
;;; one column in a combination.  A partial method order supplies absolute
;;; ordering information between some methods and no ordering information
;;; between other methods.  Its best described by example:
;;;
;;;   (M1 M2 M3)        Actually, this is a total order.
;;;   (M1 (M2 M3) M4)   M1 must precede M2, M3 and M4
;;;                     M2 must precede M4
;;;                     M3 must precede M4
;;;                     the order of M2 and M3 is unspecified
;;;
;;;   ((M1 M2) (M3 M4)) M1 must precede M3 and M4
;;;                     M2 must precede M3 and M4
;;;                     ordering of M1 and M2 unspecified
;;;                     ordering of M3 and M4 unspecified
;;;
;;; In other words, a partial method order is a list whose elements may be
;;; lists.  The top-level list provides ordering information.  Methods in
;;; the top level list must precede the `flattened' part of the list that
;;; follows them.  But, when an element of the top level list is itself a
;;; list, no ordering among those sublist elements is specified.
;;;
;;; The most important operation defined on partial method orders is a kind
;;; of cross product.  The result is a partial method order with only those
;;; methods that appeared in both inputs.  The order of the result is as
;;; specified by the first input, except that where the first input doesn't
;;; specify ordering between two methods, the ordering is taken from the
;;; second input.  If neither input provides ordering then there will be
;;; partial ordering in the result.
;;; 

(defun precedence->pmo (precedence specializers methods)
  (gathering1 (collecting)
    (dolist (p precedence)
      (let ((last-hit-state nil)
	    (last-hit-p nil)
	    (last-hit-m nil))
	(flet ((enqueue (m)
		 (ecase last-hit-state
		   ((nil) (setq last-hit-state 'one
				last-hit-p p
				last-hit-m m))
		   (one   (setq last-hit-state 'two
				last-hit-m (list m last-hit-m)))
		   (two   (push m last-hit-m))))
	       (flush-queue ()
		 (ecase last-hit-state
		   ((nil) ())
		   (one   (gather1 last-hit-m))
		   (two   (gather1 (nreverse last-hit-m))))
		 (setq last-hit-state nil
		       last-hit-p nil)))
	  (do ((s specializers (cdr s))
	       (m methods (cdr m)))
	      ((null s) (flush-queue))
	    (when (specializer-eq (car s) p)
	      (enqueue (car m)))))))))

(defun pmo->total (pmo)
  (gathering1 (collecting)
    (dolist (e pmo)
      (if (not (listp e))
	  (gather1 e)
	  (dolist (ee e) (gather1 ee))))))

(defun pmo-nelements (pmo)
  (let ((n 0))
    (dolist (e pmo)
      (if (not (listp e))
	  (incf n)
	  (incf n (length e))))
    n))

(defun cross-pmos (pmo-1 pmo-2)
  (let* ((result (list nil))
	 (tail result)
	 (subsetp-flag t))
    (flet ((gather (m) (setq tail (setf (cdr tail) (list m)))))
      (dolist (e1 pmo-1)
	(if (not (listp e1))
	    (if (pmo-memq e1 pmo-2)
		(gather e1)
		(unless (eq subsetp-flag '?) (setq subsetp-flag nil)))
	    ;;
	    ;; This element of pmo-1 is a list.  That means
	    ;; pmo-1 supplies no ordering information among
	    ;; the elements of this list.  Now go use the order
	    ;; of pmo-2 to try and place elements of this
	    ;; list in the result.
	    ;;
	    (progn
	      (setq subsetp-flag '?)
	      (dolist (e2 pmo-2)
		(if (not (listp e2))
		    (if (memq e2 e1)
			(gather e2)
			())
		    ;;
		    ;; Holy Shit Batman, we have come across a list in
		    ;; both pmo-1 and pmo-2.  The intersection
		    ;; of the two goes into the result now.
		    ;; 
		    (let ((result (intersection e1 e2)))
		      (cond ((null result))
			    ((cdr result) (gather result))
			    (t (gather (car result)))))))))))
    (values (cdr result)
	    (ecase subsetp-flag
	      ((nil) nil)
	      ((t)   t)
	      (? (pmo-subsetp pmo-1 (cdr result)))))))

(defun pmo-subsetp (pmo-1 pmo-2)
  (dolist (e1 pmo-1 t)
    (if (not (listp e1))
	(unless (pmo-memq e1 pmo-2)  (return-from pmo-subsetp nil))
	(dolist (ee1 e1)
	  (unless (pmo-memq ee1 pmo-2) (return-from pmo-subsetp nil))))))

(defun pmo-memq (x pmo)
  (do* ((tail pmo (cdr tail))
	(e (car tail) (car tail)))
       ((null tail) nil)
    (if (not (listp e))
	(when (eq x e) (return tail))
	(when (memq x e) (return tail)))))

(defun pmo-sub-p (sub-pmo super-pmo)
  (dolist (super-e super-pmo t)
    (if (not (listp super-e))
	(unless (setq sub-pmo (pmo-memq super-e sub-pmo)) (return nil))
	(let ((farthest sub-pmo))
	  (dolist (super-ee super-e)
	    (do* ((tail sub-pmo (cdr tail))
		  (sub-e (car tail) (car tail)))
		 ((null tail) (return-from pmo-sub-p nil))
	      (if (not (listp sub-e))
		  (when (eq super-ee sub-e) (return 't))
		  (when (memq super-ee sub-e) (return 't)))
	      (when (eq farthest tail) (pop farthest))))
	  (setq sub-pmo farthest)))))


;;;
;;; COMPUTE-PRECEDENCE-DAG
;;; 
;;;
;;; The reason this value is split out is that it can be meaningfully cached.
;;; It is reasonable to expect that generic functions will have the same sets
;;; of specializers, so caching this value can save time.  This is especially
;;; winning since this is the part of this algorithm that takes the most work.
;;;
;;; The cache must be cleared whenever any class changes its class precedence
;;; list.  It does not need to be reset when a class gets a cpl for the very
;;; first time.  The cache reseting code could be changed pretty easily to
;;; invalidate less of the cache when something changes.  That is left as an
;;; exercise for future users.
;;;
(defvar *precedence-dag-cache* (make-hash-table :test #'equal :size 500))
(defvar *enable-precedence-dag-caching* 't)
(defun clear-precedence-dag-cache () (clrhash *precedence-dag-cache*))

(defun compute-precedence-dag (classes)
  (setq classes (remove-duplicates classes))
  (if (null *enable-precedence-dag-caching*)
      (compute-precedence-dag-1 classes)
      (let ((key (sort (copy-list classes)
		       #'(lambda (c1 c2)
			   (let ((cpl1 (class-precedence-list c1))
				 (cpl2 (class-precedence-list c2)))
			     (cond ((memq c2 cpl1) t)
				   ((memq c1 cpl2) nil)
				   (t (< (length cpl2) (length cpl1)))))))))
	(or (gethash key *precedence-dag-cache*)
	    (setf (gethash key *precedence-dag-cache*)
		  (compute-precedence-dag-1 classes))))))

;;;
;;; The code which actually builds the precedence dag works in three passes.
;;; The first two passes operate on a tree with an entry type specialized to
;;; this code.  The third pass uses that specialized tree to produce actual
;;; result tree.
;;;
;;; The specialized entry type used by this code is called CPDI-ENTRY.  CPDI
;;; is an abbreviation for Class Precedence Dag Internal.  These entries are
;;; created by the macro MAKE-CPDI-ENTRY.  These entries have 5 fields:
;;;
;;;  CPDI-ENTRY-CLASS
;;;     The class object for this entry.
;;;     
;;;  CPDI-ENTRY-PRECEDENCE
;;;     The precedence of CLASSES at this node.
;;;     
;;;  CPDI-ENTRY-SUPERS
;;;     A list of the super nodes of this node.
;;;     
;;;  CPDI-ENTRY-COUNT
;;;     At the end of the first pass, this is the length of
;;;     ENTRY-SUPERS.  During the second pass, this value is
;;;     decremented each time a node is encountered. When this
;;;     counter reaches zero, it means all the parents of this
;;;     node have been visited.  This gets parents first search.
;;;     
;;;  CPDI-ENTRY-STATUS
;;;     The second pass uses this field to mark nodes as being
;;;     either KEPT or DELETED.  In the third pass this field
;;;     is used to know which nodes to place in the result and
;;;     to implement structure sharing in the result.  The first
;;;     a kept subtree is visited, this field is filled with the
;;;     result subtree for that subtree so that that result can
;;;     be used again if the kept node is encountered again.
;;;
;;; Entries in the returned tree are called CPD-ENTRY.  CPD is an abbreviation
;;; for Class Precedence Dag.  These have three fields:
;;;
;;;  CPD-ENTRY-CLASS
;;;     The class object.
;;;
;;;  CPD-ENTRY-PRECEDENCE
;;;     The precedence at this point in the dag.
;;;
;;;  CPD-ENTRY-MULTIPLE-SUPERS-P
;;;     A boolean flag indicating whether this subtree has multiple
;;;     supers in the dag.  Our caller is free to use this as an
;;;     optimization when detecting multiple inheritance in the dag.
;;;     
;;; 
;;; 
;;; The first pass is the BUILD pass.  This builds a skeleton of the complete
;;; class DAG.  This skeleton includes:
;;;   * The class named T (the top of the tree).
;;;   * Each class in CLASSES.
;;;   * Any other class having the following properties:
;;;      - has multiple supers
;;;      - is a subclass of more than one class in CLASSES
;;;      - more than one of the supers is itself a subclass
;;;        of some class in CLASSES
;;;
;;; The second pass (REDUCE) goes through and marks some of the nodes deleted.
;;; Nodes are deleted when they have the same precedence as THE ONE of their
;;; parent nodes they inherit from.  This pass uses parents first traversal of
;;; the tree.  Parents first traversal means that when considering whether to
;;; delete or keep a node,  the status of each of its parents is known.  Using
;;; the class precedence list of the node, we can determine which of the kept
;;; parents the node will inherit from.
;;;
;;; The third pass (COLLECT) simply builds the returned tree by including one
;;; node for each kept node in the tree produced by pass 1 and 2.
;;; 
;;;
(defun compute-precedence-dag-1 (classes)
  (let* ((top-entry (make-cpdi-entry *the-class-t* 
				     (remove-if #'(lambda (x)
						    (neq x *the-class-t*))
						classes)))
	 (top-of-tree (make-cpnode top-entry ())))
    (compute-precedence-dag-pass-1 classes top-of-tree)
    (compute-precedence-dag-pass-2 top-of-tree)
    (compute-precedence-dag-pass-3 top-of-tree)))

(defun compute-precedence-dag-pass-1 (classes tree)
  (let ((been-here-alist ()))
    (labels ((insert (tree new-node new-entry class cpl)
	       (let ((subtrees (cpnode-subnodes tree))
		     (inserted-somewhere-below-here-p nil))
		 ;;
		 ;; First see if the new node can be inserted below
		 ;; any of our subtrees.  Note that a new node can
		 ;; be below more than one of our subtrees.
		 ;; 
		 (dolist (subtree subtrees)
		   (let* ((subentry (cpnode-entry subtree))
			  (subclass (cpdi-entry-class subentry)))
		     (when (memq subclass cpl)
		       (setq inserted-somewhere-below-here-p t)
		       (insert subtree new-node new-entry class cpl))))
		 ;;
		 ;; Then see if the new node can be inserted above
		 ;; any of our subtrees.  Note that a new node can
		 ;; be above some of our subtrees and below others.
		 ;;
		 (dolist (subtree subtrees)
		   (let* ((subentry (cpnode-entry subtree))
			  (subclass (cpdi-entry-class subentry)))
		     (when (memq class (class-precedence-list subclass))
		       (setq inserted-somewhere-below-here-p t)
		       (unlink subtree subentry tree)      ;sub not below us
		       (link new-node new-entry tree)	   ;new below us
		       (link subtree subentry new-node)))) ;sub below new

		 (unless inserted-somewhere-below-here-p
		   (link new-node new-entry tree))))

	     (build (node class)
	       (unless (or (eq class *the-class-t*)
			   (eq class *the-class-object*))
		 (dolist (subclass (class-direct-subclasses class))
		   (build-1 node subclass))))
	     
	     (build-1 (node subclass)
	       (let ((been-here (assq subclass been-here-alist)))
		 (if been-here
		     ;;
		     ;; If we have already encountered this class, then
		     ;; record this possibly new path to whatever nodes
		     ;; are below it.  Note that we are relying on LINK
		     ;; not to record redundant relationships.
		     ;;
		     (dolist (old-node (cdr been-here))
		       (link old-node (cpnode-entry old-node) node))
		     ;;
		     ;;
		     ;;
		     (let ((cpl (class-precedence-list subclass)))
		       (if (class-goes-in-p subclass cpl)
			   ;;
			   ;; A new node has to go into the tree for this
			   ;; subclass.  Create that node, insert it, and
			   ;; then recurse with it.
			   ;;
			   (let* ((precedence (compute-precedence cpl))
				  (new-entry (make-cpdi-entry subclass
							      precedence))
				  (new-node (make-cpnode new-entry ())))
			     (link new-node new-entry node)
			     (push (list subclass new-node) been-here-alist)
			     (build new-node subclass))
			   ;;
			   ;; No new node for this class.  But we do have
			   ;; to be sure to record this class on the been
			   ;; here alist.
			   ;;
			   (let ((existing (cpnode-subnodes node))
				 (been-here (list subclass)))
			     (build node subclass)
			     (dolist (new-sub (cpnode-subnodes node))
			       (unless (memq new-sub existing)
				 (push new-sub (cdr been-here))
				 (link new-sub (cpnode-entry new-sub) node)))
			     (push been-here been-here-alist)))))))

	     (class-goes-in-p (class cpl)
	       (let ((supers (class-local-supers class)))
		 (or (memq class classes)
		     (and (cdr supers)
			  (let ((state nil))	;More than one class
			    (dolist (class cpl)	;from classes in cpl?
			      (when (memq class classes)
				(if (eq state nil)
				    (setq state t)
				    (return 't)))))
			  (let ((state nil))
			    (block check-supers
			      (dolist (sup supers)
				(dolist (class (class-precedence-list sup))
				  (when (memq class classes)
				    (if (null state)
					(setq state t)
					(return-from check-supers 't)))))))))))

	     (compute-precedence (cpl)
	       (gathering1 (collecting)
		 (dolist (class cpl)
		   (when (memq class classes) (gather1 class)))))

	     (link (subnode subentry supnode)
	       (unless (memq subnode (cpnode-subnodes supnode))
		 (push subnode (cpnode-subnodes supnode))
		 (incf (cpdi-entry-count subentry))
		 (push supnode (cpdi-entry-supers subentry))))

	     (unlink (subnode subentry supnode)
	       (when (memq subnode (cpnode-subnodes supnode))
		 (setf (cpnode-subnodes supnode)
		       (delete subnode (cpnode-subnodes supnode)))
		 (decf (cpdi-entry-count subentry))
		 (setf (cpdi-entry-supers subentry)
		       (delete supnode (cpdi-entry-supers subentry))))))
      (dolist (class classes)
	(unless (or (eq class *the-class-t*)
		    (assq class been-here-alist))
	  (let* ((cpl (class-precedence-list class))
		 (precedence (compute-precedence cpl))
		 (new-entry (make-cpdi-entry class precedence))
		 (new-node (make-cpnode new-entry ())))
	    (insert tree new-node new-entry class cpl)
	    (push (list class new-node) been-here-alist)
	    (build new-node class))))
      tree)))

(defun compute-precedence-dag-pass-2 (tree)
  (labels ((reduce (node)
	     (let* ((entry (cpnode-entry node))
		    (subs  (cpnode-subnodes node))
		    (class ())
		    (rcpl  ())
		    (supers ())
		    (precedence ())
		    (kept-super nil))
	       (if (> (cpdi-entry-count entry) 1)
		   (decf (cpdi-entry-count entry))
		   (progn
		     (when (setq supers (cpdi-entry-supers entry))
		       (setq precedence (cpdi-entry-precedence entry)
			     class (cpdi-entry-class entry)
			     rcpl (reverse (class-precedence-list class))
			     kept-super (get-kept-super supers rcpl))
		       (when (and kept-super
				  (equal (cpdi-entry-precedence
					   (cpnode-entry
					     kept-super))
					 precedence))
			 (setf (cpdi-entry-status entry) 'deleted)))
		     (dolist (sub subs) (reduce sub))))))
	   (get-kept-super (supers rcpl)
	     (when supers
	       (let* ((best-super (car supers))
		      (best-rcpl-tail
			(memq (cpdi-entry-class (cpnode-entry best-super))
			      rcpl)))
		 (dolist (s (cdr supers))
		   (let ((tail (memq (cpdi-entry-class (cpnode-entry s))
				     best-rcpl-tail)))
		     (when tail
		       (setq best-rcpl-tail tail
			     best-super s))))
		 (if (eq (cpdi-entry-status (cpnode-entry best-super)) 'kept)
		     (values best-super best-rcpl-tail)
		     (let ((best-sub-super nil)
			   (best-sub-rcpl-tail ()))
		       (dolist (s supers)
			 (multiple-value-bind (sub-super sub-rcpl-tail)
			     (get-kept-super (cpdi-entry-supers (cpnode-entry s))
					     rcpl)
			   (when (and sub-super
				      (or (null best-sub-super)
					  (tailp sub-rcpl-tail
						 best-sub-rcpl-tail)))
			     (setq best-sub-super sub-super
				   best-sub-rcpl-tail sub-rcpl-tail))))
		       (values best-sub-super best-sub-rcpl-tail)))))))
    (reduce tree)))

(defun compute-precedence-dag-pass-3 (tree)
  (labels ((collect (node previous-precedence)
	     (let* ((entry (cpnode-entry node))
		    (subnodes  (cpnode-subnodes node))
		    (status (cpdi-entry-status entry))
		    (precedence (cpdi-entry-precedence entry)))
	       (case (cpdi-entry-status entry)
		 (kept
		   (when (sub-precedence-p precedence previous-precedence)
		     (let* ((result-entry
			      (make-cpd-entry (cpdi-entry-class entry)
					      precedence))
			    (result-node
			      (make-cpnode result-entry
					   (collect-1 subnodes precedence))))
		       (setf (cpdi-entry-status entry) (list result-node)))))
		 (deleted
		   (collect-1 subnodes previous-precedence))
		 (t
		   ;; We have been here before, mark the node(s) as
		   ;; having multiple supers and return them.
		   (dolist (node status)
		     (let ((entry (cpnode-entry node)))
		       (setf (cpd-entry-multiple-supers-p entry) 't)))
		   status))))
	   (collect-1 (subnodes previous-precedence)
	     (gathering1 (joining)
	       (dolist (subnode subnodes)
		 (gather1
		   (copy-list (collect subnode previous-precedence))))))
	   (sub-precedence-p (sub sup)
	     (dolist (c sup t)
	       (unless (setq sub (memq c sub)) (return nil)))))
    (car (collect tree ()))))



;from std-class.lisp

;;;
;;; compute-class-precedence-list
;;;
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
