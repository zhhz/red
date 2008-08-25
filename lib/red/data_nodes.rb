module Red
  class DataNode < String # :nodoc:
    def wrap_string(string, left_wrapper = "", right_wrapper = nil)
      return "%s%s%s" % [left_wrapper, string, right_wrapper || left_wrapper]
    end
    
    class Error < DataNode # :nodoc:
      #def compile_node(options = {})
      #  "/*  Error %s  */" % [@value]
      #end
      #
      #def data_type
      #  :error
      #end
    end
    
    class Nil < DataNode # :nodoc:
      def initialize(value, options)
        self << ""
      end
    end
    
    class Other < DataNode # :nodoc:
      def initialize(value, options)
        self << (options[:as_argument] ? "(%s)" : "%s") % [value.inspect]
      end
    end
    
    class Range < DataNode # :nodoc:
      #def initialize(*args)
      #  case @@red_library
      #    when :Prototype : super(*args)
      #    else              raise(BuildError::NoRangeConstructor, "#{@@red_library} JavaScript library has no literal range constructor")
      #  end
      #end
      #
      #def compile_node(options = {})
      #  case @@red_library
      #    when :Prototype : return "$R(%s, %s%s)" % self.compile_internals
      #    else              return ""
      #  end
      #end
      #
      #def compile_internals(options = {})
      #  exclusive = @value.exclude_end? ? ", true" : ""
      #  return [@value.begin, @value.end, exclusive]
      #end
    end
    
    class String < DataNode # :nodoc:
      def initialize(string, options)
        options[:quotes] ||= "'"
        self << wrap_string(string, options[:quotes])
      end
    end
    
    class Symbol < DataNode # :nodoc:
      def initialize(symbol, options)
        value = self.camelize(symbol.to_s, options[:not_camelized])
        self << wrap_string(value, options[:quotes])
      end
      
      def camelize(string, disabled = false)
        return string unless self.camelize?(string) && !disabled
        words = string.gsub(/@/,'').gsub('?','_bool').gsub('!','_bang').gsub('_z_dd','$$').gsub('_z_d','$').split(/_| /)
        underscore = words.shift if words.first.empty?
        return (underscore ? '_' : '') + words[0] + words[1..-1].map {|word| word == word.upcase ? word : word.capitalize }.join
      end
      
      def camelize?(string)
        is_not_a_constant_name        = string != string.upcase || string =~ (/@|\$/)
        is_not_a_js_special_attribute = string[0..1] != '__'
        return is_not_a_constant_name && is_not_a_js_special_attribute
      end
    end
  end
end
