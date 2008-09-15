module Red
  class DefinitionNode < String # :nodoc:
    class Class < DefinitionNode # :nodoc:
      # [:class, :Foo, (expression), [:scope, (expression | :block)]] => superclass doesn't show up sometimes when namespaced a certain way; I forgot what the pattern is though
      def initialize(class_name_sexp, superclass_sexp, scope_sexp, options = {})
        (options = scope_sexp) && (scope_sexp = superclass_sexp) && (superclass_sexp = nil) if scope_sexp.is_a?(Hash)
        class_name = class_name_sexp.red!
        superclass = superclass_sexp.red!
        
        if class_name_sexp.is_sexp?(:colon3)
          old_namespace_stack = @@namespace_stack
          namespaced_class    = class_name
          @@namespace_stack   = [namespaced_class]
        elsif class_name_sexp.is_sexp?(:colon2)
          @@namespace_stack.push(class_name)
          namespaced_class    = class_name
          class_name          = class_name_sexp.last.red!
        else
          @@namespace_stack.push(class_name)
          namespaced_class    = @@namespace_stack.join(".")
        end
        @@red_constants |= [namespaced_class]
        
        scope = scope_sexp.red!(:as_class_eval => true)
        
        unless @@red_classes.include?(namespaced_class)
          constructor = "%s=function %s(){this.m$_assignId();this.m$initialize.apply(this,arguments)}" % [namespaced_class, class_name]
          classlike   = "var _x;for(_x in Class.prototype){%s[_x]=Class.prototype[_x];}" % [namespaced_class]
        end
        
        unless %w(Object).include?(class_name)
          superclass        = "Red" if superclass.empty?
          inherit_cvars     = "var _x;for(_x in %s){if(_x.slice(0,2)==='c$'){%s[_x]=%s[_x];};}" % [superclass, namespaced_class, superclass]
          inherit_methods   = "var _x;for(_x in %s.prototype){if(_x.slice(0,2)==='m$'){%s.prototype[_x]=%s.prototype[_x];};}" % [superclass, namespaced_class, superclass]
          superclass_method = "%s.m$superclass=function superclass(){return %s;}" % [namespaced_class, superclass] unless %w(Module Class).include?(class_name)
          inheritance       = [inherit_cvars, inherit_methods, superclass_method].join(";\n")
        end
        
        class_eval_block = "%s.m$instanceEval(function(){var _o=this.prototype;\n_o.m$class=function class(){return %s;};\n%s;})" % [namespaced_class, namespaced_class, scope]
        
        self << [constructor, classlike, inheritance, class_eval_block].compact.join(";\n")
        
        @@red_classes |= [namespaced_class]
        old_namespace_stack.nil? ? @@namespace_stack.pop : @@namespace_stack = old_namespace_stack
      end
    end
    
    class Module < DefinitionNode # :nodoc:
      # [:module, :Foo, [:scope, (expression | :block)]]
      def initialize(module_name_sexp, scope_sexp, options)
        module_name = module_name_sexp.red!
        
        if module_name_sexp.is_sexp?(:colon3)
          old_namespace_stack = @@namespace_stack
          namespaced_module   = module_name
          @@namespace_stack   = [namespaced_module]
        elsif module_name_sexp.is_sexp?(:colon2)
          namespaced_module   = module_name
          module_name         = module_name_sexp.last.red!
          @@namespace_stack.push(module_name)
        else
          @@namespace_stack.push(module_name)
          namespaced_module   = @@namespace_stack.join(".")
        end
        @@red_constants |= [namespaced_module]
        
        scope = scope_sexp.red!(:as_class_eval => true)
        
        unless @@red_modules.include?(namespaced_module)
          constructor = "%s=new(Module)()" % [namespaced_module]
        end
        
        module_eval_block = "%s.m$instanceEval(function(){var _o=this.i$_methods;\n%s;})" % [namespaced_module, scope] unless scope.empty?
        
        self << [constructor, module_eval_block].compact.join(";\n")
        
        @@red_modules |= [namespaced_module]
        @@namespace_stack.pop
      end
    end
    
    class Method < DefinitionNode # :nodoc:
      # def args_and_contents_from(scope, function)
      #   block = scope.assoc(:block) || scope
      #   block_arg = block.delete(block.assoc(:block_arg)) || ([:block_arg, :block] if block.flatten.include?(:yield))
      #   arguments = block.assoc(:args) ? block.assoc(:args)[1..-1] || [] : []
      #   defaults = arguments.delete(arguments.assoc(:block))
      #   splat_arg = arguments.pop.to_s[1..-1] if arguments.last && arguments.last.to_s.include?('*')
      #   arguments = (block_arg ? arguments << block_arg.last : arguments).map {|arg| arg.red!}
      #   block_given = "var blockGivenBool=(typeof(arguments[arguments.length-1])=='function')" if block_arg
      #   args_array = "var blockGivenBool;var l=(blockGivenBool?arguments.length-1:arguments.length);#{splat_arg}=[];for(var i=#{block_arg ? arguments.size - 1 : arguments.size};i<l;++i){#{splat_arg}.push(arguments[i]);};var block=(blockGivenBool?arguments[arguments.length-1]:nil)" if splat_arg
      #   contents = [block_given, args_array, defaults.red!(:as_argument_default => true), scope.red!(:force_return => function != 'initialize')].compact.reject {|x| x.empty? }
      #   return [arguments, contents]
      # end
      
      class Instance < Method # :nodoc:
        # [:defn, :foo, [:scope, [:block, [:args, (:my_arg1, :my_arg2, ..., :'*my_args', (:block))], (:block_arg, :my_block), {expression}, {expression}, ...]]
        def initialize(function_name_sexp, scope_sexp, options)
          function        = (METHOD_ESCAPE[function_name_sexp] || function_name_sexp).red!
          @@red_function  = function
          block_sexp      = scope_sexp.assoc(:block)
          block_arg_sexp  = block_sexp.delete(block_sexp.assoc(:block_arg)) || ([:block_arg, :_block] if block_sexp.flatten.include?(:yield))
          @@red_block_arg = block_arg_sexp.last if block_arg_sexp
          argument_sexps  = block_sexp.assoc(:args)[1..-1] || []
          defaults_sexp   = argument_sexps.delete(argument_sexps.assoc(:block))
          splat_arg       = argument_sexps.pop.to_s[1..-1] if argument_sexps.last && argument_sexps.last.to_s.include?('*')
          argument_sexps += [block_arg_sexp.last] if block_arg_sexp
          args_array      = argument_sexps.map {|argument| argument.red! }
          block_given     = "var blockGivenBool=(typeof(arguments[arguments.length-1])=='function')" if block_arg_sexp
          splatten_args   = "var blockGivenBool;var _l=(blockGivenBool?arguments.length-1:arguments.length);#{splat_arg}=[];var i;for(i=#{block_arg_sexp ? argument_sexps.size - 1 : argument_sexps.size};i<_l;++i){#{splat_arg}.push(arguments[i]);};var #{block_arg_sexp.last rescue :_block}=(blockGivenBool?arguments[arguments.length-1]:nil)" if splat_arg
          defaults        = defaults_sexp.red!(:as_argument_default => true) if defaults_sexp
          arguments       = args_array.join(",")
          scope           = scope_sexp.red!(:force_return => function != 'initialize')
          contents        = [block_given, splatten_args, defaults, scope].compact.join(";")
          if options[:as_class_eval]
            #string = "_o.m$%s=function %s(%s){%s;}"
            string = "_o.m$%s=function(%s){%s;}"
          else
            #string = "m$%s=function %s(%s){%s;}"
            string = "m$%s=function(%s){%s;}"
          end
          #self << string % [function, function, arguments, contents]
          self << string % [function, arguments, contents]
          @@red_block_arg = nil
          @@red_function  = nil
        end
      end
      
      class Singleton < Method # :nodoc:
        # [:defs, {expression}, :foo, [:scope, (:block, [:args, (:my_arg1, :my_arg2, ..., :'*my_args', (:block))], (:block_arg, :my_block), {expression}, {expression}, ...)]
        def initialize(object_sexp, function_name_sexp, scope_sexp, options)
          function        = (METHOD_ESCAPE[function_name_sexp] || function_name_sexp).red!
          @@red_function  = function
          object          = object_sexp.is_sexp?(:self) ? @@namespace_stack.join(".") : object_sexp.red!
          singleton       = "%s.m$%s" % [object, function]
          block_sexp      = scope_sexp.assoc(:args) ? (scope_sexp << [:block, scope_sexp.delete(scope_sexp.assoc(:args)), [:nil]]).assoc(:block) : scope_sexp.assoc(:block)
          block_arg_sexp  = block_sexp.delete(block_sexp.assoc(:block_arg)) || ([:block_arg, :_block] if block_sexp.flatten.include?(:yield))
          @@red_block_arg = block_arg_sexp.last if block_arg_sexp
          block_sexp      = [[:nil]] if block_sexp.empty?
          argument_sexps  = block_sexp.assoc(:args)[1..-1] || []
          defaults_sexp   = argument_sexps.delete(argument_sexps.assoc(:block))
          splat_arg       = argument_sexps.pop.to_s[1..-1] if argument_sexps.last && argument_sexps.last.to_s.include?('*')
          argument_sexps += [block_arg_sexp.last] if block_arg_sexp
          args_array      = argument_sexps.map {|argument| argument.red! }
          block_given     = "var blockGivenBool=(typeof(arguments[arguments.length-1])=='function')" if block_arg_sexp
          splatten_args   = "var blockGivenBool;var _l=(blockGivenBool?arguments.length-1:arguments.length);#{splat_arg}=[];var i;for(i=#{block_arg_sexp ? argument_sexps.size - 1 : argument_sexps.size};i<_l;++i){#{splat_arg}.push(arguments[i]);};var #{block_arg_sexp.last rescue :_block}=(blockGivenBool?arguments[arguments.length-1]:nil)" if splat_arg
          defaults        = defaults_sexp.red!(:as_argument_default => true) if defaults_sexp
          arguments       = args_array.join(",")
          scope           = scope_sexp.red!(:force_return => function != 'initialize')
          contents        = [block_given, splatten_args, defaults, scope].compact.join(";")
          #self << "%s=function %s(%s){%s;}" % [singleton, function, arguments, contents]
          self << "%s=function(%s){%s;}" % [singleton, arguments, contents]
          @@red_block_arg = nil
          @@red_function  = nil
        end
      end
    end
    
    class Scope < DefinitionNode # :nodoc:
      # [:scope,  (expression | :block)]
      def initialize(contents_sexp = nil, options = {})
        (options = contents_sexp) && (contents_sexp = [:block]) if contents_sexp.is_a?(::Hash)
        variables  = []
        contents_sexp.flatten.each_with_index do |x,i|
          variables.push(contents_sexp.flatten[i + 1]) if [:lasgn,:vcall].include?(x)
        end
        variables -= (contents_sexp.delete(contents_sexp.assoc(:args)) || [])[1..-1] || [] # don't want to undefine the arguments in a method definition
        declare    = "var %s" % variables.map {|x| "%s=$u" % x.red! }.uniq.join(",") unless variables.empty?
        contents   = [declare, contents_sexp.red!(options)].compact.join(";")
        self << "%s" % contents
      end
    end
    
    class SingletonClass < DefinitionNode # :nodoc:
      # [:sclass, {expression}, [:scope, (expression | :block)]]
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
    
    class Undef < DefinitionNode # :nodoc:
      # [:undef, {expression}]
      def initialize(function_name_sexp, options)
        function_sexp = function_name_sexp.last.red!
        namespaced_function = @@namespace_stack.empty? ? function_sexp : (@@namespace_stack + ['prototype', "m$%s" % function_sexp]).join('.')
        self << "delete %s" % [namespaced_function]
      end
    end
  end
end
