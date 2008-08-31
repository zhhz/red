module Red
  class IllegalNode # :nodoc:
    class FlipflopNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoFlipflops, "JavaScript does not support flip-flop operators")
      end
    end
    
    class MatchNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoArbitraryMatch, "JavaScript does not support arbitrary boolean matching")
      end
    end
    
    class MultipleAssignmentNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoMultipleAssignment, "JavaScript does not support catalogued assignment using multiple comma-separated expressions")
      end
    end
    
    class PostexeNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoBEGINorEND, "BEGIN and END blocks are not supported")
      end
    end
    
    class RedoNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoDoOvers, "JavaScript has no redo keyword")
      end
    end
    
    class RegexEvaluationNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoRegexEvaluation, "Construction of JavaScript regular expressions with evaluated content is not supported")
      end
    end
    
    class RetryNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoDoOvers, "JavaScript has no retry keyword")
      end
    end
    
    class SymbolEvaluationNode < IllegalNode # :nodoc:
      def initialize(*args)
        raise(BuildError::NoSymbolEvaluation, "Construction of JavaScript identifiers through evaluated symbols is not supported")
      end
    end
  end
end
