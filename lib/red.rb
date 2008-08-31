$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'parse_tree'
require 'red/errors'
require 'red/plugin'
require 'red/nodes/assignment_nodes'
require 'red/nodes/call_nodes'
require 'red/nodes/constant_nodes'
require 'red/nodes/control_nodes'
require 'red/nodes/data_nodes'
require 'red/nodes/definition_nodes'
require 'red/nodes/illegal_nodes'
require 'red/nodes/literal_nodes'
require 'red/nodes/logic_nodes'
require 'red/nodes/variable_nodes'
require 'red/nodes/wrap_nodes'

module Red
  ARRAY_NODES = {
    :and          => LogicNode::Conjunction::And,
    :argscat      => IllegalNode::MultipleAssignmentNode,
    :argspush     => IllegalNode::MultipleAssignmentNode,
    :array        => LiteralNode::Array,
    :attrasgn     => AssignmentNode::Attribute,
    :begin        => ControlNode::Begin,
    :block        => LiteralNode::Multiline,
    :block_arg    => CallNode::Block::Ampersand,
    :block_pass   => CallNode::Block::Ampersand,
    :break        => ConstantNode::Break,
    :call         => CallNode::Method::ExplicitReceiver,
    :case         => LogicNode::Case,
    :class        => DefinitionNode::Class,
    :cdecl        => AssignmentNode::Constant,
    :colon2       => LiteralNode::Namespace,
    :colon3       => LiteralNode::Namespace::TopLevel,
    :const        => VariableNode::Constant,
    :cvar         => VariableNode::ClassVariable,
    :cvasgn       => AssignmentNode::ClassVariable,
    :cvdecl       => AssignmentNode::ClassVariable,
    :dasgn        => AssignmentNode::LocalVariable,
    :dasgn_curr   => AssignmentNode::LocalVariable,
    :defined      => WrapNode::Defined,
    :defn         => DefinitionNode::Method::Instance,
    :defs         => DefinitionNode::Method::Singleton,
    :dot2         => LiteralNode::Range,
    :dot3         => LiteralNode::Range::Exclusive,
    :dregx        => IllegalNode::RegexEvaluationNode,
    :dregx_once   => IllegalNode::RegexEvaluationNode,
    :dstr         => LiteralNode::String,
    :dsym         => IllegalNode::SymbolEvaluationNode,
    :dvar         => VariableNode::OtherVariable,
    :dxstr        => LiteralNode::Uninterpreted,
    :ensure       => ControlNode::Ensure,
    :evstr        => LiteralNode::String,
    :false        => ConstantNode::False,
    :fcall        => CallNode::Method::ImplicitReceiver,
    :flip2        => IllegalNode::FlipflopNode,
    :flip3        => IllegalNode::FlipflopNode,
    :for          => ControlNode::For,
    :gasgn        => AssignmentNode::GlobalVariable,
    :gvar         => VariableNode::GlobalVariable,
    :hash         => LiteralNode::Hash,
    :iasgn        => AssignmentNode::InstanceVariable,
    :if           => LogicNode::If,
    :iter         => CallNode::Block,
    :ivar         => VariableNode::InstanceVariable,
    :lasgn        => AssignmentNode::LocalVariable,
    :lvar         => VariableNode::OtherVariable,
    :lit          => LiteralNode::Other,
    :match        => IllegalNode::MatchNode,
    :match2       => CallNode::Match,
    :match3       => CallNode::Match::Reverse,
    :masgn        => IllegalNode::MultipleAssignmentNode,
    :module       => DefinitionNode::Module,
    :next         => ConstantNode::Next,
    :nil          => ConstantNode::Nil,
    :not          => WrapNode::Not,
    :op_asgn1     => AssignmentNode::Operator::Bracket,
    :op_asgn2     => AssignmentNode::Operator::Dot,
    :op_asgn_and  => AssignmentNode::Operator::And,
    :op_asgn_or   => AssignmentNode::Operator::Or,
    :or           => LogicNode::Conjunction::Or,
    :postexe      => IllegalNode::PostexeNode,
    :redo         => IllegalNode::RedoNode,
    :rescue       => ControlNode::Rescue,
    :retry        => IllegalNode::RetryNode,
    :return       => WrapNode::Return,
    :sclass       => DefinitionNode::SingletonClass,
    :scope        => LiteralNode::Other,
    :self         => ConstantNode::Self,
    :splat        => LiteralNode::Splat,
    :super        => WrapNode::Super,
    :svalue       => LiteralNode::Other,
    :str          => LiteralNode::String,
    :true         => ConstantNode::True,
    :undef        => IllegalNode::UndefNode,
    :until        => ControlNode::Loop::Until,
    :vcall        => VariableNode::OtherVariable,
    :when         => LogicNode::Case::When,
    :while        => ControlNode::Loop::While,
    :xstr         => LiteralNode::Uninterpreted,
    :yield        => CallNode::Yield,
    :zarray       => LiteralNode::Array,
    :zsuper       => WrapNode::Super
  }
  
  DATA_NODES = {
    Bignum        => DataNode::Other,
    Fixnum        => DataNode::Other,
    Float         => DataNode::Other,
    Range         => DataNode::Range,
    Regexp        => DataNode::Other,
    Symbol        => DataNode::Symbol,
    String        => DataNode::String,
    NilClass      => DataNode::Nil
  }
  
  def self.init
    @@namespace_stack = []
    @@exception_index = 0
    @@red_constants = %w::
    @@red_classes   = %w::
    @@red_modules   = %w::
    @@red_initializers = {'' => [:defn, :initialize, [:scope, [:block, [:args], [:nil]]]]}
  end
  
  def red!(options = {}, reset = false)
    Red.init if reset
    case self
    when Array
      raise(BuildError::UnknownNode, "Don't know how to handle sexp type :#{self.first}") unless ARRAY_NODES[self.first]
      return ARRAY_NODES[self.first].new(*(self[1..-1] + [options]))
    else
      return DATA_NODES[self.class].new(self, options)
    end
  end
  
  def translate_to_sexp_array # :nodoc:
    raise TypeError, "Can only translate Strings" unless self.is_a?(String)
    ParseTree.translate(self.escape_dollar_sign_methods)
  end
  
  def escape_dollar_sign_methods
    self.gsub(/\$(\$*\w*)\(/,"_r_e_d\\0").gsub('_r_e_d$','_r_e_d').gsub('_r_e_d$','_r_e_dd')
  end
  
  def add_parentheses_wrapper(options)
    self.replace("(%s)" % self) if options[:perform_if]
    return self
  end
  
  # def handle_red_error(error) # :nodoc:
  #   @@red_errors ||= "\n// Errors"
  #   @@red_errors << "\n// %s: %s" % [@@exception_index += 1, error]
  #   return DataNode::ErrorNode.new(@@exception_index)
  # end
  
  def self.rails
    require 'red/plugin'
  end
end
