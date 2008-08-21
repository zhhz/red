module Red
  class ConditionalNode # :nodoc:
    class IfNode # :nodoc:
      def initialize(condition, true_case, else_case)
        @condition, @true_case, @else_case = [condition, true_case, else_case].build_nodes
      end
      
      def compile_node(options = {})
        unless options[:as_argument]
          "if (%s) %s%s%s"
        else
          "(%s ? %s : %s)"
        end % self.compile_internals(options)
      end
      
      def compile_internals(options = {})
        true_case, else_case = [@true_case, @else_case].compile_nodes
        condition = @condition.compile_node(:as_argument => true)
        return [condition, (true_case.empty? ? 'null' : @true_case.compile_node(:as_argument => true)), (else_case.empty? ? 'null' : @else_case.compile_node(:as_argument => true))] if options[:as_argument]
        condition = (true_case.empty? ? "!(%s)" : "%s") % [condition]
        true_case = "{ %s; }" % [true_case] unless true_case.empty?
        join      = " else "                      unless true_case.empty? || else_case.empty?
        else_case = "{ %s; }" % [else_case] unless else_case.empty?
        return [condition, true_case, join, else_case]
      end
    end
    
    class CaseNode # :nodoc:
      def initialize(switch, *cases)
        @switch, @else_case = [switch, cases.pop].build_nodes
        @when_cases = cases.build_nodes
      end
      
      def compile_node(options = {})
        return "switch (%s) { %s%s }" % self.compile_internals
      end
      
      def compile_internals(options = {})
        switch, else_case = [@switch, @else_case].compile_nodes
        when_cases = @when_cases.compile_nodes.join
        default = "default:%s;" % [else_case] unless else_case.empty?
        return [switch, when_cases, default]
      end
    end
    
    class WhenNode # :nodoc:
      def initialize(conditions, expression)
        @conditions = conditions[1..-1].build_nodes
        @expression = expression.build_node
      end
      
      def compile_node(options = {})
        return "case %s:%s;%s" % self.compile_internals
      end
      
      def compile_internals(options = {})
        condition = @conditions.first.compile_node(:quotes => "'")
        expression = @expression.compile_node
        final = "break;"
        return [condition, expression, final]
      end
    end
  end
end
