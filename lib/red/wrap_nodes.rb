module Red
  class WrapNode # :nodoc:
    def initialize(expression = nil)
      @expression = expression.build_node
    end
    
    def compile_internals(options = {})
      return [@expression].compile_nodes(:as_argument => true)
    end
    
    class DefinedNode < WrapNode # :nodoc:
      def compile_node(options = {})
        return "typeof %s" % self.compile_internals
      end
    end
    
    class NotNode < WrapNode # :nodoc:
      def compile_node(options = {})
        return "!(%s)" % self.compile_internals
      end
    end
    
    class ReturnNode < WrapNode # :nodoc:
      def compile_node(options = {})
        return ("return %s" % self.compile_internals).rstrip
      end
    end
    
    class SuperNode < WrapNode # :nodoc:
      def initialize(args = [nil])
        case @@red_library
          when :Prototype : @args = args[1..-1].build_nodes
          else              raise(BuildError::NoSuperMethods, "Calls to super are not supported in #{@@red_library} JavaScript library")
        end
      end
      
      def compile_node(options = {})
        case @@red_library
          when :Prototype : return "$super(%s)" % @args.compile_nodes(:as_argument => true).join(', ')
          else              return ""
        end
      end
    end
    
    class YieldNode < WrapNode # :nodoc:
      def compile_node(options = {})
        return ("yield %s" % self.compile_internals).rstrip
      end
    end
  end
end
