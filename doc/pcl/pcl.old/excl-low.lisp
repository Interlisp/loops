;;; -*- Mode:LISP; Package:(PCL LISP 1000); Base:10; Syntax:Common-lisp -*-
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
;;; This is the EXCL (Franz) lisp version of the file portable-low.
;;; 
;;; This is for version 1.1.2.  Many of the special symbols now in the lisp
;;; package (e.g. lisp::pointer-to-fixnum) will be in some other package in
;;; a later release so this will need to be changed.
;;; 

(in-package 'pcl)

(setq excl::*redefinition-warnings* nil)

(defmacro without-interrupts (&body body)
  `(let ((outer-interrupts excl::*without-interrupts*)
	 (excl::*without-interrupts* 0))
     (macrolet ((interrupts-on  ()
		  '(unless outer-interrupts
		     (setq excl::*without-interrupts* nil)))
		(interrupts-off ()
		  '(setq excl::*without-interrupts* 0)))
       ,.body)))

(eval-when (compile load eval)
  (unless (fboundp 'excl::sy�hash)
    (setf (symbol-function 'excl::sy�hash)
	  (symbol-function 'excl::�sy�hash-value)))
  )

(defmacro memq (item list)
  (let ((list-var (gensym))
	(item-var (gensym)))
    `(prog ((,list-var ,list)
	    (,item-var ,item))
	start
	   (cond ((null ,list-var)
		  (return nil))
		 ((eq (car ,list-var) ,item-var)
		  (return ,list-var))
		 (t
		  (pop ,list-var)
		  (go start))))))

(defun iwmc-class-p (x)
  (and (excl::structurep x)
       (locally
	 (declare (optimize (speed 3) (safety 0)))
	 (eq (svref x 0) 'iwmc-class))))

(excl::defcmacro iwmc-class-p (x)
  (once-only (x)
    `(and (excl::structurep ,x)
	  (locally
	    (declare (optimize (speed 3) (safety 0)))
	    (eq (svref ,x 0) 'iwmc-class)))))

(defmacro %iwmc-class-class-wrapper (x)
  `(locally
     (declare (optimize (speed 3) (safety 0)))
     (svref ,x 1)))

(defmacro %iwmc-class-static-slots (x)
  `(locally
     (declare (optimize (speed 3) (safety 0)))
     (svref ,x 2)))

(defmacro load-time-eval (form)
  (cond ((and sys:*macroexpand-for-compiler* sys:*compile-to-core*)
	 `',(eval form))
	((and sys:*macroexpand-for-compiler* sys:*compile-to-file*)
	 `'(,compiler::*eval-when-load-marker* . ,form))
	(t
	 `(progn ,form))))

;(defmacro symbol-cache-no (symbol mask)
;  (if (and (constantp symbol)
;	   (constantp mask))
;      `(load-time-eval (logand (ash (excl::sy�hash ,symbol) -1) ,mask))
;      `(the fixnum
;	    (logand (the fixnum (ash (the fixnum (excl::sy�hash ,symbol)) -1))
;	       (the fixnum ,mask)))))

(defun object-cache-no (object mask)
  (declare (optimize (speed 3) (safety 0))
	   (type fixnum object)
	   (type fixnum mask))
  (logand (the fixnum (excl::pointer-to-fixnum object))  mask))

(eval-when (eval) (compile 'object-cache-no))

(excl::defcmacro object-cache-no (object mask)
  `(the fixnum
	(locally (declare (optimize (speed 3) (safety 0)))
	  (logand (the fixnum (excl::pointer-to-fixnum ,object))
		  (the fixnum ,mask)))))

(defun printing-random-thing-internal (thing stream)
  (format stream "~O" (excl::pointer-to-fixnum thing)))

#-vax
(defun set-function-name-1 (fn new-name ignore)
  (declare (ignore ignore))
  (cond ((excl::function-object-p fn)
	 (setf (excl::fn�symdef fn) new-name))
	(t nil))
  fn)

(defun function-arglist (f)
  (excl::arglist f))

(defun symbol-append (sym1 sym2 &optional (package *package*))
   ;; This is a version of symbol-append from macros.cl
   ;; It insures that all created symbols are of one case and that
   ;; case is the current prefered case.
   ;; This special version of symbol-append is not necessary if all you
   ;; want to do is compile and run pcl in a case-insensitive-upper 
   ;; version of cl.  
   ;;
   (let ((string (string-append sym1 sym2)))
      (case excl::*current-case-mode*
	 ((:case-insensitive-lower :case-sensitive-lower)
	  (setq string (string-downcase string)))
	 ((:case-insensitive-upper :case-sensitive-upper)
	  (setq string (string-upcase string))))
      (intern string package)))

;;; Define inspector hooks for PCL object instances.

;;; Due to metacircularity certain slots of metaclasses do not have normal
;;; accessors, and for now we just make them uninspectable.  They could be
;;; special cased some day.

(defun (:property pcl::iwmc-class :inspector-function) (object)
  (do* ((class (class-of object))
	(components (class-precedence-list class))
	(desc (list (inspect::make-field-def "class" #'class-of :lisp)))
	(slots (slots-to-inspect class object) (cdr slots)))
       ((null slots) (nreverse desc))
    (let ((name (slotd-name (car slots)))
	  res)
      (push (inspect::make-field-def
	     (string name)
	     (or (block foo
		   (dolist (comp components)
		     (dolist (slot (class-instance-slots comp))
		       (and (eq (slotd-name slot) name)
			    (setq res (first (slotd-readers slot)))
			    (return-from foo res)))))
		 #'(lambda (x) 
		     (declare (ignore x))
		     :|Uninspectable Metaclass Slot|))
	     :lisp)
	    desc))))

(defun (:property pcl::iwmc-class :inspector-type-function) (x)
  (class-name (class-of x)))
