module Red
  class CallNode # :nodoc:
    class BlockNode # :nodoc:
      def initialize(receiver, arguments_array, expression = nil)
        @receiver, @expression = [receiver, expression].build_nodes
        @arguments = (((arguments_array ||= []).first == :masgn) ? arguments_array.assoc(:array)[1..-1].map {|node| node.last} : [arguments_array.last]).build_nodes
      end
      
      def compile_node(options = {})
        receiver = @receiver.compile_node.gsub(/\(\)$/,'')
        arguments = @arguments.compile_nodes.join(', ')
        expression = @expression.compile_node
        case receiver.to_sym
        when :lambda, :function, :proc
          "function(%s) { %s }" % [arguments, expression]
        else
          "%s(function(%s) { %s })" % [receiver, arguments, expression]
        end
      end
    end
    
    class MatchNode # :nodoc:
      def initialize(regex, expression)
        @regex, @expression = [regex, expression].build_nodes
      end
      
      def compile_node(options = {}) # :nodoc:
        regex = @regex.compile_node
        expression = @expression.compile_node(:as_argument => true)
        "%s.match(%s)" % [regex, expression]
      end
      
      class ReverseNode < MatchNode # :nodoc:
        def initialize(expression, regex)
          @regex, @expression = [regex, expression].build_nodes
        end
      end
    end
    
    class MethodNode # :nodoc:
      def compile_node(options = {})
        call_to_returned_function = [DefinitionNode::InstanceMethodNode, CallNode::BlockNode].include?(@receiver.class) ? :call : false
        receiver, function = [@receiver, @function].compile_nodes
        arguments = @arguments.compile_nodes(:as_argument => true, :quotes => "'")
        return ("$%s(%s)" % [receiver = ((receiver == '$-') || (receiver == 'id' && @@red_library == :Prototype) ? nil : receiver), arguments.first]).gsub('$$','$').gsub('$class','$$') if @receiver.is_a?(VariableNode::GlobalVariableNode) && function == '-'
        case function.to_sym
        when :-, :+, :<, :>, :%, :*, :/, :^, :==, :===, :instanceof
          "%s %s %s" % [receiver, function, arguments.first]
        when :raise
          "throw(%s)" % [arguments.first]
        when :new
          "new %s(%s)" % [receiver, arguments.join(', ')]
        when :var
          "var %s" % [arguments.join(', ')]
        when :[]
          if ([:symbol, :string].include?(@arguments.first.data_type) rescue false)
            arguments = @arguments.compile_nodes(:quotes => "", :as_argument => true)
            "%s.%s"
          else
            "%s[%s]"
          end % [receiver, arguments.first]
        when call_to_returned_function
          "(%s)(%s)" % [receiver, arguments]
        else
          receiver += '.' unless receiver.empty?
          "%s%s(%s)" % [receiver, function, arguments.join(', ')]
        end
      end
      
      def increment_operator
        return @function.compile_node if ['+', '-'].include?(@function.compile_node) && @arguments.first.compile_node == '1'
      end
      
      class ExplicitNode < MethodNode # :nodoc:
        def initialize(receiver, function, arguments = [nil])
          @receiver, @function = [receiver, function].build_nodes
          @arguments = arguments[1..-1].build_nodes
        end
      end
      
      class ImplicitNode < MethodNode # :nodoc:
        def initialize(function, arguments = [nil])
          @function = function.build_node
          @receiver = (:self if @function.compile_node == '[]').build_node
          @arguments = arguments[1..-1].build_nodes
        end
      end
    end
  end
end
