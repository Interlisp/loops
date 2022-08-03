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
;;; Basic environmental stuff.
;;;

(in-package 'pcl)

#+Genera
(progn

(defvar *old-arglist*)

(defun pcl-arglist (function &rest other-args)
  (let ((defn nil))
    (cond ((and (funcallable-instance-p function)
		(generic-function-p function))
	   (generic-function-pretty-arglist function))
	  ((and (sys:validate-function-spec function)
		(sys:fdefinedp function)
		(setq defn (sys:fdefinition function))
		(funcallable-instance-p defn)
		(generic-function-p defn))
	   (generic-function-pretty-arglist defn))
	  (t (apply *old-arglist* function other-args)))))

(eval-when (eval load)
  (unless (boundp '*old-arglist*)
    (setq *old-arglist* (symbol-function 'zl:arglist))
    (setf (symbol-function 'zl:arglist) #'pcl-arglist)))


(defvar *old-function-name*)

(defun pcl-function-name (function &rest other-args)
  (if (and (funcallable-instance-p function)
	   (generic-function-p function))
      (generic-function-name function)
      (apply *old-function-name* function other-args)))

(eval-when (eval load)
  (unless (boundp '*old-function-name*)
    (setq *old-function-name* (symbol-function 'si:function-name))
    (setf (symbol-function 'si:function-name) #'pcl-function-name)))

)

#+Lucid
(progn

(defvar *old-arglist*)

(defun pcl-arglist (function &rest other-args)
  (let ((defn nil))
    (cond ((and (funcallable-instance-p function)
		(generic-function-p function))
	   (generic-function-pretty-arglist function))
	  ((and (symbolp function)
		(fboundp function)
		(setq defn (symbol-function function))
		(funcallable-instance-p defn)
		(generic-function-p defn))
	   (generic-function-pretty-arglist defn))
	  (t (apply *old-arglist* function other-args)))))

(eval-when (eval load)
  (unless (boundp '*old-arglist*)
    (setq *old-arglist* (symbol-function 'sys::arglist))
    (setf (symbol-function 'sys::arglist) #'pcl-arglist)))

)