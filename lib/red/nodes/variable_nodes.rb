module Red
  class VariableNode < String # :nodoc:
    class ClassVariable < VariableNode # :nodoc:
      # [:cvar, :@@foo]
      def initialize(variable_name_sexp, options)
        class_name = @@namespace_stack.join('.')
        variable_name = variable_name_sexp.red!
        self << "%s.cvget('%s')" % [class_name, variable_name]
      end
    end
    
    class Constant < VariableNode # :nodoc:
      # ex.1: constant_name     = 'Baz'
      #       @@namespace_stack = ['Foo', 'Bar']
      #       @@red_constants   = ['Foo', 'Foo.Bar', 'Foo.Baz']
      # 1st check: 'Foo.Bar.Baz' in @@red_constants
      # 2nd check: 'Foo.Baz'     in @@red_constants
      # finds it & returns 'Foo.Baz'
      # 
      # ex.2: constant_name     = 'Qux'
      #       @@namespace_stack = ['Foo', 'Bar']
      #       @@red_constants   = ['Foo', 'Foo.Bar', 'Foo.Baz']
      # 1st check: 'Foo.Bar.Qux' in @@red_constants
      # 2nd check: 'Foo.Qux'     in @@red_constants
      # 3rd check: 'Qux'         in @@red_constants
      # finds nothing & returns 'Foo.Bar.Qux'
      
      # [:const, :Foo]
      def initialize(constant_name_sexp, options)
        constant_name = "c$%s" % constant_name_sexp.red!
        locally_namespaced_constant = (@@namespace_stack + [constant_name]).join('.')
        i = -1
        begin
          constant = (@@namespace_stack[0..i] + [constant_name]).join('.')
          preexisting_constant_namespace = constant if @@red_constants.include?(constant)
          i -= 1
        end until preexisting_constant_namespace || @@namespace_stack.size + i < -1
        self << "%s" % [(preexisting_constant_namespace || locally_namespaced_constant)]
      end
    end
    
    class InstanceVariable < VariableNode # :nodoc:
      # [:ivar, :@foo]
      def initialize(variable_name_sexp, options)
        variable_name = variable_name_sexp.red!
        self << "this.i$%s" % [variable_name]
      end
    end
    
    class Keyword < VariableNode # :nodoc:
      # [:nil]
      # [:self]
      def initialize(options)
        string = case self when Nil : "nil" when Self : "this" end
        self << string
      end
      
      class Nil < Keyword # :nodoc:
      end
      
      class Self < Keyword # :nodoc:
      end
    end
    
    class OtherVariable < VariableNode # :nodoc:
      # [:dvar,  :foo]
      # [:gvar,  :foo]
      # [:lvar,  :foo]
      # [:vcall, :foo]
      def initialize(variable_name_sexp, options)
        variable_name = variable_name_sexp.red!
        self << "%s" % [variable_name]
      end
    end
  end
end
