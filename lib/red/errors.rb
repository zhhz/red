module Red
  class BuildError < StandardError # :nodoc:
    # Raised when a lone +Regex+ is used as a condition.
    class NoArbitraryMatch < BuildError # :nodoc:
    end
    
    # Raised when a +BEGIN+ or +END+ block is used.
    class NoBEGINorEND < BuildError # :nodoc:
    end
    
    # Raised when a +break+ keyword is followed by an argument.
    class NoBreakArguments < BuildError # :nodoc:
    end
    
    # Raised when a +redo+ or +retry+ keyword is used.
    class NoDoOvers < BuildError # :nodoc:
    end
    
    # Raised when a flipflop operator is called using <tt>..</tt> or
    # <tt>...</tt>
    class NoFlipflops < BuildError # :nodoc:
    end
    
    # Raised when a +next+ keyword is followed by an argument.
    class NoNextArguments < BuildError # :nodoc:
    end
    
    # Raised when a +Regex+ literal declaration contains evaluated content.
    class NoRegexEvaluation < BuildError # :nodoc:
    end
    
    # Raised when an +Error+ class is passed to +rescue+.
    class NoSpecificRescue < BuildError # :nodoc:
    end
    
    # Raised when the active JavaScript library has no special array
    # constructor.
    class NoSplatConstructor < BuildError # :nodoc:
    end
    
    # Raised when an unknown ParseTree sexp type is called to initialize.
    class UnknownNode < BuildError # :nodoc:
    end
  end
end
