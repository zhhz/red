module Red
  class DefinitionNode # :nodoc:
    class ClassNode # :nodoc:
      def initialize(class_name, superclass, scope)
        raise(BuildError::NoClassInheritance, "Class inheritance is currently not supported#{"for the #{@@red_library} JavaScript library";''}") if superclass
        old_class = @@red_class
        @@red_class = @class = class_name
        @class_name, @superclass = [class_name, superclass].build_nodes
        block_node = scope.assoc(:block) || scope
        if initializer_node = block_node.rassoc(:initialize)
          args_node = initializer_node.assoc(:scope).assoc(:block).assoc(:args)
          @arguments = (args_node[1..-1] || []).build_nodes
          @initializer = initializer_node.assoc(:scope).assoc(:block).reject {|node| node == args_node}.build_node
        end
        properties = block_node.select {|node| (node.first == :cvdecl) rescue false }
        functions = block_node.select {|node| (node != initializer_node) && ![:block, :scope].include?(node) }
        @slots = (properties | functions).build_nodes
        @@red_class = old_class
      end
      
      def compile_node(options = {})
        old_class = @@red_class
        @@red_class = @class
        if @initializer
          output = self.compile_as_standard_class
        else
          output = self.compile_as_virtual_class
        end
        @@red_class = old_class
        return output
      end
      
      def compile_as_standard_class(options = {})
        class_name = @class_name.compile_node
        arguments = @arguments.compile_nodes.join(', ')
        slots = @slots.compile_nodes(:as_attribute => true)
        initializer = @initializer.compile_node
        return "%s%s = function(%s) { %s;%s }" % [self.var?, class_name, arguments, initializer, slots]
      end
      
      def compile_as_virtual_class(options = {})
        class_name = @class_name.compile_node
        slots = @slots.compile_nodes(:as_prototype => true).compact.join(', ')
        return "%s%s = { %s }" % [self.var?, class_name, slots]
      end
      
      def var?
        return "var " unless @class_name.is_a?(LiteralNode::NamespaceNode)
      end
    end
    
    class ClassMethodNode # :nodoc:
      def initialize(receiver, function_name, scope)
        @receiver, @function_name = [receiver, function_name].build_nodes
        @arguments = (scope.assoc(:block).assoc(:args)[1..-1] || []).build_nodes
        @lines = (scope.assoc(:block)[2..-1] || []).build_nodes
      end
      
      def compile_node(options = {})
        case false
        when options[:as_attribute].nil?
          "this.%s = function(%s) { %s; }"
        when options[:as_prototype].nil?
          "%s: function(%s) { %s; }"
        when !(options[:as_attribute].nil? && options[:as_prototype].nil?)
          "function %s(%s) { %s; }"
        end % self.compile_internals
      end
      
      def compile_internals(options = {})
        function_name = @function_name.compile_node
        arguments = @arguments.compile_nodes.join(', ')
        lines = @lines.compile_nodes.compact.join('; ')
        return [function_name, arguments, lines]
      end
    end
    
    class InstanceMethodNode # :nodoc:
      def initialize(function_name, scope)
        block = scope.assoc(:block)
        @@rescue_is_safe = (block[2].first == :rescue)
        @function_name = (function_name == :function ? nil : function_name).build_node
        @arguments = (block.assoc(:args)[1..-1] || []).build_nodes
        @lines = (block[2..-1] || []).build_nodes
      end
      
      def compile_node(options = {})
        case false
        when options[:as_attribute].nil?
          "this.%s = function(%s) { %s; }"
        when options[:as_prototype].nil?
          "%s: function(%s) { %s; }"
        when !(options[:as_attribute].nil? && options[:as_prototype].nil?)
          "function %s(%s) { %s; }"
        end % self.compile_internals
      end
      
      def compile_internals(options = {})
        function_name = @function_name.compile_node
        arguments = @arguments.compile_nodes.join(', ')
        lines = @lines.compile_nodes.compact.join('; ')
        return [function_name, arguments, lines]
      end
    end
    
    class ModuleNode # :nodoc:
      def initialize(module_name, scope)
        old_module = @@red_module
        @@red_module = module_name
        @module_name, @scope = [module_name, scope].build_nodes
        @@red_module = old_module
      end
      
      def compile_node(options = {})
        return "%s" % self.compile_internals
      end
      
      def compile_internals(options = {})
        old_module = @@red_module
        @@red_module = @module_name.compile_node
        scope = @scope.compile_node
        @@red_module = old_module
        return [scope]
      end
    end
    
      
    class ObjectLiteralNode # :nodoc:
      def initialize(receiver, scope)
        block_node = scope.assoc(:block) || scope
        properties = block_node.select {|node| (node.first == :cvdecl) rescue false }
        functions = block_node.select {|node| ![:block, :scope].include?(node) }
        @slots = (properties | functions).build_nodes
      end
      
      def compile_node(options = {})
        slots = @slots.compile_nodes(:as_prototype => true).compact.join(', ')
        return "{ %s }" % [slots]
      end
    end
  end
end
