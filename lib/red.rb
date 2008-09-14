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

module Red
  ARRAY_NODES = {
    :and          => LogicNode::Conjunction::And,
    #:argscat      => IllegalNode::MultipleAssignmentNode,
    #:argspush     => IllegalNode::MultipleAssignmentNode,
    :array        => LiteralNode::Array,
    :attrasgn     => AssignmentNode::Attribute,
    :begin        => ControlNode::Begin,
    :block        => LiteralNode::Multiline,
    :block_arg    => CallNode::Block::Ampersand,
    :block_pass   => CallNode::Ampersand,
    :break        => ControlNode::Keyword::Break,
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
    :defined      => CallNode::Defined,
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
    :false        => LogicNode::Boolean::False,
    :fcall        => CallNode::Method::ImplicitReceiver,
    :flip2        => IllegalNode::FlipflopNode,
    :flip3        => IllegalNode::FlipflopNode,
    :for          => ControlNode::For,
    :gasgn        => AssignmentNode::GlobalVariable,
    :gvar         => VariableNode::OtherVariable,
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
    :masgn        => AssignmentNode::Multiple,
    :module       => DefinitionNode::Module,
    :next         => ControlNode::Keyword::Next,
    :nil          => VariableNode::Keyword::Nil,
    :not          => LogicNode::Not,
    :op_asgn1     => AssignmentNode::Operator::Bracket,
    :op_asgn2     => AssignmentNode::Operator::Dot,
    :op_asgn_and  => AssignmentNode::Operator::And,
    :op_asgn_or   => AssignmentNode::Operator::Or,
    :or           => LogicNode::Conjunction::Or,
    :postexe      => IllegalNode::PostexeNode,
    :redo         => IllegalNode::RedoNode,
    :rescue       => ControlNode::Rescue,
    :retry        => IllegalNode::RetryNode,
    :return       => ControlNode::Return,
    :sclass       => DefinitionNode::SingletonClass,
    :scope        => DefinitionNode::Scope,
    :self         => VariableNode::Keyword::Self,
    :splat        => LiteralNode::Splat,
    :super        => CallNode::Super,
    :svalue       => LiteralNode::Other,
    :str          => LiteralNode::String,
    :to_ary       => LiteralNode::Array,
    :true         => LogicNode::Boolean::True,
    :undef        => DefinitionNode::Undef,
    :until        => ControlNode::Loop::Until,
    :vcall        => VariableNode::OtherVariable,
    :when         => LogicNode::Case::When,
    :while        => ControlNode::Loop::While,
    :xstr         => LiteralNode::Uninterpreted,
    :yield        => CallNode::Yield,
    :zarray       => LiteralNode::Array,
    :zsuper       => CallNode::Super::Delegate
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
  
  METHOD_ESCAPE = {
    :==           => :_eql2,
    :===          => :_eql3,
    :=~           => :_eqti,
    :[]           => :_brkt,
    :[]=          => :_breq,
    :<=           => :_lteq,
    :>=           => :_gteq,
    :<<           => :_ltlt,
    :<            => :_lthn,
    :>            => :_gthn,
    :'<=>'        => :_ltgt,
    :|            => :_pipe,
    :&            => :_ampe,
    :+            => :_plus,
    :-            => :_subt,
    :*            => :_star,
    :**           => :_str2,
    :/            => :_slsh,
    :%            => :_perc,
    :'^'          => :_care,
    :~            => :_tild
  }
  
  def self.init
    @@namespace_stack = []
    @@exception_index = 0
    @@red_constants = %w:Red Object Module Class Function Proc Array Number:
    @@red_classes   = %w:Red Object Module Class Function Proc Array Number:
    @@red_modules   = %w::
    @@red_function  = nil
    @@red_block_arg = nil
    @@red_scope     = []
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
    ParseTree.translate(self)
  end
  
  def is_sexp?(*sexp_types)
    self.is_a?(Array) && sexp_types.include?(self.first)
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
