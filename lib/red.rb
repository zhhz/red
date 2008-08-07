$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'parse_tree'
require 'red/assignment_nodes'
require 'red/call_nodes'
require 'red/conditional_nodes'
require 'red/conjunction_nodes'
require 'red/constant_nodes'
require 'red/control_nodes'
require 'red/data_nodes'
require 'red/definition_nodes'
require 'red/errors'
require 'red/illegal_nodes'
require 'red/literal_nodes'
require 'red/plugin'
require 'red/variable_nodes'
require 'red/wrap_nodes'

module Red
  @@red_library = nil
  @@red_module  = nil
  @@red_class   = nil
  @@rescue_is_safe = false
  @@exception_index = 0
  
  ARRAY_NODES = {
    :and          => ConjunctionNode::AndNode,
    :argscat      => IllegalNode::MultipleAssignmentNode,
    :argspush     => IllegalNode::MultipleAssignmentNode,
    :array        => LiteralNode::ArrayNode,
    :attrasgn     => AssignmentNode::AttributeNode,
    :begin        => ControlNode::BeginNode,
    :block        => LiteralNode::MultilineNode,
    :block_arg    => IllegalNode::BlockArgument,
    :block_pass   => IllegalNode::BlockArgument,
    :break        => ConstantNode::BreakNode,
    :call         => CallNode::MethodNode::ExplicitNode,
    :case         => ConditionalNode::CaseNode,
    :class        => DefinitionNode::ClassNode,
    :cdecl        => AssignmentNode::GlobalVariableNode,
    :colon2       => LiteralNode::NamespaceNode,
    :colon3       => ControlNode::LibraryNode,
    :const        => VariableNode::OtherVariableNode,
    :cvar         => VariableNode::ClassVariableNode,
    :cvasgn       => AssignmentNode::ClassVariableNode,
    :cvdecl       => AssignmentNode::ClassVariableNode,
    :dasgn        => AssignmentNode::LocalVariableNode,
    :dasgn_curr   => AssignmentNode::LocalVariableNode,
    :defined      => WrapNode::DefinedNode,
    :defn         => DefinitionNode::InstanceMethodNode,
    :defs         => DefinitionNode::ClassMethodNode,
    :dot2         => LiteralNode::RangeNode,
    :dot3         => LiteralNode::RangeNode::ExclusiveNode,
    :dregx        => IllegalNode::RegexEvaluationNode,
    :dregx_once   => IllegalNode::RegexEvaluationNode,
    :dstr         => LiteralNode::StringNode,
    :dsym         => IllegalNode::SymbolEvaluationNode,
    :dvar         => VariableNode::OtherVariableNode,
    :dxstr        => LiteralNode::StringNode,
    :ensure       => ControlNode::EnsureNode,
    :evstr        => LiteralNode::StringNode,
    :false        => ConstantNode::FalseNode,
    :fcall        => CallNode::MethodNode::ImplicitNode,
    :flip2        => IllegalNode::FlipflopNode,
    :flip3        => IllegalNode::FlipflopNode,
    :for          => ControlNode::ForNode,
    :gasgn        => AssignmentNode::GlobalVariableNode,
    :gvar         => VariableNode::GlobalVariableNode,
    :hash         => LiteralNode::HashNode,
    :iasgn        => AssignmentNode::InstanceVariableNode,
    :if           => ConditionalNode::IfNode,
    :iter         => CallNode::BlockNode,
    :ivar         => VariableNode::InstanceVariableNode,
    :lasgn        => AssignmentNode::LocalVariableNode,
    :lvar         => VariableNode::OtherVariableNode,
    :lit          => LiteralNode::OtherNode,
    :match        => IllegalNode::MatchNode,
    :match2       => CallNode::MatchNode,
    :match3       => CallNode::MatchNode::ReverseNode,
    :masgn        => IllegalNode::MultipleAssignmentNode,
    :module       => DefinitionNode::ModuleNode,
    :next         => ConstantNode::NextNode,
    :nil          => ConstantNode::NilNode,
    :not          => WrapNode::NotNode,
    :op_asgn1     => AssignmentNode::OperatorNode::BracketNode,
    :op_asgn2     => AssignmentNode::OperatorNode::DotNode,
    :op_asgn_and  => AssignmentNode::OperatorNode::AndNode,
    :op_asgn_or   => AssignmentNode::OperatorNode::OrNode,
    :or           => ConjunctionNode::OrNode,
    :postexe      => IllegalNode::PostexeNode,
    :redo         => IllegalNode::RedoNode,
    :rescue       => ControlNode::RescueNode,
    :retry        => IllegalNode::RetryNode,
    :return       => WrapNode::ReturnNode,
    :sclass       => DefinitionNode::ObjectLiteralNode,
    :scope        => LiteralNode::OtherNode,
    :self         => ConstantNode::SelfNode,
    :splat        => LiteralNode::SplatNode,
    :super        => WrapNode::SuperNode,
    :svalue       => LiteralNode::OtherNode,
    :str          => LiteralNode::StringNode,
    :true         => ConstantNode::TrueNode,
    :undef        => IllegalNode::UndefNode,
    :until        => ControlNode::UntilNode,
    :vcall        => VariableNode::OtherVariableNode,
    :when         => ConditionalNode::WhenNode,
    :while        => ControlNode::WhileNode,
    :xstr         => LiteralNode::StringNode,
    :yield        => WrapNode::YieldNode,
    :zarray       => LiteralNode::ArrayNode,
    :zsuper       => WrapNode::SuperNode
  }
  
  DATA_NODES = {
    Bignum        => DataNode::OtherNode,
    Fixnum        => DataNode::OtherNode,
    Float         => DataNode::OtherNode,
    Range         => DataNode::RangeNode,
    Regexp        => DataNode::OtherNode,
    Symbol        => DataNode::SymbolNode,
    String        => DataNode::StringNode,
    NilClass      => DataNode::NilNode
  }
  
  def build_node # :nodoc:
    case self
    when Array
      raise(BuildError::UnknownNode, "Don't know how to handle sexp type :#{self.first}") unless ARRAY_NODES[self.first]
      return ARRAY_NODES[self.first].new(*self[1..-1])
    else
      return DATA_NODES[self.class].new(self)
    end
  rescue => e
    self.handle_red_error(e)
  end
  
  def build_nodes  # :nodoc:
    self.map {|node| node.build_node}
  end
  
  def compile_nodes(options = {}) # :nodoc:
    self.map {|node| node.compile_node(options)}
  end
  
  def string_to_node # :nodoc:
    self.translate_to_sexp_array.build_node
  rescue SyntaxError => e
    self.handle_red_error(e)
  end
  
  def translate_to_sexp_array # :nodoc:
    raise TypeError, "Can only translate Strings" unless self.is_a?(String)
    ParseTree.translate("::Standard\n" + self)
  end
  
  def handle_red_error(error) # :nodoc:
    @@red_errors ||= "\n// Errors"
    @@red_errors << "\n// %s: %s" % [@@exception_index += 1, error]
    return DataNode::ErrorNode.new(@@exception_index)
  end
  
  def self.rails
    require 'red/plugin'
  end
end