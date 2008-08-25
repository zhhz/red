module Red
  class LogicNode < String # :nodoc:
    class Case < LogicNode # :nodoc:
      def initialize(condition, *args)
        options = args.pop
        else_case = args.pop.zoop
        cases = args.map {|when_case| when_case.zoop }
        cases << "default: %s" % [else_case] unless else_case.empty?
        self << "switch (%s) { %s; }" % [condition.zoop(:as_argument => true), cases.compact.join('; ')]
      end
      
      class When < Case # :nodoc:
        def initialize(conditions, expression, options)
          condition = conditions[1].zoop(:quotes => "'")
          expression = expression.zoop
          expression << '; ' unless expression.empty?
          self << "case %s: %sbreak" % [condition, expression]
        end
      end
    end
    
    class Conjunction < LogicNode # :nodoc:
      def initialize(a, b, options)
        self << self.class::STRING % [a.zoop(:as_argument => true), b.zoop(:as_argument => true)]
      end
      
      class And < Conjunction # :nodoc:
        STRING = "(%s && %s)"
      end
      
      class Or < Conjunction # :nodoc:
        STRING = "(%s || %s)"
      end
    end
    
    class If < LogicNode # :nodoc:
      def initialize(condition, true_case, else_case, options)
        if options[:as_argument]
          true_case = true_case.nil? ? 'null' : true_case.zoop(:as_argument => true)
          else_case = else_case.nil? ? 'null' : else_case.zoop(:as_argument => true)
          self << "(%s ? %s : %s)" % [condition.zoop(:as_argument => true), true_case, else_case]
        else
          condition = (true_case.nil? ? "!(%s)" : "%s") % [condition.zoop]
          true_case = "{ %s; }" % [true_case.zoop(:as_argument => true)] unless true_case.nil?
          join      = " else "                                           unless true_case.nil? || else_case.nil?
          else_case = "{ %s; }" % [else_case.zoop(:as_argument => true)] unless else_case.nil?
          self << "if (%s) %s%s%s" % [condition, true_case, join, else_case]
        end
      end
    end
  end
end
