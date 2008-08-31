module Red
  class CallNode < String # :nodoc:
    class Block < CallNode # :nodoc:
      def initialize(receiver, block_args, *args)
        options = args.pop
        expression = args[0].is_a?(Array) && args[0][0] == :block ? args[0] : [:block, args[0] || [:nil]]
        block_arguments = (block_args.is_a?(Array) && block_args.first == :masgn) ? block_args.assoc(:array)[1..-1].map { |dasgn_curr| dasgn_curr.last.red!(:as_argument => true) } : [(block_args.last rescue nil).red!(:as_argument => true)]
        block = "function(%s) { %s; }._as(this)" % [block_arguments.join(', '), expression.red!(:force_return => true)]
        if  [:proc, :lambda].include?(receiver.last)
          self << block
        else
          receiver_arguments_sexp = receiver.last.is_a?(Array) && receiver.last.first == :array ? receiver.last[1..-1] : []
          receiver_arguments = receiver_arguments_sexp.map {|arg| arg.red!(:as_argument => true, :quotes => "'")}
          object = receiver.reject{|sexp| sexp == receiver_arguments_sexp}.red!(:suppress_arguments => true)
          self << "%s(%s)" % [object, (receiver_arguments + [block]).compact.join(', ')]
        end
      end
      
      class Ampersand < Block # :nodoc:
        def initialize(block_name, function_call, options)
          function_call.last.is_a?(Array) && function_call.last.first == :array ? function_call.last << block_name : function_call << [:array, block_name]
          self << function_call.red!(options)
        end
      end
    end
    
    class Match # :nodoc:
      def initialize(regex, expression)
        @regex, @expression = [regex, expression].build_nodes
      end
      
      def compile_node(options = {}) # :nodoc:
        regex = @regex.compile_node
        expression = @expression.compile_node(:as_argument => true)
        "%s.match(%s)" % [regex, expression]
      end
      
      class Reverse < Match # :nodoc:
        def initialize(expression, regex)
          @regex, @expression = [regex, expression].build_nodes
        end
      end
    end
    
    class Method < CallNode # :nodoc:
      def sugar(receiver, function, args, options)
        object = receiver.red!(:as_argument => true)
        arguments = "(%s)" % [args.last.is_a?(Array) && args.last.first == :array ? args.last[1..-1].map {|arg| arg.red!(:as_argument => true, :quotes => "'")} : []].join(', ') unless options[:suppress_arguments]
        single_arg = (args.last[1] rescue nil).red!(:as_argument => true)
        case function
        when :-, :+, :<, :>, :>=, :<=, :%, :*, :/, :^, :===, :in, :instanceof
          string = options[:as_argument] ? "(%s %s %s)" : "%s %s %s"
          self << string % [object, function.red!, single_arg]
        when :include
          namespace = @@namespace_stack.empty? ? 'Object' : @@namespace_stack.join('.')
          instance_methods = "for (var x in %s) { if (!(x.slice(0,2) == '$$')) { %s.prototype[x] = _mod[x]; }; }" % [single_arg, namespace, single_arg]
          class_variables = "for (var x in %s) { if (!(x == 'prototype')) { %s[x] = %s[x]; }; }" % [single_arg, namespace, single_arg]
          self << [instance_methods, class_variables].join(";\n\n")
        when :[]
          object = "this" if receiver.nil?
          args = (args.last.is_a?(Array) && args.last.first == :array) ? args.last[1..-1] : []
          self << "%s._g%s" % [object, arguments]
          #if args.assoc(:str) || args.assoc(:lit) && args.assoc(:lit)[1].is_a?(Symbol)
          #  self << "%s.%s" % [object, args[0][1]]
          #else
          #  self << "%s[%s]" % [object, single_arg]
          #end
        when :raise
          self << "throw(%s)" % [single_arg]
        when :new
          self << "new %s%s" % [object, arguments]
        when :==
          self << "%s.eqlBool(%s)" % [object, single_arg]
        when :<<
          self << "%s._ltlt(%s)" % [object, single_arg]
        else
          object = receiver.nil? ? "" : "%s." % [object]
          self << "%s%s%s" % [object, function.red!, arguments]
        end
      end
      
      class ExplicitReceiver < Method # :nodoc:
        def initialize(receiver, function, *args)
          (args << function) && function = receiver && receiver = nil if args.empty?
          options = args.pop
          self.sugar(receiver, function, args, options)
        end
      end
      
      class ImplicitReceiver < Method # :nodoc:
        def initialize(function, *args)
          options = args.pop
          self.sugar([:self], function, args, options)
        end
      end
    end
    
    class Super < CallNode # :nodoc:
      def initialize(*args)
        options = args.pop
        arguments = (args.first[1..-1] rescue []).unshift([:self]).map {|arg| arg.red!(:as_argument => true) }
        self << "this.class().superclass().prototype.%s.apply(%s)" % [@@red_function, arguments.join(', ')]
      end
    end
    
    class Yield < CallNode # :nodoc:
      def initialize(args = nil, options = {})
        (options = args) && (args = nil) if args.is_a?(Hash)
        arguments = args ? ( args.first == :array ? args[1..-1].map {|arg| arg.red!(:as_argument => true) } : [args.red!(:as_argument => true)] ) : []
        self << "block(%s)" % [arguments.join(', ')]
      end
    end
  end
end
