module Red
  class ConstantNode < String # :nodoc:
    def initialize(*args)
      self << self.class::STRING
      # raise(BuildError::NoBreakArguments, "Break can't take an argument in JavaScript") unless args.empty?
      # raise(BuildError::NoNextArguments, "Next/continue can't take an argument in JavaScript") unless args.empty?
    end
    
    class Break < ConstantNode # :nodoc:
      STRING = "break"
    end
    
    class False < ConstantNode # :nodoc:
      STRING = "false"
    end
    
    class Next < ConstantNode # :nodoc:
      STRING = "continue"
    end
    
    class Nil < ConstantNode # :nodoc:
      STRING = "null"
    end
    
    class Self < ConstantNode # :nodoc:
      STRING = "this"
    end
    
    class True < ConstantNode # :nodoc:
      STRING = "true"
    end
  end
end
