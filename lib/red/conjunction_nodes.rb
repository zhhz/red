module Red
  class ConjunctionNode # :nodoc:
    def initialize(a, b)
      @a, @b = [a, b].build_nodes
    end
    
    def compile_internals(options = {})
      [@a, @b].compile_nodes(:as_argument => true)
    end
    
    class AndNode < ConjunctionNode # :nodoc:
      def compile_node(options = {})
        return "(%s && %s)" % self.compile_internals
      end
    end
    
    class OrNode < ConjunctionNode # :nodoc:
      def compile_node(options = {})
        return "(%s || %s)" % self.compile_internals
      end
    end
  end
end
