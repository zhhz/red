module Red
  class ControlNode < String # :nodoc:
    class Begin < ControlNode # :nodoc:
      def initialize(body, options)
        self << body.red!(:force_return => true)
      end
    end
    
    class Ensure < ControlNode # :nodoc:
      def initialize(attempted, ensure_body, options)
        string = (attempted.first == :rescue) ? "%s finally { %s; }" : "try { %s; } finally { %s; }"
        string = options[:as_argument] ? "function() { %s; }()" % [string] : string
        attempted = (attempted.is_a?(Array) && [:block, :rescue].include?(attempted.first)) ? attempted : [:block, attempted]
        ensure_body = (ensure_body.is_a?(Array) && ensure_body.first) == :block ? ensure_body : [:block, ensure_body]
        self << string % [attempted.red!(:force_return => options[:as_argument]), ensure_body.red!(:force_return => options[:as_argument])]
      end
    end
    
    class Rescue < ControlNode # :nodoc:
      def initialize(attempted, rescue_body, options)
        #raise(BuildError::NoSpecificRescue, "JavaScript does not support rescuing of specific exception classes") unless !rescue_body[1]
        string = "try { %s; } catch(%s) { %s; }"
        string = options[:as_argument] ? "function() { %s; }()" % [string] : string
        if (block = (rescue_body.assoc(:block) || [])[1..-1]) && block.first.last == [:gvar, %s($!)]
          exception_variable = block.shift[1].red!
          rescued = block.unshift(:block)
        else
          exception_variable = :e
          rescued = rescue_body[2].is_a?(Array) && rescue_body[2].first == :block ? rescue_body[2] : [:block, rescue_body[2]]
        end
        attempted = attempted.is_a?(Array) && attempted.first == :block ? attempted : [:block, attempted]
        self << string % [attempted.red!, exception_variable, rescued.red!]
        #self << string % [attempted.red!(:force_return => options[:as_argument] || options[:force_return]), exception_variable, rescued.red!(:force_return => options[:as_argument] || options[:force_return])]
      end
    end
    
    class For < ControlNode # :nodoc:
      def initialize(source, iterator, body, options)
        if [:xstr, :dxstr].include?(source.first)
          self << "for (%s) { %s; }" % [source.red!, body.red!]
        else
          self << "for (var %s in %s) { %s; }" % [iterator.last.red!, source.red!(:as_argument => true), body.red!]
        end
      end
    end
    
    class Loop < ControlNode # :nodoc:
      def initialize(condition, body, run_only_if_condition_met, options)
        condition = (self.is_a?(Until) ? "!(%s)" : "%s") % [condition.red!(:as_argument => true)]
        if run_only_if_condition_met
          self << "while (%s) { %s; }" % [condition, body.red!]
        else
          self << "do { %s; } while (%s)" % [body.red!, condition]
        end
      end
      
      class Until < Loop # :nodoc:
      end
      
      class While < Loop # :nodoc:
      end
    end
  end
end
