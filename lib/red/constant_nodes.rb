module Red
  class ConstantNode # :nodoc:
    class BreakNode < ConstantNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoBreakArguments, "Break can't take an argument in JavaScript") unless args.empty?
      end
      
      def compile_node(options = {})
        return "break"
      end
    end
    
    class FalseNode < ConstantNode # :nodoc:
      def compile_node(options = {})
        return "false"
      end
    end
    
    class NextNode < ConstantNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoNextArguments, "Next/continue can't take an argument in JavaScript") unless args.empty?
      end
      
      def compile_node(options = {})
        return "continue"
      end
    end
    
    class NilNode < ConstantNode # :nodoc:
      def compile_node(options = {})
        return "null"
      end
    end
    
    class SelfNode < ConstantNode # :nodoc:
      def compile_node(options = {})
        return "this"
      end
    end
    
    class TrueNode < ConstantNode # :nodoc:
      def compile_node(options = {})
        return "true"
      end
    end
  end
end
