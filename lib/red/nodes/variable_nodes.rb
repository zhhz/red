module Red
  class VariableNode < String # :nodoc:
    def initialize(variable_name, options)
      self << variable_name.red!
    end
    
    class ClassVariable < VariableNode # :nodoc:
      def initialize(variable_name, options)
        self << "%s.$$%s" % [@@namespace_stack.join('.'), variable_name.red!]
      end
    end
    
    class Constant < VariableNode # :nodoc:
      def initialize(constant_name, options)
        i = -1
        begin
          constant = (@@namespace_stack[0..i] + [constant_name.red!]).join('.')
          namespaced_constant = constant if @@red_constants.include?(constant)
          i -= 1
        end until namespaced_constant || i.abs > @@namespace_stack.size + 1
        self << (namespaced_constant || (@@namespace_stack + [constant_name.red!]).join('.'))
      end
    end
    
    class InstanceVariable < VariableNode # :nodoc:
      def initialize(variable_name, options = {})
        self << "this.$%s" % [variable_name.red!]
      end
    end
    
    class GlobalVariable < VariableNode # :nodoc:
    end
    
    class OtherVariable < VariableNode # :nodoc:
    end
  end
end
