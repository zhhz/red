module Red
  class AssignmentNode # :nodoc:
    def initialize(variable_name, expression)
      raise(BuildError::NoMultilineAssignment, "Multiline assignment (e.g. foo = begin; line1; line2; end) is not supported") if expression.first == :block
      @variable_name, @expression = [variable_name, expression].build_nodes
    end
    
    def compile_internals(options = {})
      return [@variable_name, @expression].compile_nodes(:as_argument => true)
    end
    
    class ClassVariableNode < AssignmentNode  # :nodoc:
      def compile_node(options = {})
        expression = @expression.compile_node(:as_argument => true)
        if options[:as_prototype]
          receiver = @variable_name.compile_node
          "%s: %s"
        else
          receiver = "%s.%s" % [@@red_class, @variable_name.compile_node]
          "%s = %s"
        end % [receiver, expression]
      end
    end
    
    class GlobalVariableNode < AssignmentNode  # :nodoc:
      def compile_node(options = {})
        return "%s = %s" % self.compile_internals
      end
    end
    
    class InstanceVariableNode < AssignmentNode # :nodoc:
      def compile_node(options = {})
        return "this.%s = %s" % self.compile_internals
      end
    end
    
    class LocalVariableNode < AssignmentNode # :nodoc:
      def compile_node(options = {})
        return (@variable_name.is_a?(LiteralNode::NamespaceNode) ? "%s = %s" : "var %s = %s") % self.compile_internals
      end
    end
    
    class AttributeNode # :nodoc:
      def initialize(variable_name, slot_equals, arguments)
        @variable_name, @expression = [variable_name, arguments.last].build_nodes
        @slot = (slot_equals == :[]= ? arguments[1] : slot_equals.to_s.gsub(/=/,'').to_sym).build_node
      end
      
      def compile_node(options = {})
        return "%s = %s" % compile_internals
      end
      
      def compile_internals(options = {})
        variable_name, slot, expression = [@variable_name, @slot, @expression].compile_nodes(:quotes => '', :as_argument => true)
        receiver = self.compile_receiver(variable_name, slot)
        return [receiver, expression]
      end
      
      def compile_receiver(variable_name, slot)
        return ([:symbol, :string].include?((@slot.data_type rescue :node)) ? "%s.%s" : "%s[%s]") % [variable_name, slot]
      end
    end
    
    class OperatorNode # :nodoc:
      def compile_node(options = {})
        return "%s%s = %s %s %s" % self.compile_internals
      end
      
      def compile_internals(options = {})
        receiver, operation = [@receiver, @operation].compile_nodes
        expression = @expression.compile_node(:as_argument => true)
        slot       = @slot.compile_node(:quotes => '')
        original   = self.compile_receiver(receiver, slot)
        var        = (self.var? rescue nil)
        return [var, original, original, operation, expression]
      end
      
      class BracketNode < OperatorNode # :nodoc:
        def initialize(receiver, bracket_contents, operation, expression)
          @receiver, @slot, @operation, @expression = [receiver, bracket_contents.last, operation, expression].build_nodes
        end
        
        def compile_receiver(receiver, slot)
          return ([:symbol, :string].include?((@slot.data_type rescue :node)) ? "%s.%s" : "%s[%s]") % [receiver, slot]
        end
      end
      
      class DotNode < OperatorNode # :nodoc:
        def initialize(receiver, slot_equals, operation, expression)
          @receiver, @slot, @operation, @expression = [receiver, slot_equals.to_s.gsub(/=/,''), operation, expression].build_nodes
        end
        
        def compile_receiver(receiver, slot)
          return "%s.%s" % [receiver, slot]
        end
      end
      
      class OrNode < OperatorNode # :nodoc:
        def initialize(receiver, assignment_node_array)
          @receiver, @slot, @operation, @expression = [receiver, nil, %s(||), assignment_node_array.last].build_nodes
        end
        
        def compile_receiver(receiver, slot)
          return "%s" % [receiver]
        end
        
        def var?
          return "var " unless [VariableNode::GlobalVariableNode, VariableNode::InstanceVariableNode].include?(@receiver.class)
        end
      end
      
      class AndNode < OperatorNode # :nodoc:
        def initialize(receiver, assignment_node_array)
          @receiver, @slot, @operation, @expression = [receiver, nil, %s(&&), assignment_node_array.last].build_nodes
        end
        
        def compile_receiver(receiver, slot)
          return "%s" % [receiver]
        end
        
        def var?
          return "var " unless [VariableNode::GlobalVariableNode, VariableNode::InstanceVariableNode].include?(@receiver.class)
        end
      end
    end
  end
end
