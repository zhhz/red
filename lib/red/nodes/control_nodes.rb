module Red
  class ControlNode < String # :nodoc:
    class Begin < ControlNode # :nodoc:
      # [:begin, {expression | :block}]
      def initialize(body_sexp, options)
        body = body_sexp.red!(:force_return => options[:as_assignment] || options[:as_receiver] || options[:as_argument] || options[:force_return])
        self << "%s" % [body]
      end
    end
    
    class Ensure < ControlNode # :nodoc:
      # [:ensure, {expression | :block}, {expression | :block}]
      def initialize(attempted_sexp, ensure_body_sexp, options)
        #string = (options[:as_argument] || options[:force_return] ? "function(){%s;}()" : "%s") % [string]
        
        attempted   = (attempted_sexp.is_sexp?(:block, :rescue) ? attempted_sexp : [:block, attempted_sexp]).red!(:force_return => options[:force_return])
        ensure_body = (ensure_body_sexp.is_sexp?(:block) ? ensure_body_sexp : [:block, ensure_body_sexp]).red!(:force_return => options[:force_return])
        string      = attempted_sexp.is_sexp?(:rescue) ? "%sfinally{%s;}" : "try{%s;}finally{%s;}"
        
        self << string % [attempted, ensure_body]
      end
    end
    
    class Rescue < ControlNode # :nodoc:
      # [:rescue, (expression | :block), {:resbody}]
      def initialize(attempted_sexp, rescue_body_sexp, options = {})
        (options = rescue_body_sexp) && (rescue_body_sexp = attempted_sexp) && (attempted_sexp = [:nil]) if rescue_body_sexp.is_a?(Hash)
        
        string      = "try{%s;}catch(_e){_eRescued=false;%s;if(!_eRescued){throw(_e);};}"
        if options[:as_argument] || options[:as_assignment]
          string = "function(){%s;}.m$(this)()" % string
          options[:force_return] = true
        end
        attempted   = (attempted_sexp.is_sexp?(:block) ? attempted_sexp : [:block, attempted_sexp]).red!(:force_return => options[:force_return])
        rescue_body = rescue_body_sexp.red!(:force_return => options[:force_return])
        
        self << "try{%s;}catch(_e){_eRescued=false;%s;if(!_eRescued){throw(_e);};}" % [attempted, rescue_body]
      end
    end
    
    class RescueBody < ControlNode # :nodoc:
      # [:resbody, {nil | [:array, {expression}, {expression}, ...]}, (expression | :block), (:resbody)]
      def initialize(exception_types_array_sexp, block_sexp, rescue_body_sexp = nil, options = {})
        (options = block_sexp) && (block_sexp = nil) if block_sexp.is_a?(Hash)
        (options = rescue_body_sexp) && (block_sexp.first==:resbody ? (rescue_body_sexp = block_sexp && block_sexp = nil) : (rescue_body_sexp = nil)) if rescue_body_sexp.is_a?(Hash)
        
        if block_sexp.is_sexp?(:block) && block_sexp[1].is_sexp?(:lasgn) && block_sexp[1].last == [:gvar, %s($!)]
          exception_variable  = "var %s=_e;" % block_sexp.delete(block_sexp.assoc(:lasgn))[1].red!
        elsif block_sexp.is_sexp?(:lasgn) && block_sexp.last == [:gvar, %s($!)]
          exception_variable  = "var %s=_e;" % block_sexp[1].red!
          block_sexp          = [:nil]
        end
        
        exception_types_array = (exception_types_array_sexp || [:array, [:const, :Exception]]).red!
        block                 = (block_sexp.is_sexp?(:block) ? block_sexp : [:block, block_sexp]).red!(:force_return => options[:force_return])
        rescue_body           = "else{%s;}" % rescue_body_sexp.red!(:force_return => options[:force_return]) if rescue_body_sexp
        
        self << "%sif($e(_e,%s)){_eRescued=true;%s;}%s" % [exception_variable, exception_types_array, block, rescue_body]
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
        options = arguments_array_sexp.pop
        arguments = arguments_array_sexp.map {|arg| arg.red!(:as_argument => true) }.join(",")
        keyword = self.class.to_s.split('::').last.downcase
        self << "Red.LoopError._%s(%s)" % [keyword, arguments]
      end
      
      class Break < Keyword # :nodoc:
      end
      
      class Next < Keyword # :nodoc:
      end
      
      class Redo < Keyword # :nodoc:
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
