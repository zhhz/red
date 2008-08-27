module Red
  class DefinitionNode < String # :nodoc:
    def nodes(*node_types)
      lambda {|node| node.is_a?(Array) && node_types.include?(node.first) }
    end
    
    def attr_sexp(attribute)
      return [:defn, attribute, [:scope, [:block, [:args], [:ivar, :"@#{attribute}"]]]]
    end
    
    class Class < DefinitionNode # :nodoc:
      def initialize(class_name, superclass, scope, options)
        # Add the string name of this module to the namespace hierarchy.
        @@namespace_stack.push(class_name.red!)
        namespaced_class = @@namespace_stack.join('.')
        
        # Split out the various pieces needed to emulate class behavior.
        block = scope.assoc(:block) || scope
        attrs      = block.rassoc(:attr) ? block.delete(block.rassoc(:attr)).assoc(:array)[1..-1].map {|node| self.attr_sexp(node.last.to_sym).red!(:as_property => true) } : []
        arguments  = (block.rassoc(:initialize).assoc(:scope).assoc(:block).assoc(:args)[1..-1] rescue nil) || []
        properties = block.select(&nodes(:cvdecl))
        functions  = block.select(&nodes(:defn))
        modules    = block.select(&nodes(:module))
        classes    = block.select(&nodes(:class))
        class_eval = block.reject(&nodes(:cvdecl, :defn, :module, :class))
        included   = class_eval.select {|node| node.is_a?(Array) && node[0..1] == [:fcall, :include]}
        class_eval = class_eval.reject {|node| node.is_a?(Array) && node[0..1] == [:fcall, :include]}
        
        # Combine and compile.
        arguments  = arguments.map {|argument| argument.red!(:as_argument => true)}
        functions  = attrs + functions.map {|function| function.red!(:as_property => true)}
        properties = properties.map {|property| property.red!(:as_property => true)}
        children = (modules + classes).map {|node| node.red! }
        constructor = "%s%s = function %s(%s) { this.initialize.apply(this, arguments) }" % [("var " unless namespaced_class.include?('.')), namespaced_class, class_name, arguments.join(', ')] unless @@red_classes.include?(namespaced_class)
        included = included.map {|node| node.red! }
        instance_methods = "for (var x in _mod = {\n  %s\n}) { %s.prototype[x] = _mod[x] }" % [functions.join(",\n  \n  "), namespaced_class] unless functions.empty?
        class_variables = "for (var x in _mod = {\n  %s\n}) { %s[x] = _mod[x] }" % [properties.join(",\n  \n  "), namespaced_class] unless properties.empty?
        
        # Return the compiled JavaScript string.
        self << [constructor, included.join(";\n\n"), instance_methods, class_variables, children.join(";\n\n"), (class_eval.red! rescue '')].compact.reject {|x| x.empty?}.join(";\n\n")
        
        # Go back up one level in the namespace hierarchy, and add this
        # to the list of classes that Red knows about.
        @@red_classes |= [namespaced_class]
        @@namespace_stack.pop
      end
      
      # Pull the "initialize" method from the class definition, or inherit
      # it from the superclass; then link the initializer to this class for
      # future inheritance.
      # @superclass = superclass.build_node
      # initializer_node = @@red_initializers[@@namespace_stack.join('.')] = (block_node = scope.assoc(:block) || scope).rassoc(:initialize) || @@red_initializers[@superclass.compile_node] || @@red_initializers['']
      
      # Build nodes for the initializer and for its arguments.
      # args_node = initializer_node.assoc(:scope).assoc(:block).assoc(:args)
      # @arguments = (args_node[1..-1] || []).build_nodes
      # @initializer = initializer_node.assoc(:scope).assoc(:block).reject { |node| node == args_node }.build_node
      # @functions  = block_node.select(&nodes(:defn)).build_nodes#.reject {|node| node[1] == :initialize }.build_nodes
      
      # If the superclass is not one of the recognized namespaces, prefix it
      # with the current namespace.
      # superclass = @superclass.compile_node
      # superclass = (@@namespace_stack + [superclass]).join('.') unless superclass.empty? || @@red_classes.include?(superclass)
      
      # Determine whether this is a reopened class.
      # reopened = @@red_classes.include?(namespaced_class)
      
      # initializer = @initializer.compile_node(:no_return => true)
      
      # Compile the pieces into JavaScript strings.
      # inheritance = "for (var x in %s) { %s[x] = %s[x] }; %s.prototype = new %s" % [superclass, namespaced_class, superclass, namespaced_class, superclass] unless superclass.empty?
    end
    
    class Module < DefinitionNode # :nodoc:
      def initialize(module_name, scope, options)
        # Add the string name of this module to the namespace hierarchy.
        @@namespace_stack.push(module_name.red!)
        namespaced_module = @@namespace_stack.join('.')
        
        # Split out the various pieces needed to emulate module behavior.
        block = scope.assoc(:block) || scope
        properties  = block.select(&nodes(:cvdecl))
        functions   = block.select(&nodes(:defn))
        modules     = block.select(&nodes(:module))
        classes     = block.select(&nodes(:class))
        module_eval = block.reject(&nodes(:cvdecl, :defn, :module, :class))
        
        # Combine and compile.
        slots = (properties + functions).map {|node| node.red!(:as_property => true)}
        children = (modules + classes).map {|node| node.red! }
        constructor = "%s%s = { }" % [("var " unless namespaced_module.include?('.')), namespaced_module] unless @@red_modules.include?(namespaced_module)
        slots = "for (var x in _mod = {\n  %s\n}) { %s[x] = _mod[x] }" % [slots.join(",\n  \n  "), namespaced_module] unless slots.empty?
        
        # Return the compiled JavaScript string.
        self << [constructor, slots, children.join(";\n\n"), (module_eval.red! rescue '')].compact.reject {|x| x.empty?}.join(";\n\n")
        
        # Go back up one level in the namespace hierarchy, and add this module
        # to the list of modules that Red knows about.
        @@red_modules |= [namespaced_module]
        @@namespace_stack.pop
      end
      
      #def initialize(module_name, scope)
      #  # Pull any "initialize" method from the module definition and link it
      #  # to this class for future inclusion.
      #  @@red_initializers[@@namespace_stack.join('.')] = (block_node = scope.assoc(:block) || scope).rassoc(:initialize) || @@red_initializers['']
      #  
      #  @functions  = block_node.select(&nodes(:defn)).reject {|node| node[1] == :initialize }.build_nodes
      #end
    end
    
    class Method < DefinitionNode # :nodoc:
      def args_and_contents_from(block, function, indent = 0)
        block_arg = block.delete(block.assoc(:block_arg)) || ([:block_arg, :block] if block.flatten.include?(:yield))
        arguments = block.delete(block.assoc(:args))[1..-1] || []
        defaults = arguments.delete(arguments.assoc(:block))
        arguments = (block_arg ? arguments << block_arg.last : arguments).map {|arg| arg.red!(:as_argument => true)}
        contents = [("blockGivenBool = function() { return !!block; }" if block_arg), defaults.red!(:as_default => true), block.red!(:force_return => function != 'initialize', :indent => indent)].compact.reject {|x| x.empty? }
        return [arguments, contents]
      end
      
      class Instance < Method # :nodoc:
        def initialize(function_name, scope, options)
          function = function_name.red!
          block = scope.assoc(:block)
          indent = options[:as_property] ? 2 : 0
          arguments, contents = self.args_and_contents_from(block, function, indent)
          if options[:as_property]
            self << "%s: function %s(%s) {\n    %s;\n  }" % [function, function, arguments.join(', '), contents.join(";\n    ")]
          else
            self << "function %s(%s) { %s; }" % [function, arguments.join(', '), contents.join(";\n")]
          end
        end
      end
      
      class Singleton < Method # :nodoc:
        def initialize(object, function_name, scope, options)
          function = function_name.red!
          receiver = "%s.%s" % [(object == [:self] ? @@namespace_stack.join('.') : object.red!), function]
          block = scope.assoc(:args) ? (scope << [:block, scope.delete(scope.assoc(:args)), [:nil]]).assoc(:block) : scope.assoc(:block)
          block << [:nil] if block.assoc(:block_arg) == block.last
          arguments, contents = self.args_and_contents_from(block, function)
          self << "%s = function %s(%s) { %s; }" % [receiver, function, arguments.join(', '), contents]
        end
      end
    end
    
    class SingletonClass < DefinitionNode # :nodoc:
      #def initialize(receiver, scope)
      #  old_class = @@red_class
      #  @@red_class = @class = receiver.build_node.compile_node
      #  block_node = scope.assoc(:block) || scope
      #  properties = block_node.select {|node| (node.first == :cvdecl) rescue false }
      #  functions = block_node.select {|node| ![:block, :scope].include?(node) }
      #  @slots = (properties | functions).build_nodes
      #  @@red_class = old_class
      #end
      #
      #def compile_node(options = {})
      #  old_class = @@red_class
      #  @@red_class = @class
      #  slots = @slots.compile_nodes(:as_property => true).compact.join(', ')
      #  @@red_class = old_class
      #  return "{ %s }" % [slots]
      #end
    end
  end
end
