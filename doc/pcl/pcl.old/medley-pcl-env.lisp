(DEFINE-FILE-INFO PACKAGE "PCL" READTABLE "XCL")
(il:filecreated " 5-Aug-88 13:31:13" il:{pooh/n}<pooh>pcl>medley-pcl-env\;2 86489  

      il:|changes| il:|to:|  (il:functions interesting-frame-p)

      il:|previous| il:|date:| " 5-Aug-88 12:51:51" il:{pooh/n}<pooh>pcl>medley-pcl-env\;1)


; Copyright (c) 1988 by Xerox Corporation.  All rights reserved.

(il:prettycomprint il:medley-pcl-envcoms)

(il:rpaqq il:medley-pcl-envcoms
          (

(il:* il:|;;;| "***************************************")

           

(il:* il:|;;;| " Copyright (c) 1987, 1988, by Xerox Corporation.  All rights reserved.")

           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Use and copying of this software and preparation of derivative works based upon this software are permitted.  Any distribution of this software or derivative works must comply with all applicable United States export control laws.")

           

(il:* il:|;;;| " ")

           

(il:* il:|;;;| "This software is made available AS IS, and Xerox Corporation makes no  warranty about the software, its performance or its conformity to any  specification.")

           

(il:* il:|;;;| " ")

           

(il:* il:|;;;| "Any person obtaining a copy of this software is requested to send their name and post office or electronic mail address to:")

           

(il:* il:|;;;| "   CommonLoops Coordinator")

           

(il:* il:|;;;| "   Xerox Artifical Intelligence Systems")

           

(il:* il:|;;;| "   2400 Hanover St.")

           

(il:* il:|;;;| "   Palo Alto, CA 94303")

           

(il:* il:|;;;| "(or send Arpanet mail to CommonLoops-Coordinator.pa@Xerox.com)")

           

(il:* il:|;;;| "")

           

(il:* il:|;;;| " Suggestions, comments and requests for improvements are also welcome.")

           

(il:* il:|;;;| " *************************************************************************")

           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Protect the Corporation")

           

(il:* il:|;;;| "")

           (il:declare\: il:dontcopy il:donteval@compile (il:prop il:makefile-environment il:pcl-env)
                  )
           (il:p (eval-when (load)
                        (format *terminal-io* 
                 "~&;PCL-ENV Copyright (c) 1987, 1988, by Xerox Corporation.  All rights reserved.~%"
                               )))
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Make funcallable instances (FINs) print by calling print-object.")

           

(il:* il:|;;;| "")

           (il:p (eval-when (eval load)
                        (il:defprint 'il:compiled-closure 'il:print-closure)))
           (il:functions il:print-closure)
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Naming methods")

           

(il:* il:|;;;| "")

           (il:functions generic-function-method-names full-method-name make-full-method-name 
                  parse-full-method-name)
           (il:functions prompt-for-full-method-name)
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Converting generic defining macros into DEFDEFINER macros")

           

(il:* il:|;;;| "")

           (il:functions make-defdefiner unmake-defdefiner)
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "For tricking ED into being able to use just the generic-function-name instead of the full method name")

           

(il:* il:|;;;| "")

           (il:functions source-manager-method-edit-fn source-manager-method-hasdef-fn 
                  source-manager-method-setf-edit-fn source-manager-method-setf-hasdef-fn)
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Initialize the PCL env")

           

(il:* il:|;;;| "")

           (il:functions initialize-pcl-env)
           (il:p (eval-when (eval load)
                        (initialize-pcl-env)))
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Inspecting PCL objects")

           

(il:* il:|;;;| "")

           (il:functions pcl-object-p)
           (il:functions                                     (il:* il:\; "These functions are here as an indirection between the inspector and the methods below.  You see, IL:EVAL can't handle compiled-closures (and therefor generic-functions), and the inspector code uses IL:EVAL...")
                  \\internal-inspect-object \\internal-inspect-slot-names 
                  \\internal-inspect-slot-value \\internal-inspect-setf-slot-value 
                  \\internal-inspect-slot-name-command \\internal-inspect-title)
           (methods (inspect-object nil)
                  (inspect-slot-names nil)
                  (inspect-slot-value nil)
                  (inspect-setf-slot-value nil)
                  (inspect-slot-name-command nil)
                  (inspect-title nil))
           (methods (inspect-slot-names (standard-class))
                  (inspect-title (standard-class)))
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| " Debugger support for PCL")

           

(il:* il:|;;;| "")

           (il:files pcl-env-internal)
           
           (il:* il:|;;| "")

           
           (il:* il:|;;| "Non-PCL specific changes to the debugger")

           (il:coms 

                  (il:* il:|;;| "Redefining the standard INTERESTING-FRAME-P function.  Now functions can be declared uninteresting to BT by giving them an XCL::UNINTERESTINGP property.")

                  (il:prop xcl::uninterestingp si::*unwind-protect* il:*env* evalhook xcl::nohook 
                         xcl::undohook xcl::execa0001 xcl::execa0001a0002 t xcl::|interpret-UNDOABLY|
                         cl::|interpret-LET| cl::|interpret-LETA0001| cl::|interpret-FLET| 
                         cl::|interpret-IF| cl::|interpret-BLOCK| cl::|interpret-BLOCKA0001| 
                         il:do-event il:eval-input apply)
                  (il:functions xcl::interesting-frame-p)
                  (il:vars (il:*short-backtrace-filter* 'xcl::interesting-frame-p))
                  
                  (il:* il:|;;| " Change the frame inspector to open up lexical environments")

                  (il:coms (il:records il:bkmenuitem)
                                                             (il:* il:\; "Since the DEFSTRUCT is going to build the accessors in the package that is current at read-time, and we want the accessors to reside in the IL package, we have got to make sure that the defstruct happens when the package is IL.  I guess the \"right\" way to do this is to have this stuff in a different file, but given that we want all the PCL-ENV stuff in a single file,  I'll resort to this trickery.")
                         (il:p (in-package "IL"))
                         (il:e (in-package "IL"))
                         (il:structures il:frame-prop-name)
                         (il:p (in-package "PCL"))
                         (il:e (in-package "PCL")))
                  (il:functions il:debugger-stack-frame-prop-names il:debugger-stack-frame-fetchfn 
                         il:debugger-stack-frame-storefn il:debugger-stack-frame-value-command 
                         il:debugger-stack-frame-title il:debugger-stack-frame-property)
                  
                  (il:* il:|;;| 
         "Teaching the debugger that there are other file-manager types that can appear on the stack")

                  (il:variables xcl::*function-types*)
                  
                  (il:* il:|;;| "Redefine a couple of system functions to use the above stuff")

                  (il:functions dbg::attach-backtrace-menu dbg::collect-backtrace-items 
                         dbg::backtrace-menu-buttoneventfn)
                  (il:fns il:select.fns.editor))
           
           (il:* il:|;;| "")

           
           (il:* il:|;;| "PCL specific extensions to the debugger")

           (il:coms 

                  (il:* il:|;;| "There are some new things that act as functions, and that we want to be able to edit from a backtrace window")

                  (il:addvars (xcl::*function-types* methods method-setfs))
                  (il:p (eval-when (eval load)
                               (unless (generic-function-p (symbol-function 'il:inspect/as/function))
                                   (make-specializable 'il:inspect/as/function))))
                  (methods (il:inspect/as/function nil)
                         (il:inspect/as/function (object))
                         (il:inspect/as/function (standard-method)))
                  
                  (il:* il:|;;| "A replacement for the vanilla IL:INTERESTING-FRAME-P so we can see methods and generic-functions on the stack.")

                  (il:functions interesting-frame-p)
                  (il:vars (il:*short-backtrace-filter* 'interesting-frame-p)))
           

(il:* il:|;;;| "")

           

(il:* il:|;;;| "Support for ?= and friends")

           

(il:* il:|;;;| "")

           (il:prop il:argnames defclass defgeneric-options defgeneric-options-setf 
                  define-method-combination defmethod defmethod-setf multiple-value-prog2 with-slots
                  with-accessors)
           (il:fns il:smartarglist)))



(il:* il:|;;;| "***************************************")




(il:* il:|;;;| " Copyright (c) 1987, 1988, by Xerox Corporation.  All rights reserved.")




(il:* il:|;;;| "")




(il:* il:|;;;| 
"Use and copying of this software and preparation of derivative works based upon this software are permitted.  Any distribution of this software or derivative works must comply with all applicable United States export control laws."
)




(il:* il:|;;;| " ")




(il:* il:|;;;| 
"This software is made available AS IS, and Xerox Corporation makes no  warranty about the software, its performance or its conformity to any  specification."
)




(il:* il:|;;;| " ")




(il:* il:|;;;| 
"Any person obtaining a copy of this software is requested to send their name and post office or electronic mail address to:"
)




(il:* il:|;;;| "   CommonLoops Coordinator")




(il:* il:|;;;| "   Xerox Artifical Intelligence Systems")




(il:* il:|;;;| "   2400 Hanover St.")




(il:* il:|;;;| "   Palo Alto, CA 94303")




(il:* il:|;;;| "(or send Arpanet mail to CommonLoops-Coordinator.pa@Xerox.com)")




(il:* il:|;;;| "")




(il:* il:|;;;| " Suggestions, comments and requests for improvements are also welcome.")




(il:* il:|;;;| " *************************************************************************")




(il:* il:|;;;| "")




(il:* il:|;;;| "Protect the Corporation")




(il:* il:|;;;| "")

(il:declare\: il:dontcopy il:donteval@compile 

(il:putprops il:pcl-env il:makefile-environment (:package "PCL" :readtable "XCL"))
)

(eval-when (load)
       (format *terminal-io* 
              "~&;PCL-ENV Copyright (c) 1987, 1988, by Xerox Corporation.  All rights reserved.~%"))



(il:* il:|;;;| "")




(il:* il:|;;;| "Make funcallable instances (FINs) print by calling print-object.")




(il:* il:|;;;| "")


(eval-when (eval load)
       (il:defprint 'il:compiled-closure 'il:print-closure))

(defun il:print-closure (x &optional stream depth)

   (il:* il:|;;| "See the IRM, section 25.3.3.  Unfortunatly, that documentation is not correct; in particular, it makes no mention of the third argument.")

   (cond
      ((not (funcallable-instance-p x))

       (il:* il:|;;| "IL:\\CCLOSURE.DEFPRINT is the orginal system function for printing closures")

       (il:\\cclosure.defprint x stream))
      ((streamp stream)

       (il:* il:|;;| "Use the standard PCL printing method, then return T to tell the printer that we have done the printing ourselves.")

       (print-object x stream)
       t)
      (t 
         (il:* il:|;;| "Internal printing (again, see the IRM section 25.3.3).  Return a list containing the string of characters that would be printed, if the object were being printed for real.")

         (with-output-to-string (stream)
                (list (print-object x stream))))))



(il:* il:|;;;| "")




(il:* il:|;;;| "Naming methods")




(il:* il:|;;;| "")


(defun generic-function-method-names (symbol setfp)
   (let* ((spec (if setfp
                    `(setf ,symbol)
                    symbol))
          (gf (and (gboundp spec)
                   (gdefinition spec))))
         (when gf
             (mapcar #'(lambda (m)
                              (full-method-name m (when setfp symbol)))
                    (generic-function-methods gf)))))

(defun full-method-name (method setfp)
   "Return the full name of the method"
   (let ((specializers (mapcar #'(lambda (x)
                                        (if (eq x 't)
                                            't
                                            (class-name x)))
                              (method-type-specifiers method))))

        (il:* il:|;;| "Now go through some hair to make sure that specializer is really right.  Once PCL returns the right value for specializers this can be taken out.")

        (let* ((arglist (method-arglist method))
               (number-required (or (position-if #'(lambda (x)
                                                          (member x lambda-list-keywords))
                                           arglist)
                                    (length arglist)))
               (diff (- number-required (length specializers))))
              (when (> diff 0)
                  (setq specializers (nconc (copy-list specializers)
                                            (make-list diff :initial-element 't)))))
        (if setfp
            (make-full-method-name setfp (method-qualifiers method)
                   (butlast specializers)
                   (last specializers))
            (make-full-method-name (generic-function-name (method-generic-function method))
                   (method-qualifiers method)
                   specializers))))

(defun make-full-method-name (generic-function-name qualifiers arg-types &optional (setf-arg-types
                                                                                    nil setfp))
   "Return the full name of a method, given the generic-function name, the method qualifiers, and the arg-types"

   (il:* il:|;;| "The name of the method is:")

   (il:* il:|;;| "     (<generic-function-name> <qualifier-1> ..  <arg-specializer-1>..)")

   (labels ((remove-trailing-ts (l)
                   (if (null l)
                       nil
                       (let ((tail (remove-trailing-ts (cdr l))))
                            (if (null tail)
                                (if (eq (car l)
                                        't)
                                    nil
                                    (list (car l)))
                                (if (eq l tail)
                                    l
                                    (cons (car l)
                                          tail)))))))
          (setq arg-types (remove-trailing-ts arg-types))
          (setq setf-arg-types (remove-trailing-ts setf-arg-types))
          (if setfp
              `(,generic-function-name ,@qualifiers ,arg-types ,setf-arg-types)
              `(,generic-function-name ,@qualifiers ,arg-types))))

(defun parse-full-method-name (method-name)
   "Parse the method name, returning the gf-name, the qualifiers, and the arg-types, the setf-arg-types, and a flag indicating whether or nit it is a setf-method."
   (let ((gf-name (first method-name))
         (qualifiers nil)
         arg-types
         (setf-arg-types nil)
         (setf-method-p nil))
        (do ((tail (rest method-name)
                   (rest tail)))
            ((null tail)

             (il:* il:|;;| "Bogus name, so return NIL")

             nil)
          (when (listp (first tail))
              (setq arg-types (first tail))
              (setq qualifiers (nreverse qualifiers))
              (unless (null (rest tail))
                  (setq setf-arg-types (second tail))
                  (setq setf-method-p t)
                  (unless (null (rest (rest tail)))
                         (return nil)))
              (return (values gf-name qualifiers arg-types setf-arg-types setf-arg-types 
                             setf-method-p)))
          (push (first tail)
                qualifiers))))

(defun prompt-for-full-method-name (generic-function-name setfp &optional has-def-p)
   "Prompt the user for the full name of a method on the given generic function name"
   (let
    ((method-names (generic-function-method-names generic-function-name setfp)))
    (cond
       ((null method-names)
        nil)
       ((null (cdr method-names))
        (car method-names))
       (t (il:menu
           (il:create il:menu
                  il:items il:�                              (il:* il:\; 
               "If HAS-DEF-P, include only those methods that have a symbolic def'n that we can find")
                  (remove-if #'null
                         (mapcar #'(lambda (m)
                                          (if (or (not has-def-p)
                                                  (il:hasdef m (if setfp
                                                                   'method-setfs
                                                                   'methods)))
                                              `(,(with-output-to-string (s)
                                                        (dolist (x m)
                                                            (format s "~A " x))
                                                        s)
                                                ',m)
                                              nil))
                                method-names))
                  il:title il:� "Which method?"))))))



(il:* il:|;;;| "")




(il:* il:|;;;| "Converting generic defining macros into DEFDEFINER macros")




(il:* il:|;;;| "")


(defmacro make-defdefiner (definer-name definer-type type-description &body definer-options)
   "Make the DEFINER-NAME use DEFDEFINER, defining items of type DEFINER-TYPE"
   (let ((old-definer-macro-name (intern (string-append definer-name " old definition")
                                        (symbol-package definer-name)))
         (old-definer-macro-expander (intern (string-append definer-name " old expander")
                                            (symbol-package definer-name))))
        `(progn 
                (il:* il:|;;| "First, move the current defining function off to some safe place")

                (unmake-defdefiner ',definer-name)
                (cond
                   ((not (fboundp ',definer-name))
                    (error "~A has no definition!" ',definer-name))
                   ((fboundp ',old-definer-macro-name))
                   ((macro-function ',definer-name)          (il:* il:\; "We have to move the macro expansion function as well, so it won't get clobbered when the original macro is redefined.  See AR 7410.")
                    (let* ((expansion-function (macro-function ',definer-name)))
                          (setf (symbol-function ',old-definer-macro-expander)
                                (loop (if (symbolp expansion-function)
                                          (setq expansion-function (symbol-function 
                                                                          expansion-function))
                                          (return expansion-function))))
                          (setf (macro-function ',old-definer-macro-name)
                                ',old-definer-macro-expander)
                          (setf (get ',definer-name 'make-defdefiner)
                                expansion-function)))
                   (t (error "~A does not name a macro." ',definer-name)))

                (il:* il:|;;| "Make sure the type is defined")

                (xcl:def-define-type ,definer-type ,type-description)

                (il:* il:|;;| "Now redefine the definer, using DEFEDFINER and the original def'n")

                (xcl:defdefiner ,(if definer-options
                                     (cons definer-name definer-options)
                                     definer-name) ,definer-type (&body b)
                   `(,',old-definer-macro-name ,@,'b)))))

(defun unmake-defdefiner (definer-name)
   (let ((old-expander (get definer-name 'make-defdefiner)))
        (when old-expander
            (setf (macro-function definer-name old-expander))
            (remprop definer-name 'make-defdefiner))))



(il:* il:|;;;| "")




(il:* il:|;;;| 
"For tricking ED into being able to use just the generic-function-name instead of the full method name"
)




(il:* il:|;;;| "")


(defun source-manager-method-edit-fn (name type source editcoms options)
   "Edit a method of the given name"
   (let ((full-name (if (symbolp name)                       (il:* il:\; 
                 "If given a symbol, it names a generic function, so try to get the full method name")
                        (prompt-for-full-method-name name nil t)
                                                             (il:* il:\; 
                                                             "Otherwise it should name the method")
                        name)))
        (when (not (null full-name))
              (il:default.editdef full-name type source editcoms options))
                                                             (il:* il:\; "Return the name")
        (or full-name name)))

(defun source-manager-method-hasdef-fn (name type &optional source)
   "Is there a method defined with the given name?"
   (typecase name
       (symbol 

          (il:* il:|;;| "If passed in a symbol, pretend that there is a method by that name if there is a generic function by that name, and there is a method whose source we can find.")

          (and (fboundp name)
               (generic-function-p (symbol-function name))
               (find-if #'(lambda (m)
                                 (il:hasdef m type source))
                      (generic-function-method-names name nil))
               name))
       (list 

          (il:* il:|;;| "Standard methods are named (gf-name {qualifiers}* ({specializers}*))")

          (when (and (>= (length name)
                         2)
                     (do ((x name (rest x)))
                         ((null (rest x))
                          (listp (first x)))
                       (if (not (symbolp (first x)))
                           (return nil)))
                     (il:getdef name type source '(il:nocopy il:noerror)))
                name))
       (t 
          (il:* il:|;;| "Nothing else can name a method")

          nil)))

(defun source-manager-method-setf-edit-fn (name type source editcoms options)
   "Edit a method-setf of the given name"
   (let ((full-name (if (symbolp name)                       (il:* il:\; 
                 "If given a symbol, it names a generic function, so try to get the full method name")
                        (prompt-for-full-method-name name t t)
                                                             (il:* il:\; 
                                                             "Otherwise it should name the method")
                        name)))
        (when (not (null full-name))
              (il:default.editdef full-name type source editcoms options))
                                                             (il:* il:\; "Return the name")
        (or full-name name)))

(defun source-manager-method-setf-hasdef-fn (name type source)
   (typecase name
       (symbol 

          (il:* il:|;;| "If passed in a symbol, pretend that there is a method by that name if there is a generic function by that name")

          (let ((spec `(setf ,name)))
               (and (gboundp spec)
                    (gdefinition spec)
                    (find-if #'(lambda (m)
                                      (il:hasdef m type source))
                           (generic-function-method-names name t))
                    name)))
       (list 

          (il:* il:|;;| 
        "Standard setf-methods are named (gf-name {qualifiers}* ({specializers}*) ({specializers}*))")

          (when (and (>= (length name)
                         3)
                     (do ((x name (rest x)))
                         ((null (cddr x))
                          (and (listp (first x))
                               (listp (second x))))
                       (if (not (symbolp (first x)))
                           (return nil)))
                     (il:getdef name type source '(il:nocopy il:noerror)))
                name))
       (t 
          (il:* il:|;;| "Nothing else can name a method")

          nil)))



(il:* il:|;;;| "")




(il:* il:|;;;| "Initialize the PCL env")




(il:* il:|;;;| "")


(defun initialize-pcl-env ()
   "Initialize the Xerox PCL environment"

   (il:* il:|;;| "Set up SourceManager DEFDEFINERS for classes and methods.")

   (il:* il:|;;| "Make sure to define methods before classes, so that (IL:FILES?) will build filecoms that have classes before methods. ")

   (unless (il:hasdef 'methods 'il:filepkgtype)
       (make-defdefiner defmethod methods "methods" (:name (lambda (form)
                                                                  (multiple-value-bind
                                                                   (name qualifiers arglist)
                                                                   (parse-defmethod (cdr form))
                                                                   (make-full-method-name
                                                                    name qualifiers (
                                                                 specialized-lambda-list-specializers
                                                                                     arglist)))))
              (:undefiner (lambda (method-name)
                                 (multiple-value-bind
                                  (name qualifiers arg-types)
                                  (parse-full-method-name method-name)
                                  (when (and (symbolp name)
                                             (fboundp name))
                                      (let* ((gf (symbol-function name))
                                             (method (when (generic-function-p gf)
                                                         (get-method gf qualifiers
                                                                (mapcar #'find-class arg-types)))))
                                            (when method (remove-method gf method)))))))))
   (unless (il:hasdef 'method-setfs 'il:filepkgtype)
       (make-defdefiner defmethod-setf method-setfs "method setfs"
              (:name (lambda (form)
                            (multiple-value-bind (name qualifiers arglist setf-arglist)
                                   (parse-defmethod (cdr form)
                                          t)
                                   (make-full-method-name name qualifiers (
                                                                 specialized-lambda-list-specializers
                                                                           arglist)
                                          (specialized-lambda-list-specializers setf-arglist))))))

       (il:* il:|;;| "METHOD-SETFS \"include\" SETFs")

       (il:filepkgcom 'method-setfs 'il:contents #'(lambda (com name type &optional reason)
                                                          (declare (ignore name reason))
                                                          (if (member type '(il:setfs method-setfs)
                                                                     :test
                                                                     #'eq)
                                                              (cdr com)
                                                              nil))))
   (unless (il:hasdef 'classes 'il:filepkgtype)
       (make-defdefiner defclass classes "class definitions" (:undefiner
                                                              (lambda (name)
                                                                     (when (find-class name t)
                                                                         (setf (find-class name)
                                                                               nil)))))

       (il:* il:|;;| "CLASSES \"include\" TYPES.")

       (il:filepkgcom 'classes 'il:contents #'(lambda (com name type &optional reason)
                                                     (declare (ignore name reason))
                                                     (if (member type '(il:types classes)
                                                                :test
                                                                #'eq)
                                                         (cdr com)
                                                         nil))))

   (il:* il:|;;| "Set up the hooks so that ED can be handed the name of a generic function, and end up editing a method instead")

   (il:filepkgtype 'methods 'il:editdef 'source-manager-method-edit-fn 'il:hasdef 
          'source-manager-method-hasdef-fn)
   (il:filepkgtype 'method-setfs 'il:editdef 'source-manager-method-setf-edit-fn 'il:hasdef
          'source-manager-method-setf-hasdef-fn)

   (il:* il:|;;| "Set up the inspect macro.  The right way to do this is to (MAKE-SPECIALIZEABLE 'IL:INSPECT), but for now...")

   (push '((il:function pcl-object-p) . \\internal-inspect-object)
         il:inspectmacros)

   (il:* il:|;;| "Unmark any SourceManager changes caused by the loadup")

   (dolist (com (il:filepkgchanges))
       (dolist (name (cdr com))
           (when (and (symbolp name)
                      (eq (symbol-package name)
                          (find-package "PCL")))
               (il:unmarkaschanged name (car com))))))

(eval-when (eval load)
       (initialize-pcl-env))



(il:* il:|;;;| "")




(il:* il:|;;;| "Inspecting PCL objects")




(il:* il:|;;;| "")


(defun pcl-object-p (x)
   "Is the datum a PCL object?"
   (or (iwmc-class-p x)
       (funcallable-instance-p x)))

(defun \\internal-inspect-object (x type where)
   (inspect-object x type where))

(defun \\internal-inspect-slot-names (x)
   (inspect-slot-names x))

(defun \\internal-inspect-slot-value (x slot-name)
   (inspect-slot-value x slot-name))

(defun \\internal-inspect-setf-slot-value (x slot-name value)
   (inspect-setf-slot-value x slot-name value))

(defun \\internal-inspect-slot-name-command (slot-name x window)
   (inspect-slot-name-command slot-name x window))

(defun \\internal-inspect-title (x y)
   (inspect-title x y))

(defmethod
   inspect-object
   (x type where)
   "Open an insect window on the object x"
   (il:inspectw.create x '\\internal-inspect-slot-names '\\internal-inspect-slot-value 
          '\\internal-inspect-setf-slot-value '\\internal-inspect-slot-name-command nil nil
          '\\internal-inspect-title nil where #'(lambda (n v)
                                                       (declare (ignore v))
                                                       n)    (il:* il:\; 
                                               "same effect as NIL but avoids bug in INSPECTW.CREATE")
          ))

(defmethod
   inspect-slot-names
   (x)
   "Return a list of names of slots of the object that should be shown in the inspector"
   (let ((slot-names nil))
        (do ((slot (all-slots x)
                   (cddr slot)))
            ((null slot)                                     (il:* il:\; 
               "Reverse the list, so the slots show up in the same order as they occur in the object")
             (nreverse slot-names))
          (push (car slot)
                slot-names))))

(defmethod
   inspect-slot-value
   (x slot-name)
   (slot-value x slot-name))

(defmethod
   inspect-setf-slot-value
   (x slot-name value)
   "Used by the inspector to set the value fo a slot"

   (il:* il:|;;| "Make this UNDO-able")

   (il:undosave `(inspect-setf-slot-value ,x ,slot-name ,(slot-value x slot-name)))

   (il:* il:|;;| "Then change the value")

   (setf (slot-value x slot-name)
         value))

(defmethod
   inspect-slot-name-command
   (slot-name x window)
   "Allows the user to select a menu item to change a slot value in an inspect window"

   (il:* il:|;;| "This code is a very slightly hacked version of the system function DEFAULT.INSPECTW.PROPCOMMANDFN.  We have to do this because the standard version makes some nasty assumptions about structure-objects that are not true for PCL objects.")

   (declare (special il:|SetPropertyMenu|))
   (case (il:menu (cond
                     ((typep il:|SetPropertyMenu| 'il:menu)
                      il:|SetPropertyMenu|)
                     (t (il:setq il:|SetPropertyMenu| (il:|create| il:menu
                                                             il:items il:�
                                                             '((set 'set 
                                                                   "Allows a new value to be entered"
                                                                    )))))))
       (set 

          (il:* il:|;;| "The user want to set the value")

          (il:ersetq (prog ((il:oldvalueitem (il:itemofpropertyvalue slot-name window))
                            il:newvalue il:pwindow)
                           (il:ttydisplaystream (il:setq il:pwindow (il:getpromptwindow window 3)))
                           (il:clearbuf t t)
                           (il:resetlst
                               (il:resetsave (il:\\itemw.flipitem il:oldvalueitem window)
                                      (list 'il:\\itemw.flipitem il:oldvalueitem window))
                               (il:resetsave (il:tty.process (il:this.process)))
                               (il:resetsave (il:printlevel 4 3))
                               (il:|printout| t "Enter the new " slot-name " for " x t 
                                      "The expression read will be EVALuated." t "> ")
                               (il:setq il:newvalue (il:lispx (il:lispxread t t)
                                                           '>))
                                                             (il:* il:\; 
                                              "clear tty buffer because it sometimes has stuff left.")
                               (il:clearbuf t t))
                           (il:closew il:pwindow)
                           (return (il:inspectw.replace window slot-name il:newvalue)))))))

(defmethod
   inspect-title
   (x window)
   "Return the title to use in an inspect window viewing x"
   (format nil "Inspecting a ~A" (class-name (class-of x))))

(defmethod
   inspect-slot-names
   ((x standard-class))
   "Return only those slots that the user should really see"
   (call-next-method))

(defmethod
   inspect-title
   ((x standard-class)
    window)
   (format nil "Inspecting the class ~A" (class-name x)))



(il:* il:|;;;| "")




(il:* il:|;;;| " Debugger support for PCL")




(il:* il:|;;;| "")


(il:filesload pcl-env-internal)



(il:* il:|;;| "")




(il:* il:|;;| "Non-PCL specific changes to the debugger")




(il:* il:|;;| 
"Redefining the standard INTERESTING-FRAME-P function.  Now functions can be declared uninteresting to BT by giving them an XCL::UNINTERESTINGP property."
)


(il:putprops si::*unwind-protect* xcl::uninterestingp t)

(il:putprops il:*env* xcl::uninterestingp t)

(il:putprops evalhook xcl::uninterestingp t)

(il:putprops xcl::nohook xcl::uninterestingp t)

(il:putprops xcl::undohook xcl::uninterestingp t)

(il:putprops xcl::execa0001 xcl::uninterestingp t)

(il:putprops xcl::execa0001a0002 xcl::uninterestingp t)

(il:putprops t xcl::uninterestingp t)

(il:putprops xcl::|interpret-UNDOABLY| xcl::uninterestingp t)

(il:putprops cl::|interpret-LET| xcl::uninterestingp t)

(il:putprops cl::|interpret-LETA0001| xcl::uninterestingp t)

(il:putprops cl::|interpret-FLET| xcl::uninterestingp t)

(il:putprops cl::|interpret-IF| xcl::uninterestingp t)

(il:putprops cl::|interpret-BLOCK| xcl::uninterestingp t)

(il:putprops cl::|interpret-BLOCKA0001| xcl::uninterestingp t)

(il:putprops il:do-event xcl::uninterestingp t)

(il:putprops il:eval-input xcl::uninterestingp t)

(il:putprops apply xcl::uninterestingp t)

(defun xcl::interesting-frame-p (xcl::pos &optional xcl::interpflg)
                                                        (il:* il:\; "Edited 28-Dec-87 12:50 by smL")
   "Return TRUE iff the frame should be visible for a short backtrace."
   (declare (special il:openfns))
   (let ((xcl::name (if (il:stackp xcl::pos)
                        (il:stkname xcl::pos)
                        xcl::pos)))
        (typecase xcl::name
            (symbol (case xcl::name
                        (il:*env*                            (il:* il:\; 
                                                             "*ENV* is used by ENVEVAL etc.")
                           nil)
                        (il:errorset (or (<= (il:stknargs xcl::pos)
                                             1)
                                         (not (eq (il:stkarg 2 xcl::pos nil)
                                                  'il:internal))))
                        (il:eval (or (<= (il:stknargs xcl::pos)
                                         1)
                                     (not (eq (il:stkarg 2 xcl::pos nil)
                                              'xcl::internal))))
                        (il:apply (or (<= (il:stknargs xcl::pos)
                                          2)
                                      (not (il:stkarg 3 xcl::pos nil))))
                        (otherwise (cond
                                      ((get xcl::name 'xcl::uninterestingp)
                                                             (il:* il:\; 
                                                             "Explicitly declared uninteresting.")
                                       nil)
                                      ((eq (il:chcon1 xcl::name)
                                           (il:charcode il:\\))
                                                             (il:* il:\; 
                              "Implicitly declared uninteresting by starting the name with a \"\\\".")
                                       nil)
                                      ((or (member xcl::name il:openfns :test #'eq)
                                           (eq xcl::name 'funcall))
                                                             (il:* il:\; 
                     "The function won't be seen when compiled, so only show it if INTERPFLG it true")
                                       xcl::interpflg)
                                      (t                     (il:* il:\; "Interesting by default.")
                                         t)))))
            (cons (case (car xcl::name)
                      (:broken t)
                      (otherwise nil)))
            (otherwise nil))))

(il:rpaqq il:*short-backtrace-filter* xcl::interesting-frame-p)



(il:* il:|;;| " Change the frame inspector to open up lexical environments")

(il:declare\: il:eval@compile

(il:record il:bkmenuitem (il:label il:bkmenuinfo il:frame-name))
)



(il:* il:\; 
"Since the DEFSTRUCT is going to build the accessors in the package that is current at read-time, and we want the accessors to reside in the IL package, we have got to make sure that the defstruct happens when the package is IL.  I guess the \"right\" way to do this is to have this stuff in a different file, but given that we want all the PCL-ENV stuff in a single file,  I'll resort to this trickery."
)


(in-package "IL")

(cl:defstruct (frame-prop-name (:type list))
   (label-fn 'nill)
   (value-fn (function (lambda (prop-name framespec)
                         (frame-prop-name-data prop-name))))
   (setf-fn 'nill)
   (inspect-fn (function (lambda (value prop-name framespec window)
                           (default.inspectw.valuecommandfn value prop-name (car framespec)
                                  window))))
   (data nil))

(cl:in-package "PCL")

(defun il:debugger-stack-frame-prop-names (il:framespec)

(il:* il:|;;;| 
"Frame prop-names are structures of the form (LABEL-FN VALUE-FN SETF-FN EDIT-FN DATA).")

   (let
    ((il:pos (car il:framespec))
     (il:backtrace-item (cadr il:framespec)))
    (il:if (eq 'eval (il:stkname il:pos))
        il:then
        (let
         ((il:expression (il:stkarg 1 il:pos))
          (il:environment (il:stkarg 2 il:pos)))
         `(,(il:make-frame-prop-name :inspect-fn (il:function (il:lambda (il:value il:prop-name 
                                                                                il:framespec 
                                                                                il:window)
                                                                (il:inspect/as/function il:value
                                                                       (car il:framespec)
                                                                       il:window)))
                   :data il:expression)
           ,(il:make-frame-prop-name :data "ENVIRONMENT")
           ,@(il:for il:aspect il:in `((,(and il:environment (il:environment-vars il:environment))
                                        "vars")
                                       (,(and il:environment (il:environment-functions il:environment
                                                                    ))
                                        "functions")
                                       (,(and il:environment (il:environment-blocks il:environment))
                                        "blocks")
                                       (,(and il:environment (il:environment-tagbodies il:environment
                                                                    ))
                                        "tag bodies")) il:bind il:group-name il:p-list
                il:eachtime (il:setq il:group-name (cadr il:aspect))
                      (il:setq il:p-list (car il:aspect)) il:when (not (null il:p-list))
                il:join `(,(il:make-frame-prop-name :data il:group-name)
                          ,@(il:for il:p il:on il:p-list il:by cddr
                               il:collect (il:make-frame-prop-name :label-fn (il:function (il:lambda
                                                                                            (
                                                                                         il:prop-name
                                                                                             
                                                                                         il:framespec
                                                                                             )
                                                                                            (car
                                                                                             (
                                                                              il:frame-prop-name-data
                                                                                              
                                                                                         il:prop-name
                                                                                              ))))
                                                 :value-fn
                                                 (il:function (il:lambda (il:prop-name il:framespec)
                                                                (cadr (il:frame-prop-name-data 
                                                                             il:prop-name))))
                                                 :setf-fn
                                                 (il:function (il:lambda (il:prop-name il:framespec 
                                                                                il:new-value)
                                                                (il:change (cadr (
                                                                              il:frame-prop-name-data
                                                                                  il:prop-name))
                                                                       il:new-value)))
                                                 :data il:p))))))
      il:else
      (flet ((il:build-name (&key il:arg-name il:arg-number)
                    (il:make-frame-prop-name :label-fn (il:function (il:lambda (il:prop-name 
                                                                                      il:framespec)
                                                                      (car (il:frame-prop-name-data
                                                                            il:prop-name))))
                           :value-fn
                           (il:function (il:lambda (il:prop-name il:framespec)
                                          (il:stkarg (cadr (il:frame-prop-name-data il:prop-name))
                                                 (car il:framespec))))
                           :setf-fn
                           (il:function (il:lambda (il:prop-name il:framespec il:new-value)
                                          (il:setstkarg (cadr (il:frame-prop-name-data il:prop-name))
                                                 (car il:framespec)
                                                 il:new-value)))
                           :data
                           (list il:arg-name il:arg-number))))
            (let ((il:nargs (il:stknargs il:pos t))
                  (il:nargs1 (il:stknargs il:pos))
                  (il:fnname (il:stkname il:pos))
                  il:argname
                  (il:arglist))
                 (and (il:litatom il:fnname)
                      (il:ccodep il:fnname)
                      (il:setq il:arglist (il:listp (il:smartarglist il:fnname))))
                 `(,(il:make-frame-prop-name :inspect-fn (il:function (il:lambda (il:value 
                                                                                        il:prop-name
                                                                                        il:framespec
                                                                                        il:window)
                                                                        (il:inspect/as/function
                                                                         il:value
                                                                         (car il:framespec)
                                                                         il:window)))
                           :data
                           (il:fetch (il:bkmenuitem il:frame-name) il:of il:backtrace-item))
                   ,@(il:bind il:mode il:for il:i il:from 1 il:to il:nargs1
                        il:collect (progn (il:while (il:fmemb (il:setq il:argname (il:pop il:arglist)
                                                               )
                                                           lambda-list-keywords)
                                             il:do (il:setq il:mode il:argname))
                                          (il:build-name :arg-name
                                                 (or (il:stkargname il:i il:pos)
                                                             (il:* il:\; "special")
                                                     (if (case il:mode
                                                             ((nil &optional) il:argname)
                                                             (t nil))
                                                         (string il:argname)
                                                         (il:concat "arg " (- il:i 1))))
                                                 :arg-number il:i)))
                   ,@(let* ((il:novalue "No value")
                            (il:slots (il:for il:pvar il:from 0 il:as il:i il:from (il:add1 il:nargs1
                                                                                          )
                                         il:to il:nargs il:by 1
                                         il:when (and (il:neq il:novalue (il:stkarg il:i il:pos 
                                                                                il:novalue))
                                                      (or (il:setq il:argname (il:stkargname il:i 
                                                                                     il:pos))
                                                          (il:setq il:argname (il:concat "local " 
                                                                                     il:pvar))))
                                         il:collect (il:build-name :arg-name il:argname :arg-number 
                                                           il:i))))
                           (and il:slots (cons (il:make-frame-prop-name :data "locals")
                                               il:slots)))))))))

(defun il:debugger-stack-frame-fetchfn (il:framespec il:prop-name)
   (il:apply* (il:frame-prop-name-value-fn il:prop-name)
          il:prop-name il:framespec))

(defun il:debugger-stack-frame-storefn (il:framespec il:prop-name il:newvalue)
   (il:apply* (il:frame-prop-name-setf-fn il:prop-name)
          il:prop-name il:framespec il:newvalue))

(defun il:debugger-stack-frame-value-command (il:datum il:prop-name il:framespec il:window)
   (il:apply* (il:frame-prop-name-inspect-fn il:prop-name)
          il:datum il:prop-name il:framespec il:window))

(defun il:debugger-stack-frame-title (il:framespec &optional il:window)
   (declare (ignore il:window))
   (il:concat (il:stkname (car il:framespec))
          "  Frame"))

(defun il:debugger-stack-frame-property (il:prop-name il:framespec)
   (il:apply* (il:frame-prop-name-label-fn il:prop-name)
          il:prop-name il:framespec))



(il:* il:|;;| 
"Teaching the debugger that there are other file-manager types that can appear on the stack")


(defvar xcl::*function-types* '(il:fns il:functions)
                              "Manager types that can appear on the stack")



(il:* il:|;;| "Redefine a couple of system functions to use the above stuff")


(defun dbg::attach-backtrace-menu (&optional il:ttywindow il:skip)
   (declare (special il:\\term.ofd il:backtracefont))
   (or il:ttywindow (il:setq il:ttywindow (il:wfromds (il:ttydisplaystream))))
   (prog ((il:pos (il:stknth 0 (il:getwindowprop il:ttywindow 'dbg::stack-position)))
          il:btw il:bkmenu (*print-level* 2)                 (il:* il:\; "for the FORMAT below")
          (*print-length* 3)
          (*print-escape* t)
          (*print-gensym* t)
          (*print-pretty* nil)
          (*print-circle* nil)
          (*print-radix* 10)
          (*print-array* nil)
          (il:*print-structure* nil)
          (il:ttyregion (il:windowprop il:ttywindow 'il:region)))
         (il:setq il:bkmenu (il:|create| il:menu
                                   il:items il:� (dbg::collect-backtrace-items il:ttywindow il:skip)
                                   il:whenselectedfn il:� 'dbg::backtrace-item-selected
                                   il:menuoutlinesize il:� 0
                                   il:menufont il:� il:backtracefont
                                   il:menucolumns il:� 1
                                   il:whenheldfn il:� #'(il:lambda (il:item il:menu il:button)
                                                          (declare (ignore il:item il:menu))
                                                          (case il:button
                                                              (il:left (il:promptprint 
                                                         "Open a frame inspector on this stack frame"
                                                                              ))
                                                              (il:middle (il:promptprint 
                                                                         "Inspect/Edit this function"
                                                                                ))))))
         (cond
            ((il:setq il:btw (il:|for| il:atw il:|in| (il:attachedwindows il:ttywindow)
                                il:|when| (and (il:setq il:btw (il:windowprop il:atw 'il:menu))
                                               (eq (il:|fetch| (il:menu il:whenselectedfn)
                                                      il:|of| (car il:btw))
                                                   'dbg::backtrace-item-selected))
                                il:|do|                      (il:* il:\; 
                                       "test for an attached window that has a backtrace menu in it.")
                                      (return il:atw)))      (il:* il:\; 
                               "if there is already a backtrace window, delete the old menu from it.")
             (il:deletemenu (car (il:windowprop il:btw 'il:menu))
                    nil il:btw)
             (il:windowprop il:btw 'il:extent nil)
             (il:clearw il:btw))
            ((il:setq il:btw (il:createw (dbg::region-next-to (il:windowprop il:ttywindow
                                                                     'il:region)
                                                (il:widthifwindow (il:imin (il:|fetch| (il:menu
                                                                                        il:imagewidth
                                                                                        )
                                                                              il:|of| il:bkmenu)
                                                                         il:|MaxBkMenuWidth|))
                                                (il:|fetch| (il:region il:height) il:|of| 
                                                                                        il:ttyregion)
                                                :left)))     (il:* il:\; 
                            "put bt window at left of TTY window unless ttywindow is near left edge.")
             (il:attachwindow il:btw il:ttywindow (if (il:igreaterp (il:|fetch| (il:region il:left)
                                                                       il:|of| (il:windowprop
                                                                                il:btw
                                                                                'il:region))
                                                             (il:|fetch| (il:region il:left)
                                                                il:|of| il:ttyregion))
                                                      'il:right
                                                      'il:left)
                    nil
                    'il:localclose)
             (il:windowprop il:btw 'il:process (il:windowprop il:ttywindow 'il:process))
                                                             (il:* il:\; 
                                                             " so that button clicks will switch TTY")
             ))
         (il:addmenu il:bkmenu il:btw (il:|create| il:position
                                             il:xcoord il:� 0
                                             il:ycoord il:� (il:idifference (il:windowprop
                                                                             il:btw
                                                                             'il:height)
                                                                   (il:|fetch| (il:menu 
                                                                                      il:imageheight)
                                                                      il:|of| il:bkmenu))))

    (il:* il:|;;| "IL:ADDMENU sets up buttoneventfn for window that we don't want.  We want to catch middle button events before the menu handler, so that we can pop up edit/inspect menu for the frame currently selected.  So replace the buttoneventfn, and can nuke the cursorin and cursormoved guys, cause don't need them.")

         (il:windowprop il:btw 'il:buttoneventfn 'dbg::backtrace-menu-buttoneventfn)
         (il:windowprop il:btw 'il:cursorinfn nil)
         (il:windowprop il:btw 'il:cursormovedfn nil)))

(defun dbg::collect-backtrace-items (dbg::ttywindow dbg::skip)
   (xcl:with-collection 

          (il:* il:|;;| 
          "There are a number of possibilities for the values returned by the filter-fn.")

          (il:* il:|;;| "(1) INTERESTING-P is false, and the other values are all NIL.  This is the simple case where the stack frame NEXT-POS should be ignored completly, and processing should continue with the next frame.")

          (il:* il:|;;| "(2) INTERESTING-P is true, and the other values are all NIL.  This is the simple case where the stack frame NEXT-POS should appear in the backtrace as is, and processing should continue with the next frame.")

          (il:* il:|;;| "[Note that these two cases take care of old values of the filter-fn.]")

          (il:* il:|;;| "(3) INTERESTING-P is false, and LAST-FRAME-CONSUMED is a stack frame.  In that case, ignore all stack frames from NEXT-POS to LAST-FRAME-CONSUMED, inclusive.")

          (il:* il:|;;| "(4) INTERESTING-P is true, and LAST-FRAME-CONSUMED is a stack frame.  In this case, the backtrace should include a single entry coresponding to the frame USE-FRAME (which defaults to LAST-FRAME-CONSUMED), and processing should continue with the next frame after LAST-FRAME-CONSUMED.  If LABEL is non-NIL, it will be the label that appears in the backtrace menu; otherwise the name of USE-FRAME will be used (or the form being EVALed if the frame is an EVAL frame).")

          (let* ((dbg::filter (cond
                                 ((null dbg::skip)
                                  #'xcl:true)
                                 ((eq dbg::skip t)
                                  il:*short-backtrace-filter*)
                                 (t dbg::skip)))
                 (dbg::top-frame (il:stknth 0 (il:getwindowprop dbg::ttywindow 'dbg::stack-position))
                        )
                 (dbg::next-frame dbg::top-frame)
                 (dbg::frame-number 0)
                 dbg::interestingp dbg::last-frame-consumed dbg::use-frame dbg::label)
                (loop (when (null dbg::next-frame)
                            (return))
                      (multiple-value-setq (dbg::interestingp dbg::last-frame-consumed dbg::use-frame
                                                  dbg::label)
                             (funcall dbg::filter dbg::next-frame))
                      (when (null dbg::last-frame-consumed)  (il:* il:\; 
                                                    "Set the default value of LAST-FRAME-CONSUMED...")
                          (setf dbg::last-frame-consumed dbg::next-frame))
                      (when dbg::interestingp                (il:* il:\; "...and USEFRAME")
                          (when (null dbg::use-frame)
                                (setf dbg::use-frame dbg::last-frame-consumed))
                                                             (il:* il:\; "...and LABEL")
                          (when (null dbg::label)
                              (setf dbg::label (il:stkname dbg::use-frame))
                              (if (member dbg::label '(eval il:eval il:apply apply)
                                         :test
                                         'eq)
                                  (setf dbg::label (il:stkarg 1 dbg::use-frame))))
                                                             (il:* il:\; 
                                                      "Walk the stack until we find the frame to use")
                          (loop (cond
                                   ((not (typep dbg::next-frame 'il:stackp))
                                    (error "~%Use-frame ~S not found" dbg::use-frame))
                                   ((xcl::stack-eql dbg::next-frame dbg::use-frame)
                                    (return))
                                   (t (incf dbg::frame-number)
                                      (setf dbg::next-frame (il:stknth -1 dbg::next-frame 
                                                                   dbg::next-frame)))))
                                                             (il:* il:\; 
                                                   "Add the menu item to the list under construction")
                          (xcl:collect (il:|create| il:bkmenuitem
                                              il:label il:� (let ((*print-level* 2)
                                                                  (*print-length* 3)
                                                                  (*print-escape* t)
                                                                  (*print-gensym* t)
                                                                  (*print-pretty* nil)
                                                                  (*print-circle* nil)
                                                                  (*print-radix* 10)
                                                                  (*print-array* nil)
                                                                  (il:*print-structure* nil))
                                                                 (prin1-to-string dbg::label))
                                              il:bkmenuinfo il:� dbg::frame-number
                                              il:frame-name il:� dbg::label)))
                                                             (il:* il:\; "Update NEXT-POS")
                      (loop (cond
                               ((not (typep dbg::next-frame 'il:stackp))
                                (error "~%Last-frame-consumed ~S not found" dbg::last-frame-consumed)
                                )
                               ((prog1 (xcl::stack-eql dbg::next-frame dbg::last-frame-consumed)
                                    (incf dbg::frame-number)
                                    (setf dbg::next-frame (il:stknth -1 dbg::next-frame 
                                                             (il:* il:\; 
                                                             "Reuse the old stack-pointer")
                                                                 dbg::next-frame)))
                                (return))))))))

(defun dbg::backtrace-menu-buttoneventfn (dbg::window &aux (dbg::menu
                                                            (car (il:listp (il:windowprop
                                                                            dbg::window
                                                                            'il:menu)))))
   (unless (or (il:lastmousestate il:up)
               (null dbg::menu))
       (il:totopw dbg::window)
       (cond
          ((il:lastmousestate il:middle)

           (il:* il:|;;| "look for a selected frame in this menu, and then pop up the editor invoke menu for that frame.  don't change the selection, just present the edit menu.")

           (let* ((dbg::selection (il:menu.handler dbg::menu (il:windowprop dbg::window 'il:dsp)))
                  (dbg::ttywindow (il:windowprop dbg::window 'il:mainwindow))
                  (dbg::pos (il:windowprop dbg::ttywindow 'dbg::lastpos)))

                 (il:* il:|;;| "don't have to worry about releasing POS because we only look at it here (nobody here hangs on to it) and we will be around for less time than LASTPOS.  The debugger is responsible for releasing LASTPOS.")

                 (il:inspect/as/function (cond
                                            ((and dbg::selection (il:|fetch| (il:bkmenuitem 
                                                                                    il:frame-name)
                                                                    il:|of| (car dbg::selection))))
                                            ((and (symbolp (il:stkname dbg::pos))
                                                  (il:getd (il:stkname dbg::pos)))
                                             (il:stkname dbg::pos))
                                            (t 'il:nill))
                        dbg::pos dbg::ttywindow)))
          (t (let ((dbg::selection (il:menu.handler dbg::menu (il:windowprop dbg::window 'il:dsp))))
                  (when dbg::selection
                      (il:doselecteditem dbg::menu (car dbg::selection)
                             (cdr dbg::selection))))))))
(il:defineq

(il:select.fns.editor
  (il:lambda (il:fn)                                    (il:* il:\; "Edited 15-Sep-87 18:25 by smL")

    (il:* il:|;;| "gives the user a menu choice of editors.")

    (let ((il:menu-items (cond
                            ((il:ccodep il:fn)
                             '((il:|InspectCode| 'il:inspectcode "Shows the compiled code.")
                               (il:|DisplayEdit| 'ed "Edit it with the display editor")
                               (il:|TtyEdit| 'il:ef "Edit it with the standard editor")))
                            ((il:closure-p il:fn)
                             '((il:|Inspect| 'inspect "Inspect this object")))
                            (t '((il:|DisplayEdit| 'ed "Edit it with the display editor")
                                 (il:|TtyEdit| 'il:ef "Edit it with the standard editor"))))))
         (il:menu (il:|create| il:menu
                         il:items il:� il:menu-items
                         il:centerflg il:� t)))))
)



(il:* il:|;;| "")




(il:* il:|;;| "PCL specific extensions to the debugger")




(il:* il:|;;| 
"There are some new things that act as functions, and that we want to be able to edit from a backtrace window"
)


(il:addtovar xcl::*function-types* methods method-setfs)

(eval-when (eval load)
       (unless (generic-function-p (symbol-function 'il:inspect/as/function))
           (make-specializable 'il:inspect/as/function)))

(defmethod
   il:inspect/as/function
   (xcl::name xcl::stack-pointer xcl::debugger-window)

   (il:* il:|;;| "Calls an editor on function NAME.  STKP and WINDOW are the stack pointer and window of the break in which this inspect command was called.")

   (let ((xcl::editor (il:select.fns.editor xcl::name)))
        (case xcl::editor
            ((nil) 

               (il:* il:|;;| "No editor chosen, so don't do anything")

               nil)
            (il:inspectcode 

               (il:* il:|;;| "Inspect the compiled code")

               (let ((xcl::frame (xcl::stack-pointer-frame xcl::stack-pointer)))
                    (if (and (il:stackp xcl::stack-pointer)
                             (xcl::stack-frame-valid-p xcl::frame))
                        (il:inspectcode (let ((xcl::code-base (xcl::stack-frame-fn-header xcl::frame)
                                                     ))
                                             (cond
                                                ((eq (il:\\get-compiled-code-base xcl::name)
                                                     xcl::code-base)
                                                 xcl::name)
                                                (t 

                                 (il:* il:|;;| "Function executing in this frame is not the one in the definition cell of its name, so fetch the real code.  Have to pass a CCODEP")

                                                   (il:make-compiled-closure xcl::code-base))))
                               nil nil nil (xcl::stack-frame-pc xcl::frame))
                        (il:inspectcode xcl::name))))
            (ed 

               (il:* il:|;;| "Use the standard editor.")

               (il:* il:|;;| "This used to take care to apply the editor in the debugger process, so forms evaluated in the editor happen in the context of the break.  But that doesn't count for much any more, now that lexical variables are the way to go.  Better to use the LEX debugger command (thank you, Herbie) and shift-select pieces of code from the editor into the debugger window. ")

               (ed xcl::name `(,@xcl::*function-types* :display)))
            (otherwise (funcall xcl::editor xcl::name)))))

(defmethod
   il:inspect/as/function
   ((name object)
    stkp window)
   (when (il:menu (il:|create| il:menu
                         il:items il:� '(("Inspect" t "Inspect this object"))))
         (inspect name)))

(defmethod
   il:inspect/as/function
   ((x standard-method)
    stkp window)
   (let* ((generic-function-name (slot-value (slot-value x 'generic-function)
                                        'name))
          (method-setf-p (and (consp generic-function-name)
                              (eq (first generic-function-name)
                                  'setf)
                              (second generic-function-name)))
          (method-name (full-method-name x method-setf-p))
          (editor (il:select.fns.editor (slot-value x 'function))))
         (il:allow.button.events)
         (case editor
             (ed (ed method-name (if method-setf-p
                                     '(:display method-setfs)
                                     '(:display methods))))
             (il:inspectcode (il:inspectcode (slot-value x 'function)))
             ((nil) nil)
             (otherwise (funcall editor method-name)))))



(il:* il:|;;| 
"A replacement for the vanilla IL:INTERESTING-FRAME-P so we can see methods and generic-functions on the stack."
)


(defun interesting-frame-p (stack-pos &optional interp-flag)

(il:* il:|;;;| "Return up to four values:  INTERESTING-P LAST-FRAME-CONSUMED USE-FRAME and LABEL.  See the function IL:COLLECT-BACKTRACE-ITEMS for a full description of how these values are used.")

   (labels ((function-matches-frame-p #'frame "Is the function being called in this frame?"
                   (let* ((frame-name (il:stkname frame))
                          (code-being-run (cond
                                             ((typep frame-name 'il:closure)
                                              frame-name)
                                             ((and (consp frame-name)
                                                   (eq 'il:\\interpreter (xcl::stack-frame-name
                                                                          (il:\\stackargptr frame))))
                                              frame-name)
                                             (t (xcl::stack-frame-fn-header (il:\\stackargptr frame))
                                                ))))
                         (or (eq function code-being-run)
                             (and (typep function 'il:compiled-closure)
                                  (eq (xcl::compiled-closure-fnheader function)
                                      code-being-run)))))
            (generic-function-from-frame (frame)
                   "If this the frame of a generic function return the gf, otherwise return NIL."

                   (il:* il:|;;| "Generic functions are implemented as compiled closures.  On the stack, we only see the fnheader for the the closure.  This could be a discriminator code, or in the default method only case it will be the actual method function.  To tell if this is a generic function frame, we have to check very carefully to see if the right stuff is on the stack.  Specifically, the closure's ccode, and the first local variable has to be a ptrhunk big enough to be a FIN environment, and fin-env-fin of that ptrhunk has to point to a generic function whose ccode and environment match. ")

                   (let ((n-args (il:stknargs frame))
                         (env nil)
                         (gf nil))
                        (if (and 
                                 (il:* il:|;;| "is there at least one local?")

                                 (> (il:stknargs frame t)
                                    n-args)

                                 (il:* il:|;;| "and does the local contain something that might be the closure environment of a funcallable instance?")

                                 (setf env (il:stkarg (1+ n-args)
                                                  frame))

                                 (il:* il:|;;| "and does the local contain something that might be the closure environment of a funcallable instance?")

                                 (typep env *fin-env-type*)
                                 (setf gf (fin-env-fin env))

                                 (il:* il:|;;| "whose fin-env-fin points to a generic function?")

                                 (generic-function-p gf)

                                 (il:* il:|;;| "whose environment is the same as env?")

                                 (eq (xcl::compiled-closure-env gf)
                                     env)

                                 (il:* il:|;;| 
                                 "and whose code is the same as the code for this frame? ")

                                 (function-matches-frame-p gf frame))
                            gf
                            nil))))
          (let ((frame-name (il:stkname stack-pos)))

               (il:* il:|;;| "")

               (il:* il:|;;| "See if there is a generic-function on the stack at this location.")

               (let ((gf (generic-function-from-frame stack-pos)))
                    (when gf
                        (return-from interesting-frame-p (values t stack-pos stack-pos gf))))

               (il:* il:|;;| "")

               (il:* il:|;;| "See if this is an interpreted method.  The method body is wrapped in a (BLOCK <function-name> ...).  We look for an interpreted call to BLOCK whose block-name is the name of generic-function.")

               (when (and (eq frame-name 'eval)
                          (consp (il:stkarg 1 stack-pos))
                          (eq (first (il:stkarg 1 stack-pos))
                              'block)
                          (symbolp (second (il:stkarg 1 stack-pos)))
                          (fboundp (second (il:stkarg 1 stack-pos)))
                          (generic-function-p (symbol-function (second (il:stkarg 1 stack-pos)))))
                   (let* ((form (il:stkarg 1 stack-pos))
                          (block-name (second form))
                          (generic-function (symbol-function block-name))
                          (methods (generic-function-methods (symbol-function block-name))))

                         (il:* il:|;;| "If this is really a method being called from a generic-function, the g-f should be no more than a few frames up the stack.  Check for the method call by looking for a call to APPLY, where the function being applied is the code in one of the methods.")

                         (do ((i 30 (1- i))
                              (previous-pos stack-pos current-pos)
                              (current-pos (il:stknth -1 stack-pos)
                                     (il:stknth -1 current-pos))
                              (found-method nil)
                              (method-pos))
                             ((or (null current-pos)
                                  (<= i 0))
                              nil)
                           (cond
                              ((equalp generic-function (generic-function-from-frame current-pos))
                               (if found-method
                                   (return-from interesting-frame-p (values t previous-pos method-pos
                                                                           found-method))
                                   (return)))
                              (found-method nil)
                              ((eq (il:stkname current-pos)
                                   'apply)
                               (dolist (method methods)
                                   (when (eq (method-function method)
                                             (il:stkarg 1 current-pos))
                                       (setq method-pos current-pos)
                                       (setq found-method method)
                                       (return))))))))

               (il:* il:|;;| "")

               (il:* il:|;;| "Try to handle compiled methods")

               (when (and (symbolp frame-name)
                          (not (fboundp frame-name))
                          (eq (il:chcon1 frame-name)
                              (il:charcode il:\())
                          (or (string= "(pcl::method " (symbol-name frame-name)
                                     :start2 0 :end2 13)
                              (string= "(pcl:method " (symbol-name frame-name)
                                     :start2 0 :end2 12)
                              (string= "(method " (symbol-name frame-name)
                                     :start2 0 :end2 8)))

                   (il:* il:|;;| "Looks like a name that PCL consed up.  See if there is a GF nearby up the stack.  If there is, use it to help determine which method we have.")

                   (do ((i 30 (1- i))
                        (current-pos (il:stknth -1 stack-pos)
                               (il:stknth -1 current-pos))
                        (gf))
                       ((or (null current-pos)
                            (<= i 0))
                        nil)
                     (setq gf (generic-function-from-frame current-pos))
                     (when gf
                         (dolist (method (generic-function-methods gf))
                             (when (function-matches-frame-p (method-function method)
                                          stack-pos)
                                 (return-from interesting-frame-p (values t stack-pos stack-pos 
                                                                         method))))
                         (return))))

               (il:* il:|;;| "")

               (il:* il:|;;| "If we haven't already returned, use the default method.")

               (xcl::interesting-frame-p stack-pos interp-flag))))

(il:rpaqq il:*short-backtrace-filter* interesting-frame-p)



(il:* il:|;;;| "")




(il:* il:|;;;| "Support for ?= and friends")




(il:* il:|;;;| "")


(il:putprops defclass il:argnames (nil (class-name (#\{ superclass-name #\} #\*)
                                              (#\{ slot-spec #\} #\*)
                                              #\{ class-option #\} #\*)))

(il:putprops defgeneric-options il:argnames (nil (name lambda-list setf-lambda-list #\{ option #\} 
                                                       #\*)))

(il:putprops defgeneric-options-setf il:argnames (nil (name lambda-list setf-lambda-list #\{ option 
                                                            #\} #\*)))

(il:putprops define-method-combination il:argnames (nil (name #\{ #\{ short-form-option #\} #\* #\| 
                                                              lambda-list (#\{ method-group-specifier
                                                                               #\} #\*)
                                                              #\{ declaration #\| il:doc-string #\} 
                                                              #\* #\{ il:form #\} #\* #\})))

(il:putprops defmethod il:argnames (nil (name #\{ method-qualifier #\} #\* specialized-lambda-list 
                                              #\{ declaration #\| il:doc-string #\} #\* #\{ il:form 
                                              #\} #\*)))

(il:putprops defmethod-setf il:argnames (nil (name #\{ method-qualifier #\} #\* 
                                                   specialized-lambda-list 
                                                   sepcialized-setf-lambda-list #\{ declaration #\| 
                                                   il:doc-string #\} #\* #\{ il:form #\} #\*)))

(il:putprops multiple-value-prog2 il:argnames (nil (first second #\{ il:form #\} #\*)))

(il:putprops with-slots il:argnames (nil ((#\{ slot-entry #\} #\*)
                                          instance #\{ form #\} #\*)))

(il:putprops with-accessors il:argnames (nil ((#\{ slot-entry #\} #\*)
                                              instance #\{ form #\} #\*)))
(il:defineq

(il:smartarglist
  (il:lambda (il:fn il:explainflg il:tail)              (il:* il:\; "Edited 16-Sep-87 13:58 by smL")

    (il:* il:|;;| "Hacked by smL to add support for fetching arglists of generic-functions")

    (prog (il:tem il:def)
          (cond
             ((not (il:litatom il:fn))
              (il:|if| (and il:explainflg (il:listp il:fn)
                            (eq (car il:fn)
                                'lambda))
                  il:|then| (return (il:\\simplify.cl.arglist (cadr il:fn))))
              (return (il:arglist il:fn))))
      il:retry
          (cond
             ((get il:fn 'il:broken)
              (return (il:smartarglist (get il:fn 'il:broken)
                             il:explainflg)))
             ((il:setq il:tem (il:getlis il:fn '(il:argnames)))

              (il:* il:|;;| "gives user an override.  also provides a way of ensuring that argument names stay around even if helpsys data base goes away.  for example, if user wanted to advise a system subr and was worried.")

              (return (cond
                         ((or (il:nlistp (il:setq il:tem (cadr il:tem)))
                              (car il:tem))

                          (il:* il:|;;| "ARGNAMES is used for two purposes, one to provide an override, the other to have a lookup. therefore for nospread functions, we must store both the arglist to be used for explaining, and the one to be used for breaking and advising. this situation is indicated by having the value of ARGNAMES be a dotted pair of the two arglists. (note that the first one will always be a list, hence this nlistp check to distinguish the two cases.)")

                          il:tem)
                         (il:explainflg (cadr il:tem))
                         (t (cddr il:tem))))))
          (cond
             (il:explainflg (cond
                               ((and (symbolp il:fn)
                                     (fboundp il:fn)
                                     (generic-function-p (symbol-function il:fn)))
                                                             (il:* il:\; "Oh boy, a generic function")
                                (return (generic-function-pretty-arglist (symbol-function il:fn))))
                               ((and (il:exprp (il:setq il:def (or (get il:fn 'il:advised)
                                                                   (il:getd il:fn)
                                                                   (get il:fn 'il:expr))))
                                     (il:fmemb (car (il:listp il:def))
                                            '(lambda il:lambda il:nlambda)))
                                (return (il:\\simplify.cl.arglist (cadr il:def))))
                               ((and (il:setq il:def (il:getdef il:fn 'il:functions 'il:current
                                                            '(il:noerror il:nocopy)))
                                     (il:selectq (car il:def)
                                           ((defmacro defun) 
                                                 t)
                                           ((xcl:defdefiner xcl:defcommand) 
                                                 (il:|pop| il:def))
                                           nil))
                                (return (il:\\simplify.cl.arglist (third (xcl:remove-comments il:def)
                                                                         )))))))
          (cond
             ((il:setq il:def (or (il:getd il:fn)
                                  (cadr (il:getlis il:fn '(il:expr il:code)))))
              (cond
                 ((and (or (il:exprp il:def)
                           (il:ccodep il:def))
                       (or (not il:explainflg)
                           (not (il:fmemb (il:argtype il:def)
                                       '(2 3)))))

                  (il:* il:|;;| 
  "Can use ARGLIST if function is defined.   Want to try harder if 'EXPLAINING' rather than advising")

                  (return (il:arglist il:def))))))
          (return (cond
                     ((and il:explainflg (il:setq il:tem (il:getmacroprop il:fn il:compilermacroprops
                                                                )))
                      (il:selectq (car il:tem)
                            ((il:lambda il:nlambda il:openlambda) 
                                  (cadr il:tem))
                            (= (il:smartarglist (cdr il:tem)
                                      il:explainflg))
                            (nil nil)
                            (cond
                               ((il:listp (car il:tem))
                                (return (cond
                                           ((cdr (last (car il:tem)))
                                            (il:append (car il:tem)
                                                   (list 'il:|...| (cdr (last (car il:tem))))))
                                           (t (car il:tem))))))))
                     ((and (il:neq il:tem t)
                           il:tem))
                     ((and (il:setq il:tem (il:fncheck il:fn t nil t il:tail))
                           (il:neq il:tem il:fn))
                      (il:setq il:fn il:tem)
                      (go il:retry))
                     (t (il:arglist il:fn)))))))
)
(il:putprops il:medley-pcl-env il:copyright ("Xerox Corporation" 1988))
(il:declare\: il:dontcopy
  (il:filemap (nil (65230 66236 (il:select.fns.editor 65243 . 66234)) (81018 86388 (il:smartarglist 
81031 . 86386)))))
il:stop
