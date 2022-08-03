;;; -*- Mode: LISP; Syntax: Common-Lisp; Package: ZL-USER; Base: 10; Patch-File: T -*-
;;; Patch file for Private version 0.0
;;; Written by Gregor, 8/02/87 14:45:18
;;; while running on SPIFF from FEP0:>Inc-Genera-7-1-from-Genera-7-1.load.1
;;; with Genera 7.1, Experimental Ether 3.21, IP-TCP 52.16, Local-Mods 5.1,
;;; microcode 3670-XSQ-MIC 396, FEP 127, FEP0:>v127-lisp.flod(55),
;;; FEP0:>v127-loaders.flod(55), FEP0:>v127-debug.flod(34), FEP0:>v127-info.flod(55).


(NOTE-PRIVATE-PATCH "Make rel 7 debugger know about PCL Generic functions.")

;;;
;;; The general idea is to make the debugger associate the name of a closure
;;; with the actual closure, not with the closure function.  In this hack
;;; implementation, this is done using a hash-table which associates closure
;;; environments with closure names.
;;; 

;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer 3600-low.lisp
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")

(defvar *closure-names* (lisp:make-hash-table :test #'eq :size 500))

;;;
;;; This code is adapted from frame-lexical-environment.
;;; 
(defun function-name-for-debugger (frame)
  (let ((function (frame-function frame)))
    (or
      ;; if this is a closure and we can get its environment and there
      ;; is an entry for that environment in *closure-names*, return
      ;; that.  Otherwise just return the name of the closure function.
      (and (not (zerop (frame-lexical-called frame)))
	   (lisp:compiled-function-p function)
	   (let* ((local-map
		    (assq :local-map
			  (si:compiled-function-debugging-info function)))
		  ;; Closures over (flavors) methods put the environment
		  ;; into local 2, otherwise local 0 (actually arg 0) is
		  ;; the environment.
		  (env-local
		    (car (rassq 'compiler:.lexical-environment-pointer.
				(cdr local-map))))
		  ;; Use NIL for the environment if something went wrong
		  ;; or if this is a closure over a flavors method.
		  (env (and (zerop env-local)
			    (frame-local-value frame env-local))))
	     (and env
		  (gethash env *closure-names*))))
      
      (function-name function))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun error-reporter-frame-p (frame)
  ;; An error here would probably cause an infinite recursion of errors, so just return NIL
  ;; so we can get into the Debugger.  I realize this might paper over problems.
  (ignore-errors
    (let ((function (frame-function frame)))
      (or (assq 'error-reporter (debugging-info function))
	  (let ((function-spec (function-name-for-debugger frame)))
	    (loop while (and (listp function-spec) (eq (first function-spec) ':internal)) do
	      (setq function-spec (second function-spec)))
	    (typecase function-spec
	      (:symbol (get function-spec :error-reporter))
	      (:list (and (validate-function-spec function-spec)
			  (or (si:function-spec-get function-spec :error-reporter)
			      (selectq (car function-spec)
				((flavor:method flavor:whopper flavor:combined)
				 ;; There must be a better way to do this
				 (eq (flavor:method-generic function-spec) 'signal-condition))
				(otherwise nil)))))))))))



;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


;; True if frame is not just an internal frame of an interpreted function
(defun frame-interesting-p (frame
			    &optional (censor-invisible-frames *censor-invisible-frames*))
  (labels ((uninternalize-fspec (fspec)
	     ;; Internal functions of uninteresting functions are uninteresting
	     (if (and (listp fspec) (eq (first fspec) :internal))
		 (if (and (or (eq (fourth fspec) 'si:with-process-interactive-priority-body)
			      (eq (fourth fspec) 'si:with-process-non-interactive-priority-body))
			  (not (memq :process-priority *invisible-frame-types-to-show*)))
		     ;; These things aren't interesting
		     (return-from frame-interesting-p nil)
		   (uninternalize-fspec (second fspec)))
	       fspec)))
    (if (and censor-invisible-frames
	     (frame-invisible-p frame))
	nil
      (let* ((function (frame-function frame))
	     (fspec (uninternalize-fspec (function-name-for-debugger frame))))
	(and (neq fspec function)		;Not an unnamed LAMBDA expression
	     (not (if (listp  *uninteresting-functions*)
		      (member fspec  *uninteresting-functions*)
		      (gethash fspec *uninteresting-functions*)))
	     (not (member fspec si:*digested-special-forms*)))))))

(defprop invisible-frame t si:debug-info)


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")

(defun frame-invisible-p (frame)
  (if (or (null frame)
	  (eq *invisible-frame-types-to-show* t))
      nil					;user said no frames are invisible
    (labels ((invisible-p (function frame)
	       (let* ((invisible-property
			(assq 'invisible-frame (debugging-info function)))
		      (invisible-p (second invisible-property)))
		 (cond ((null invisible-property)
			;; If there is no INVISIBLE-FRAME property, then look
			;; at the parent function
			(let ((fspec (if frame
					 (function-name-for-debugger frame)
					 (function-name function))))
			  (if (and (listp fspec) (eq (first fspec) :internal))
			      (invisible-p (si:valid-function-definition (second fspec))
					   nil)
			   nil)))
		       ((eq invisible-p nil) nil)
		       ((eq invisible-p t) t)
		       (t (null (memq invisible-p *invisible-frame-types-to-show*)))))))
      (invisible-p (frame-function frame) frame))))




;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


;;; Functions to extract the argument and local variable values from a frame.

;; Return list of the function and args that were invoked (as best as it can).
;; Note that this tries to get the original name of the function so that
;; if it has been redefined and you are doing c-m-R the new version will be called.
;; On the a machine doesn't work for functions which modify their arguments.
(defun get-frame-function-and-args (frame)
  (let* ((*printing-monitor-message* t)
	 (frame-function-name (function-name-for-debugger frame))
	 (args (loop for i from 0 below (frame-number-of-visible-args frame)
		     collect (frame-arg-value frame i))))
    (multiple-value-bind (nil rest-arg-value nil lexpr-call)
	(decode-frame-rest-arg frame)
      ;; NCONC the rest arg if any was supplied separately from the regular args
      (and lexpr-call (setq args (nconc (nbutlast args) (copylist rest-arg-value)))))
    (if (or (special-form-p frame-function-name)
	    (macro-function frame-function-name))
	;; The real form given to the special form or macro, second arg is ENV
	(car args)
      (cons frame-function-name args))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun fun ()
  (let ((*printing-monitor-message* t))
    (function-name-for-debugger *frame*)))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun present-stack-frame (frame &optional (stream standard-output))
  (let ((frame-object (cons frame *error*))
	(name (function-name-for-debugger frame)))
    ;; Using a single box gives an easier target to hit
    (dw:with-output-as-presentation (:stream stream
				     :object frame-object
				     :type 'stack-frame
				     :allow-sensitive-inferiors nil)
      ;; This will give useful behavior even when we're not in the Debugger any more
      (dw:with-output-as-presentation (:stream stream
				       :object name
				       :type 'sys:function-spec)
	(let ((prinlevel nil)
	      (prinlength nil))
	  (prin1 name stream))))))



;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun print-function-and-args (frame &optional show-pc-p show-source-file-p
						show-local-if-different present-as-function)
  (let ((*printing-monitor-message* t)
	(prinlevel *function-prinlevel*)
	(prinlength *function-prinlength*)
	(function (frame-function frame)))
    (print-carefully "function name"
      (terpri)
      (and (closurep function)
	   (princ "Closure of "))
      (with-character-style (*emphasis-character-style*)
	(if present-as-function
	    (present (function-name-for-debugger frame) 'sys:function-spec)
	  (present-stack-frame frame)))
      (tyo #\:)
      (when (and show-pc-p
		 (typep function :compiled-function))
	(let ((pc-now (frame-relative-exit-pc frame)))
	  (if pc-now (format t "  (P.C. = ~O)" pc-now))))
      (with-character-style (*deemphasis-character-style*)
	(loop for func = function then (fsymeval (cadr encaps))
	      for delimiter = "  (encapsulated for " then ", "
	      as encaps = (and (legitimate-function-p func)
			       (assq 'si:encapsulated-definition (debugging-info func)))
	      while encaps
	      do (princ delimiter)
		 (princ (caddr encaps))
	      finally (or (eq func function)
			  (princ ")"))))
      (when show-source-file-p
	(print-function-source-file function)))
    (terpri)
    (print-frame-args frame 3 show-local-if-different)))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


;;; Show commands

;; This is how the error message is printed when the error handler starts up.
;; Give error message, context, and warnings about screwed-up environment
(defun show (&optional (show-proceed-options t) already-printed)
  (unless already-printed (terpri))
  (print-error-message (and (not already-printed) *error*) nil *show-backtrace* t)
  (unless (typep *error* 'stepper-break)
    (show-function-and-args)
    (when show-proceed-options
      (show-proceed-options)))
  (and *reason-debugger-entered*
       (format t "~& Debugger was entered because ~A" *reason-debugger-entered*))
  ;; If we interrupted PROCESS-LOCK, PROCESS-ENQUEUE, or PROCESS-WAIT waiting
  ;; for a lock, show the user what process owns the lock and what it's doing
  (let* ((curr-frame *current-frame*)
	 (curr-func (frame-function curr-frame)))
    (when (eq (function-name-for-debugger curr-frame) 'process-wait)
      (setq curr-frame (frame-previous-frame curr-frame)
	    curr-func (frame-function curr-frame)))
    (when (or (eq (function-name-for-debugger curr-frame) 'process-lock)
	      (eq (function-name-for-debugger curr-frame) 'si:process-enqueue))
      (let ((arg0 (frame-arg-value curr-frame 0))
	    (proc))
	(cond ((eq (function-name-for-debugger curr-frame) 'si:process-enqueue)
	       (setq proc (aref arg0 (si:process-queue-current-pointer arg0)))
	       (format t "~& You are waiting for a locked queue"))
	      (t
	       (setq proc (cdr arg0))
	       (format t "~& You are waiting for a lock")))
	(if (typep proc 'si:process)
	    (format t " held by process ~A, which is in state ~A.~%"
	      (process-name proc) (process-whostate proc))
	  (format t ".~%")))))
  ;; Print any useful warnings
  (or (eq base ibase)
      (format t "~& Warning: BASE is ~D. but IBASE is ~D.~%" base ibase))
  (let ((dca (symeval-in-error-environment 'default-cons-area)))
    (or (eq dca working-storage-area)
	(format t "~& Warning: The default cons area is ~A, not working-storage-area.~%"
	  (area-name dca))))
  (when (symeval-in-error-environment 'inhibit-scheduling-flag)
    (format t "~& Warning: ~INHIBIT-SCHEDULING-FLAG is set.  You are probably in the ~
	       middle of a program~@
	       that did not expect to be interrupted.  Things may be inconsistent.~~%"))
  nil)


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun show-all-compiled-7-1 (&optional show-source-file-p)
  (let* ((*printing-monitor-message* t)
	 (frame *current-frame*)
	 (function (frame-function frame)))
    (format t "~V~S~" *emphasis-character-style* (function-name-for-debugger frame))
    (when show-source-file-p
      (print-function-source-file function))
    (format t "~2%")
    ;; Print the arguments, including the rest-arg which is a local
    (let ((local-start (print-frame-args *current-frame* 1 t)))
      (cond ((frame-active-p *current-frame*)
	     ;; Print the rest of the locals, if the frame is active
	     (print-frame-locals *current-frame* local-start 1)
	     (format t "~%~VDisassembled code:~" *deemphasis-character-style*)
	     (show-all-compiled-1 frame function)
	     ;; This kludge is to prevent the prompt from triggering a **MORE**
	     ;; when it comes out on the bottom line of the window
	     (if (memq :notice (send standard-output :which-operations))
		 (send standard-output :notice :input-wait)))))))
 
(defun show-all-compiled-7-2 (&optional show-source-file-p)
  (let* ((*printing-monitor-message* t)
	 (frame *current-frame*)
	 (function (frame-function frame)))
    (format t "~V~S~" *emphasis-character-style*
	    (FUNCTION-NAME-FOR-DEBUGGER FRAME))
    ;; KRA: (lframe-function-name *current-language* function nil))
    (when show-source-file-p
      (print-function-source-file function))
    (format t "~2%")
    ;; Print the arguments, including the rest-arg which is a local
    (let ((local-start (print-frame-args *current-frame* 1 t)))
      (cond ((frame-active-p frame)
	     ;; Print the rest of the locals, if the frame is active
	     (print-frame-locals frame local-start 1)
	     (lframe-show-code-for-function *current-language* frame function
					    (lframe-show-source-code-p *current-language*)
					    :brief nil)
	     ;; This kludge is to prevent the prompt from triggering a **MORE**
	     ;; when it comes out on the bottom line of the window
	     (when (memq :notice (send standard-output :which-operations))
	       (send standard-output :notice :input-wait)))))))
 
(defun show-all-compiled (&rest args)
  (apply (if (cl:member :genera-release-7-2 cl:*features*)
	     #'show-all-compiled-7-2
	     #'show-all-compiled-7-1)
	 args))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun find-frame-internal (string &optional exact reverse-p skip-invisible)
  (flet ((move-frame (frame)
	   (loop for f = (if reverse-p
			     (frame-next-open-frame frame)
			   (frame-previous-open-frame frame))
		       then (if reverse-p
				(frame-next-open-frame f)
			      (frame-previous-open-frame f))
		 until (or (not skip-invisible)
			   (not (frame-invisible-p f)))
		 finally (return f))))
    ;; STRING can really be a function or a function-spec, too
    (loop with function-to-search-for = (si:valid-function-definition string t)
	  for frame = (move-frame *current-frame*) then (move-frame frame)
	  until (null frame)
	  as frame-function = (frame-function frame)
	  when (or (and function-to-search-for
			(eq function-to-search-for frame-function))
		   (and (not exact)
			(let ((name (function-name-for-debugger frame)))
			  (string-search string (cond ((stringp name) name)
						      ((symbolp name) (string name))
						      (t (format nil "~S" name)))))))
	    do (setq *current-frame* frame)
	       (return frame)
	  finally 
	    (format t "~&Search failed.~%")
	    (return nil))))



;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


;; Print only the names of the functions, as many per line as will fit.
(defun short-backtrace (&optional (n 10000.) internal-flag continuations)
  (send standard-output :fresh-line)
  (if (null continuations)
      (scl:filling-output (t :fill-on-spaces nil)
	(let ((printed-something nil)
	      (pending-parents nil))
	  (print-backtrace n 0 internal-flag
	    (lambda (frame index)
	      (let* ((function (function-name-for-debugger frame))
		     (continued (memq function pending-parents))
		     ;; The parent can either be the nominal function-parent
		     ;; for this function, or whatever function owns this
		     ;; :INTERNAL function
		     (parent (if (and (listp function)
				      (eq (first function) ':internal))
				 (second function)
			       (multiple-value-bind (fspec type)
				   (function-parent function)
				 (and (eq type 'defun) fspec)))))
		(when continued
		  ;; If we have just printed a pending parent, remove it
		  ;; from the list
		  (setq pending-parents (delq function pending-parents)))
		(if (and parent
			 (loop for i from index below n
			       for fr = frame then (frame-previous-frame fr) while fr
			       as fr-name = (function-name-for-debugger fr) 
			       when (equal fr-name parent)
				 do (setq parent fr-name)
				    (return t)))
		    ;; If this function has a parent which will eventually get
		    ;; printed, save it away for later
		    (push parent pending-parents)
		  ;; Here is where we can print something, finally
		  (when printed-something
		    (send standard-output :conditional-string-out " ")
		    (cl:write-char (if continued #\ #\))
		    (cl:write-char #\space))
		  (present-stack-frame frame)
		  (setq printed-something t)))))))
    ;;--- When DW filling-streams are faster, always use them
    ;;--- Perhaps a "flatsize" stream would be a useful addition to DW?
    (let ((current-font (send-if-handles debug-io :current-font)))
      (if (or (null current-font)		;watch out for cold-load stream
	      (null (tv:font-char-width-table current-font)))
	  ;; I know that this is not in the new idiom, but it's up to 50% faster than
	  ;; the version below for fixed-width fonts
	  (let* ((line-length (or (send-if-handles standard-output :size-in-characters) 95.))
		 (chars-left line-length))
	    (print-backtrace n 0 internal-flag
	      (lambda (frame count)
		(let* ((name (function-name-for-debugger frame))
		       (name-length (+ (if (plusp count) 3 0) (flatsize name))))
		  (when (and (> name-length chars-left)
			     ( name-length line-length))
		    (terpri)
		    (setq chars-left line-length))
		  (when (plusp count) (princ "  "))
		  (present-stack-frame frame)
		  (decf chars-left name-length)))))
	;; For variable-width fonts, use the slow (but more elegant) implementation
	(formatting-textual-list (t :separator "  "
				    :filled :before
				    :after-line-break " ")
	  (print-backtrace n 0 internal-flag
	    (lambda (frame ignore)
	      (formatting-textual-list-element ()
		(present-stack-frame frame)))))))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defun print-backtrace (n skip internal-flag frame-printer-function)
  (macrolet ((move-frame (frame)
	       `(if internal-flag
		    (frame-previous-active-frame ,frame)
		  (frame-previous-interesting-active-frame ,frame))))
    (loop with cl:*print-pretty* = nil		;two things filling is too many
	  for frame = *current-frame* then (move-frame frame)
	  for i upfrom (- skip) below n
	  until (null frame)
	  do (unless (minusp i)
	       ;; In backtraces, always censor uninteresting frames, no
	       ;; matter what c-N or c-P will do
	       (when (or internal-flag
			 (frame-interesting-p frame))
		 (funcall frame-printer-function frame i))))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(define-presentation-to-command-translator edit-frame-function
   (stack-frame
    :tester ((frame &rest ignore)
	     ;; Don't accept stale stack frames
	     (let ((error (cdr frame)))
	       (and (variable-boundp *error*)
		    (eq error *error*)
		    (neq (condition-status error)
			 :signalled))))
     :documentation "Edit this frame's function"
     :gesture :edit-function)
   (frame)
  `(com-edit-function ,(function-name-for-debugger (car frame))))



;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(cp:define-command (com-return :command-table "Debugger"
			       :provide-output-destination-keyword nil)
		   ()
  (cond ((not (frame-active-p *current-frame*))
	 (princ "~&This frame has not yet been activated; you cannot return from it"))
	((null (frame-previous-active-frame *current-frame*))
	 (princ "~&This is the bottom frame; you cannot return from it"))
	(t
	 (let* ((name (function-name-for-debugger *current-frame*))
		(values (multiple-value-bind (type maxvals)
			    (frame-real-value-disposition *current-frame*)
			  (selectq type
			    (:ignore
			     (format t "~&The caller is not interested in any values")
			     (or (fquery nil "Return from ~S? " name)
				 (throw 'quit t))
			     nil)
			    (:single
			     (format t "~&Return a value from the function ~S.~%" name)
			     (list (read-and-verify-expression t nil nil
							       "New value to return")))
			    (:multiple
			     ;; If multiple-value-list, allow specification of as many as
			     ;; wanted.
			     (format t (if maxvals
					   "~&The caller expects ~R values"
					 "~&The caller expects any number of values")
			       maxvals)
			     (if (eql maxvals 0)
				 (fquery nil "Return from ~S? " name)
			       (multiple-value-bind (nil values-names)
				   (let ((function (frame-function *current-frame*)))
				     (and (legitimate-function-p function)
					  (arglist function)))
				 (accumulate-multiple-return-values
				   "~&Enter values, ending with �"
				   "Value #~S~@[ (~A)~]" maxvals values-names))))))))
	   (return-from-frame *current-frame* values)))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


;;; Other informational commands.

(cp:define-command (com-show-arglist :command-table "Debugger"
				     :provide-output-destination-keyword nil)
		   ()
  (let* ((function (frame-function *current-frame*))
	 (arglist (arglist function)))
    (format t "~&The argument list for ~S is ~S" (function-name-for-debugger *current-frame*) arglist)))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(cp:define-command (com-edit-function :command-table "Global"
				      :provide-output-destination-keyword nil
				      :explicit-arglist
				        (&optional (function nil function-supplied-p)))
		   ((function 'stack-frame-or-function-spec
			      :default
			        (if (variable-boundp *current-frame*)
				    (function-name-for-debugger *current-frame*))))
  (let* ((function (if function-supplied-p
		       function
		     (and (variable-boundp *current-frame*)
			  (function-name-for-debugger *current-frame*)))))
    (cond ((presentation-frame-p function)
	   (setq function (function-name-for-debugger (car function))))
	  ((and (listp function) (memq (car function) flavor::*accessor-method-types*))
	   (format t "~&The accessor for ~S is defined by the flavor ~S"
		   (flavor::accessor-instance-variable function)
		   (flavor:method-flavor function))
	   (return-from com-edit-function
	     (ed `(zwei:edit-definition ,(flavor:method-flavor function) (defflavor))))))
    (let* ((real-function (si:valid-function-definition function t))
	   (function (and real-function (function-name function))))
      (if (typep real-function :compiled-function)
	  (multiple-value-bind (bp definition-type)
	      (and (not function-supplied-p)
		   (variable-boundp *current-frame*)
		   (frame-exit-source-locator-bp *current-frame*))
	    (if bp
		(ed `(zwei:function-at-bp ,function ,bp ,definition-type))
	      (ed function)))
	(if (null function)
	    (format t "~&There is no function for this frame")
	  (ed function))))))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(cp:define-command (com-show-source-code :command-table "Global"
					 :provide-output-destination-keyword nil
					 :explicit-arglist
					   (&optional (function nil function-supplied-p)))
		   ((function 'compiled-function-spec
			      :default
			        (if (variable-boundp *current-frame*)
				    (function-name-for-debugger *current-frame*)
				  nil)))
  (let* ((function (if function-supplied-p
		       function (function-name-for-debugger *current-frame*)))
	 (frame (if function-supplied-p nil *current-frame*)))
    (show-frame-source frame function)))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defmethod (:bug-report-recipient-system condition) ()
  (loop for frame = *innermost-interesting-frame*
		  then (frame-previous-frame frame)
	until (null frame)
	as function = (function-name-for-debugger frame)
	as bug-report = (or (assq 'bug-report-recipient-system (debugging-info function))
			    (assq function *function-bug-report-alist*))
	do (when bug-report
	     (return (cdr bug-report)))
	finally (return *default-bug-report-recipient-system*)))


;=====================================
(SYSTEM-INTERNALS:BEGIN-PATCH-SECTION)
; From buffer debugger.lisp >rel-7>debugger BD: (552)
(SYSTEM-INTERNALS:PATCH-SECTION-ATTRIBUTES
  "-*- Mode: LISP; Package: Debugger; Base: 8; Lowercase: Yes -*-")


(defmethod (:bug-report-description condition) (standard-output n-frames)
  (let ((*error* self)				;need this to print backtraces
	(current-frame *current-frame*))
    ;; Encourage users to include complete information in their bug reports
    (when (%pointer-lessp current-frame *innermost-interesting-frame*)
      (when (fquery () "The current frame, for ~S, is in the middle of the stack.~@
			Do you want the stack trace in your bug report to start at ~
			the top of the stack,~%at the frame for ~S, instead? "
		    (function-name-for-debugger current-frame)
		    (function-name-for-debugger *innermost-interesting-frame*))
	(setq current-frame *innermost-interesting-frame*)))
    ;; N-FRAMES could be an actual frame!
    (when (presentation-frame-p n-frames)
      (setq n-frames (1+ (loop for frame = current-frame then (frame-previous-frame frame)
			       until (or (null frame) (eq frame (car n-frames)))
			       count 1))))
    (let* ((total-frames (loop for frame = current-frame
					 then (frame-previous-active-frame frame)
			       until (null frame)
			       count t)))
      ;; NFRAMES = NIL  all frames, NFRAMES = T  ask
      (cond ((null n-frames)
	     (setq n-frames total-frames))
	    ((not (numberp n-frames))
	     (setq n-frames *default-backtrace-depth*)
	     (when
	       (and (> total-frames n-frames)
		    (fquery ()
			    "There are a total of ~D frames in the stack.  By default only~@
			    information for the top ~D frames is included.  Would you prefer~@
			    to include detailed information for every frame instead? "
			    total-frames n-frames))
	       (setq n-frames total-frames)))))
    (let ((*error-message-prinlevel* *bug-report-prinlevel*)
	  (*error-message-prinlength* *bug-report-prinlength*)
	  (*current-frame* current-frame)
	  (*censor-invisible-frames* nil))
      (terpri)
      (print-error-message self nil t t)
      (let ((package (symeval-globally 'package)))
	(format t "~%The condition signalled was ~S~%" (typep self)))
      (let ((tc (symeval-in-error-environment 'trace-conditions
					      *innermost-interesting-frame*)))
	(when tc
	  (format t "TRACE-CONDITIONS was set to ~S~%" tc)))
      (let ((interesting-specials (find-all-special-usages
				    (frame-function current-frame)))
	    (prinlevel *error-message-prinlevel*)
	    (prinlength *error-message-prinlength*))
	;; Print the backtrace, including "interesting" specials at the point
	;; where they were last bound
	(print-backtrace n-frames 0 nil
			 (lambda (frame i)
			   (let ((local-start (print-function-and-args frame t t t)))
			     (when (and (zerop i)
					(frame-active-p frame))
			       (print-frame-locals frame local-start 3))
			     (let ((frame-bindings (collect-frame-bindings frame)))
			       (loop for (sym val unbound-p) in frame-bindings
				     do (when (memq sym interesting-specials)
					  (format t "   Special ~S: ~S~%"
					    sym (if unbound-p "unbound" val))
					  (setq interesting-specials
						(delq sym interesting-specials))))))))
	;; If there are any more "interesting" specials (which have global
	;; values but are not otherwise bound), display them
	(when interesting-specials
	  (terpri)
	  (loop for spec in interesting-specials
		do (format t "   Special ~S: ~S~%"
		     spec (if (boundp spec) (symeval spec) "unbound")))))
      (multiple-value-bind (*current-frame* more-stack)
	  (frame-next-nth-interesting-active-frame current-frame (- n-frames))
	(when more-stack
	  (format t "~2&~VRest of stack:~" *deemphasis-character-style*)
	  (print-backtrace 10000. 0 nil
			   (lambda (frame ignore)
			     (let ((prinlevel *function-prinlevel*)
				   (prinlength *function-prinlength*)
				   (function (frame-function frame)))
			       (print-carefully "function name"
				 (terpri)
				 (and (closurep function)
				      (princ "Closure of "))
				 (format t "~V~S~:"
				   *emphasis-character-style* (function-name function))
				 (when (typep function :compiled-function)
				   (let ((pc-now (frame-relative-exit-pc frame)))
				     (if pc-now (format t "  (P.C. = ~O)" pc-now))))
				 (with-character-style (*deemphasis-character-style*)
				   (print-function-source-file function)))))))))))


