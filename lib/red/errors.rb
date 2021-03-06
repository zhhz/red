module Red
  class BuildError < StandardError # :nodoc:
    # Raised when a lone +Regex+ is used as a condition.
    class NoArbitraryMatch < BuildError # :nodoc:
    end
    
    # Raised when an +END+ block is used.
    class NoENDBlocks < BuildError # :nodoc:
    end
    
    # Raised when a +retry+ keyword is used.
    class NoRetry < BuildError # :nodoc:
    end
    
    # Raised when a flipflop operator is called using <tt>..</tt> or
    # <tt>...</tt>
    class NoFlipflops < BuildError # :nodoc:
    end
    
    # Raised when a +Regex+ literal declaration contains evaluated content.
    class NoRegexEvaluation < BuildError # :nodoc:
    end
    
    # Raised when an unknown ParseTree sexp type is called to initialize.
    class UnknownNode < BuildError # :nodoc:
    end
  end
end
