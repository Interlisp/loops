;;;-*-Mode:LISP; Package:(PCL Lisp 1000); Base:10; Syntax:Common-lisp -*-
;;;
;;; *************************************************************************
;;; Copyright (c) 1985, 1986, 1987, 1988, 1989, 1990 Xerox Corporation.
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
;;; The version of low for Kyoto Common Lisp (KCL)
(in-package 'pcl)

(defmacro %svref (vector index)
  `(svref (the simple-vector ,vector) (the fixnum ,index)))

(defsetf %svref (vector index) (new-value)
  `(setf (svref (the simple-vector ,vector) (the fixnum ,index))
         ,new-value))


;;;
;;; std-instance-p
;;;
(si:define-compiler-macro std-instance-p (x)
  (once-only (x)
    `(and (si:structurep ,x)
	  (eq (si:structure-name ,x) 'std-instance))))

(dolist (inline '((si:structurep
		    ((t) compiler::boolean nil nil "type_of(#0)==t_structure")
		    compiler::inline-always)
		  (si:structure-name
		    ((t) t nil nil "(#0)->str.str_name")
		    compiler::inline-unsafe)))
  (setf (get (first inline) (third inline)) (list (second inline))))

(setf (get 'cclosure-env 'compiler::inline-always)
      (list '((t) t nil nil "(#0)->cc.cc_env")))

;;;
;;; turbo-closure patch.  See the file kcl-mods.text for details.
;;;
#+:turbo-closure
(progn
(CLines
  "object tc_cc_env_nthcdr (n,tc)"
  "object n,tc;                        "
  "{return (type_of(tc)==t_cclosure&&  "
  "         tc->cc.cc_turbo!=NULL&&    "
  "         type_of(n)==t_fixnum)?     "
  "         tc->cc.cc_turbo[fix(n)]:   " ; assume that n is in bounds
  "         Cnil;                      "
  "}                                   "
  )

(defentry tc-cclosure-env-nthcdr (object object) (object tc_cc_env_nthcdr))

(setf (get 'tc-cclosure-env-nthcdr 'compiler::inline-unsafe)
      '(((fixnum t) t nil nil "(#1)->cc.cc_turbo[#0]")))
)


;;;; low level stuff to hack compiled functions and compiled closures.
;;;
;;; The primary client for this is fsc-low, but since we make some use of
;;; it here (e.g. to implement set-function-name-1) it all appears here.
;;;

(eval-when (compile eval)

(defmacro define-cstruct-accessor (accessor structure-type field value-type
					    field-type tag-name)
  (let ((setf (intern (concatenate 'string "SET-" (string accessor))))
	(caccessor (format nil "pcl_get_~A_~A" structure-type field))
	(csetf     (format nil "pcl_set_~A_~A" structure-type field))
	(vtype (intern (string-upcase value-type))))
    `(progn
       (CLines ,(format nil "~A ~A(~A)                ~%~
                             object ~A;               ~%~
                             { return ((~A) ~A->~A.~A); }       ~%~
                                                      ~%~
                             ~A ~A(~A, new)           ~%~
                             object ~A;               ~%~
                             ~A new;                  ~%~
                             { return ((~A)(~A->~A.~A = ~Anew)); } ~%~
                            "
			value-type caccessor structure-type 
			structure-type
			value-type structure-type tag-name field
			value-type csetf structure-type
			structure-type 
			value-type 
			value-type structure-type tag-name field field-type
			))

       (defentry ,accessor (object) (,vtype ,caccessor))
       (defentry ,setf (object ,vtype) (,vtype ,csetf))


       (defsetf ,accessor ,setf)

       )))
)
;;; 
;;; struct cfun {                   /*  compiled function header  */
;;;         short   t, m;
;;;         object  cf_name;        /*  compiled function name  */
;;;         int     (*cf_self)();   /*  entry address  */
;;;         object  cf_data;        /*  data the function uses  */
;;;                                 /*  for GBC  */
;;;         char    *cf_start;      /*  start address of the code  */
;;;         int     cf_size;        /*  code size  */
;;; };
;;; add field-type tag-name
(define-cstruct-accessor cfun-name  "cfun" "cf_name"  "object" "(object)" "cf")
(define-cstruct-accessor cfun-self  "cfun" "cf_self"  "int" "(int (*)())" 
                         "cf")
(define-cstruct-accessor cfun-data  "cfun" "cf_data"  "object" "(object)" "cf")
(define-cstruct-accessor cfun-start "cfun" "cf_start" "int" "(char *)" "cf")
(define-cstruct-accessor cfun-size  "cfun" "cf_size"  "int" "(int)" "cf")

(CLines
  "object pcl_cfunp (x)              "
  "object x;                         "
  "{if(x->c.t == (int) t_cfun)       "
  "  return (Ct);                    "
  "  else                            "
  "    return (Cnil);                "
  "  }                               "
  )

(defentry cfunp (object) (object pcl_cfunp))

;;; 
;;; struct cclosure {               /*  compiled closure header  */
;;;         short   t, m;
;;;         object  cc_name;        /*  compiled closure name  */
;;;         int     (*cc_self)();   /*  entry address  */
;;;         object  cc_env;         /*  environment  */
;;;         object  cc_data;        /*  data the closure uses  */
;;;                                 /*  for GBC  */
;;;         char    *cc_start;      /*  start address of the code  */
;;;         int     cc_size;        /*  code size  */
;;; };
;;; 
(define-cstruct-accessor cclosure-name "cclosure"  "cc_name"  "object"
                         "(object)" "cc")          
(define-cstruct-accessor cclosure-self "cclosure"  "cc_self"  "int" 
                         "(int (*)())" "cc")
(define-cstruct-accessor cclosure-data "cclosure"  "cc_data"  "object"
                          "(object)" "cc")
(define-cstruct-accessor cclosure-start "cclosure" "cc_start" "int" 
                         "(char *)" "cc")
(define-cstruct-accessor cclosure-size "cclosure"  "cc_size"  "int"
			 "(int)" "cc")
(define-cstruct-accessor cclosure-env "cclosure"   "cc_env"   "object"
                         "(object)" "cc")


(CLines
  "object pcl_cclosurep (x)          "
  "object x;                         "
  "{if(x->c.t == (int) t_cclosure)   "
  "  return (Ct);                    "
  "  else                            "
  "   return (Cnil);                 "
  "  }                               "
  )

(defentry cclosurep (object) (object pcl_cclosurep))


(defun printing-random-thing-internal (thing stream)
  (format stream "~O" (si:address thing)))


(defun set-function-name-1 (fn new-name ignore)
  (cond ((cclosurep fn)
	 (setf (cclosure-name fn) new-name))
	((cfunp fn)
	 (setf (cfun-name fn) new-name))
	((and (listp fn)
	      (eq (car fn) 'lambda-block))
	 (setf (cadr fn) new-name))
	((and (listp fn)
	      (eq (car fn) 'lambda))
	 (setf (car fn) 'lambda-block
	       (cdr fn) (cons new-name (cdr fn)))))
  fn)

