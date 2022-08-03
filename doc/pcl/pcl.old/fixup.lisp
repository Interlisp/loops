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

(eval-when (compile load eval)
  (fix-early-generic-functions))

#+Lispm
(eval-when (load eval)
  (si:record-source-file-name 'print-iwmc-class 'defun 't))

(defun print-iwmc-class (instance stream depth)
  (declare (ignore depth))
  (print-object instance stream))

;;;
;;; Note this little trick we have to do here.
;;; 
(defmethod compute-applicable-methods-1
	   ((generic-function standard-generic-function) args)
  (compute-applicable-methods-internal generic-function args))

(eval-when (load eval)
  (let ((gf #'compute-applicable-methods-1))
    (setf (generic-function-name gf) 'compute-applicable-methods)
    (setf (symbol-function 'compute-applicable-methods) gf)))

;;; 
;;; if initargs are valid return nil, otherwise signal an error
;;;
(defun check-initargs-1 (class initargs methods)
  (let ((legal (apply #'append (mapcar #'slotd-initargs (class-slots class)))))
    (unless (getf initargs :allow-other-keys)
      ;; Add to the set of slot-filling initargs the set of
      ;; initargs that are accepted by the methods.  If at
      ;; any point we come across &allow-other-keys, we can
      ;; just quit.
      (dolist (method methods)
	(multiple-value-bind (keys allow-other-keys)
	    (function-keywords method)
	  (when allow-other-keys
	    (return-from check-initargs-1 nil))
	  (setq legal (append keys legal))))
      ;; Now check the supplied-initarg-names and the default initargs
      ;; against the total set that we know are legal.
      (doplist (key val) initargs
	(unless (memq key legal)
	  (error "Invalid initialization argument ~S for class ~S"
		 key
		 (class-name class)))))))
