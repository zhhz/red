module Red
  class DataNode # :nodoc:
    attr_reader :value
    
    def initialize(value = nil)
      @value = value
    end
    
    def compile_node(options = {})
      return @value.inspect
    end
    
    def wrap_string(string, left_wrapper = "", right_wrapper = nil)
      return "%s%s%s" % [left_wrapper, string, right_wrapper || left_wrapper]
    end
    
    class ErrorNode < DataNode # :nodoc:
      def compile_node(options = {})
        "_____ Error %s _____" % [@value]
      end
      
      def data_type
        :error
      end
    end
    
    class NilNode < DataNode # :nodoc:
      def compile_node(options = {})
        ""
      end
    end
    
    class OtherNode < DataNode # :nodoc:
    end
    
    class RangeNode < DataNode # :nodoc:
      def initialize(*args)
        case @@red_library
          when :Prototype : super(*args)
          else              raise(BuildError::NoRangeConstructor, "#{@@red_library} JavaScript library has no literal range constructor")
        end
      end
      
      def compile_node(options = {})
        case @@red_library
          when :Prototype : return "$R(%s, %s%s)" % self.compile_internals
          else              return ""
        end
      end
      
      def compile_internals(options = {})
        exclusive = @value.exclude_end? ? ", true" : ""
        return [@value.begin, @value.end, exclusive]
      end
    end
    
    class StringNode < DataNode # :nodoc:
      def compile_node(options = {})
        options[:quotes] ||= "'"
        return wrap_string(@value, options[:quotes])
      end
      
      def data_type
        :string
      end
    end
    
    class SymbolNode < DataNode # :nodoc:
      def compile_node(options = {})
        self.camelize!(options[:not_camelized])
        return wrap_string(@value, options[:quotes])
      end
      
      def camelize!(disabled = false)
        return @value = @value.to_s unless camelize? && !disabled
        words = @value.to_s.gsub(/@|\$/,'').split(/_| /)
        underscore = words.shift if words.first.empty?
        @value = (underscore ? '_' : '') + words[0] + words[1..-1].map {|word| word.capitalize}.join
      end
      
      def camelize?
        is_not_a_constant_name        = @value.to_s != @value.to_s.upcase
        is_not_a_js_special_attribute = @value.to_s[0..1] != '__'
        return is_not_a_constant_name && is_not_a_js_special_attribute
      end
      
      def data_type
        :symbol
      end
    end
  end
end
