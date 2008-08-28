module Red
  class LogicNode < String # :nodoc:
    class Case < LogicNode # :nodoc:
      def initialize(condition, *args)
        options = args.pop
        else_case = args.pop.red!
        cases = args.map {|when_case| when_case.red! }
        cases << "default: %s" % [else_case] unless else_case.empty?
        self << "switch (%s) { %s; }" % [condition.red!(:as_argument => true), cases.compact.join('; ')]
      end
      
      class When < Case # :nodoc:
        def initialize(conditions, expression, options)
          condition = conditions[1].red!(:quotes => "'")
          expression = expression.red!
          expression << '; ' unless expression.empty?
          self << "case %s: %sbreak" % [condition, expression]
        end
      end
    end
    
    class Conjunction < LogicNode # :nodoc:
      def initialize(a, b, options)
        self << self.class::STRING % [a.red!(:as_argument => true), b.red!(:as_argument => true)]
      end
      
      class And < Conjunction # :nodoc:
        STRING = "(_a=$T(%s))?((_c=$T(_b=%s))?_b:_c):_a"
      end
      
      class Or < Conjunction # :nodoc:
        STRING = "$T(_a=%s)?_a:%s"
      end
    end
    
    class If < LogicNode # :nodoc:
      def initialize(condition, true_case, else_case, options)
        if options[:as_argument]
          true_case = true_case.nil? ? "$nil" : true_case.red!(:as_argument => true)
          else_case = else_case.nil? ? "$nil" : else_case.red!(:as_argument => true)
          self << "($T(%s) ? %s : %s)" % [condition.red!(:as_argument => true), true_case, else_case]
        else
          condition = (true_case.nil? ? "!$T(%s)" : "$T(%s)") % [condition.red!(:as_argument => true)]
          true_case = "{ %s; }" % [true_case.red!] unless true_case.nil?
          join      = " else "                     unless true_case.nil? || else_case.nil?
          else_case = "{ %s; }" % [else_case.red!] unless else_case.nil?
          self << "if (%s) %s%s%s" % [condition, true_case, join, else_case]
        end
      end
    end
  end
end
