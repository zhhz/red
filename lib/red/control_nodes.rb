module Red
  class ControlNode # :nodoc:
    class BeginNode # :nodoc:
      def initialize(body)
        @@rescue_is_safe = (body.first == :rescue)
        @body = body.build_node
      end
      
      def compile_node(options = {})
        "%s" % [@body.compile_node]
      end
    end
    
    class EnsureNode # :nodoc:
      def initialize(attempted, ensure_body)
        @@rescue_is_safe = @ensure_from_rescue = attempted.first == :rescue
        @attempted, @ensured = [attempted, ensure_body].build_nodes
      end
      
      def compile_node(options = {})
        if @ensure_from_rescue
          "%s finally { %s; }" 
        else
          "try { %s; } finally { %s; }"
        end % self.compile_internals
      end
      
      def compile_internals(options = {})
        return [@attempted, @ensured].compile_nodes
      end
    end
    
    class ForNode # :nodoc:
      def initialize(source, iterator, body)
        @properties_loop = (iterator.last == :property)
        @source, @iterator, @body = [source, iterator.last, body].build_nodes
      end
      
      def compile_node(options = {})
        source = @source.compile_node(:as_argument => true)
        iterator = @iterator.compile_node
        body = @body.compile_node
        if @properties_loop
          "for (var property in %s) { %s; }" % [source, body]
        else
          "for (var %s = 0; %s < %s.length; %s++) { %s; }" % [iterator, iterator, source, iterator, body]
        end
      end
    end
    
    class RescueNode # :nodoc:
      def initialize(attempted, rescue_body)
        raise(BuildError::NoArbitraryRescue, "JavaScript does not support arbitrary placement of rescue/try blocks") unless @@rescue_is_safe
        raise(BuildError::NoSpecificRescue, "JavaScript does not support rescuing of specific exception classes") unless !rescue_body[1]
        @@rescue_is_safe == false
        @attempted = attempted.build_node
        if (block = (rescue_body.assoc(:block) || [])[1..-1]) && block.first.last == [:gvar, %s($!)]
          exception_node = block.shift
          @exception_variable = exception_node[1].build_node
          @rescued = block.unshift(:block).build_node
        else
          @exception_variable = :e.build_node
          @rescued = rescue_body[2].build_node
        end
      end
      
      def compile_node(options = {})
        return "try { %s; } catch(%s) { %s; }" % self.compile_internals
      end
      
      def compile_internals(options = {})
        return [@attempted, @exception_variable, @rescued].compile_nodes
      end
    end
    
    class UntilNode # :nodoc:
      def initialize(condition, body, run_only_if_condition_met)
        @condition, @body = [condition, body].build_nodes
        @do_while_loop = !run_only_if_condition_met
      end
      
      def compile_node(options = {})
        if @do_while_loop
          return "do { %s; } while (!(%s))" % self.compile_internals.reverse
        else
          return "while (!(%s)) { %s; }" % self.compile_internals
        end
      end
      
      def compile_internals(options = {})
        condition, body = [@condition, @body].compile_nodes
        return [condition, body]
      end
    end
    
    class WhileNode # :nodoc:
      def initialize(condition, body, run_only_if_condition_met)
        @condition, @body = [condition, body].build_nodes
        @do_while_loop = !run_only_if_condition_met
      end
      
      def compile_node(options = {})
        if @do_while_loop
          return "do { %s; } while (%s)" % self.compile_internals.reverse
        else
          return "while (%s) { %s; }" % self.compile_internals
        end
      end
      
      def compile_internals(options = {})
        condition, body = [@condition, @body].compile_nodes
        return [condition, body]
      end
    end
    
    class LibraryNode # :nodoc:
      def initialize(library)
        @@red_library = @library = library
      end
      
      def compile_node(options = {})
        @@red_library = @library
        nil
      end
    end
  end
end
