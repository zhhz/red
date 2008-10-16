$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'parse_tree'
require 'red/errors'
require 'red/plugin'
require 'red/nodes/assignment_nodes'
require 'red/nodes/call_nodes'
require 'red/nodes/control_nodes'
require 'red/nodes/data_nodes'
require 'red/nodes/definition_nodes'
require 'red/nodes/illegal_nodes'
require 'red/nodes/literal_nodes'
require 'red/nodes/logic_nodes'
require 'red/nodes/variable_nodes'

module Red # :nodoc:
  ARRAY_NODES = {
    :and          => LogicNode::Conjunction::And,
    :alias        => DefinitionNode::Alias,
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
    :dregx        => LiteralNode::Regexp,
    :dregx_once   => IllegalNode::RegexEvaluationNode,
    :dstr         => LiteralNode::String,
    :dsym         => LiteralNode::Symbol,
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
    :redo         => ControlNode::Keyword::Redo,
    :regex        => LiteralNode::Regexp,
    :resbody      => ControlNode::RescueBody,
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
    :sym          => LiteralNode::Symbol,
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
    Bignum        => DataNode::Numeric,
    Fixnum        => DataNode::Numeric,
    Float         => DataNode::Numeric,
    Range         => DataNode::Range,
    Regexp        => DataNode::Regexp,
    Symbol        => DataNode::Symbol,
    String        => DataNode::String,
    NilClass      => DataNode::Nil
  }
  
  METHOD_ESCAPE = {
    :==           => :_eql2,
    :===          => :_eql3,
    :=~           => :_etld,
    :[]           => :_brac,
    :[]=          => :_breq,
    :<=           => :_lteq,
    :>=           => :_gteq,
    :<<           => :_ltlt,
    :>>           => :_gtgt,
    :<            => :_lthn,
    :>            => :_gthn,
    :'<=>'        => :_ltgt,
    :|            => :_pipe,
    :&            => :_ampe,
    :+            => :_plus,
    :+@           => :_posi,
    :-            => :_subt,
    :-@           => :_nega,
    :*            => :_star,
    :**           => :_str2,
    :/            => :_slsh,
    :%            => :_perc,
    :'^'          => :_care,
    :~            => :_tild
  }
  
  NATIVE_CONSTANTS = %w{
    c$Object
    c$Module
    c$Class
    c$Comparable
    c$Enumerable
    c$Kernel
    c$Math
    c$Math.c$E
    c$Math.c$PI
    c$Array
    c$Exception
    c$StandardError
    c$ArgumentError
    c$IndexError
    c$RangeError
    c$RuntimeError
    c$TypeError
    c$FalseClass
    c$Hash
    c$MatchData
    c$NilClass
    c$Numeric
    c$Proc
    c$Range
    c$Regexp
    c$Regexp.c$IGNORECASE
    c$Regexp.c$EXTENDED
    c$Regexp.c$MULTILINE
    c$String
    c$Symbol
    c$Time
    c$TrueClass
  }
  
  INTERNAL_METHODS = %w{
    []
    []=
    <=>
    ==
    ===
    allocate
    append_features
    backtrace
    block_given?
    call
    class
    extend_object
    extended
    hash
    include
    included
    inherited
    initialize
    inspect
    is_a?
    join
    new
    raise
    sprintf
    to_proc
    to_s
    to_str
  }.map {|m| m.to_sym }
  
  def self.init
    @@namespace_stack = []
    @@red_constants   = NATIVE_CONSTANTS
    @@red_methods     = INTERNAL_METHODS
    @@red_function    = nil
    @@red_singleton   = nil
    @@red_block_arg   = nil
    @@red_import      = false
    return true
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
  
  def translate_to_sexp_array
    raise TypeError, "Can only translate Strings" unless self.is_a?(String)
    ParseTree.translate(self)
  end
  
  def is_sexp?(*sexp_types)
    self.is_a?(Array) && sexp_types.include?(self.first)
  end
  
  def self.rails
    require 'red/plugin'
  end
end
