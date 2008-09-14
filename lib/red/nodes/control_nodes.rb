module Red
  class ControlNode < String # :nodoc:
    class Begin < ControlNode # :nodoc:
      # [:begin, {expression | :block}]
      def initialize(body_sexp, options)
        body = body_sexp.red!(:force_return => true)
        self << "%s" % [body]
      end
    end
    
    class Ensure < ControlNode # :nodoc:
      # [:ensure, {expression | :block}, {expression | :block}]
      def initialize(attempted_sexp, ensure_body_sexp, options)
        attempted = (attempted_sexp.is_sexp?(:block, :rescue) ? attempted_sexp : [:block, attempted_sexp]).red!(:force_return => options[:as_argument])
        ensure_body = (ensure_body_sexp.is_sexp?(:block) ? ensure_body : [:block, ensure_body]).red!(:force_return => options[:as_argument])
        string = attempted_sexp.is_sexp?(:rescue) ? "%sfinally{%s;}" : "try{%s;}finally{%s;}"
        string = (options[:as_argument] ? "function(){%s;}()" : "%s") % [string]
        self << string % [attempted, ensure_body]
      end
    end
    
    class Rescue < ControlNode # :nodoc:
      # [:rescue, {expression | :block}, [:resbody, {nil | :array, {expression}, {expression}, ...}, (:block), {expression | :block}]]
      def initialize(attempted_sexp, rescue_body_sexp, options)
        #raise(BuildError::NoSpecificRescue, "Rescuing of specific exception classes is not supported") unless !rescue_body[1]
        string = "try { %s; } catch(%s) { %s; }"
        string = options[:as_argument] ? "function() { %s; }.m$(this)()" % [string] : string
        if (block = (rescue_body_sexp.assoc(:block) || [])[1..-1]) && block.first.last == [:gvar, %s($!)]
          exception_variable = block.shift[1].red!
          rescued = block.unshift(:block)
        else
          exception_variable = "e"
          rescued = rescue_body_sexp.last.is_sexp?(:block) ? rescue_body_sexp.last : [:block, rescue_body_sexp.last]
        end
        attempted = attempted_sexp.is_sexp?(:block) ? attempted.red! : [:block, attempted].red!
        self << string % [attempted, exception_variable, rescued.red!]
        #self << string % [attempted.red!(:force_return => options[:as_argument] || options[:force_return]), exception_variable, rescued.red!(:force_return => options[:as_argument] || options[:force_return])]
      end
    end
    
    class For < ControlNode # :nodoc:
      # [:for, {expression}, {expression}, {expression | :block}]
      def initialize(source_sexp, iterator_assignment_sexp, body_sexp, options)
        body = body_sexp.red!
        unless source_sexp.is_sexp?(:xstr, :dxstr)
          source   = source_sexp.red!(:as_argument => true)
          iterator = iterator_assignment_sexp.last.red!
          self << "for(var %s in %s){%s;}" % [iterator, source, body]
        else
          loop_statement = source_sexp.red!
          self << "for(%s){%s;}" % [loop_statement, body]
        end
      end
    end
    
    class Keyword < ControlNode # :nodoc:
      # [:break, (expression)]
      # [:next, (expression)]
      def initialize(*arguments_array_sexp)
        # raise(BuildError::NoBreakArguments, "Break can't take an argument") if self.is_a?(Break) && !args.empty?
        # raise(BuildError::NoNextArguments, "Next can't take an argument") if self.is_a?(Next) && !args!args.empty?
        string = case self when Break : "break" when Next : "continue" end
        self << string
      end
      
      class Break < Keyword # :nodoc:
      end
      
      class Next < Keyword # :nodoc:
      end
    end
    
    class Loop < ControlNode # :nodoc:
      # [:until, {expression}, {expression | :block}, true | false]
      # [:while, {expression}, {expression | :block}, true | false]
      def initialize(condition_sexp, body_sexp, run_only_if_condition_met, options)
        condition = (self.is_a?(Until) ? "!$T(%s)" : "$T(%s)") % [condition_sexp.red!(:as_argument => true)]
        body      = body_sexp.red!
        if run_only_if_condition_met
          self << "while(%s){%s;}"   % [condition, body]
        else
          self << "do{%s;}while(%s)" % [body, condition]
        end
      end
      
      class Until < Loop # :nodoc:
      end
      
      class While < Loop # :nodoc:
      end
    end
    
    class Return < ControlNode # :nodoc:
      # [:return, (expression)]
      def initialize(expression_sexp = nil, options = {})
        (options = expression_sexp) && (expression_sexp = [:nil]) if expression_sexp.is_a?(Hash)
        expression = expression_sexp.red!(:as_argument => true)
        self << "return(%s)" % [expression]
      end
    end
  end
end
