module Red
  class VariableNode # :nodoc:
    def initialize(variable_name)
      @variable_name = variable_name.build_node
    end
    
    def compile_node(options = {})
      return "%s" % self.compile_internals
    end
    
    def compile_internals(options = {})
      return [@variable_name.compile_node]
    end
    
    class ClassVariableNode < VariableNode # :nodoc:
      def compile_node(options = {})
        return "%s.%s" % self.compile_internals
      end
      
      def compile_internals(options = {})
        return [@@red_class, @variable_name.compile_node]
      end
    end
    
    class InstanceVariableNode < VariableNode # :nodoc:
      def compile_node(options = {})
        return "this.%s" % self.compile_internals
      end
    end
    
    class GlobalVariableNode < VariableNode # :nodoc:
    end
    
    class OtherVariableNode < VariableNode # :nodoc:
    end
  end
end
