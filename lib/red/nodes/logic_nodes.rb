module Red
  class LogicNode < String # :nodoc:
    class Boolean < LogicNode # :nodoc:
      # [:false]
      # [:true]
      def initialize(options)
        string = case self when False : "false" when True : "true" end
        self << string
      end
      
      class False < Boolean # :nodoc:
      end
      
      class True < Boolean # :nodoc:
      end
    end
    
    class Case < LogicNode # :nodoc:
      # [:case, {expression}, {:when}, {:when}, ..., {expression | :block}]
      def initialize(switch_sexp, *case_sexps)
        options     = case_sexps.pop
        switch      = switch_sexp.red!(:as_argument => true)
        else_case   = case_sexps.pop.red!(:as_argument => options[:as_argument])
        string      = "var _switch=(%s);%s" % [switch, '%s']
        case_string = case_sexps.inject(string) do |cases,case_sexp|
          cases %= case_sexp.red!(:as_argument => options[:as_argument])
        end
        self << case_string % [else_case]
      end
      
      class When < Case # :nodoc:
        # [:when, [:array, {expression}, {expression}, ...], {expression | :block}]
        def initialize(condition_sexps, expression_sexp, options)
          conditions = condition_sexps[1..-1].map {|condition_sexp| "%s.m$_eql3(_switch)" % [condition_sexp.red!(:as_receiver => true)] }.join("||")
          expression = expression_sexp.red!(:as_argument => options[:as_argument])
          string     = options[:as_argument] ? "(%s?%s:%s)" : "if(%s){%s;}else{%s;}"
          self << string % [conditions, expression, '%s']
        end
      end
    end
    
    class Conjunction < LogicNode # :nodoc:
      # [:and, {expression}, {expression}]
      # [:or,  {expression}, {expression}]
      def initialize(expression_a_sexp, expression_b_sexp, options)
        a = expression_a_sexp.red!(:as_argument => true)
        b = expression_b_sexp.red!(:as_argument => true)
        string = self.class::STRING
        self << string % [a,b]
      end
      
      class And < Conjunction # :nodoc:
        # FIX: nil && obj produces false instead of nil
        STRING = "(_a=$T(%s)?(_c=$T(_b=%s)?_b:_c):_a)"
      end
      
      class Or < Conjunction # :nodoc:
        STRING = "($T(_a=%s)?_a:%s)"
      end
    end
    
    class If < LogicNode # :nodoc:
      # [:if, {expression}, {expression | :block}, {expression | :block}]
      def initialize(condition_sexp, true_case_sexp, else_case_sexp, options)
        # ... each_with_index {|x,i| b << a.flatten[i+1] if x == :lasgn}
        if options[:as_argument] || options[:as_receiver] || options[:as_assignment]
          condition = condition_sexp.red!(:as_argument => true)
          true_case = true_case_sexp.nil? ? "nil" : true_case_sexp.red!(:as_argument => true)
          else_case = else_case_sexp.nil? ? "nil" : else_case_sexp.red!(:as_argument => true)
          self << "($T(%s)?%s:%s)" % [condition, true_case, else_case]
        else
          condition = (true_case_sexp.nil? ? "!$T(%s)" : "$T(%s)") % [condition_sexp.red!(:as_argument => true)]
          true_case = "{%s;}" % [true_case_sexp.red!] unless true_case_sexp.nil?
          join      = "else"                          unless true_case_sexp.nil? || else_case_sexp.nil?
          else_case = "{%s;}" % [else_case_sexp.red!] unless else_case_sexp.nil?
          self << "if(%s)%s%s%s" % [condition, true_case, join, else_case]
        end
      end
    end
    
    class Not < LogicNode # :nodoc:
      # [:not, {expression}]
      def initialize(expression_sexp, options)
        expression = expression_sexp.red!(:as_argument => true)
        self << "!$T(%s)" % [expression]
      end
    end
  end
end
