module Red
  class DataNode < String # :nodoc:
    class Error < DataNode # :nodoc:
    end
    
    class Nil < DataNode # :nodoc:
      # nil
      def initialize(value_data, options)
        self << ""
      end
    end
    
    class Other < DataNode # :nodoc:
      # 1
      # /foo/
      def initialize(value_data, options)
        value  = value_data.inspect
        string = options[:as_receiver] ? "(%s)" : "%s"
        self << string % [value]
      end
    end
    
    class Range < DataNode # :nodoc:
      # 1..2
      def initialize(value_data, options)
        start     = value_data.begin
        finish    = value_data.end
        exclusive = value_data.exclude_end?.inspect
        self << "new Range(%s,%s,%s)" % [start, finish, exclusive]
      end
    end
    
    class String < DataNode # :nodoc:
      # 'foo'
      def initialize(value_data, options)
        value  = options[:no_escape] ? value_data : value_data.gsub(/'/, "\\\\'")
        string = options[:unquoted] ? "%s" : "'%s'"
        self << string % [value]
      end
    end
    
    class Symbol < DataNode # :nodoc:
      # :foo
      def initialize(value_data, options)
        value  = self.camelize(value_data.to_s, options[:not_camelized])
        string = options[:as_receiver] ? "$q('%s')" : options[:as_argument] ? "'%s'" : "%s"
        self << string % [value]
      end
      
      def camelize(string, disabled = false)
        return string unless self.camelize?(string) && !disabled
        words = string.gsub(/@/,'').gsub('?','_bool').gsub('!','_bang').gsub('=','_eql').gsub(/^Object$/,'Red').split(/_| /)
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
