module Red
  class AssignmentNode < String # :nodoc:
    class ClassVariable < AssignmentNode  # :nodoc:
      def initialize(variable_name, expression, options)
        if options[:as_property]
          string = "$$%s: %s" % [variable_name.red!, expression.red!(:as_argument => true)]
        else
          string = "%s.$$%s = %s" % [@@namespace_stack.join('.'), variable_name.red!, expression.red!(:as_argument => true)]
        end
        self << string
      end
    end
    
    class GlobalVariable < AssignmentNode  # :nodoc:
      def initialize(variable_name, expression, options)
        self << "%s = %s" % [variable_name.red!, expression.red!(:as_argument => true)]
      end
    end
    
    class InstanceVariable < AssignmentNode # :nodoc:
      def initialize(variable_name, expression, options)
        self << "this.$%s = %s" % [variable_name.red!, expression.red!(:as_argument => true)]
      end
    end
    
    class LocalVariable < AssignmentNode # :nodoc:
      def initialize(variable_name, expression, options)
        if options[:as_default]
          self << "%s = %s || %s" % [variable_name.red!, variable_name.red!, expression.red!(:as_argument => true)]
        else
          string = (options[:as_argument] || variable_name.is_a?(Array) && variable_name.first == :colon2) ? "%s = %s" : "var %s = %s"
          self << string.add_parentheses_wrapper(:perform_if => options[:as_argument]) % [variable_name.red!, expression.red!(:as_argument => true)]
        end
      end
    end
    
    class Attribute < AssignmentNode # :nodoc:
      def initialize(variable_name, writer, arguments, options)
        expression = arguments.pop.red!(:as_argument => true)
        accessor = (writer == :[]= ? arguments[1] : writer.to_s.gsub(/=/,'').to_sym)
        if accessor.is_a?(Symbol) || accessor.first == :lit && [Symbol, String].include?(accessor.last.class)
          #string = [:const, :colon2].include?(variable_name.first) ? "%s.$$%s" : "%s.$%s"
          receiver = "%s.%s" % [variable_name.red!, accessor.red!(:quotes => '')]
        else
          receiver = "%s[%s]" % [variable_name.red!, accessor.red!(:as_argument => true)]
        end
        self << "%s = %s" % [receiver, expression]
      end
    end
    
    class Operator < AssignmentNode # :nodoc:
      class Bracket < Operator # :nodoc:
        def initialize(object, bracket_contents, operation, expression, options)
          accessor = bracket_contents.last
          if accessor.is_a?(Symbol) || accessor.first == :str || accessor.first == :lit && accessor.last.is_a?(Symbol)
            receiver = "%s.%s" % [object.red!, accessor.red!(:quotes => '')]
          else
            receiver = "%s[%s]" % [object.red!, accessor.red!(:as_argument => true)]
          end
          self << "%s = %s %s %s" % [receiver, receiver, operation.red!, expression.red!(:as_argument => true)]
        end
      end
      
      class Dot < Operator # :nodoc:
        def initialize(object, writer, operation, expression, options)
          property_name = writer.to_s.gsub(/=/,'').to_sym.red!(:quotes => '')
          receiver = ([:const, :colon2].include?(object.first) ? "%s.$$%s" : "%s.$%s") % [object.red!, property_name]
          self << "%s = %s %s %s" % [receiver, receiver, operation.red!, expression.red!(:as_argument => true)]
        end
      end
      
      class Or < Operator # :nodoc:
        def initialize(object, assignment, options)
          expression = assignment.last.red!(:as_argument => true)
          receiver = object.red!
          string = (object.is_a?(Array) && [:const, :lvar].include?(object.first)) ? "var %s = %s || %s" : "%s = %s || %s"
          self << string % [receiver, receiver, expression]
        end
      end
      
      class And < Operator # :nodoc:
        def initialize(object, assignment, options)
          expression = assignment.last.red!(:as_argument => true)
          receiver = object.red!
          string = (object.is_a?(Array) && [:const, :lvar].include?(object.first)) ? "var %s = %s && %s" : "%s = %s && %s"
          self << string % [receiver, receiver, expression]
        end
      end
    end
  end
end
