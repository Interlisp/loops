;;;-*-Mode:LISP; Package: PCL; Base:10; Syntax:Common-lisp -*-
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

(defparameter *precedence-relation-tests*
	      '(("1"
		 ;;
		 ;;         a
		 ;;        / \
		 ;;       b   c
		 ;;
		 ((a ())			;Class definitions
		  (b (a))
		  (c (a)))

		 ((a (a))			;Class precedence lists
		  (b (b a))
		  (c (c a)))

		 ((1 (a)			;Columns
		     ((t ())
		      (a (a))))
		  (2 (a b)
		     ((t ())
		      (a (a))
		      (b (b a))))
		  (3 (a c)
		     ((t ())
		      (a (a))
		      (c (c a))))
		  (4 (a b t)
		     ((t (t))
		      (a (a t))
		      (b (b a t)))))

		 ((1 ((m1 (a))			;Combination points
		      (m2 (b)))
		     (((a) (m1))
		      ((b) (m2 m1))))
		  (2 ((m1 (a a))
		      (m2 (b b)))
		     (((a a) (m1))
		      ((b b) (m2 m1))))
		  (3 ((m1 (a a))
		      (m2 (a b))
		      (m3 (b a))
		      (m4 (b b)))
		     (((a a) (m1))
		      ((a b) (m2 m1))
		      ((b a) (m3 m1))
		      ((b b) (m4 m3 m2 m1))))
		  (4 ((m1 (a a a))
		      (m2 (b b b)))
		     (((a a a) (m1))
		      ((b b b) (m2 m1))))
		  (5 ((m1 (a a a))
		      (m2 (a a b))
		      (m3 (a b a))
		      (m4 (a b b))
		      (m5 (b a a))
		      (m6 (b a b))
		      (m7 (b b a))
		      (m8 (b b b)))
		     (((a a a) (m1))
		      ((a a b) (m2 m1))
		      ((a b a) (m3 m1))
		      ((a b b) (m4 m3 m2 m1))
		      ((b a a) (m5 m1))
		      ((b a b) (m6 m5 m2 m1))
		      ((b b a) (m7 m5 m3 m1))
		      ((b b b) (m8 m7 m6 m5 m4 m3 m2 m1))))
		  (6 ((m1 (a t))
		      (m2 (b t)))
		     (((a t) (m1))
		      ((b t) (m2 m1))))
		  (7 ((m1 (a t t))
		      (m2 (b t t)))
		     (((a t t) (m1))
		      ((b t t) (m2 m1))))
		  (8 ((m5 (a a))
		      (m2 (a b)))
		     (((a a) (m5))
		      ((a b) (m2 m5))))
		  (9 ((m2 (a b))
		      (m5 (a a)))
		     (((a a) (m5))
		      ((a b) (m2 m5))))
		  (10 ((m5 (a a))
		       (m4 (t c))
		       (m3 (c t))
		       (m2 (a b))
		       (m1 (b a)))
		      (((a a) (m5))
		       ((a b) (m2 m5))
		       ((a c) (m5 m4))
		       ((b a) (m1 m5))
		       ((b b) (m1 m2 m5))
		       ((b c) (m1 m5 m4))
		       ((c a) (m3 m5))
		       ((c b) (m3 m2 m5))
		       ((c c) (m3 m5 m4))
		       ((c t) (m3))
		       ((t c) (m4))))
		  (11 ((m1 (b a))
		       (m2 (a b))
		       (m3 (c t))
		       (m4 (t c))
		       (m5 (a a)))
		      (((a a) (m5))
		       ((a b) (m2 m5))
		       ((a c) (m5 m4))
		       ((b a) (m1 m5))
		       ((b b) (m1 m2 m5))
		       ((b c) (m1 m5 m4))
		       ((c a) (m3 m5))
		       ((c b) (m3 m2 m5))
		       ((c c) (m3 m5 m4))
		       ((c t) (m3))
		       ((t c) (m4))))))

		("2"
		 ;;
		 ;;      a   b
		 ;;      |   |
		 ;;      c   d
		 ;;       \ /
		 ;;        e  b  a
		 ;;         \ | /
		 ;;          \|/
		 ;;           f
		 ;;
		 ((a  ())			;Class definitions
		  (b  ())
		  (c  (a))
		  (d  (b))
		  (e  (c d))
		  (f  (e b a)))


		 ((a (a))			;Class precedence lists
		  (b (b))
		  (c (c a))
		  (d (d b))
		  (c (c a))
		  (e (e c a d b))
		  (f (f e c d b a)))

		 ((1 (a b)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (e (a b))
		      (f (b a))))
		  (2 (b a)
		     ((t ())
		      (a (a))
		      (b (b))
		      (e (a b))
		      (f (b a))))
		  (3 (a)
		     ((t ())
		      (a (a))))
		  (4 (b)
		     ((t ())
		      (b (b)))))

		 ((1 ((m1 (a))			;Combination Points
		      (m2 (b)))
		     (((a) (m1))
		      ((b) (m2))
		      ((e) (m1 m2))
		      ((f) (m2 m1))))
		  (2 ((m1 (a a))
		      (m2 (a b))
		      (m3 (b a))
		      (m4 (b b))) ;a b e f
		     (((a a) (m1))
		      ((a b) (m2))
		      ((a e) (m1 m2))
		      ((a f) (m2 m1))
		      ((b a) (m3))
		      ((b b) (m4))
		      ((b e) (m3 m4))
		      ((b f) (m4 m3))
		      ((e a) (m1 m3))
		      ((e b) (m2 m4))
		      ((e e) (m1 m2 m3 m4))
		      ((e f) (m2 m1 m4 m3))
		      ((f a) (m3 m1))
		      ((f b) (m4 m2))
		      ((f e) (m3 m4 m1 m2))
		      ((f f) (m4 m3 m2 m1))))))

		("3" 
		 ;;
		 ;;        a
		 ;;       / \
		 ;;      b   c
		 ;;       \ / \
		 ;;        d   e
		 ;;         \ /
		 ;;          f
		 ;;
		 ((a ())			;Class definitions
		  (b (a))
		  (c (a))
		  (d (b c))
		  (e (c))
		  (f (d e)))

		 ((a (a))			;Class precedence lists
		  (b (b a))
		  (c (c a))
		  (d (d b c a))
		  (e (e c a))
		  (f (f d b e c a)))

		 ((1 (a)			;Columns
		     ((t ())	
		      (a (a))))
		 
		  (2  (a c)
		      ((t ())	
		       (a (a))	
		       (c (c a))))

		  (3  (a b)
		      ((t ())
		       (a (a))
		       (b (b a))))

		  (4  (b c)
		      ((t ())
		       (b (b))
		       (c (c))
		       (d (b c))))

		  (5  (a b c)
		      ((t ())
		       (a (a))
		       (b (b a))
		       (c (c a))
		       (d (b c a)))))
		
		 ((1 ((m1 (a))			;Combination Points
		      (m2 (b))
		      (m3 (c))
		      (m4 (d)))
		     (((a) (m1))
		      ((b) (m2 m1))
		      ((c) (m3 m1))
		      ((d) (m4 m2 m3 m1))))
		  (2 ((m1 (a a))
		      (m2 (b b)))
		     (((a a) (m1))
		      ((b b) (m2 m1))))
		  (3 ((m1 (a a))
		      (m2 (a b))
		      (m3 (b a))
		      (m4 (b b))) ;a b
		     (((a a) (m1))
		      ((a b) (m2 m1))
		      ((b a) (m3 m1))
		      ((b b) (m4 m3 m2 m1))))))

		 ("4"
		  ;; DAG 4 is two, disjoint, multiple-inheritance triangles
		  ;;
		  ;;      a   b    i   j
		  ;;       \ /      \ /
		  ;;        c        k
		  ;;

		  ((a ())			;Class definitions
		   (b ())
		   (c (a b))
		   (i ())
		   (j ())
		   (k (i j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a b))
		   (i (i))
		   (j (j))
		   (k (k i j)))

		  ((1  (a)			;Columns
		       ((t ())
			(a (a))))		
		   (2  (b)		
		       ((t ())			
			(b (b))))
		   (3  (a b c)
		       ((t ())
			(a (a))
			(b (b))
			(c (c a b))))
		   (4   (a i)
			((t ())
			 (a (a))
			 (i (i))))
		   (5   (a c i)
			((t ())
			 (a (a))
			 (c (c a))
			 (i (i))))
		   (6   (a c i k)
			((t ())
			 (a (a))
			 (c (c a))
			 (i (i))
			 (k (k i))))
		   (7   (a b c i j k)
			((t ())
			 (a (a))
			 (b (b))
			 (c (c a b))
			 (i (i))
			 (j (j))
			 (k (k i j)))))

		  ((1 ((m1 (a i))		;Combination points
		       (m2 (a j))
		       (m3 (a k)))
		      (((a i) (m1))
		       ((a j) (m2))
		       ((a k) (m3 m1 m2))))		 
		   (2 ((m1 (a i))
		       (m2 (b i))
		       (m3 (c i)))
		      (((a i) (m1))
		       ((b i) (m2))
		       ((c i) (m3 m1 m2))))
		   (3 ((m1 (a i))
		       (m2 (a k)))
		      (((a i) (m1))
		       ((a k) (m2 m1))))))

		 ("5"
		  ;;
		  ;;      a  b
		  ;;      |  |        
		  ;;      c  d  b   a
		  ;;       \ /   \ /
		  ;;        e     f
		  ;;         \   /
		  ;;          \ /
		  ;;           g
		  ;;

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (b a))
		   (g  (e f)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a))
		   (d (d b))
		   (e (e c a d b))
		   (f (f b a))
		   (g (g e c d f b a)))

		  ((1  (a b)			;Columns
		       ((t ())
			(a (a))
			(b (b))
			(e (a b))
			(f (b a))
			(g (b a)))))

		  ((1 ((m1 (a))			;Combination points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((f) (m2 m1))
		       ((g) (m2 m1))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((f) (m2 m1))
		       ((g) (m3 m2 m1))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (e))
		       (m4 (f)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((f) (m4 m2 m1))
		       ((g) (m3 m4 m2 m1))))
		   (4 ((m1 (a f))
		       (m2 (a d))
		       (m3 (c b)))
		      (((a d) (m2))
		       ((a f) (m1))
		       ((a g) (m2 m1))
		       ((c b) (m3))
		       ((c d) (m3 m2))
		       ((c f) (m3 m1))
		       ((c g) (m3 m2 m1))))
		   (5 ((m1 (a a))
		       (m2 (a b))
		       (m3 (b a))
		       (m4 (b b))) ;a b e f g
		      (((a a) (m1))
		       ((a b) (m2))
		       ((a e) (m1 m2))
		       ((a f) (m2 m1))
		       ((a g) (m2 m1))
		       ((b a) (m3))
		       ((b b) (m4))
		       ((b e) (m3 m4))
		       ((b f) (m4 m3))
		       ((b g) (m4 m3))
		       ((e a) (m1 m3))
		       ((e b) (m2 m4))
		       ((e e) (m1 m2 m3 m4))
		       ((e f) (m2 m1 m4 m3))
		       ((e g) (m2 m1 m4 m3))
		       ((f a) (m3 m1))
		       ((f b) (m4 m2))
		       ((f e) (m3 m4 m1 m2))
		       ((f f) (m4 m3 m2 m1))
		       ((f g) (m4 m3 m2 m1))
		       ((g a) (m3 m1))
		       ((g b) (m4 m2))
		       ((g e) (m3 m4 m1 m2))
		       ((g f) (m4 m3 m2 m1))
		       ((g g) (m4 m3 m2 m1))))))

		("6"
		  ;;
		  ;;      a   b   b   a
		  ;;      |   |   |   | 
		  ;;      c   d   f   g
		  ;;       \ /     \ /
		  ;;        e       h
		  ;;         \     /
		  ;;          \   /
		  ;;           \ /
		  ;;            i
		  ;;

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (b))
		   (g  (a))
		   (h  (f g))
		   (i  (e h)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a))
		   (d (d b))
		   (e (e c a d b))
		   (f (f b))
		   (g (g a))
		   (h (h f b g a))
		   (i (i e c d h f b g a)))

		  
		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (b a))
			 (i (b a))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (h (b a))
			 (i (e b a))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (h b a))
			 (i (h b a))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (e (a d))
			 (i (d a)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m2 m1))
		       ((i) (m2 m1))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((h) (m2 m1))
		       ((i) (m3 m2 m1))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m3 m2 m1))
		       ((i) (m3 m2 m1))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((e) (m1 m2))
		       ((i) (m2 m1))))
		   (5 ((m1 (a a))
		       (m2 (a b))
		       (m3 (b a))
		       (m4 (b b))) ;a b e h
		      (((a a) (m1))
		       ((a b) (m2))
		       ((a e) (m1 m2))
		       ((a h) (m2 m1))
		       ((a i) (m2 m1))
		       ((b a) (m3))
		       ((b b) (m4))
		       ((b e) (m3 m4))
		       ((b h) (m4 m3))
		       ((b i) (m4 m3))
		       ((e a) (m1 m3))
		       ((e b) (m2 m4))
		       ((e e) (m1 m2 m3 m4))
		       ((e h) (m2 m1 m4 m3))
		       ((e i) (m2 m1 m4 m3))
		       ((h a) (m3 m1))
		       ((h b) (m4 m2))
		       ((h e) (m3 m4 m1 m2))
		       ((h h) (m4 m3 m2 m1))
		       ((h i) (m4 m3 m2 m1))
		       ((i a) (m3 m1))
		       ((i b) (m4 m2))
		       ((i e) (m3 m4 m1 m2))
		       ((i h) (m4 m3 m2 m1))
		       ((i i) (m4 m3 m2 m1))))
		   (6 ((m1 (a a a))
		       (m2 (a b a))
		       (m3 (b a a))
		       (m4 (b b a)))
		      (((a a a) (m1))
		       ((a b a) (m2))
		       ((a e a) (m1 m2))
		       ((a h a) (m2 m1))
		       ((a i a) (m2 m1))
		       ((b a a) (m3))
		       ((b b a) (m4))
		       ((b e a) (m3 m4))
		       ((b h a) (m4 m3))
		       ((b i a) (m4 m3))
		       ((e a a) (m1 m3))
		       ((e b a) (m2 m4))
		       ((e e a) (m1 m2 m3 m4))
		       ((e h a) (m2 m1 m4 m3))
		       ((e i a) (m2 m1 m4 m3))
		       ((h a a) (m3 m1))
		       ((h b a) (m4 m2))
		       ((h e a) (m3 m4 m1 m2))
		       ((h h a) (m4 m3 m2 m1))
		       ((h i a) (m4 m3 m2 m1))
		       ((i a a) (m3 m1))
		       ((i b a) (m4 m2))
		       ((i e a) (m3 m4 m1 m2))
		       ((i h a) (m4 m3 m2 m1))
		       ((i i a) (m4 m3 m2 m1))))
		   (7 ((m1 (a a a))
		       (m2 (a a b))
		       (m3 (a b a))
		       (m4 (a b b))
		       (m5 (b a a))
		       (m6 (b a b))
		       (m7 (b b a))
		       (m8 (b b b)))
		      (((a a a) (m1))
		       ((a a b) (m2))
		       ((a a e) (m1 m2))
		       ((a a h) (m2 m1))
		       ((a a i) (m2 m1))
		       ((a b a) (m3))
		       ((a b b) (m4))
		       ((a b e) (m3 m4))
		       ((a b h) (m4 m3))
		       ((a b i) (m4 m3))
		       ((a e a) (m1 m3))
		       ((a e b) (m2 m4))
		       ((a e e) (m1 m2 m3 m4))
		       ((a e h) (m2 m1 m4 m3))
		       ((a e i) (m2 m1 m4 m3))
		       ((a h a) (m3 m1))
		       ((a h b) (m4 m2))
		       ((a h e) (m3 m4 m1 m2))
		       ((a h h) (m4 m3 m2 m1))
		       ((a h i) (m4 m3 m2 m1))
		       ((a i a) (m3 m1))
		       ((a i b) (m4 m2))
		       ((a i e) (m3 m4 m1 m2))
		       ((a i h) (m4 m3 m2 m1))
		       ((a i i) (m4 m3 m2 m1))
		       ((b a a) (m5))
		       ((b a b) (m6))
		       ((b a e) (m5 m6))
		       ((b a h) (m6 m5))
		       ((b a i) (m6 m5))
		       ((b b a) (m7))
		       ((b b b) (m8))
		       ((b b e) (m7 m8))
		       ((b b h) (m8 m7))
		       ((b b i) (m8 m7))
		       ((b e a) (m5 m7))
		       ((b e b) (m6 m8))
		       ((b e e) (m5 m6 m7 m8))
		       ((b e h) (m6 m5 m8 m7))
		       ((b e i) (m6 m5 m8 m7))
		       ((b h a) (m7 m5))
		       ((b h b) (m8 m6))
		       ((b h e) (m7 m8 m5 m6))
		       ((b h h) (m8 m7 m6 m5))
		       ((b h i) (m8 m7 m6 m5))
		       ((b i a) (m7 m5))
		       ((b i b) (m8 m6))
		       ((b i e) (m7 m8 m5 m6))
		       ((b i h) (m8 m7 m6 m5))
		       ((b i i) (m8 m7 m6 m5))
		       ((e a a) (m1 m5))
		       ((e a b) (m2 m6))
		       ((e a e) (m1 m2 m5 m6))
		       ((e a h) (m2 m1 m6 m5))
		       ((e a i) (m2 m1 m6 m5))
		       ((e b a) (m3 m7))
		       ((e b b) (m4 m8))
		       ((e b e) (m3 m4 m7 m8))
		       ((e b h) (m4 m3 m8 m7))
		       ((e b i) (m4 m3 m8 m7))
		       ((e e a) (m1 m3 m5 m7))
		       ((e e b) (m2 m4 m6 m8))
		       ((e e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e e h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e e i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e h a) (m3 m1 m7 m5))
		       ((e h b) (m4 m2 m8 m6))
		       ((e h e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e h h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e h i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e i a) (m3 m1 m7 m5))
		       ((e i b) (m4 m2 m8 m6))
		       ((e i e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e i h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e i i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((h a a) (m5 m1))
		       ((h a b) (m6 m2))
		       ((h a e) (m5 m6 m1 m2))
		       ((h a h) (m6 m5 m2 m1))
		       ((h a i) (m6 m5 m2 m1))
		       ((h b a) (m7 m3))
		       ((h b b) (m8 m4))
		       ((h b e) (m7 m8 m3 m4))
		       ((h b h) (m8 m7 m4 m3))
		       ((h b i) (m8 m7 m4 m3))
		       ((h e a) (m5 m7 m1 m3))
		       ((h e b) (m6 m8 m2 m4))
		       ((h e e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h e h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h e i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h h a) (m7 m5 m3 m1))
		       ((h h b) (m8 m6 m4 m2))
		       ((h h e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h h h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h h i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h i a) (m7 m5 m3 m1))
		       ((h i b) (m8 m6 m4 m2))
		       ((h i e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h i h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h i i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i a a) (m5 m1))
		       ((i a b) (m6 m2))
		       ((i a e) (m5 m6 m1 m2))
		       ((i a h) (m6 m5 m2 m1))
		       ((i a i) (m6 m5 m2 m1))
		       ((i b a) (m7 m3))
		       ((i b b) (m8 m4))
		       ((i b e) (m7 m8 m3 m4))
		       ((i b h) (m8 m7 m4 m3))
		       ((i b i) (m8 m7 m4 m3))
		       ((i e a) (m5 m7 m1 m3))
		       ((i e b) (m6 m8 m2 m4))
		       ((i e e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i e h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i e i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i h a) (m7 m5 m3 m1))
		       ((i h b) (m8 m6 m4 m2))
		       ((i h e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i h h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i h i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i i a) (m7 m5 m3 m1))
		       ((i i b) (m8 m6 m4 m2))
		       ((i i e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i i h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i i i) (m8 m7 m6 m5 m4 m3 m2 m1))))))
		
		 ("7" 
		  ;;      a   b   a   b
		  ;;      |   |   |   | 
		  ;;      c   d   f   g
		  ;;       \ /     \ /
		  ;;        e       h
		  ;;         \     /
		  ;;          \   /
		  ;;           \ /
		  ;;            i

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (a))
		   (g  (b))
		   (h  (f g))
		   (i  (e h)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a))
		   (d (d b))
		   (e (e c a d b))
		   (f (f a))
		   (g (g b))
		   (h (h f a g b))
		   (i (i e c d h f a g b)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (a b))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (h (a b))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (h a b))
			 (i (h a b))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (e (a d))
			 (i (d a)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m1 m2))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((h) (m1 m2))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m3 m1 m2))
		       ((i) (m3 m1 m2))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((e) (m1 m2))
		       ((i) (m2 m1))))
		   (5 ((m1 (a a))
		       (m2 (a b))
		       (m3 (b a))
		       (m4 (b b))) ;a b e h
		      (((a a) (m1))
		       ((a b) (m2))
		       ((a e) (m1 m2))
		       ((a h) (m1 m2))
		       ((b a) (m3))
		       ((b b) (m4))
		       ((b e) (m3 m4))
		       ((b h) (m3 m4))
		       ((e a) (m1 m3))
		       ((e b) (m2 m4))
		       ((e e) (m1 m2 m3 m4))
		       ((e h) (m1 m2 m3 m4))
		       ((h a) (m1 m3))
		       ((h b) (m2 m4))
		       ((h e) (m1 m2 m3 m4))
		       ((h h) (m1 m2 m3 m4))))
		   (6 ((m1 (a a a))
		       (m2 (a b a))
		       (m3 (b a a))
		       (m4 (b b a)))
		      (((a a a) (m1))
		       ((a b a) (m2))
		       ((a e a) (m1 m2))
		       ((a h a) (m1 m2))
		       ((b a a) (m3))
		       ((b b a) (m4))
		       ((b e a) (m3 m4))
		       ((b h a) (m3 m4))
		       ((e a a) (m1 m3))
		       ((e b a) (m2 m4))
		       ((e e a) (m1 m2 m3 m4))
		       ((e h a) (m1 m2 m3 m4))
		       ((h a a) (m1 m3))
		       ((h b a) (m2 m4))
		       ((h e a) (m1 m2 m3 m4))
		       ((h h a) (m1 m2 m3 m4))))
		   (7 ((m1 (a a a))
		       (m2 (a a b))
		       (m3 (a b a))
		       (m4 (a b b))
		       (m5 (b a a))
		       (m6 (b a b))
		       (m7 (b b a))
		       (m8 (b b b)))
		      (((a a a) (m1))
		       ((a a b) (m2))
		       ((a a e) (m1 m2))
		       ((a a h) (m1 m2))
		       ((a b a) (m3))
		       ((a b b) (m4))
		       ((a b e) (m3 m4))
		       ((a b h) (m3 m4))
		       ((a e a) (m1 m3))
		       ((a e b) (m2 m4))
		       ((a e e) (m1 m2 m3 m4))
		       ((a e h) (m1 m2 m3 m4))
		       ((a h a) (m1 m3))
		       ((a h b) (m2 m4))
		       ((a h e) (m1 m2 m3 m4))
		       ((a h h) (m1 m2 m3 m4))
		       ((b a a) (m5))
		       ((b a b) (m6))
		       ((b a e) (m5 m6))
		       ((b a h) (m5 m6))
		       ((b b a) (m7))
		       ((b b b) (m8))
		       ((b b e) (m7 m8))
		       ((b b h) (m7 m8))
		       ((b e a) (m5 m7))
		       ((b e b) (m6 m8))
		       ((b e e) (m5 m6 m7 m8))
		       ((b e h) (m5 m6 m7 m8))
		       ((b h a) (m5 m7))
		       ((b h b) (m6 m8))
		       ((b h e) (m5 m6 m7 m8))
		       ((b h h) (m5 m6 m7 m8))
		       ((e a a) (m1 m5))
		       ((e a b) (m2 m6))
		       ((e a e) (m1 m2 m5 m6))
		       ((e a h) (m1 m2 m5 m6))
		       ((e b a) (m3 m7))
		       ((e b b) (m4 m8))
		       ((e b e) (m3 m4 m7 m8))
		       ((e b h) (m3 m4 m7 m8))
		       ((e e a) (m1 m3 m5 m7))
		       ((e e b) (m2 m4 m6 m8))
		       ((e e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e e h) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e h a) (m1 m3 m5 m7))
		       ((e h b) (m2 m4 m6 m8))
		       ((e h e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e h h) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((h a a) (m1 m5))
		       ((h a b) (m2 m6))
		       ((h a e) (m1 m2 m5 m6))
		       ((h a h) (m1 m2 m5 m6))
		       ((h b a) (m3 m7))
		       ((h b b) (m4 m8))
		       ((h b e) (m3 m4 m7 m8))
		       ((h b h) (m3 m4 m7 m8))
		       ((h e a) (m1 m3 m5 m7))
		       ((h e b) (m2 m4 m6 m8))
		       ((h e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((h e h) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((h h a) (m1 m3 m5 m7))
		       ((h h b) (m2 m4 m6 m8))
		       ((h h e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((h h h) (m1 m2 m3 m4 m5 m6 m7 m8))))))

		("8"

		  ;;
		  ;;     a   b     b   a 
		  ;;     |   |     |   | 
		  ;;     c   d     f   g
		  ;;      \ /       \ /
		  ;;       e         h
		  ;;        \       /
		  ;;         \     / a   b
		  ;;          \   /  |   |  
		  ;;           \ /   j   k
		  ;;            i     \ / 
		  ;;             \     l
		  ;;              \   /
		  ;;               \ /
		  ;;                m
		  ;;                

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (b))
		   (g  (a))
		   (h  (f g))
		   (i  (e h))
		   (j  (a))
		   (k  (b))
		   (l  (j k))
		   (m  (i l)))
		       
		  ((a  (a))
		   (b  (b))
		   (c  (c a))			;Class precedence lists
		   (d  (d b))
		   (e  (e c a d b))
		   (f  (f b))
		   (g  (g a))
		   (h  (h f b g a))
		   (i  (i e c d h f b g a))
		   (j  (j a))
		   (k  (k b))
		   (l  (l j a k b))
		   (m  (m i e c d h f g l j a k b)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (b a))
			 (i (b a))
			 (l (a b))
			 (m (a b))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (h (b a))
			 (i (e b a))
			 (l (a b))
			 (m (e a b))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (h b a))
			 (i (h b a))
			 (l (a b))
			 (m (h a b))))
		   (4   (a b e h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (h (h b a))
			 (i (e h b a))
			 (l (a b))
			 (m (e h a b)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m2 m1))
		       ((i) (m2 m1))
		       ((l) (m1 m2))
		       ((m) (m1 m2))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((h) (m2 m1))
		       ((i) (m3 m2 m1))
		       ((l) (m1 m2))
		       ((m) (m3 m1 m2))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((h) (m3 m2 m1))
		       ((i) (m3 m2 m1))
		       ((l) (m1 m2))
		       ((m) (m3 m1 m2))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((e) (m1 m2))
		       ((i) (m2 m1))))
		   (5 ((m1 (a a))
		       (m2 (a b))
		       (m3 (b a))
		       (m4 (b b))) ;a b e h i l m
		      (((a a) (m1))
		       ((a b) (m2))
		       ((a e) (m1 m2))
		       ((a h) (m2 m1))
		       ((a i) (m2 m1))
		       ((a l) (m1 m2))
		       ((a m) (m1 m2))
		       ((b a) (m3))
		       ((b b) (m4))
		       ((b e) (m3 m4))
		       ((b h) (m4 m3))
		       ((b i) (m4 m3))
		       ((b l) (m3 m4))
		       ((b m) (m3 m4))
		       ((e a) (m1 m3))
		       ((e b) (m2 m4))
		       ((e e) (m1 m2 m3 m4))
		       ((e h) (m2 m1 m4 m3))
		       ((e i) (m2 m1 m4 m3))
		       ((e l) (m1 m2 m3 m4))
		       ((e m) (m1 m2 m3 m4))
		       ((h a) (m3 m1))
		       ((h b) (m4 m2))
		       ((h e) (m3 m4 m1 m2))
		       ((h h) (m4 m3 m2 m1))
		       ((h i) (m4 m3 m2 m1))
		       ((h l) (m3 m4 m1 m2))
		       ((h m) (m3 m4 m1 m2))
		       ((i a) (m3 m1))
		       ((i b) (m4 m2))
		       ((i e) (m3 m4 m1 m2))
		       ((i h) (m4 m3 m2 m1))
		       ((i i) (m4 m3 m2 m1))
		       ((i l) (m3 m4 m1 m2))
		       ((i m) (m3 m4 m1 m2))
		       ((l a) (m1 m3))
		       ((l b) (m2 m4))
		       ((l e) (m1 m2 m3 m4))
		       ((l h) (m2 m1 m4 m3))
		       ((l i) (m2 m1 m4 m3))
		       ((l l) (m1 m2 m3 m4))
		       ((l m) (m1 m2 m3 m4))
		       ((m a) (m1 m3))
		       ((m b) (m2 m4))
		       ((m e) (m1 m2 m3 m4))
		       ((m h) (m2 m1 m4 m3))
		       ((m i) (m2 m1 m4 m3))
		       ((m l) (m1 m2 m3 m4))
		       ((m m) (m1 m2 m3 m4))))
		   (6 ((m1 (a a a))
		       (m2 (a b a))
		       (m3 (b a a))
		       (m4 (b b a)))
		      (((a a a) (m1))
		       ((a b a) (m2))
		       ((a e a) (m1 m2))
		       ((a h a) (m2 m1))
		       ((a i a) (m2 m1))
		       ((a l a) (m1 m2))
		       ((a m a) (m1 m2))
		       ((b a a) (m3))
		       ((b b a) (m4))
		       ((b e a) (m3 m4))
		       ((b h a) (m4 m3))
		       ((b i a) (m4 m3))
		       ((b l a) (m3 m4))
		       ((b m a) (m3 m4))
		       ((e a a) (m1 m3))
		       ((e b a) (m2 m4))
		       ((e e a) (m1 m2 m3 m4))
		       ((e h a) (m2 m1 m4 m3))
		       ((e i a) (m2 m1 m4 m3))
		       ((e l a) (m1 m2 m3 m4))
		       ((e m a) (m1 m2 m3 m4))
		       ((h a a) (m3 m1))
		       ((h b a) (m4 m2))
		       ((h e a) (m3 m4 m1 m2))
		       ((h h a) (m4 m3 m2 m1))
		       ((h i a) (m4 m3 m2 m1))
		       ((h l a) (m3 m4 m1 m2))
		       ((h m a) (m3 m4 m1 m2))
		       ((i a a) (m3 m1))
		       ((i b a) (m4 m2)) 
		       ((i e a) (m3 m4 m1 m2))
		       ((i h a) (m4 m3 m2 m1))
		       ((i i a) (m4 m3 m2 m1))
		       ((i l a) (m3 m4 m1 m2))
		       ((i m a) (m3 m4 m1 m2))
		       ((l a a) (m1 m3))
		       ((l b a) (m2 m4))
		       ((l e a) (m1 m2 m3 m4))
		       ((l h a) (m2 m1 m4 m3))
		       ((l i a) (m2 m1 m4 m3))
		       ((l l a) (m1 m2 m3 m4))
		       ((l m a) (m1 m2 m3 m4))
		       ((m a a) (m1 m3))
		       ((m b a) (m2 m4))
		       ((m e a) (m1 m2 m3 m4))
		       ((m h a) (m2 m1 m4 m3))
		       ((m i a) (m2 m1 m4 m3))
		       ((m l a) (m1 m2 m3 m4))
		       ((m m a) (m1 m2 m3 m4))))
		   (7 ((m1 (a a a))
		       (m2 (a a b))
		       (m3 (a b a))
		       (m4 (a b b))
		       (m5 (b a a))
		       (m6 (b a b))
		       (m7 (b b a))
		       (m8 (b b b)))
		      (((a a a) (m1))
		       ((a a b) (m2))
		       ((a a e) (m1 m2))
		       ((a a h) (m2 m1))
		       ((a a i) (m2 m1))
		       ((a a l) (m1 m2))
		       ((a a m) (m1 m2))
		       ((a b a) (m3))
		       ((a b b) (m4))
		       ((a b e) (m3 m4))
		       ((a b h) (m4 m3))
		       ((a b i) (m4 m3))
		       ((a b l) (m3 m4))
		       ((a b m) (m3 m4))
		       ((a e a) (m1 m3))
		       ((a e b) (m2 m4))
		       ((a e e) (m1 m2 m3 m4))
		       ((a e h) (m2 m1 m4 m3))
		       ((a e i) (m2 m1 m4 m3))
		       ((a e l) (m1 m2 m3 m4))
		       ((a e m) (m1 m2 m3 m4))
		       ((a h a) (m3 m1))
		       ((a h b) (m4 m2))
		       ((a h e) (m3 m4 m1 m2))
		       ((a h h) (m4 m3 m2 m1))
		       ((a h i) (m4 m3 m2 m1))
		       ((a h l) (m3 m4 m1 m2))
		       ((a h m) (m3 m4 m1 m2))
		       ((a i a) (m3 m1))
		       ((a i b) (m4 m2))
		       ((a i e) (m3 m4 m1 m2))
		       ((a i h) (m4 m3 m2 m1))
		       ((a i i) (m4 m3 m2 m1))
		       ((a i l) (m3 m4 m1 m2))
		       ((a i m) (m3 m4 m1 m2))
		       ((a l a) (m1 m3))
		       ((a l b) (m2 m4))
		       ((a l e) (m1 m2 m3 m4))
		       ((a l h) (m2 m1 m4 m3))
		       ((a l i) (m2 m1 m4 m3))
		       ((a l m) (m1 m2 m3 m4))
		       ((a l l) (m1 m2 m3 m4))
		       ((a m a) (m1 m3))
		       ((a m b) (m2 m4))
		       ((a m e) (m1 m2 m3 m4))
		       ((a m h) (m2 m1 m4 m3))
		       ((a m i) (m2 m1 m4 m3))
		       ((a m l) (m1 m2 m3 m4))
		       ((a m m) (m1 m2 m3 m4))
		       ((b a a) (m5))
		       ((b a b) (m6))
		       ((b a e) (m5 m6))
		       ((b a h) (m6 m5))
		       ((b a i) (m6 m5))
		       ((b a l) (m5 m6))
		       ((b a m) (m5 m6))
		       ((b b a) (m7))
		       ((b b b) (m8))
		       ((b b e) (m7 m8))
		       ((b b h) (m8 m7))
		       ((b b i) (m8 m7))
		       ((b b l) (m7 m8))
		       ((b b m) (m7 m8))
		       ((b e a) (m5 m7))
		       ((b e b) (m6 m8))
		       ((b e e) (m5 m6 m7 m8))
		       ((b e h) (m6 m5 m8 m7))
		       ((b e i) (m6 m5 m8 m7))
		       ((b e l) (m5 m6 m7 m8))
		       ((b e m) (m5 m6 m7 m8))
		       ((b h a) (m7 m5))
		       ((b h b) (m8 m6))
		       ((b h e) (m7 m8 m5 m6))
		       ((b h h) (m8 m7 m6 m5))
		       ((b h i) (m8 m7 m6 m5))
		       ((b h l) (m7 m8 m5 m6))
		       ((b h m) (m7 m8 m5 m6))
		       ((b i a) (m7 m5))
		       ((b i b) (m8 m6))
		       ((b i e) (m7 m8 m5 m6))
		       ((b i h) (m8 m7 m6 m5))
		       ((b i i) (m8 m7 m6 m5))
		       ((b i l) (m7 m8 m5 m6))
		       ((b i m) (m7 m8 m5 m6))
		       ((b l a) (m5 m7))
		       ((b l b) (m6 m8))
		       ((b l e) (m5 m6 m7 m8))
		       ((b l h) (m6 m5 m8 m7))
		       ((b l i) (m6 m5 m8 m7))
		       ((b l l) (m5 m6 m7 m8))
		       ((b l m) (m5 m6 m7 m8))
		       ((b m a) (m5 m7))
		       ((b m b) (m6 m8))
		       ((b m e) (m5 m6 m7 m8))
		       ((b m h) (m6 m5 m8 m7))
		       ((b m i) (m6 m5 m8 m7))
		       ((b m l) (m5 m6 m7 m8))
		       ((b m m) (m5 m6 m7 m8))
		       ((e a a) (m1 m5))
		       ((e a b) (m2 m6))
		       ((e a e) (m1 m2 m5 m6))
		       ((e a h) (m2 m1 m6 m5))
		       ((e a i) (m2 m1 m6 m5))
		       ((e a l) (m1 m2 m5 m6))
		       ((e a m) (m1 m2 m5 m6))
		       ((e b a) (m3 m7))
		       ((e b b) (m4 m8))
		       ((e b e) (m3 m4 m7 m8))
		       ((e b h) (m4 m3 m8 m7))
		       ((e b i) (m4 m3 m8 m7))
		       ((e b l) (m3 m4 m7 m8))
		       ((e b m) (m3 m4 m7 m8))
		       ((e e a) (m1 m3 m5 m7))
		       ((e e b) (m2 m4 m6 m8))
		       ((e e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e e h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e e i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e e l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e e m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e h a) (m3 m1 m7 m5))
		       ((e h b) (m4 m2 m8 m6))
		       ((e h e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e h h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e h i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e h l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e h m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e i a) (m3 m1 m7 m5))
		       ((e i b) (m4 m2 m8 m6))
		       ((e i e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e i h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e i i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((e i l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e i m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((e l a) (m1 m3 m5 m7))
		       ((e l b) (m2 m4 m6 m8))
		       ((e l e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e l h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e l i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e l l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e l m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e m a) (m1 m3 m5 m7))
		       ((e m b) (m2 m4 m6 m8))
		       ((e m e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e m h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e m i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((e m l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((e m m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((h a a) (m5 m1))
		       ((h a b) (m6 m2))
		       ((h a e) (m5 m6 m1 m2))
		       ((h a h) (m6 m5 m2 m1))
		       ((h a i) (m6 m5 m2 m1))
		       ((h a l) (m5 m6 m1 m2))
		       ((h a m) (m5 m6 m1 m2))
		       ((h b a) (m7 m3))
		       ((h b b) (m8 m4))
		       ((h b e) (m7 m8 m3 m4))
		       ((h b h) (m8 m7 m4 m3))
		       ((h b i) (m8 m7 m4 m3))
		       ((h b l) (m7 m8 m3 m4))
		       ((h b m) (m7 m8 m3 m4))
		       ((h e a) (m5 m7 m1 m3))
		       ((h e b) (m6 m8 m2 m4))
		       ((h e e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h e h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h e i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h e l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h e m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h h a) (m7 m5 m3 m1))
		       ((h h b) (m8 m6 m4 m2))
		       ((h h e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h h h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h h i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h h l) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h h m) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h i a) (m7 m5 m3 m1))
		       ((h i b) (m8 m6 m4 m2))
		       ((h i e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h i h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h i i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((h i l) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h i m) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((h l a) (m5 m7 m1 m3))
		       ((h l b) (m6 m8 m2 m4))
		       ((h l e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h l h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h l i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h l l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h l m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h m a) (m5 m7 m1 m3))
		       ((h m b) (m6 m8 m2 m4))
		       ((h m e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h m h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h m i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((h m l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((h m m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i a a) (m5 m1))
		       ((i a b) (m6 m2))
		       ((i a e) (m5 m6 m1 m2))
		       ((i a h) (m6 m5 m2 m1))
		       ((i a i) (m6 m5 m2 m1))
		       ((i a l) (m5 m6 m1 m2))
		       ((i a m) (m5 m6 m1 m2))
		       ((i b a) (m7 m3))
		       ((i b b) (m8 m4))
		       ((i b e) (m7 m8 m3 m4))
		       ((i b h) (m8 m7 m4 m3))
		       ((i b i) (m8 m7 m4 m3))
		       ((i b l) (m7 m8 m3 m4))
		       ((i b m) (m7 m8 m3 m4))
		       ((i e a) (m5 m7 m1 m3))
		       ((i e b) (m6 m8 m2 m4))
		       ((i e e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i e h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i e i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i e l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i e m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i h a) (m7 m5 m3 m1))
		       ((i h b) (m8 m6 m4 m2))
		       ((i h e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i h h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i h i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i h l) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i h m) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i i a) (m7 m5 m3 m1))
		       ((i i b) (m8 m6 m4 m2))
		       ((i i e) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i i h) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i i i) (m8 m7 m6 m5 m4 m3 m2 m1))
		       ((i i l) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i i m) (m7 m8 m5 m6 m3 m4 m1 m2))
		       ((i l a) (m5 m7 m1 m3))
		       ((i l b) (m6 m8 m2 m4))
		       ((i l e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i l h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i l i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i l l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i l m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i m a) (m5 m7 m1 m3))
		       ((i m b) (m6 m8 m2 m4))
		       ((i m e) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i m h) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i m i) (m6 m5 m8 m7 m2 m1 m4 m3))
		       ((i m l) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((i m m) (m5 m6 m7 m8 m1 m2 m3 m4))
		       ((l a a) (m1 m5))
		       ((l a b) (m2 m6))
		       ((l a e) (m1 m2 m5 m6))
		       ((l a h) (m2 m1 m6 m5))
		       ((l a i) (m2 m1 m6 m5))
		       ((l a l) (m1 m2 m5 m6))
		       ((l a m) (m1 m2 m5 m6))
		       ((l b a) (m3 m7))
		       ((l b b) (m4 m8))
		       ((l b e) (m3 m4 m7 m8))
		       ((l b h) (m4 m3 m8 m7))
		       ((l b i) (m4 m3 m8 m7))
		       ((l b l) (m3 m4 m7 m8))
		       ((l b m) (m3 m4 m7 m8))
		       ((l e a) (m1 m3 m5 m7))
		       ((l e b) (m2 m4 m6 m8))
		       ((l e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l e h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l e i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l e l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l e m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l h a) (m3 m1 m7 m5))
		       ((l h b) (m4 m2 m8 m6))
		       ((l h e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l h h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((l h i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((l h l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l h m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l i a) (m3 m1 m7 m5))
		       ((l i b) (m4 m2 m8 m6))
		       ((l i e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l i h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((l i i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((l i l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l i m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((l l a) (m1 m3 m5 m7))
		       ((l l b) (m2 m4 m6 m8))
		       ((l l e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l l h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l l i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l l l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l l m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l m a) (m1 m3 m5 m7))
		       ((l m b) (m2 m4 m6 m8))
		       ((l m e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l m h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l m i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((l m l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((l m m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m a a) (m1 m5))
		       ((m a b) (m2 m6))
		       ((m a e) (m1 m2 m5 m6))
		       ((m a h) (m2 m1 m6 m5))
		       ((m a i) (m2 m1 m6 m5))
		       ((m a l) (m1 m2 m5 m6))
		       ((m a m) (m1 m2 m5 m6))
		       ((m b a) (m3 m7))
		       ((m b b) (m4 m8))
		       ((m b e) (m3 m4 m7 m8))
		       ((m b h) (m4 m3 m8 m7))
		       ((m b i) (m4 m3 m8 m7))
		       ((m b l) (m3 m4 m7 m8))
		       ((m b m) (m3 m4 m7 m8))
		       ((m e a) (m1 m3 m5 m7))
		       ((m e b) (m2 m4 m6 m8))
		       ((m e e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m e h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m e i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m e l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m e m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m h a) (m3 m1 m7 m5))
		       ((m h b) (m4 m2 m8 m6))
		       ((m h e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m h h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((m h i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((m h l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m h m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m i a) (m3 m1 m7 m5))
		       ((m i b) (m4 m2 m8 m6))
		       ((m i e) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m i h) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((m i i) (m4 m3 m2 m1 m8 m7 m6 m5))
		       ((m i l) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m i m) (m3 m4 m1 m2 m7 m8 m5 m6))
		       ((m l a) (m1 m3 m5 m7))
		       ((m l b) (m2 m4 m6 m8))
		       ((m l e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m l h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m l i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m l l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m l m) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m m a) (m1 m3 m5 m7))
		       ((m m b) (m2 m4 m6 m8))
		       ((m m e) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m m h) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m m i) (m2 m1 m4 m3 m6 m5 m8 m7))
		       ((m m l) (m1 m2 m3 m4 m5 m6 m7 m8))
		       ((m m m) (m1 m2 m3 m4 m5 m6 m7 m8))))))

		("9"
		  ;;
		  ;;   a   b   c   a
		  ;;   |  /|  /|  /
		  ;;   | / | / | /
		  ;;   |/  |/  |/
		  ;;   i   j   k (a c)
		  ;;    \  |  /
		  ;;     \ | /
		  ;;       z

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (i  (a b))
		   (j  (b c))
		   (k  (a c))
		   (z  (i j k)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (i (i a b))
		   (j (j b c))
		   (k (k a c))
		   (z (z i j k a b c)))

		 ((1 (a b c)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (i (a b))
		      (j (b c))
		      (k (a c))
		      (z (a b c)))))

		 ((1 ((m1 (a))			;Points
		      (m2 (b))
		      (m3 (c)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((i) (m1 m2))
		      ((j) (m2 m3))
		      ((k) (m1 m3))
		      ((z) (m1 m2 m3))))
		  (2 ((m1 (a a))
		      (m2 (a b))
		      (m3 (b a))
		      (m4 (b b))) ; a b i
		     (((a a) (m1))
		      ((a b) (m2))
		      ((a i) (m1 m2))
		      ((b a) (m3))
		      ((b b) (m4))
		      ((b i) (m3 m4))
		      ((i a) (m1 m3))
		      ((i b) (m2 m4))
		      ((i i) (m1 m2 m3 m4))))))
		       

		("10"
		  ;;
		  ;;     a
		  ;;    /|
		  ;;   / |
		  ;;  b  |
		  ;;   \ |
		  ;;    \|
		  ;;     c
		  ;;     

		  ((a  ())			;Class definitions
		   (b  (a))
		   (c  (b a)))

		  ((a (a))			;Class precedence lists
		   (b (b a))
		   (c (c b a)))

		 ((1 (a)			;Columns
		     ((t ())
		      (a (a))))
		  (2 (b)
		     ((t ())
		      (b (b))))
		  (3 (c)
		     ((t ())
		      (c (c))))
		  (4 (a b)
		     ((t ())
		      (a (a))
		      (b (b a))))
		  (5 (a c)
		     ((t ())
		      (a (a))
		      (c (c a))))
		  (6 (b c)
		     ((t ())
		      (b (b))
		      (c (c b))))
		  (7 (a b c)
		     ((t ())
		      (a (a))
		      (b (b a))
		      (c (c b a)))))

		 ((1 ((m1 (a a a))			;Points
		      (m2 (a a b))
		      (m3 (a b a))
		      (m4 (a b b))
		      (m5 (b a a))
		      (m6 (b a b))
		      (m7 (b b a))
		      (m8 (b b b)))
		     (((a a a) (m1))
		      ((a a b) (m2 m1))
		      ((a b a) (m3 m1))
		      ((a b b) (m4 m3 m2 m1))
		      ((b a a) (m5 m1))
		      ((b a b) (m6 m5 m2 m1))
		      ((b b a) (m7 m5 m3 m1))
		      ((b b b) (m8 m7 m6 m5 m4 m3 m2 m1))))))

		("11"
		  ;;
		  ;;  a  c  d  b  c
		  ;;   \ | /    \/
		  ;;    \|/     j
		  ;;     i     /
		  ;;      \   /
		  ;;       \ /
		  ;;        z
		  ;;     

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (d  ())
		   (i  (a c d))
		   (j  (b c))
		   (z  (i j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (d (d))
		   (i (i a c d))
		   (j (j b c))
		   (z (z i a j b c d)))

		 ((1 (a b)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (z (a b))))
		  (2 (a b c)
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (i (a c))
		      (j (b c))
		      (z (a b c))))
		  (3 (a c)
		     ((t ())
		      (a (a))
		      (c (c))
		      (i (a c))))
		  (4 (a b c d)
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (d (d))
		      (i (a c d))
		      (j (b c))
		      (z (a b c d)))))

		 ((1 ((m1 (a))				;Points
		      (m2 (c)))
		     (((a) (m1))
		      ((c) (m2))
		      ((i) (m1 m2))))
		  (2 ((m1 (a))
		      (m2 (b)))
		     (((a) (m1))
		      ((b) (m2))
		      ((z) (m1 m2))))
		  (3 ((m1 (a))
		      (m2 (b))
		      (m3 (c)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((i) (m1 m3))
		      ((j) (m2 m3))
		      ((z) (m1 m2 m3))))
		  (4 ((m1 (a c))
		      (m2 (a j))
		      (m3 (a b))
		      (m4 (i c))
		      (m5 (i j))
		      (m6 (i b)))
		     (((a c) (m1))
		      ((a b) (m3))
		      ((a j) (m2 m3 m1))
		      ((i c) (m4 m1))
		      ((i b) (m6 m3))
		      ((i j) (m5 m6 m4 m2 m3 m1))))))

		("12"
		  ;;
		  ;;  a  b  c
		  ;;  |  |  |
		  ;;  i  j  k
		  ;;   \ | /
		  ;;    \|/
		  ;;     z
		  ;;     

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (i  (a))
		   (j  (b))
		   (k  (c))
		   (z  (i j k)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (i (i a))
		   (j (j b))
		   (z (z i a j b k c)))

		 ((1 (a b c)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (z (a b c))))
		  (2 (i j k)
		     ((t ())
		      (i (i))
		      (j (j))
		      (k (k))
		      (z (i j k))))
		  (3 (a b c i j k)
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (i (i a))
		      (j (j b))
		      (k (k c))
		      (z (i a j b k c)))))

		 ((1 ((m1 (a))				;Points
		      (m2 (b))
		      (m3 (c)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((z) (m1 m2 m3))))
		  (2 ((m1 (a))
		      (m2 (b))
		      (m3 (c))
		      (m4 (i))
		      (m5 (j))
		      (m6 (k)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((i) (m4 m1))
		      ((j) (m5 m2))
		      ((k) (m6 m3))
		      ((z) (m4 m1 m5 m2 m6 m3))))
		  (3 ((m1 (a a))
		      (m2 (a b))
		      (m3 (b a))
		      (m4 (b b)))
		     (((a a) (m1))
		      ((a b) (m2))
		      ((a z) (m1 m2))
		      ((b a) (m3))
		      ((b b) (m4))
		      ((b z) (m3 m4))
		      ((z a) (m1 m3))
		      ((z b) (m2 m4))
		      ((z z) (m1 m2 m3 m4))))
		      ))

		("13"
		  ;;
		  ;;  a     b     c
		  ;;   \   / \   /
		  ;;    \ /   \ /
		  ;;     i     j (c b)
		  ;;      \   /
		  ;;       \ /
		  ;;        z
		  ;;     

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (i  (a b))
		   (j  (c b))
		   (z  (i j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (i (i a b))
		   (j (j c b))
		   (z (z i a j c b)))

		 ((1 (a b c)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (i (a b))
		      (j (c b))
		      (z (a c b))))
		  (2 (i j)
		     ((t ())
		      (i (i))
		      (j (j))
		      (z (i j))))
		  (3 (a b c i j)
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (i (i a b))
		      (j (j c b))
		      (z (i a j c b)))))

		 ((1 ((m1 (a))				;Points
		      (m2 (b))
		      (m3 (c)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((i) (m1 m2))
		      ((j) (m3 m2))
		      ((z) (m1 m3 m2))))
		  (2 ((m1 (a))
		      (m2 (b))
		      (m3 (c))
		      (m4 (i))
		      (m5 (j)))
		     (((a) (m1))
		      ((b) (m2))
		      ((c) (m3))
		      ((i) (m4 m1 m2))
		      ((j) (m5 m3 m2))
		      ((z) (m4 m1 m5 m3 m2))))))

		("14"
		  ;;
		  ;;  a     b     c
		  ;;  |\   /|\   /|
		  ;;  | \ / | \ / |
		  ;;  i  |  j  |  k
		  ;;  \  |  |  |  /
		  ;;   \�|� | �|�/
		  ;;     | \|/ |
		  ;;     |  |  |
		  ;;     l  n  m  ; n (k j i)
		  ;;      \ | /
		  ;;       \|/
		  ;;        z (l m n)
		  ;;        

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (i  (a))
		   (j  (b))
		   (k  (c))
		   (l  (a b))
		   (m  (b c))
		   (n  (k j i))
		   (z  (l m n)))


		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (i (i a))
		   (j (j b))
		   (k (k c))
		   (l (l a b))
		   (m (m b c))
		   (n (n k c j b i a))
		   (z (z l m n k j i a b c)))

		 ((1 (a b)			;Columns
		     ((t ())
		      (a (a))
		      (b (b))
		      (l (a b))
		      (n (b a))))
		  (2 (b c)
		     ((t ())
		      (b (b))
		      (c (c))
		      (n (c b))
		      (m (b c))))
		  (3 (a b c)
		     ((t ())
		      (a (a))
		      (b (b))
		      (c (c))
		      (l (a b))
		      (m (b c))
		      (n (c b a))
		      (z (a b c))))
		  (4 (i j k)
		     ((t ())
		      (i (i))
		      (j (j))
		      (k (k))
		      (n (k j i)))))

		 ((1 ((m1 (a j k))			;Points
		      (m2 (a b c))
		      (m3 (i b c)))
		     (((a b c) (m2))
		      ((a j k) (m1 m2))
		      ((i b c) (m3 m2))
		      ((i j k) (m3 m1 m2))))))
		      
		("15"
		  ;;
		  ;;  a     b     c   d
		  ;;  |\   /|\   /|   |
		  ;;  | \ / | \ / |   |
		  ;;  |  |  |  X  |  /
		  ;;  |  |  | / \ | /
		  ;;  |  |  |/   \|/
		  ;;  l  i  j     k
		  ;;   \ |  |    /
		  ;;    \|  |   /
		  ;;     \\ |  /
		  ;;      \\| /
		  ;;       \|/
		  ;;        z (i k j l)
		  ;;            

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  ())
		   (d  ())
		   (i  (a b))
		   (j  (b c))
		   (k  (b c d))
		   (l  (a))
		   (z  (i k j l)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c))
		   (d (d))
		   (i (i a b))
		   (j (j b c))
		   (k (k b c d))
		   (l (l a))
		   (z (z i k j l a b c d)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (i (a b))))
		   (2   (a b c d)
			((t ())
			 (a (a))
			 (b (b))
			 (c (c))
			 (d (d))
			 (i (a b))
			 (j (b c))
			 (k (b c d))
			 (z (a b c d)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((i) (m1 m2))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (c))
		       (m4 (d)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m3))
		       ((d) (m4))
		       ((i) (m1 m2))
		       ((j) (m2 m3))
		       ((k) (m2 m3 m4))
		       ((z) (m1 m2 m3 m4))))))

		("16"
		  ;; a     b
		  ;;  \   /   b   a
		  ;;   \ /    |   |
		  ;;    c     d   e
		  ;;     \     \ /
		  ;;      \     f
		  ;;       \   /   a   b
		  ;;        \ /    |   |
		  ;;         g     h   i
		  ;;          \     \ /
		  ;;           \     j
		  ;;            \   /
		  ;;             \ /
		  ;;              k   a     b
		  ;;               \   \   /
		  ;;                \   \ /
		  ;;                 \   l
		  ;;                  \ /
		  ;;                   m

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a b))
		   (d  (b))
		   (e  (a))
		   (f  (d e))
		   (g  (c f))
		   (h  (a))
		   (i  (b))
		   (j  (h i))
		   (k  (g j))
		   (l  (a b))
		   (m  (k l)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a b))
		   (d (d b))
		   (e (e a))
		   (f (f d b e a))
		   (g (g c f d e a b))
		   (h (h a))
		   (i (i b))
		   (j (j h a i b))
		   (k (k g c f d e j h a i b))
		   (l (l a b))
		   (m (m k g c f d e j h i l a b)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (f (b a))
			 (j (a b))
			 (l (a b))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (e (e a))
			 (f (b e a))
			 (g (e a b))
			 (j (a b))
			 (l (a b))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (f (b a))
			 (h (h a))
			 (j (h a b))
			 (k (h a b))
			 (l (a b))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (f (d a)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((f) (m2 m1))
		       ((j) (m1 m2))
		       ((l) (m1 m2))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((e) (m3 m1))
		       ((f) (m2 m3 m1))
		       ((g) (m3 m1 m2))
		       ((j) (m1 m2))
		       ((l) (m1 m2))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((f) (m2 m1))
		       ((h) (m3 m1))
		       ((j) (m3 m1 m2))
		       ((k) (m3 m1 m2))
		       ((l) (m1 m2))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((f) (m2 m1))))))

		("17"
		  ;;
		  ;;  a   b
		  ;;  |   |
		  ;;  c   d   b   a
		  ;;   \ /    |   |
		  ;;    e     f   g
		  ;;     \     \ /
		  ;;      \     h
		  ;;       \   /  
		  ;;        \ /
		  ;;         i   a     b
		  ;;          \   \   /
		  ;;           \   \ /
		  ;;            \   j
		  ;;             \ /
		  ;;              k
		  ;;              

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (b))
		   (g  (a))
		   (h  (f g))
		   (i  (e h))
		   (j  (a b))
		   (k  (i j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a))
		   (d (d b))
		   (e (e c a d b))
		   (f (f b))
		   (g (g a))
		   (h (h f b g a))
		   (i (i e c d h f b g a))
		   (j (j a b))
		   (k (k i e c d h f g j a b)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (b a))
			 (i (b a))
			 (j (a b))
			 (k (a b))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (h (b a))
			 (i (e b a))
			 (j (a b))
			 (k (e a b))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (h (h b a))
			 (i (h b a))
			 (j (a b))
			 (k (h a b))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (e (a d))
			 (i (d a)))))

		   ((1 ((m1 (a))			;Points
			(m2 (b)))
		       (((a) (m1))
			((b) (m2))
			((e) (m1 m2))
			((h) (m2 m1))
			((i) (m2 m1))
			((j) (m1 m2))
			((k) (m1 m2))))
		    (2 ((m1 (a))
			(m2 (b))
			(m3 (e)))
		       (((a) (m1))
			((b) (m2))
			((e) (m3 m1 m2))
			((h) (m2 m1))
			((i) (m3 m2 m1))
			((j) (m1 m2))
			((k) (m3 m1 m2))))
		    (3 ((m1 (a))
			(m2 (b))
			(m3 (h)))
		       (((a) (m1))
			((b) (m2))
			((e) (m1 m2))
			((h) (m3 m2 m1))
			((i) (m3 m2 m1))
			((j) (m1 m2))
			((k) (m3 m1 m2))))
		    (4 ((m1 (a))
			(m2 (d)))
		       (((a) (m1))
			((d) (m2))
			((e) (m1 m2))
			((i) (m2 m1))))))

		("18"
		  ;;
		  ;;  a   b
		  ;;  |   |
		  ;;  c   d
		  ;;   \ /   b     a
		  ;;    e     \   /
		  ;;     \     \ /
		  ;;      \     f
		  ;;       \   /  
		  ;;        \ /   a   b
		  ;;         g    |   |
		  ;;          \   h   i
		  ;;           \   \ /
		  ;;            \   j
		  ;;             \ /
		  ;;              k
		  ;;              

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a))
		   (d  (b))
		   (e  (c d))
		   (f  (b a))
		   (g  (e f))
		   (h  (a))
		   (i  (b))
		   (j  (h i))
		   (k  (g j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a))
		   (d (d b))
		   (e (e c a d b))
		   (f (f b a))
		   (g (g e c d f b a))
		   (h (h a))
		   (i (i b))
		   (j (j h a i b))
		   (k (k g e c d f j h i b a)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (f (b a))
			 (g (b a))
			 (j (a b))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (e (e a b))
			 (f (b a))
			 (g (e b a))
			 (j (a b))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (e (a b))
			 (f (b a))
			 (g (b a))
			 (h (h a))
			 (j (h a b))
			 (k (h b a))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (e (a d))
			 (g (d a)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((f) (m2 m1))
		       ((g) (m2 m1))
		       ((j) (m1 m2))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m3 m1 m2))
		       ((f) (m2 m1))
		       ((g) (m3 m2 m1))
		       ((j) (m1 m2))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((e) (m1 m2))
		       ((f) (m2 m1))
		       ((g) (m2 m1))
		       ((h) (m3 m1))
		       ((j) (m3 m1 m2))
		       ((k) (m3 m2 m1))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((e) (m1 m2))
		       ((g) (m2 m1))))))

		("19"
		  ;;
		  ;; a     b
		  ;;  \   /   b   a
		  ;;   \ /    |   |
		  ;;    c     d   e
		  ;;     \     \ /
		  ;;      \     f
		  ;;       \   /  
		  ;;        \ /   b   a
		  ;;         g    |   |
		  ;;          \   h   i
		  ;;           \   \ /
		  ;;            \   j
		  ;;             \ /
		  ;;              k
		  ;;              

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a b))
		   (d  (b))
		   (e  (a))
		   (f  (d e))
		   (g  (c f))
		   (h  (b))
		   (i  (a))
		   (j  (h i))
		   (k  (g j)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a b))
		   (d (d b))
		   (e (e a))
		   (f (f d b e a))
		   (g (g c f d e a b))
		   (h (h b))
		   (i (i a))
		   (j (j h b i a))
		   (k (k g c f d e j h i a b)))

		  ((1   (a b)			;Columns
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (f (b a))
			 (j (b a))))
		   (2   (a b e)
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (e (e a))
			 (f (b e a))
			 (g (e a b))
			 (j (b a))))
		   (3   (a b h)
			((t ())
			 (a (a))
			 (b (b))
			 (c (a b))
			 (f (b a))
			 (h (h b))
			 (j (h b a))
			 (k (h a b))))
		   (4   (a d)
			((t ())
			 (a (a))
			 (d (d))
			 (f (d a)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (b)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((f) (m2 m1))
		       ((j) (m2 m1))))
		   (2 ((m1 (a))
		       (m2 (b))
		       (m3 (e)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((e) (m3 m1))
		       ((f) (m2 m3 m1))
		       ((g) (m3 m1 m2))
		       ((j) (m2 m1))))
		   (3 ((m1 (a))
		       (m2 (b))
		       (m3 (h)))
		      (((a) (m1))
		       ((b) (m2))
		       ((c) (m1 m2))
		       ((f) (m2 m1))
		       ((h) (m3 m2))
		       ((j) (m3 m2 m1))
		       ((k) (m3 m1 m2))))
		   (4 ((m1 (a))
		       (m2 (d)))
		      (((a) (m1))
		       ((d) (m2))
		       ((f) (m2 m1))))))

		("20"
		  ;;
		  ;;  a    i
		  ;;  |    |
		  ;;  b    j
		  ;;  |    |
		  ;;  c    k
		  ;;  |    |
		  ;;  d    l
		  ;;  |    |
		  ;;  e    m
		  ;;              

		  ((a  ())			;Class definitions
		   (b  (a))
		   (c  (b))
		   (d  (c))
		   (e  (d))
		   (i  ())
		   (j  (i))
		   (k  (j))
		   (l  (k))
		   (m  (l)))

		  ((a (a))			;Class precedence lists
		   (b (b a))
		   (c (c b a))
		   (d (d c b a))
		   (e (e d c b a))
		   (i (i))
		   (j (j i))
		   (k (k j i))
		   (l (l k j i))
		   (m (m l k j i)))

		  ((1   (a i)			;Columns
			((t ())
			 (a (a))
			 (i (i))))
		   (2   (a b i j)
			((t ())
			 (a (a))
			 (b (b a))
			 (i (i))
			 (j (j i)))))

		  ((1 ((m1 (a))			;Points
		       (m2 (i)))
		      (((a) (m1))
		       ((i) (m2))))))

		("21"
		  ;;
		  ;;  a   b
		  ;;  |\ /|
		  ;;  | X |
		  ;;  |/ \|
		  ;;  c   d
		  ;;   \ /
		  ;;    e
		  ;;
		  ;;              

		  ((a  ())			;Class definitions
		   (b  ())
		   (c  (a b))
		   (d  (a b))
		   (e  (c d)))

		  ((a (a))			;Class precedence lists
		   (b (b))
		   (c (c a b))
		   (d (d a b))
		   (e (e c d a b)))

		  ((1 (a b)			;Columns
		      ((t ())
		       (a (a))
		       (b (b))
		       (c (a b))
		       (d (a b))))
		   (2 (a b d)
		      ((t ())
		       (a (a))
		       (b (b))
		       (c (a b))
		       (d (d a b))
		       (e (d a b)))))

		 ((1 ((m1 (a))			;Combination points
		      (m2 (d))
		      (m3 (b)))
		     (((a) (m1))
		      ((b) (m3))
		      ((c) (m1 m3))
		      ((d) (m2 m1 m3))
		      ((e) (m2 m1 m3))))))

	        ("22"
		 ;;
		 ;;       a
		 ;;      /|\
		 ;;    /  |  \
		 ;;   i   j   k
		 ;;   
		 ((a  ())
		  (i  (a))
		  (j  (a))
		  (k  (a)))
		 
		 ((a (a))			;Class precedence lists
		  (i (i a))
		  (j (j a))
		  (k (k a)))

		 ((1 (t a j k)
		     ((t (t))
		      (a (a t))
		      (j (j a t))
		      (k (k a t))))
		  (2 (t a i k)
		     ((t (t))
		      (a (a t))
		      (i (i a t))
		      (k (k a t)))))

		 ((1 ((m1 (k i))  ;redundant point test
		      (m2 (k k))
		      (m3 (k a))
		      (m4 (a i))
		      (m5 (t t))
		      (m6 (j a)))
		     (((t t) (m5))
		      ((a i) (m4 m5))
		      ((j a) (m6 m5))
		      ((j i) (m6 m4 m5))
		      ((k a) (m3 m5))
		      ((k i) (m1 m3 m4 m5))
		      ((k k) (m2 m3 m5))))))

	        ("23" ;test case for cpl
		 ;;
		 ;;   a   b   c
		 ;;   |\ /   /
		 ;;   | X   /
		 ;;   |/ \ /
		 ;;   d   e
		 ;;    \ /
		 ;;     f
		 ;;   
		 ((a  ())
		  (b  ())
		  (c  ())
		  (d  (a b))
		  (e  (a c))
		  (f  (d e)))
		 
		 ((a (a))			;Class precedence lists
		  (b (b))
		  (c (c))
		  (d (d a b))
		  (e (e a c))
		  (f (f d e a c b)))		;old value was (f d e a b c)

		 ((1 (a b)
		     ((t ())
		      (a (a))
		      (b (b))
		      (d (a b))))
		  (2 (a b d)
		     ((t ())
		      (a (a))
		      (b (b))
		      (d (d a b))))
		  (3 (a b e)
		     ((t ())
		      (a (a))
		      (b (b))
		      (d (a b))
		      (e (e a))
		      (f (e a b))))
		  (4 (a b d e)
		     ((t ())
		      (a (a))
		      (b (b))
		      (d (d a b))
		      (e (e a))
		      (f (d e a b)))))

		 ((1 ((m1 (a))			;points
		      (m2 (b))
		      (m3 (d))
		      (m4 (e)))
		     (((a) (m1))
		      ((b) (m2))
		      ((d) (m3 m1 m2))
		      ((e) (m4 m1))
		      ((f) (m3 m4 m1 m2))))))))

(defvar *precedence-relation-test-classes*)

(defun install-precedence-relation-test-classes ()
  (format t "~&Installing test classes for checking precedence relations.~%~
             Each symbol printed will name a class.  In addition, the~%~
             global value of that symbol will be set to the class object...~%")
  (setq *precedence-relation-test-classes* '())
  (dolist (e *precedence-relation-tests*)
    (destructuring-bind (number class-definitions) e
      (flet ((convert-name (n)
	       (if (eq n 't)
		   '*the-class-t*
		   (symbol-append n number *the-pcl-package*))))
	(dolist (definition class-definitions)
	  (destructuring-bind (name supers) definition
	    (setq name (convert-name name)
		  supers (mapcar #'convert-name supers))
	    (eval `(defclass ,name ,supers ()))	;Aaaargh!!!
	    (set name (find-class name))
	    (push (find-class name) *precedence-relation-test-classes*)
	    (format t "~S  " name))))))
  (setq *precedence-relation-test-classes*
	(reverse (list* *the-class-t*
			*the-class-object*
			*precedence-relation-test-classes*))))

(eval-when (load eval)
  (install-precedence-relation-test-classes))

(defun test-precedence-relations ()
  (labels ((convert-name (name number)
	     (if (eq name 't)
		 '*the-class-t*
		 (symbol-append name number *the-pcl-package*)))
	   (*find-class (name number)
	     (if (eq name 't)
		 *the-class-t*
		 (find-class (convert-name name number))))
	   (*find-classes (names number)
	     (mapcar #'(lambda (name) (*find-class name number)) names))
	   (class-lessp (c1 c2)
	     (if (or (not (memq c1 *precedence-relation-test-classes*))
		     (not (memq c2 *precedence-relation-test-classes*)))
		 (error "Not called on a precedence relation test class.")
		 (memq c2 (memq c1 *precedence-relation-test-classes*)))))

    (dolist (test *precedence-relation-tests*)
      (destructuring-bind (number defns cpl-tests column-tests point-tests)
			  test
	(progn defns)
	(format t "~%~%Testing DAG ~A..." number)
	
	(format t "~&CPL tests: ")
	(dolist (test cpl-tests)
	  (destructuring-bind (class-name expected-names) test
	    (format t " ~A" class-name)
	    (let* ((class (*find-class class-name number))
		   (expected
		     (append (*find-classes expected-names number)
			     (list *the-class-object* *the-class-t*)))
		   (result (compute-std-cpl class)))
	      (unless (equal result expected)
		(error "CPL test ~A (DAG ~A) failed:~%~
                        expected -- ~S~%~
                        computed -- ~S"
		       class-name
		       number
		       (mapcar #'class-name expected)
		       (mapcar #'class-name result))))))

	(format t "~&Column tests: ")
	(dolist (test column-tests)
	  (destructuring-bind (n class-names expected-names) test
	    (format t " ~A" n)
	    (let* ((classes (*find-classes class-names number))
		   (expected
		     (mapcar #'(lambda (e)
				 (cons (*find-class (car e) number)
				       (cdr e)))
			     expected-names))
		   (result ())
		   ;; Turn the skeleton cache off so that we really are
		   ;; testing the newest code and to avoid corrupting
		   ;; the cache.
		   (*enable-precedence-dag-caching* nil))
	      (walk-cpnode (compute-one-column-internal classes class-names)
		 #'(lambda (entry)
		     (unless (eq (column-entry-flag entry) 'been-here)
		       (setf (column-entry-flag entry) 'been-here)
		       (push (list (column-entry-class entry)
				   (column-entry-pmo entry))
			     result))
		     nil))
	      (setq expected (sort expected #'class-lessp :key #'car)
		    result   (sort result #'class-lessp :key #'car))
	      (unless (equal expected result)
		(error "Column Test ~D (DAG ~A) failed:~%~
                        expected -- ~S~%~
                        computed -- ~S"
		       n number expected result)))))

	(format t "~&Combination point tests: ")
	(dolist (test point-tests)
	  (destructuring-bind (n methods expected-names) test
	    (format t " ~D" n)
	    (let* ((name (intern (format nil "~A~D-~D" 'g number n)))
		   (gf (setf (gdefinition name)
			     (make-instance 'standard-generic-function
					    :name name)))
		   (method-objects
		     (mapcar #'(lambda (m)
				(let* ((name (car m))
				       (specializers (cadr m))
				       (method 
					(make-instance
					  'standard-method
					  :type-specifiers
					  (*find-classes specializers
							 number))))
				  (add-method gf method)
				  (cons name method)))
			     methods)))
	      (labels ((get-method (name)
			 (or (cdr (assoc name method-objects))
			     (error "Couldn't get method ~S." name)))
		       (point-lessp (p1 p2)
			 (cond ((eq p1 p2) nil)
			       ((eq (car p1) (car p2))
				(point-lessp (cdr p1) (cdr p2)))
			       (t
				(class-lessp (car p1) (car p2)))))
		       (sort-points (points)
			 (sort points #'(lambda (p1 p2)
					  (point-lessp (car p1)
						       (car p2)))))
		       (points-for-printing (points)
			 (mapcar
			   #'(lambda (point)
			       (list (mapcar #'class-name (car point))
				     (mapcar #'(lambda (x)
						 (car (rassoc x
							      method-objects)))
					     (cadr point))))
			   points)))
		(let ((expected
			(sort-points 
			  (mapcar #'(lambda (ep)
				      (list (*find-classes (car ep) number)
					    (mapcar #'get-method (cadr ep))))
				  expected-names)))
		      (computed
			(sort-points (*compute-combination-points gf))))
		  (unless (equal expected computed)
		    (error "Combination Point test ~D (DAG ~A) failed:~%~
                            Expected -- ~S ~%~
                            Computed -- ~S"
			   n
			   number
			   (points-for-printing expected)
			   (points-for-printing computed))))))))))
    ))
