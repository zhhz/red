module Red
  class WrapNode < String # :nodoc:
    def initialize(expression = nil, options = {})
      (options = expression) && (expression = nil) if expression.is_a?(Hash)
      self << (self.class::STRING % expression.red!(:as_argument => true)).rstrip
    end
    
    class Defined < WrapNode # :nodoc:
      #def compile_node(options = {})
      #  return "!(typeof %s == undefined)" % self.compile_internals
      #end
    end
    
    class Not < WrapNode # :nodoc:
      STRING = "!(%s)"
    end
    
    class Return < WrapNode # :nodoc:
      STRING = "return %s"
    end
    
    class Super < WrapNode # :nodoc:
    end
  end
end
