module Red
  class LiteralNode # :nodoc:
    def initialize(*elements)
      @initial    = elements.shift.build_node
      @subsequent = elements.build_nodes
    end
    
    def compile_node(options = {})
      content = @initial.compile_node(options)
      return "%s" % [content]
    end
    
    def data_type
      return :node unless @initial.is_a?(DataNode)
      case @initial
        when DataNode::NilNode    : :nil
        when DataNode::RangeNode  : :range
        when DataNode::StringNode : (@subsequent.empty? ? :string : :eval)
        when DataNode::SymbolNode : :symbol
        else @initial.value.is_a?(Numeric) ? :numeric : :regexp
      end
    end
    
    class ArrayNode < LiteralNode # :nodoc:
      def compile_node(options = {})
        elements = @subsequent.unshift(@initial).compile_nodes.reject {|element| element.empty? }.join(', ')
        return "[%s]" % [elements]
      end
    end
    
    class HashNode < LiteralNode # :nodoc:
      def initialize(*array)
        @hash = {}
        Hash[*array].each do |k,v|
          key, value = [k,v].build_nodes
          raise(BuildError::NoArbitraryHashKeys, "JavaScript does not support non-string objects as hash keys") unless [:string, :symbol].include?(key.data_type)
          @hash[key] = value
        end
      end
      
      def compile_node(options = {})
        pairs = @hash.map { |k,v| "%s: %s" % [k.compile_node(:quotes => "'"), v.compile_node(:as_argument => true)] }.join(', ')
        "{ %s }" % [pairs]
      end
    end
    
    class MultilineNode < LiteralNode # :nodoc:
      def compile_node(options = {})
        lines = @subsequent.unshift(@initial).compile_nodes(options).compact.join('; ')
        return "%s" % [lines]
      end
    end
    
    class NamespaceNode < LiteralNode # :nodoc:
      def compile_node(options = {})
        namespaces = @initial.compile_node
        class_name = @subsequent.first.compile_node
        return "%s.%s" % [namespaces, class_name]
      end
    end
    
    class OtherNode < LiteralNode # :nodoc:
    end
    
    class RangeNode < LiteralNode # :nodoc:
      def initialize(*args)
        case @@red_library
          when :Prototype : super(*args)
          else              raise(BuildError::NoRangeConstructor, "#{@@red_library} JavaScript library has no literal range constructor")
        end
      end
      
      def compile_node(options = {})
        start = @initial.compile_node(:as_argument => true)
        finish = @subsequent.first.compile_node(:as_argument => true)
        case @@red_library
          when :Prototype : return "$R(%s, %s)" % [start, finish]
          else              ""
        end
      end
      
      class ExclusiveNode < RangeNode # :nodoc:
        def compile_node(options = {})
          start = @initial.compile_node(:as_argument => true)
          finish = @subsequent.first.compile_node(:as_argument => true)
          case @@red_library
            when :Prototype : return "$R(%s, %s, true)" % [start, finish]
            else              ""
          end
        end
      end
    end
    
    class SplatNode < LiteralNode # :nodoc:
      def initialize(*args)
        case @@red_library
          when :Prototype : super(*args)
          else              raise(BuildError::NoSplatConstructor, "Splat array constructor not supported for #{@@red_library} JavaScript library")
        end
      end
      
      def compile_node(options = {})
        initial = @initial.compile_node
        case @@red_library
          when :Prototype : return "$A(%s)" % [initial]
          else              ""
        end
      end
    end
    
    class StringNode < LiteralNode # :nodoc:
      def compile_node(options = {})
        initial    = @initial.compile_node(options)
        subsequent = @subsequent.map {|element| " + %s" % [element.compile_node]}.join
        return "%s%s" % [initial, subsequent]
      end
    end
  end
end
