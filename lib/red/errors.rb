module Red
  class BuildError < StandardError # :nodoc:
    # Raised when a hash is given a key other than a +String+ or +Symbol+
    # object.
    class NoArbitraryHashKeys < BuildError # :nodoc:
    end
    
    # Raised when a lone +Regex+ is used as a condition.
    class NoArbitraryMatch < BuildError # :nodoc:
    end
    
    # Raised when a +rescue+ block is placed in a way that would produce a
    # JavaScript syntax error.
    class NoArbitraryRescue < BuildError # :nodoc:
    end
    
    # Raised when a +BEGIN+ or +END+ block is used.
    class NoBEGINorEND < BuildError # :nodoc:
    end
    
    # Raised when a block is declared as a method argument.
    class NoBlockArguments < BuildError # :nodoc:
    end
    
    # Raised when a +break+ keyword is followed by an argument.
    class NoBreakArguments < BuildError # :nodoc:
    end
    
    # Raised when the active JavaScript library does not support class
    # inheritance.
    class NoClassInheritance < BuildError # :nodoc:
    end
    
    # Raised when the active JavaScript library does not support calls to
    # class variables or declarations of class variables.
    class NoClassVariables < BuildError # :nodoc:
    end
    
    # Raised when a +redo+ or +retry+ keyword is used.
    class NoDoOvers < BuildError # :nodoc:
    end
    
    # Raised when a flipflop operator is called using <tt>..</tt> or
    # <tt>...</tt>
    class NoFlipflops < BuildError # :nodoc:
    end
    
    # Raised when a +begin+ block is used for multiline assignment.
    class NoMultilineAssignment < BuildError # :nodoc:
    end
    
    # Raised when a comma-separated multiple assignment expression is used.
    class NoMultipleAssignment < BuildError # :nodoc:
    end
    
    # Raised when a +break+ keyword is followed by an argument.
    class NoNextArguments < BuildError # :nodoc:
    end
    
    # Raised when the active JavaScript library has no native literal range
    # constructor.
    class NoRangeConstructor < BuildError # :nodoc:
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
    
    # Raised when the active JavaScript library does not support calls to
    # +super+.
    class NoSuperMethods < BuildError # :nodoc:
    end
    
    # Raised when a +Symbol+ literal declaration contains evaluated content.
    class NoSymbolEvaluation < BuildError # :nodoc:
    end
    
    # Raised when an +undef+ keyword is used.
    class NoUndef < BuildError # :nodoc:
    end
    
    # Raised when an unknown ParseTree sexp type is called to initialize.
    class UnknownNode < BuildError # :nodoc:
    end
  end
end
