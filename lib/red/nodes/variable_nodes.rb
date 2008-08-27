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
