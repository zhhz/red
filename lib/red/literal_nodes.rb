module Red
  class LiteralNode < String # :nodoc:
    class Array < LiteralNode # :nodoc:
      def initialize(*args)
        options = args.pop
        elements = args.map {|element| element.red!(:quotes => "'") }
        self << "[%s]" % elements.join(', ')
      end
    end
    
    class Hash < LiteralNode # :nodoc:
      def initialize(*args)
        options = args.pop
        pairs = ::Hash[*args].map do |k,v|
          #raise(BuildError::NoArbitraryHashKeys, "JavaScript does not support non-string objects as hash keys") unless [:string, :symbol].include?(k.data_type)
          "%s: %s" % [k.red!(:quotes => "'"), v.red!(:as_argument => true)]
        end
        self << "{ %s }" % [pairs.join(', ')]
      end
    end
    
    class Uninterpreted < LiteralNode # :nodoc:
      def initialize(*args)
        options = args.pop
        self << args.map {|piece| piece.red!(:quotes => '')}.join
      end
    end
    
    class Multiline < LiteralNode # :nodoc:
      def initialize(*args)
        # force_return: changes final expression to "return <expression>",
        #   unless there is already return anywhere inside <expression>.
        # as_argument: duplicates :force_return and adds "function() {
        #   <multiline block>; }()" wrapper to the entire block.
        options = args.pop
        if options[:as_argument] || options[:force_return] && args.last.is_a?(::Array) && !args.last.flatten.include?(:return)
          returner = "return %s" % [args.pop.red!(:as_argument => true)]
        end
        string = options[:as_argument] ? "function() { %s; }()" : "%s"
        lines = (args.map {|line| line.red!(options)} + [returner]).compact
        self << string % [lines.join(";\n#{options[:indent] ? '  ' * options[:indent] : "\n"}")]
      end
    end
    
    class Namespace < LiteralNode # :nodoc:
      def initialize(namespace, class_name, options)
        self << "%s.%s" % [namespace.red!, class_name.red!]
      end
    end
    
    class Other < LiteralNode # :nodoc:
      def initialize(value, options)
        self << value.red!(options)
      end
    end
    
    class Range < LiteralNode # :nodoc:
      #def initialize(*args)
      #  case @@red_library
      #    when :Prototype : super(*args)
      #    else              raise(BuildError::NoRangeConstructor, "#{@@red_library} JavaScript library has no literal range constructor")
      #  end
      #end
      #
      #def compile_node(options = {})
      #  start = @initial.compile_node(:as_argument => true)
      #  finish = @subsequent.first.compile_node(:as_argument => true)
      #  case @@red_library
      #    when :Prototype : return "$R(%s, %s)" % [start, finish]
      #    else              ""
      #  end
      #end
      #
      class Exclusive < Range # :nodoc:
      #  def compile_node(options = {})
      #    start = @initial.compile_node(:as_argument => true)
      #    finish = @subsequent.first.compile_node(:as_argument => true)
      #    case @@red_library
      #      when :Prototype : return "$R(%s, %s, true)" % [start, finish]
      #      else              ""
      #    end
      #  end
      end
    end
    
    class Splat < LiteralNode # :nodoc:
      #def initialize(*args)
      #  case @@red_library
      #    when :Prototype : super(*args)
      #    else              raise(BuildError::NoSplatConstructor, "Splat array constructor not supported for #{@@red_library} JavaScript library")
      #  end
      #end
      #
      #def compile_node(options = {})
      #  initial = @initial.compile_node
      #  case @@red_library
      #    when :Prototype : return "$A(%s)" % [initial]
      #    else              ""
      #  end
      #end
    end
    
    class String < LiteralNode # :nodoc:
      def initialize(*args)
        options = args.pop
        initial = args.shift.red!(options)
        subsequent = args.map { |element| " + %s" % [element.red!] }.join
        self << [initial, subsequent].join
      end
    end
  end
end
