module Red
  class LiteralNode < String # :nodoc:
    class Array < LiteralNode # :nodoc:
      # [:zarray]
      # [:to_ary, {expression}]
      # [:array,  {expression}, {expression}, ...]
      def initialize(*element_sexps)
        options  = element_sexps.pop
        elements = element_sexps.map {|element_sexp| element_sexp.red!(:as_argument => true)}.join(",")
        self << "[%s]" % [elements]
      end
    end
    
    class Hash < LiteralNode # :nodoc:
      # [:hash, ({expression->key}, {expression->value}, ...)]
      def initialize(*element_sexps)
        options  = element_sexps.pop
        elements = element_sexps.map {|element_sexp| element_sexp.red!(:as_argument => true)}.join(",")
        self << "c$Hash.m$_brac(%s)" % [elements]
      end
    end
    
    class Multiline < LiteralNode # :nodoc:
      # [:block, {expression}, {expression}, ...]
      def initialize(*expression_sexps)
        # force_return: changes final expression to "return <expression>",
        #   unless there is already return anywhere inside <expression>.
        # as_argument: duplicates :force_return and adds "function() {
        #   <multiline block>; }()" wrapper to the entire block.
        options = expression_sexps.pop
        if options[:as_argument] || options[:as_assignment] || options[:force_return] && expression_sexps.last.is_a?(::Array) && !expression_sexps.last.is_sexp?(:rescue, :ensure, :begin) && (expression_sexps.last.first == :iter ? true : !expression_sexps.last.flatten.include?(:return))
          returner = "return %s" % [expression_sexps.pop.red!(:as_argument => true)]
        end
        string = options[:as_argument] || options[:as_assignment] ? "function(){%s;}.m$(this)()" : "%s"
        lines = (expression_sexps.map {|line| line.red!(options)} + [returner]).compact.reject {|x| x == '' }.join(";#{options[:as_class_eval] ? "\n  " : ''}")
        self << string % [lines]
      end
    end
    
    class Namespace < LiteralNode # :nodoc:
      # [:colon2, {expression}, :Foo]
      def initialize(namespace_sexp, class_name_sexp, options)
        namespace  = namespace_sexp.red!(:as_receiver => true)
        class_name = class_name_sexp.red!
        self << "%s.c$%s" % [namespace, class_name]
      end
      
      # [:colon3, :Foo]
      class TopLevel < LiteralNode # :nodoc:
        def initialize(class_name_sexp, options)
          class_name = class_name_sexp.red!
          self << "c$%s" % [class_name]
        end
      end
    end
    
    class Other < LiteralNode # :nodoc:
      # [:lit,    {number | regexp | range}]
      # [:svalue, [:array, {expression}, {expression}, ...]]
      # [:to_ary, {expression}] => right side of :masgn when arguments are too few
      def initialize(value_sexp = nil, options = {})
        (options = value_sexp) && (value_sexp = nil) if value_sexp.is_a?(::Hash)
        symbol_sexp = [:sym, value_sexp] if value_sexp.is_a?(::Symbol)
        regexp_sexp = [:regex, value_sexp] if value_sexp.is_a?(::Regexp)
        value = (regexp_sexp || symbol_sexp || value_sexp).red!(options)
        self << "%s" % [value]
      end
    end
    
    class Range < LiteralNode # :nodoc:
      # [:dot2, {expression}, {expression}]
      def initialize(start_sexp, finish_sexp, options)
        start  = start_sexp.red!(:as_argument => true)
        finish = finish_sexp.red!(:as_argument => true)
        self << "c$Range.m$new(%s,%s,false)" % [start, finish]
      end
      
      class Exclusive < Range # :nodoc:
        # [:dot3, {expression}, {expression}]
        def initialize(start_sexp, finish_sexp, options)
          start  = start_sexp.red!(:as_argument => true)
          finish = finish_sexp.red!(:as_argument => true)
          self << "c$Range.m$new(%s,%s,true)" % [start, finish]
        end
      end
    end
    
    class Regexp < LiteralNode # :nodoc:
      # [:lit, {regexp}]
      # ### [:dregex,  "foo", {expression}, {expression}, ...]
      def initialize(regexp_sexp, options)
        regexp = regexp_sexp.red!(:as_argument => true)
        self << "$r(%s)" % [regexp]
      end
    end
    
    class Splat < LiteralNode # :nodoc:
      # [:splat, {expression}]
      #def initialize(*args)
      #  case @@red_library
      #    when :Prototype : super(*args)
      #    else              raise(BuildError::NoSplatConstructor, "Splat array constructor not supported for #{@@red_library} JavaScript library")
      #  end
      #end
      #
      #def compile_node(options = {})
      #  initial = @initial.compile_node
      #  case @@red_library
      #    when :Prototype : return "$A(%s)" % [initial]
      #    else              ""
      #  end
      #end
    end
    
    class String < LiteralNode # :nodoc:
      # [:str,   "foo"]
      # [:dstr,  "foo", {expression}, {expression}, ...]
      # [:evstr, {expression}]
      def initialize(*element_sexps)
        options  = element_sexps.pop
        elements = element_sexps.map {|element_sexp| element_sexp.red!(options.merge(:as_argument => true, :as_string_element => true)) }.join(",")
        string   = options[:unquoted] || options[:as_string_element] ? "%s" : element_sexps.size > 1 ? "$Q(%s)" : "$q(%s)"
        self << string % [elements]
      end
    end
    
    class Symbol < LiteralNode # :nodoc:
      # [:lit,   {symbol}]
      # [:dsym,  "foo", {expression}, {expression}, ...]
      def initialize(*element_sexps)
        options  = element_sexps.pop
        elements = element_sexps.map {|element_sexp| element_sexp.red!(options.merge(:as_argument => true, :as_string_element => true)) }.join(",")
        string   = element_sexps.size > 1 ? "$S(%s)" : "$s(%s)"
        self << string % [elements]
      end
    end
    
    class Uninterpreted < LiteralNode # :nodoc:
      # [:xstr,  "foo"]
      # [:dxstr, "foo", {expression}, {expression}, ...]
      def initialize(*element_sexps)
        options  = element_sexps.pop
        elements = element_sexps.map {|element_sexp| element_sexp.red!(:unquoted => true, :no_escape => true) }.join
        self << "%s" % [elements]
      end
    end
  end
end
