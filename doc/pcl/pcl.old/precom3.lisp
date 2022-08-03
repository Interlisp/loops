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

(eval-when (load)
  (pre-make-caching-dcode ((1 NIL (0)   8 16 32 64 128)
			   (2 NIL (0)   8 16 32 64 128)
			   (2 NIL (1)   8 16)
			   (2 NIL (0 1) 8 16)
			   (3 NIL (0)   8 16)
			   (3 NIL (1)   8 16)
			   (3 NIL (0 1) 8 16)
			   (3 NIL (1 2) 8 16)
			   (4 NIL (0)   8 16)
			   (4 NIL (1)   8 16)
			   (5 NIL (0)   8 16)
			   (5 NIL (0 1) 8 16)
			   (6 NIL (0)   8 16)
			   (6 NIL (0 1) 8 16)
			   (7 NIL (0)   8 16)
			   
			   (1 T (0)     8 16)
			   (2 T (0)     8 16)
			   (2 T (0 1)   8 16)
			   (3 T (0)     8 16)
			   (4 T (0)     8 16))))
