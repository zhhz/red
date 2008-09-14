module Red
  class AssignmentNode < String # :nodoc:
    class ClassVariable < AssignmentNode  # :nodoc:
      # [:cvdecl, :@@foo, {expression}] => inside eval portion of class declaration
      # [:cvasgn, :@@foo, {expression}] => inside method definition
      def initialize(variable_name_sexp, expression_sexp, options)
        class_name    = @@namespace_stack.join(".")
        variable_name = variable_name_sexp.red!
        expression    = expression_sexp.red!(:as_assignment => true)
        self << "%s.c$%s=%s" % [class_name, variable_name, expression]
      end
    end
    
    class Constant < AssignmentNode # :nodoc:
      # [:cdecl, :Foo, {expression}]
      def initialize(constant_name_sexp, expression_sexp, options)
        constant_name    = (@@namespace_stack + [constant_name_sexp.red!]).join(".")
        @@red_constants |= [constant_name]
        expression       = expression_sexp.red!(:as_assignment => true)
        self << "%s=%s" % [constant_name, expression]
      end
    end
    
    class GlobalVariable < AssignmentNode  # :nodoc:
      # [:gasgn, :$foo, {expression}]
      def initialize(variable_name_sexp, expression_sexp, options)
        variable_name = variable_name_sexp.red!
        expression    = expression_sexp.red!(:as_assignment => true)
        self << "%s=%s" % [variable_name, expression]
      end
    end
    
    class InstanceVariable < AssignmentNode # :nodoc:
      # [:iasgn, :@foo, {expression}]
      def initialize(variable_name_sexp, expression_sexp, options)
        variable_name = variable_name_sexp.red!
        expression    = expression_sexp.red!(:as_assignment => true)
        self << "this.i$%s=%s" % [variable_name, expression]
      end
    end
    
    class LocalVariable < AssignmentNode # :nodoc:
      # [:lasgn,      :foo, {expression}]
      # [:dasgn,      :foo, {expression}] => previously defined inside a proc, but not the nearest proc
      # [:dasgn_curr, :foo, {expression}] => local to the nearest proc
      def initialize(variable_name_sexp, expression_sexp, options)
        variable_name = variable_name_sexp.red!
        expression    = expression_sexp.red!(:as_assignment => true)
        if options[:as_argument_default]
          self << "%s=$T(_a=%s)?_a:%s" % [variable_name, variable_name, expression]
        else
          #string = (options[:as_argument] || variable_name.is_sexp?(:colon2)) ? "%s = %s" : "var %s = %s"
          self << "%s=%s" % [variable_name, expression]
        end
      end
    end
    
    class Attribute < AssignmentNode # :nodoc:
      # [:attrasgn, {expression}, :foo= | :[]=, [:array, {element}, {element}, ...]]
      def initialize(receiver_sexp, writer_sexp, arguments_array_sexp, options)
        receiver  = receiver_sexp.red!(:as_receiver => true)
        writer    = (METHOD_ESCAPE[writer_sexp] || writer_sexp).red!
        arguments = arguments_array_sexp[1..-1].map {|argument_sexp| argument_sexp.red!(:as_argument => true) }.join(",")
        self << "%s.m$%s(%s)" % [receiver, writer, arguments]
      end
    end
    
    class Multiple < AssignmentNode # :nodoc:
      # [:masgn, [:array, {expression}, {expression} ...], [:to_ary, {expression}] | [:array, {expression}, {expression}, ...]]
      def initialize(variables_array_sexp, assignments_array_sexp)
        variables = variables_array_sexp[1..-1].map {|variable_sexp| variable_sexp.last.red! }
        self << ""
      end
    end
    
    class Operator < AssignmentNode # :nodoc:
      class Bracket < Operator # :nodoc:
        # [:op_asgn_1, {expression}, [:array, {element}, {element} ...], :+ | :* |..., {expression}] => from e.g. "foo[bar] ||= 1"
        def initialize(receiver_sexp, arguments_array_sexp, method_sexp, expression_sexp, options)
          receiver   = receiver_sexp.red!(:as_receiver => true)
          arguments  = arguments_array_sexp[1..-1].map {|argument_sexp| argument_sexp.red!(:as_argument => true) }.join(",")
          comma      = arguments.empty? ? "" : ","
          method     = (METHOD_ESCAPE[method_sexp] || method_sexp).red!
          expression = expression_sexp.red!(:as_argument => true)
          object     = "%s.m$_brkt(%s)" % [receiver, arguments]
          unless string = ((method == '||' && LogicNode::Conjunction::Or::STRING) || (method == '&&' && LogicNode::Conjunction::And::STRING))
            operation = "%s.m$%s(%s)" % [object, method, expression]
          else
            operation = string % [object, expression]
          end
          self << "%s.m$_breq(%s%s%s)" % [receiver, arguments, comma, operation]
        end
      end
      
      class Dot < Operator # :nodoc:
        # [:op_asgn_2, {expression}, :foo=, :+ | :* |..., {expression}] => from e.g. "foo.bar ||= 1"
        def initialize(receiver_sexp, writer_sexp, method_sexp, expression_sexp, options)
          #self << "%s=%s %s %s" % [receiver, receiver, operation.red!, expression.red!(:as_argument => true)]
          receiver   = receiver_sexp.red!(:as_receiver => true)
          reader     = writer_sexp.to_s.gsub(/=/,'').to_sym.red!
          writer     = writer_sexp.red!
          method     = (METHOD_ESCAPE[method_sexp] || method_sexp).red!
          expression = expression_sexp.red!(:as_argument => true)
          object     = "%s.m$%s()" % [receiver, reader]
          unless string = ((method == '||' && LogicNode::Conjunction::Or::STRING) || (method == '&&' && LogicNode::Conjunction::And::STRING))
            operation = "%s.m$%s(%s)" % [object, method, expression]
          else
            operation = string % [object, expression]
          end
          self << "%s.m$%s(%s)" % [receiver, writer, operation]
        end
      end
      
      class Or < Operator # :nodoc:
        # [:op_asgn_or, {expression}, {expression}] => from e.g. "foo ||= 1"
        def initialize(variable_name_sexp, assignment_sexp, options)
          variable_name = variable_name_sexp.red!
          expression    = assignment_sexp.last.red!(:as_argument => true)
          conjunction   = LogicNode::Conjunction::Or::STRING % [variable_name, expression]
          self << "%s=%s" % [variable_name, conjunction]
        end
      end
      
      class And < Operator # :nodoc:
        # [:op_asgn_and, {expression}, {expression}] => from e.g. "foo &&= 1"
        def initialize(variable_name_sexp, assignment_sexp, options)
          variable_name = variable_name_sexp.red!
          expression    = assignment_sexp.last.red!(:as_argument => true)
          conjunction   = LogicNode::Conjunction::And::STRING % [variable_name, expression]
          self << "%s=%s" % [variable_name, conjunction]
        end
      end
    end
  end
end
