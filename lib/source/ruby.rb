`Red = {
  id: 100,
  
  conferInheritance: function(newClass,superclass) {
    newClass.__superclass__=superclass;
    Red.donateMethodsToSingleton(superclass,newClass,true);
    Red.donateMethodsToClass(superclass.prototype,newClass.prototype,true);
    if(newClass==c$Module){delete(newClass.prototype.m$initialize);};
    if(newClass!==Number&&newClass!==Array){newClass.prototype.toString=superclass.prototype.toString;};
  },
  
  donateMethodsToSingleton: function(donor,recipient,overwrite) {
    for(var x in donor) {
      if(x.slice(0,2)==='m$' && (overwrite || recipient[x]===undefined)) {
        var f = function() { var m=arguments.callee;return m.__methodSource__[m.__methodName__].apply(m.__methodReceiver__,arguments); };
        f.__methodName__=x;f.__methodSource__=donor;f.__methodReceiver__=recipient;
        recipient[x]=f;
      };
    };
  },
  
  donateMethodsToClass: function(donor,recipient,overwrite) {
    for(var x in donor) {
      if(x.slice(0,2)==='m$' && (overwrite || recipient[x]===undefined)) {
        var f = function() { var m=arguments.callee;return m.__methodSource__[m.__methodName__].apply(this,arguments); };
        f.__methodName__=x;f.__methodSource__=donor;
        recipient[x]=f;
      };
    };
  },
  
  updateChildren: function(parentClass) {
    for(var x in parentClass.__children__) {
      var childClass=Red.inferConstantFromString(x);
      Red.donateMethodsToSingleton(parentClass,childClass,false);
      Red.donateMethodsToClass(parentClass.prototype,childClass.prototype,false);
      Red.updateChildren(childClass);
    };
  },
  
  updateIncluders: function(module) {
    for(var x in module.__includers__) {
      var includer=Red.inferConstantFromString(x);
      Red.donateMethodsToSingleton(module,includer,false);
      Red.donateMethodsToClass(module.prototype,includer.prototype,false);
      switch(includer.m$class().__name__){case 'Module':Red.updateIncluders(includer);break;case 'Class':Red.updateChildren(includer);break;};
    };
  },
  
  initializeClass: function(longName,newClass) {
    newClass.__name__ = longName;
    newClass.__id__ = Red.id++;
    newClass.__modules__ = {};
    newClass.__children__ = {};
    newClass.__class__ = c$Class;
    newClass.prototype.__class__=newClass;
    Red.donateMethodsToSingleton(c$Class.prototype,newClass,true)
  },
  
  interpretNamespace: function(longName) {
    var ary=longName.split('.'),name=ary.pop(),namespace=window;
    while(ary.length>0){namespace=namespace['c$'+ary.shift()];};
    return [namespace,name];
  },
  
  inferConstantFromString: function(longName) {
    if(longName=='window'){return window;}
    var context=Red.interpretNamespace(longName);
    return context[0]['c$'+context[1]];
  },
  
  _module: function(longName,block){
    var newModule,context=Red.interpretNamespace(longName),namespace=context[0],name=context[1];
    if(namespace['c$'+name]) {
      newModule = namespace['c$'+name];
    } else {
      newModule = c$Module.m$new(longName);
      namespace['c$'+name] = newModule;
      newModule.__includers__={};
    };
    if(typeof(block)=='function') { block.call(newModule); };
  },
  
  _class: function(longName,superclass,block){
    var newClass,context=Red.interpretNamespace(longName),namespace=context[0],name=context[1];
    if(namespace['c$'+name]) {
      if(name!=='Object' && superclass!==namespace['c$'+name].__superclass__){m$raise(c$TypeError,$q('superclass mismatch for class '+longName));};
      newClass = namespace['c$'+name];
      if(name=='Module'&&!(newClass.__superclass__.__children__[name])){Red.conferInheritance(c$Module,c$Object);}
      if(name=='Class'&&!(newClass.__superclass__.__children__[name])){Red.conferInheritance(c$Class,c$Module);}
    } else {
      switch(name){
        case 'Array':newClass=Array;break;case 'Numeric':newClass=Number;break;
        default: newClass = function() { this.__id__ = Red.id++ };
      };
      Red.conferInheritance(newClass,superclass);
      Red.initializeClass(longName,newClass);
      superclass.__children__[newClass.__name__]=true;
      superclass.m$inherited && superclass.m$inherited(newClass);
      namespace['c$'+name] = newClass;
    };
    if(name == 'Object' || superclass == c$Object){
      newClass.cvset = function(var_name,object) { return newClass['v$'+var_name] = object; };
      newClass.cvget = function(var_name)        { return newClass['v$'+var_name]; };
    } else {
      newClass.cvset = function() { return superclass.cvset.apply(null,arguments); };
      newClass.cvget = function() { return superclass.cvget.apply(null,arguments); };
    };
    if(typeof(block)=='function') { block.call(newClass); };
    Red.updateChildren(newClass);
    if((typeof(c$TrueClass)!='undefined'&&newClass==c$TrueClass)||(typeof(c$FalseClass)!='undefined'&&newClass==c$FalseClass)) { Red.donateMethodsToClass(newClass.prototype,Boolean.prototype,true); };
  },
  
  LoopError: {
    _break:function(value){var e=new(Error);e.__keyword__='break';e._value=value==null?nil:value;throw(e);},
    _next:function(value){var e=new(Error);e.__keyword__='next';e._value=value==null?nil:value;throw(e);},
    _redo:function(){var e=new(Error);e.__keyword__='redo';throw(e);},
  }
};

var $u=undefined,nil=null;

c$Class  = function(){this.__id__=Red.id++};c$Class.__name__='Class';c$Class.__children__={};
c$Module = function(){this.__id__=Red.id++};c$Module.__name__='Module';c$Module.__children__={};c$Class.__superclass__=c$Module;
c$Object = function(){this.__id__=Red.id++};c$Object.__name__='Object';c$Object.__children__={};c$Module.__superclass__=c$Object;

c$Object.prototype.toString=function(){return '#<'+this.m$class().__name__.replace(/\\./g,'::')+':0x'+(this.__id__*999^4000000).toString(16)+'>'};
Function.prototype.m$=function(o){var f=this;var p=function(){return f.apply(o,arguments);};p._arity=f.arity;p.__id__=Red.id++;return p;};
window.__name__='window';
window.prototype=window;
window.__children__={'Object':true};
window.m$include=function(){for(var i=0,modules=arguments,l=modules.length;i<l;++i){var mp=modules[i].prototype;for(var x in mp){if(x.slice(0,2)=='m$'){var f=function(){return arguments.callee._source[arguments.callee._name].apply(window,arguments) };f._source=mp;f._name=x;window[x]=f;};};modules[i].m$included(window);modules[i].__includers__['window']=true;};if(modules[0]!=c$Kernel){Red.donateMethodsToClass(window,c$Object.prototype);Red.updateChildren(c$Object);};return window;};
window.m$blockGivenBool=function(){typeof(arguments[0])=='function'}

function $e(e,ary){if(e.m$isABool){for(var i=0,l=ary.length;i<l;++i){if(e.m$isABool(ary[i])){return true;};};};return false;};
function $Q(){for(var i=1,s=arguments[0],l=arguments.length;i<l;++i){s+=$q(arguments[i]).m$toS()._value;};return $q(s);};
function $q(obj){if(typeof obj!=='string'){return obj;};return c$String.m$new(obj);};
function $r(value,options){return c$Regexp.m$new(value,options);};
function $s(value){return(c$Symbol._table[value]||c$Symbol.m$new(value));};
function $T(x){return x!==false&&x!==nil&&x!=undefined;};

`

# +Object+ is the parent class of all classes in Red. Its methods are
# therefore available to all objects unless explicitly overridden.
# 
# In the descriptions of +Object+'s methods, the parameter _sym_ refers to
# either a quoted string or a +Symbol+ (such as <tt>:name</tt>).
# 
class Object
  def initialize # :nodoc:
  end
  
  # call-seq:
  #   obj == other      -> true or false
  #   obj.eql?(other)   -> true or false
  #   obj.equal?(other) -> true or false
  # 
  # Equality -- at the +Object+ level, <tt>==</tt> returns +true+ only if
  # _obj_ and _other_ are the same object. Typically, this method is
  # overridden in descendent classes to provide class-specific meaning.
  # 
  # Unlike <tt>==</tt>, the <tt>equal?</tt> method should never be overridden
  # by subclasses: it is used to determine object identity (that is,
  # <tt>a.equal?(b)</tt> iff +a+ is the same object as +b+).
  # 
  # The <tt>eql?</tt> method returns true if _obj_ and _other_ have the same
  # value. Used by +Hash+ to test members for equality. For objects of class
  # +Object+, <tt>eql?</tt> is synonymous with <tt>==</tt>. Subclasses
  # may override this behavior.
  # 
  def ==(other)
    `this.__id__==other.__id__`
  end
  
  # call-seq:
  #   obj === other -> true or false
  # 
  # Case Equality -- for class +Object+, effectively the same as calling
  # <tt>==</tt>, but typically overridden by descendents to provide meaningful
  # semantics in case statements.
  # 
  def ===(other)
    `this.__id__==other.__id__`
  end
  
  # call-seq:
  #   obj =~ other -> false
  # 
  # Pattern Match -- overridden by descendents (notably +Regexp+ and +String+)
  # to provide meaningful pattern-match semantics.
  # 
  def =~
    false
  end
  
  # call-seq:
  #   obj.__id__    -> integer
  #   obj.object_id -> integer
  # 
  # Returns an integer identifier for _obj_. The same number will be returned
  # on all calls to <tt>\_\_id\_\_</tt> for a given object, and no two active objects
  # will share an id.
  # 
  def __id__
    `this.__id__`
  end
  
  # call-seq:
  #   obj.__send__(sym [, args...]) -> object
  #   obj.send(sym [, args...])     -> object
  # 
  # Invokes the method identified by _sym_, passing it any arguments
  # specified. Use <tt>\_\_send\_\_</tt> if the name +send+ clashes with an
  # existing method in _obj_.
  # 
  #   class Klass
  #     def hello(*args)
  #       "Hello " + args.join(' ')
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.__send__(:hello, "gentle", "readers")  #=> "Hello gentle readers"
  # 
  def __send__(method,*args)
    `this['m$'+method._value.replace('=','Eql')].apply(this,args)`
  end
  
  # call-seq:
  #   obj.class -> class
  # 
  # Returns the class of _obj_. This method must always be called with an
  # explicit receiver, as class is also a reserved word.
  # 
  #   'a'.class     #=> String
  #   self.class    #=> Object
  # 
  def class
    `this.__class__`
  end
  
  # call-seq:
  #   obj.clone -> object
  # 
  # Produces a shallow copy of _obj_ -- the instance variables of _obj_ are
  # copied, but not the objects they reference. See also the discussion under
  # <tt>Object#dup</tt>.
  # 
  #   class Klass
  #      attr_accessor :str
  #   end
  #   
  #   s1 = Klass.new      #=> #<Klass:100>
  #   s1.str = "Hello"    #=> "Hello"
  #   s2 = s1.clone       #=> #<Klass:101>
  #   s2.str[1,4] = "i"   #=> "i"
  #   s1.str              #=> "Hi"
  #   s2.str              #=> "Hi"
  # 
  # This method may have class-specific behavior. If so, that behavior will be
  # documented under the <tt>initialize_copy</tt> method of the class.
  # 
  def clone
    `var result={}`
    `for(var x in this){if(x!='__id__'){result[x]=this[x];};}`
    `result.__id__=Red.id++`
    return `result`
  end
  
  # call-seq:
  #   obj.dup -> object
  # 
  # Produces a shallow copy of _obj_ -- the instance variables of _obj_ are
  # copied, but not the objects they reference. See also the discussion under
  # <tt>Object#clone</tt>. In general, +clone+ and +dup+ may have different
  # semantics in descendent classes. While +clone+ is used to duplicate an
  # object, including its internal state, +dup+ typically uses the class of
  # the descendent object to create the new instance.
  # 
  # This method may have class-specific behavior. If so, that behavior will be
  # documented under the <tt>initialize_copy</tt> method of the class.
  # 
  def dup
    `var result=this.m$class.m$new()`
    `for(var x in this){if(x!='__id__'&&x.slice(0,2)!='i$'){result[x]=this[x];};}`
    `result.__id__=Red.id++`
    return `result`
  end
  
  # FIX: Incomplete
  def enum
  end
  
  # call-seq:
  #   obj == other      -> true or false
  #   obj.eql?(other)   -> true or false
  #   obj.equal?(other) -> true or false
  # 
  # Equality -- at the +Object+ level, <tt>==</tt> returns +true+ only if
  # _obj_ and _other_ are the same object. Typically, this method is
  # overridden in descendent classes to provide class-specific meaning.
  # 
  # Unlike <tt>==</tt>, the <tt>equal?</tt> method should never be overridden
  # by subclasses: it is used to determine object identity (that is,
  # <tt>a.equal?(b)</tt> iff +a+ is the same object as +b+).
  # 
  # The <tt>eql?</tt> method returns true if _obj_ and _other_ have the same
  # value. Used by +Hash+ to test members for equality. For objects of class
  # +Object+, <tt>eql?</tt> is synonymous with <tt>==</tt>. Subclasses
  # may override this behavior.
  # 
  def eql?(other)
    `this.__id__==other.__id__`
  end
  
  # call-seq:
  #   obj == other      -> true or false
  #   obj.eql?(other)   -> true or false
  #   obj.equal?(other) -> true or false
  # 
  # Equality -- at the +Object+ level, <tt>==</tt> returns +true+ only if
  # _obj_ and _other_ are the same object. Typically, this method is
  # overridden in descendent classes to provide class-specific meaning.
  # 
  # Unlike <tt>==</tt>, the <tt>equal?</tt> method should never be overridden
  # by subclasses: it is used to determine object identity (that is,
  # <tt>a.equal?(b)</tt> iff +a+ is the same object as +b+).
  # 
  # The <tt>eql?</tt> method returns true if _obj_ and _other_ have the same
  # value. Used by +Hash+ to test members for equality. For objects of class
  # +Object+, <tt>eql?</tt> is synonymous with <tt>==</tt>. Subclasses
  # may override this behavior.
  # 
  def equal?(other)
    `this.__id__==other.__id__`
  end
  
  # call-seq:
  #   obj.extend(module, ...) -> obj
  # 
  # Adds to _obj_ the instance methods from each module given as a parameter.
  # Internally, invokes <tt>extend_object</tt> and the callback
  # <tt>extended</tt> on each given module in turn, passing _obj_ as the
  # argument.
  # 
  #   module Mod
  #     def hello
  #       "Hello from Mod"
  #     end
  #   end
  #   
  #   class Klass
  #     def hello
  #       "Hello from Klass"
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.hello         #=> "Hello from Klass"
  #   k.extend(Mod)   #=> #<Klass:100>
  #   k.hello         #=> "Hello from Mod"
  # 
  def extend(*modules)
    `for(var i=0,l=modules.length;i<l;++i){modules[i].m$extendObject(this);modules[i].m$extended(this);}`
    return self
  end
  
  # call-seq:
  #   obj.hash -> js_string
  # 
  # Generates a hash value for this object, in JavaScript native string form,
  # which is used by class +Hash+ to access its internal contents table. This
  # function must have the property that <tt>a.eql?(b)</tt> implies
  # <tt>a.hash == b.hash</tt>, and is typically overridden in child classes.
  # 
  def hash
    `'o_'+this.__id__`
  end
  
  # call-seq:
  #   obj.inspect -> string
  # 
  # Returns a string containing a human-readable representation of _obj_. If
  # not overridden, uses the +to_s+ method to generate the string.
  # 
  def inspect
    `this.m$toS()`
  end
  
  # call-seq:
  #   obj.instance_eval { || block } -> object
  # 
  # Evaluates the given block within the context of the receiver (_obj_). In
  # order to set the context, the variable _self_ is set to _obj_ while the
  # code is executing, giving the code access to _obj_'s instance variables.
  # 
  #   class Klass
  #     def initialize
  #       @secret = 99
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.instance_eval { @secret }   #=> 99
  # 
  def instance_eval(&block)
    `block._block.m$(this)()`
  end
  
  # call-seq:
  #   obj.instance_of?(class) -> true or false
  # 
  # Returns +true+ if _obj_ is an instance of the given class. See also
  # <tt>Object#kind_of?</tt>.
  # 
  def instance_of?(klass)
    `this.m$class()==klass`
  end
  
  # call-seq:
  #   obj.instance_variable_defined?(sym) -> true or false
  # 
  # Returns true if the given instance variable is defined in obj.
  # 
  #   class Klass
  #     def initialize(a)
  #       @a = a
  #     end
  #   end
  #   
  #   k = Klass.new(99)
  #   k.instance_variable_defined?(:@a)    #=> true
  #   k.instance_variable_defined?("@b")   #=> false
  # 
  def instance_variable_defined?(name)
    `this[name._value.replace('@','i$')]!=null`
  end
  
  # call-seq:
  #   obj.instance_variable_get(sym) -> object
  # 
  # Returns the value of the given instance variable, or +nil+ if the instance
  # variable is not set. The <tt>@</tt> part of the variable name should be
  # included for regular instance variables.
  # 
  #   class Klass
  #     def initialize(a)
  #       @a = a
  #     end
  #   end
  #   
  #   k = Klass.new(99)
  #   k.instance_variable_get(:@a)    #=> 99
  # 
  def instance_variable_get(name)
    `var v=this[name._value.replace('@','i$')]`
    `v==null?nil:v`
  end
  
  # call-seq:
  #   obj.instance_variable_set(sym, object) -> object
  # 
  # Sets the instance variable named by _sym_ to _obj_. The variable need not
  # exist prior to this call.
  # 
  #   class Klass
  #     def initialize(a)
  #       @a = a
  #     end
  #   end
  #   
  #   k = Klass.new(99)
  #   k.instance_variable_set(:@a,79)   #=> 79
  #   k.instance_variable_get('@a')     #=> 79
  # 
  # FIX: Incomplete
  def instance_variable_set(name, obj)
    `this[name._value.replace('@','i$')]=obj`
  end
  
  # call-seq:
  #   obj.instance_variables -> array
  # 
  # Returns an array of instance variable names for the receiver. Note that
  # simply defining an accessor does not create the corresponding instance
  # variable.
  # 
  #   class Klass
  #     attr_accessor :iv
  #     def initialize
  #       @v = 5
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.instance_variables    #=> ["@v"]
  # 
  def instance_variables
    `var result=[]`
    `for(var x in this){if(x.slice(0,2)=='i$'){result.push($q('@'+$_uncamel(x.slice(2,x.length))));};}`
    return `result`
  end
  
  # call-seq:
  #   obj.is_a?(class)    -> true or false
  #   obj.kind_of?(class) -> true or false
  # 
  # Returns +true+ if _class_ is the class of _obj_, or if _class_ is one of
  # the superclasses of _obj_ or modules included in _obj_.
  # 
  #   module M; end
  #   class A
  #     include M
  #   end
  #   class B < A; end
  #   class C < B; end
  #   b = B.new
  #   b.instance_of? A    #=> false
  #   b.instance_of? B    #=> true
  #   b.instance_of? C    #=> false
  #   b.instance_of? M    #=> false
  #   b.is_a? A           #=> true
  #   b.is_a? B           #=> true
  #   b.is_a? C           #=> false
  #   b.is_a? M           #=> true
  # 
  # FIX: Incomplete
  def is_a?(klass)
    `if(this.m$class()==klass||c$Object==klass){return true;}`  # true if instance_of? or if klass is Object
    `if(this.m$class().__modules__[klass]){return true;}`            # true if klass is included in obj's class
    `if(this.m$class()==c$Object){return false;}`               # false if module check fails and obj is Object
    `var bubble=this.m$class(),result=false`
    `while(bubble!=c$Object){if(klass==bubble||bubble.__modules__[klass]!=null){result=true;};if(result){break;};bubble=bubble.__superclass__;}`
    return `result`
  end
  
  # call-seq:
  #   obj.is_a?(class)    -> true or false
  #   obj.kind_of?(class) -> true or false
  # 
  # Returns +true+ if _class_ is the class of _obj_, or if _class_ is one of
  # the superclasses of _obj_ or modules included in _obj_.
  # 
  #   module M; end
  #   class A
  #     include M
  #   end
  #   class B < A; end
  #   class C < B; end
  #   b = B.new
  #   b.instance_of? A    #=> false
  #   b.instance_of? B    #=> true
  #   b.instance_of? C    #=> false
  #   b.instance_of? M    #=> false
  #   b.kind_of? A        #=> true
  #   b.kind_of? B        #=> true
  #   b.kind_of? C        #=> false
  #   b.kind_of? M        #=> true
  # 
  # FIX: Incomplete
  def kind_of?(klass)
    `if(this.m$class()==klass||c$Object==klass){return true;}`  # true if instance_of? or if klass is Object
    `if(this.m$class().__modules__[klass]){return true;}`            # true if klass is included in obj's class
    `if(this.m$class()==c$Object){return false;}`               # false if module check fails and obj is Object
    `var bubble=this.m$class(),result=false`
    `while(bubble!=c$Object){if(klass==bubble||bubble.__modules__[klass]!=null){result=true;};if(result){break;};bubble=bubble.__superclass__;}`
    return `result`
  end
  
  # call-seq:
  #   obj.method(sym) -> method
  # 
  # Looks up the named method as a receiver in _obj_, returning a +Method+
  # object (or raising NameError). The +Method+ object acts as a closure in
  # _obj_'s object instance, so instance variables and the value of _self_
  # remain available.
  # 
  #   class Klass
  #     def initialize(n)
  #       @iv = n
  #     end
  #     
  #     def hello
  #       "Hello, @iv = #{@iv}"
  #     end
  #   end
  #   
  #   k1 = Klass.new(4)
  #   m1 = k1.method(:hello)
  #   m1.call   #=> "Hello, @iv = 4"
  #   
  #   k2 = Klass.new('four')
  #   m2 = k2.method("hello")
  #   m2.call   #=> "Hello, @iv = four"
  # 
  # FIX: Incomplete
  def method(name)
  end
  
  # call-seq:
  #   obj.methods -> array
  # 
  # Returns a list of the names of methods publicly accessible in _obj_. This
  # will include all the methods accessible in _obj_'s ancestors.
  # 
  #   class Klass
  #     def k_method
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.methods[0..3]    #=> ["k_method", "nil?", "is_a?", "class"]
  #   k.methods.length   #=> 42
  # 
  def methods
    `var result=[]`
    `for(var x in this){if(x.slice(0,2)=='m$'&&x!='m$initialize'){$q($_uncamel(x.slice(2,x.length)));};}`
    return `result`
  end
  
  # call-seq:
  #   nil.nil? -> true
  #   obj.nil? -> false
  # 
  # Only the object _nil_ responds +true+ to <tt>nil?</tt>.
  # 
  def nil?
    false
  end
  
  # call-seq:
  #   obj.__id__    -> integer
  #   obj.object_id -> integer
  # 
  # Returns an integer identifier for _obj_. The same number will be returned
  # on all calls to +object_id+ for a given object, and no two active objects
  # will share an id.
  # 
  def object_id
    `this.__id__`
  end
  
  # call-seq:
  #   obj.remove_instance_variable(sym) -> obj
  # 
  # Removes the named instance variable from _obj_, returning that variable's
  # value.
  # 
  #   class Klass
  #     attr_reader :var
  #     def initialize
  #       @var = 99
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.var                               #=> 99
  #   k.remove_instance_variable(:@var)   #=> 99
  #   k.var                               #=> nil
  # 
  # FIX: Incomplete
  def remove_instance_variable(sym)
  end
  
  # call-seq:
  #   obj.respond_to?(sym) -> true or false
  # 
  # Returns +true+ if _obj_ responds to the given method.
  # 
  def respond_to?(method)
    `typeof(this['m$'+method._value])=='function'`
  end
  
  # call-seq:
  #   obj.__send__(sym [, args...]) -> obj
  #   obj.send(sym [, args...])     -> obj
  # 
  # Invokes the method identified by _sym_, passing it any arguments
  # specified. Use <tt>__send__</tt> if the name +send+ clashes with an
  # existing method in _obj_.
  # 
  #   class Klass
  #     def hello(*args)
  #       "Hello " + args.join(' ')
  #     end
  #   end
  #   
  #   k = Klass.new
  #   k.send(:hello, "gentle", "readers")  #=> "Hello gentle readers"
  # 
  def send(method,*args)
    `this['m$'+method._value.replace('=','Eql')].apply(this,args)`
  end
  
  # FIX: Incomplete
  def singleton_method_added
  end
  
  # FIX: Incomplete
  def singleton_method_removed
  end
  
  # FIX: Incomplete
  def singleton_method_undefined
  end
  
  # FIX: Incomplete
  def singleton_methods
  end
  
  # FIX: Incomplete
  def to_enum
  end
  
  # call-seq:
  #   obj.to_s -> string
  # 
  # Returns a string representing _obj_. The default +to_s+ prints _obj_'s
  # class and a version of _obj_'s +object_id+ spoofed to resemble Ruby's
  # 6-digit hex memory representation.
  # 
  def to_s
    `$q('#<'+this.m$class().__name__.replace(/\\./g,'::')+':0x'+(this.__id__*999^4000000).toString(16)+'>')`
  end
end

# A +Module+ is a collection of methods and constants. The methods in a module
# may be instance methods or module methods. Instance methods appear as
# methods in a class when the module is included, module methods do not.
# Conversely, module methods may be called without creating an encapsulating
# object, while instance methods may not. (See
# <tt>Module#module_function</tt>)
# 
# In the descriptions that follow, the parameter _sym_ refers to a symbol,
# which is either a quoted string or a +Symbol+ (such as <tt>:name</tt>).
# 
#   module Mod
#     include Math
#     CONST = 1
#     def my_method
#       # ...
#     end
#   end
#   
#   Mod.class              #=> Module
#   Mod.constants          #=> ["E", "PI", "CONST"]
#   Mod.instance_methods   #=> ["my_method"]
# 
class Module
  # call-seq:
  #    Module.new(module_name)                -> mod
  #    Module.new(module_name) {|mod| block } -> mod
  # 
  # Creates a new module. Unlike in Ruby, where you need only assign the
  # module object to a constant in order to give it a name, in Red you must
  # also pass the module name as a string argument. If a block is given, it is
  # passed the module object, and the block is evaluated in the context of
  # this module using <tt>module_eval</tt>.
  # 
  #   Greeter = Module.new do
  #     def say_hi
  #       "hello"
  #     end
  #     
  #     def say_bye
  #       "goodbye"
  #     end
  #   end
  #   
  #   a = "my string"
  #   a.extend(Greeter)  #=> "my string"
  #   a.say_hi           #=> "hello"
  #   a.say_bye          #=> "goodbye"
  # 
  def initialize(module_name, &block)
    `this.__name__=moduleName._value||moduleName`
    `this.prototype={}`
  end
  
  def <(other_module)
  end
  
  def <=(other_module)
  end
  
  def <=>(other_module)
  end
  
  def ===(object)
  end
  
  def >(other_module)
  end
  
  def >=(other_module)
  end
  
  def alias_method(new_name, old_name)
  end
  
  def ancestors
  end
  
  # call-seq:
  #   append_features(mod) -> mod
  # 
  # When another module includes this module, this module calls
  # <tt>append_features</tt> with the module that included this one as the
  # _mod_ parameter. If this module has not already been added to _mod_ or one
  # of its ancestors, this module adds its constants, methods, and module
  # variables to _mod_. See also <tt>Module#include</tt>.
  # 
  # FIX: Incomplete
  def append_features(mod)
    `Red.donateMethodsToSingleton(this,mod)`
    `Red.donateMethodsToClass(this.prototype,mod.prototype)`
    return `mod`
  end
  
  def attr(attribute, writer = false)
    `var a=attribute._value`
    `f1=this.prototype['m$'+a]=function(){return this['i$'+arguments.callee._name];};f1._name=a`
    `if(writer){f2=this.prototype['m$'+a._value+'Eql']=function(x){return this['i$'+arguments.callee._name]=x;};f2._name=a;}`
    return nil
  end
  
  def attr_accessor(*symbols)
    `for(var i=0,l=symbols.length;i<l;++i){
      var a=symbols[i]._value;
      f1=this.prototype['m$'+a]=function(){return this['i$'+arguments.callee._name];};f1._name=a;
      f2=this.prototype['m$'+a+'Eql']=function(x){return this['i$'+arguments.callee._name]=x;};f2._name=a;
    }`
    return nil
  end
  
  def attr_reader(*symbols)
    `for(var i=0,l=symbols.length;i<l;++i){
      var a=symbols[i]._value;
      f=this.prototype['m$'+a]=function(){return this['i$'+arguments.callee._name];};f._name=a;
    }`
    return nil
  end
  
  def attr_writer(*symbols)
    `for(var i=0,l=symbols.length;i<l;++i){
      var a=symbols[i]._value;
      f=this.prototype['m$'+a+'Eql']=function(x){return this['i$'+arguments.callee._name]=x;};f._name=a;
    }`
    return nil
  end
  
  def class_eval(&block)
  end
  
  def class_variable_defined?
  end
  
  def class_variable_get
  end
  
  def class_variable_set
  end
  
  def class_variables
  end
  
  def const_defined?
  end
  
  def const_get(sym)
  end
  
  def const_set(sym, object)
  end
  
  def constants
  end
  
  def define_method(sym, &block)
  end
  
  # call-seq:
  #   extend_object(obj) -> obj
  # 
  # Extends the specified object by adding this module's constants and methods
  # (which are added as singleton methods). This is the callback method used
  # by <tt>Object#extend</tt>.
  # 
  #   module Picky
  #     def Picky.extend_object(obj)
  #       unless obj.is_a?(String)
  #         puts "Picky methods added to #{o.class}"
  #         super
  #       else
  #         puts "Picky won't give its methods to a String"
  #       end
  #     end
  #   end
  #   
  #   [1,2,3].extend(Picky)
  #   "1,2,3".extend(Picky)
  # 
  # produces:
  # 
  #   Picky methods added to Array
  #   Picky won't give its methods to a String
  # 
  def extend_object(obj)
    `var tp=this.prototype`
    `for(var x in tp){
      if(x.slice(0,2)=='m$'){
        var f=function(){var m=arguments.callee;return m.__methodSource__[m.__methodName__].apply(m.__methodReceiver__,arguments) };
        f.__methodName__=x;f.__methodSource__=tp;f.__methodReceiver__=obj;
        obj[x]=f;
      };
    }`
    return `obj`
  end
  
  # call-seq:
  #   extended(extended_obj)
  # 
  # Callback invoked whenever the receiver is used to extend an object's
  # singleton class. Default callback is empty; override the method definition
  # in your modules to activate.
  # 
  #   module Mod
  #     def self.extended(obj)
  #       puts "#{obj} was extended with #{self}"
  #     end
  #   end
  #   
  #   class Thing
  #     def to_s
  #       "My object"
  #     end
  #   end
  #   
  #   Thing.new.extend(Mod)
  # 
  # produces:
  # 
  #   My object was extended with Mod
  # 
  def extended(object)
  end
  
  def hash # :nodoc:
    `'c_'+#{self.to_s}`
  end
  
  # call-seq:
  #   mod.include(module, ...) -> mod
  # 
  # Invokes <tt>append_features</tt> and the callback <tt>included</tt> on
  # each given module in turn, passing _mod_ as the argument.
  # 
  #   module Mod
  #     def hello
  #       "Hello from Mod"
  #     end
  #   end
  #   
  #   class Klass
  #     include Mod
  #   end
  #   
  #   k = Klass.new
  #   k.hello         #=> "Hello from Mod"
  # 
  def include(*modules)
    `for(var i=0,l=modules.length;i<l;++i){var mod=modules[i];mod.m$appendFeatures(this);mod.m$included(this);mod.__includers__[this.__name__]=true;}`
    return self
  end
  
  def include?(other_module)
  end
  
  # call-seq:
  #   included(including_module)
  # 
  # Callback invoked whenever the receiver is included in another module or
  # class. Default callback is empty; override the method definition in
  # your modules to activate.
  # 
  #   module Mod
  #     def self.included(base)
  #       puts "#{self} included in #{base}"
  #     end
  #   end
  #   
  #   module Enumerable
  #     include Mod
  #   end
  # 
  # produces:
  # 
  #   Mod included in Enumerable
  # 
  def included(other_module)
  end
  
  def included_modules
  end
  
  def instance_method
  end
  
  def instance_methods
  end
  
  def method_defined?
  end
  
  def module_eval(&block)
  end
  
  def name
    `$q(this.__name__.replace(/\\./g,'::'))`
  end
  
  def remove_class_variable(sym)
  end
  
  def remove_const(sym)
  end
  
  def remove_method(sym)
  end
  
  # Return a string representing this module or class.
  def to_s
    `$q(this.__name__.replace(/\\./g,'::'))`
  end
end

# As in Ruby, classes in Red are first-class objects -- each is an instance of
# class +Class+.
# 
# When a new class is created (typically using <tt>class Name ... end</tt>),
# an object of type +Class+ is created and assigned to a global constant
# (+Name+ in this case). When <tt>Name.new</tt> is called to create a new
# object, the +new+ method in +Class+ is run by default. This can be
# demonstrated by overriding +new+ in +Class+:
# 
#   class Class
#     alias saved_new new
#     def new(*args)
#       puts "Creating a new #{self.name}"
#       saved_new(*args)
#     end
#   end
#   
#   class Name
#   end
#   
#   n = Name.new
# 
# produces:
# 
#   Creating a new Name
# 
class Class < Module
  # call-seq:
  #   Class.new(class_name, superclass = Object) -> class
  # 
  # Creates a new class with the given __superclass___ (or +Object+ if no
  # superclass is given). Unlike in Ruby, where you need only assign the
  # class object to a constant in order to give it a name, in Red you must
  # also pass the class name as a string argument.
  # 
  # FIX: Incomplete
  def self.new(class_name, superclass = Object)
    `Red._class(className._value,superclass,function(){})`
    return `window['c$'+className._value]`
  end
  
  # call-seq:
  #   klass.allocate -> object
  # 
  # Returns a new object that is an instance of _klass_. This method is used
  # internally by a +Class+ object's +new+ method and should not be called
  # directly.
  # 
  def allocate
    `new(this)()`
  end
  
  # call-seq:
  #   inherited(subclass)
  # 
  # Callback invoked whenever a subclass of the current class is created.
  # 
  #   class Foo
  #     def self.inherited(subclass)
  #       puts "New subclass: #{subclass}"
  #     end
  #   end
  #   
  #   class Bar < Foo
  #   end
  #   
  #   class Baz < Bar
  #   end
  # 
  # produces:
  # 
  #   New subclass: Bar
  #   New subclass: Baz
  # 
  def inherited(subclass)
  end
  
  # call-seq:
  #   klass.new(args, ...) -> object
  # 
  # Calls +allocate+ to create a new object of class _klass_, then invokes
  # that object's +initialize+ method, passing it _args_.
  # 
  #   class Foo
  #     def initialize(a,b)
  #       @a = a
  #       @b = b
  #     end
  #     
  #     def values
  #       "a,b: [%s,%s]" % [@a, @b]
  #     end
  #   end
  #   
  #   foo = Foo.new(1,2)    #=> #<Foo:0x3cc57a>
  #   foo.values            #=> "a,b: [1,2]"
  # 
  def new
    `var result=this.m$allocate()`
    `this.prototype.m$initialize.apply(result,arguments)`
    return `result`
  end
  
  # call-seq:
  #   klass.superclass -> class or nil
  # 
  # Returns the superclass of _klass_, or +nil+.
  # 
  #   Class.superclass    #=> Module
  #   Module.superclass   #=> Object
  #   Object.superclass   #=> nil
  # 
  def superclass
    `this.__superclass__`
  end
end

`
Red.initializeClass('Object',c$Object);c$Object.__children__={'Module':true};
Red.initializeClass('Module',c$Module);c$Module.__children__={'Class':true};
Red.initializeClass('Class',c$Class)
`

# The +Comparable+ mixin is used by classes whose objects may be ordered. The
# class must define the <tt><=></tt> operator, which compares the receiver
# against another object, returning -1, 0, or +1 depending on whether the
# receiver is less than, equal to, or greater than the other object.
# +Comparable+ uses <tt><=></tt> to implement the conventional comparison
# operators (<tt><</tt>, <tt><=</tt>, <tt>==</tt>, <tt>>=</tt>, and
# <tt>></tt>) and the method <tt>between?</tt>.
# 
#   class SizeMatters
#     include Comparable
#     attr :str
#     
#     def <=>(other)
#       str.size <=> other.str.size
#     end
#     
#     def initialize(str)
#       @str = str
#     end
#     
#     def inspect
#       @str
#     end
#   end
#   
#   s1 = SizeMatters.new("Z")
#   s2 = SizeMatters.new("YY")
#   s3 = SizeMatters.new("XXX")
#   s4 = SizeMatters.new("WWWW")
#   
#   s1 < s2                 #=> true
#   s4.between?(s1, s3)     #=> false
#   s3.between?(s2, s4)     #=> true
#   [s3, s2, s4, s1].sort   #=> [Z, YY, XXX, WWWW]
# 
module Comparable
  # call-seq:
  #   obj < other -> true or false
  # 
  # Compares two objects based on the receiver's <tt><=></tt> method,
  # returning +true+ if the comparison returns -1.
  # 
  def <(obj)
    `this.m$_ltgt(obj)==-1`
  end
  
  # call-seq:
  #   obj <= other -> true or false
  # 
  # Compares two objects based on the receiver's <tt><=></tt> method,
  # returning +true+ if the comparison returns -1 or 0.
  # 
  def <=(obj)
    `var result=this.m$_ltgt(obj)`
    `result==0||result==-1`
  end
  
  # call-seq:
  #   obj == other -> true or false
  # 
  # Compares two objects based on the receiver's <tt><=></tt> method,
  # returning +true+ if the comparison returns 0. Also returns +true+ if _obj_
  # and _other_ are the same object.
  # 
  def ==(obj)
    `(this.__id__&&obj.__id__&&this.__id__==obj.__id__)||this.m$_ltgt(obj)==0`
  end
  
  # call-seq:
  #   obj > other -> true or false
  # 
  # Compares two objects based on the receiver's <tt><=></tt> method,
  # returning +true+ if the comparison returns 1.
  # 
  def >(obj)
    `this.m$_ltgt(obj)==1`
  end
  
  # call-seq:
  #   obj >= other -> true or false
  # 
  # Compares two objects based on the receiver's <tt><=></tt> method,
  # returning +true+ if it returns 1 or 0.
  def >=(obj)
    `var result=this.m$_ltgt(obj)`
    `result==0||result==1`
  end
  
  # call-seq:
  #   obj.between?(min,max) -> true or false
  # 
  # Returns +false+ if <tt>obj <=> min</tt> is less than zero or if
  # <tt>obj <=> max</tt> is greater than zero, +true+ otherwise.
  # 
  #   3.between?(1, 5)               #=> true
  #   6.between?(1, 5)               #=> false
  #   'cat'.between?('ant', 'dog')   #=> true
  #   'gnu'.between?('ant', 'dog')   #=> false
  # 
  def between?(min, max)
    `if(this.m$_ltgt(min)==-1){return false;}`
    `if(this.m$_ltgt(max)==1){return false;}`
    return true
  end
end

# Enumerable
# 
module Enumerable
  # call-seq:
  #   enum.all? [{ |obj| block }] -> true or false
  # 
  # Passes each element of the collection to the given block. The method
  # returns +true+ if the block never returns +false+ or +nil+. If the block
  # is not given, Red adds an implicit block of <tt>{|obj| obj }</tt> (that
  # is, <tt>all?</tt> will return +true+ only if none of the collection
  # members are +false+ or +nil+.)
  # 
  #    %w(ant bear cat).all? {|word| word.length >= 3}    #=> true
  #    %w(ant bear cat).all? {|word| word.length >= 4}    #=> false
  #    [nil, true, 99].all?                               #=> false
  # 
  def all?(block = `function(obj){return $T(obj);}`)
  end
end

# The +Kernel+ module contains methods that are mixed in to the +window+
# object and are available in any context.
# 
module Kernel
  # FIX: Incomplete
  def block_given?
    `typeof(arguments[0])=='function'`
  end
  
  # FIX: Incomplete
  def fail
  end
  
  def format(string)
    `m$sprintf(string)`
  end
  
  # FIX: Incomplete
  def global_variables
  end
  
  # call-seq:
  #  proc { |...| block }   -> a_proc
  #  lambda { |...| block } -> a_proc
  # 
  # Equivalent to Proc.new ...
  # 
  # FIX: Incomplete
  def lambda(func)
    `result=new(c$Proc)()`
    `result._block=func`
    return `result`
  end
  
  # FIX: Incomplete
  def local_variables
  end
  
  # call-seq:
  #   loop { || block }
  # 
  # Repeatedly executes the block.
  # 
  def loop(&block)
    `var result=nil`
    `while(true){#{yield};}`
    return `result`
  end
  
  # FIX: Incomplete
  def p
  end
  
  # FIX: Incomplete
  def print
  end
  
  # FIX: Incomplete
  def printf
  end
  
  # call-seq:
  #  proc { |...| block }   -> a_proc
  #  lambda { |...| block } -> a_proc
  # 
  # Equivalent to Proc.new ...
  # 
  # FIX: Incomplete
  def proc(func)
    `result=new(c$Proc)()`
    `result._block=func`
    return `result`
  end
  
  # call-seq:
  #   putc(int) -> int
  # 
  # FIX: Incomplete
  def putc(int)
  end
  
  # call-seq:
  #   puts(obj, ...) -> nil
  # 
  # FIX: Incomplete
  def puts(obj)
    `var string=obj.m$toS&&obj.m$toS()||$q(''+obj)`
    `console.log(string._value.replace(/\\\\/g,'\\\\\\\\'))`
    return nil
  end
  
  # FIX: Incomplete
  def raise
    `var exception_class=c$RuntimeError,msg=$q('')`
    `if(arguments[0]&&arguments[0].m$isABool(c$Exception)){
      var e=arguments[0];
    }else{
      if(arguments[0]&&arguments[0].m$class()==c$String){
        msg=arguments[0];
      }else{
        if(arguments[0]!=null){
          exception_class=arguments[0],msg=arguments[1]||msg;
        };
      }
    }`
    `var e=e||exception_class.m$new(msg)`
    `e._stack=new Error().stack`
    `throw(e)`
    return nil
  end
  
  # call-seq:
  #   rand(num = 0) -> numeric
  # 
  # Converts _num_ to the integer _max_ equivalent to <tt>num.to_i.abs</tt>.
  # If _max_ is zero, returns a pseudo-random floating point number greater
  # than or equal to 0 and less than 1. Otherwise, returns a pseudo-random
  # integer greater than or equal to zero and less than _max_.
  # 
  #   rand        #=> 0.7137224264409899
  #   rand(10)    #=> 2
  #   rand(100)   #=> 79
  # 
  def rand(num = 0)
    `var max=Math.abs(parseInt(num))`
    `max==0?Math.random():parseInt(Math.random()*max)`
  end
  
  # call-seq:
  #   sleep([duration]) -> integer
  # 
  # Suspends activity for _duration_ seconds (which may be fractional), then
  # returns the number of seconds slept (rounded). Zero arguments causes
  # <tt>sleep</tt> to sleep forever.
  # 
  #   Time.new    #=> Wed Apr 09 08:56:32 CDT 2003
  #   sleep 1.2   #=> 1
  #   Time.new    #=> Wed Apr 09 08:56:33 CDT 2003
  #   sleep 1.9   #=> 2
  #   Time.new    #=> Wed Apr 09 08:56:35 CDT 2003
  # 
  def sleep(duration)
    `if(duration==null){while(true){};}else{var awaken=new(Date)().valueOf()+(1000*duration);while(new(Date)().valueOf()<awaken){};}`
    return `Math.round(duration)`
  end
  
  # FIX: Incomplete
  def sprintf(string)
    `var i=1,source=string._value,result=[],m=$u,arg=$u,val=$u,str=$u,dL=$u,chr=$u,pad=$u;
    while(source){
      if(m=source.match(/^[^%]+/)){result.push(m[0]);source=source.slice(m[0].length);continue;};
      if(m=source.match(/^%%/))   {result.push('%'); source=source.slice(m[0].length);continue;};
      //                  1(0)2(wdth)      3(prec) 4(field-type      )
      if(m=source.match(/^%(0)?(\\d+)?(?:\\.(\\d+))?([bcdEefGgiopsuXx])/)){
        arg = arguments[i]._value||arguments[i];
        switch(m[4]){
          case'b':str=parseFloat(arg).toString(2);break;
          case'c':str=String.fromCharCode(arg);break;
          case'd':val=parseInt(arg);str=''+val;break;
          case'E':val=parseFloat(arg);str=''+(m[3]?val.toExponential(m[3]):val.toExponential()).toUpperCase();break;
          case'e':val=parseFloat(arg);str=''+(m[3]?val.toExponential(m[3]):val.toExponential());break;
          case'f':val=parseFloat(arg);str=''+(m[3]?val.toFixed(m[3]):val);break;
          case'G':str='-FIX-';break;
          case'g':str='-FIX-';break;
          case'i':val=parseInt(arg);str=''+val;break;
          case'o':str=parseFloat(arg).toString(8);break;
          case'p':str=$q(arg).m$inspect()._value;break;
          case's':val=arg.m$toS&&arg.m$toS()._value||arg;str=(m[3]?val.slice(0,m[2]):val);break;
          case'u':val=parseInt(arg);str=''+(val<0?'..'+(Math.pow(2,32)+val):val);break;
          case'X':str=parseInt(arg).toString(16).toUpperCase();break;
          case'x':str=parseInt(arg).toString(16);break;
        };
        if((dL=m[2]-str.length)!=0){for(chr=m[1]||' ',pad=[];dL>0;pad[--dL]=chr);}else{pad=[]};
        result.push(pad.join('')+str);
        source=source.slice(m[0].length);
        i+=1;
        continue;
      };
      throw('ArgumentError: malformed format string')
    }`
    return `$q(result.join(''))`
  end
  
  # FIX: Incomplete
  def srand
  end
  
  def x #:nodoc:
  #function m$sprintf(){
  #  var i=0,arg,f=arguments[i++],ary=[],m,p,c,x;
  #  while (f) {
  #    if(m=f.match(/^[^%]+/)){
  #      ary.push(m[0]);
  #    }else{ // ['mtch',[1]:'digit-final?',[2]:'plus?',[3]:'0 or \' plus non-$ ?',[4]:'minus?',[5]:'digit?',[6]:'. plus digit?',[7]:'flag']
  #      if(m = f.match(/^%%/)){ary.push('%');}else{
  #        if(m=f.match(/^%(?:(\\d+)\\$)?(\\+)?(0|'[^$])?(-)?(\\d+)?(?:\\.(\\d+))?([bcdEefGgiopsuXx])/)){
  #          if(((arg = arguments[m[1] || i++])==null)||(arg==undefined)){throw('ArgumentError: too few arguments.');};
  #          if(/[^sp]/.test(m[7])&&!(typeof(arg)=='number')){throw('TypeError: can\\'t convert '+''+' into Integer');};
  #          switch (m[7]) {
  #            case'b':str=arg.toString(2);break;
  #            case'c':str=String.fromCharCode(arg);break;
  #            case'd':str=parseInt(arg);break;
  #            case'E':str=(m[6]?arg.toExponential(m[6]):arg.toExponential()).toUpperCase();break;
  #            case'e':str=m[6]?arg.toExponential(m[6]):arg.toExponential();break;
  #            case'f':str=m[6] ? parseFloat(arg).toFixed(m[6]) : parseFloat(arg); break; // Needs work
  #            case'G':str='';break;
  #            case'g':str='';break;
  #            case'i':str=parseInt(arg);break;
  #            case'o':str=arg.toString(8);break;
  #            case'p':str=$q(arg).m$inspect();break;
  #            case's':str=((arg = String(arg)) && m[6] ? arg.substring(0, m[6]) : arg); break; // Does this work?
  #            case'u':str=arg<0?'..'+(Math.pow(2,32)+arg):arg;break;
  #            case'X':str=arg.toString(16).toUpperCase();break;
  #            case'x':str=arg.toString(16);break;
  #          };
  #          a = (/[def]/.test(m[7]) && m[2] && str > 0 ? '+' + str : str);
  #          c = m[3] ? m[3] == '0' ? '0' : m[3].charAt(1) : ' ';
  #          x = m[5] - String(a).length;
  #          if(m[5]){for(var c2=c,x2=x,ary2=[];x2>0;ary2[--x2]=c2);p=ary2.join('');}else{p='';};
  #          ary.push(m[4]?str+p:p+str);
  #        }else{throw('ArgumentError: malformed format string');};
  #      };
  #    };
  #    f = f.substring(m[0].length);
  #  }
  #  return ary.join('');
  #}
  end
end

include Kernel

# The +Math+ module contains module functions for basic trigonometric and
# transcendental functions.
# 
module Math
  E  = 2.71828182845904523536
  PI = 3.14159265358979323846
  
  # call-seq:
  #   Math.acos(x) -> numeric
  # 
  # Computes the arc cosine of _x_ and returns its value in the range 0..PI.
  # 
  def self.acos(x)
    `Math.acos(x)`
  end
  
  # call-seq:
  #   Math.acosh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.acosh(x)
  end
  
  # call-seq:
  #   Math.asin(x) -> numeric
  # 
  # Computes the arc sine of _x_ and returns its value in the range
  # -PI/2..PI/2.
  # 
  def self.asin(x)
    `Math.asin(x)`
  end
  
  # call-seq:
  #   Math.asinh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.asinh(x)
  end
  
  # call-seq:
  #   Math.atan(x) -> numeric
  # 
  # Computes the arc tangent of _x_ and returns its value in the range
  # -PI/2..PI/2.
  # 
  def self.atan(x)
    `Math.atan(x)`
  end
  
  # call-seq:
  #   Math.atan2(y,x) -> numeric
  # 
  # Computes the arc tangent of <i>+y/+x</i> and returns its value in the
  # range -PI..PI. The signs of _x_ and _y_ determine the quadrant of the
  # result.
  # 
  def self.atan2(y,x)
    `Math.atan2(y,x)`
  end
  
  # call-seq:
  #   Math.atanh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.atanh(x)
  end
  
  # call-seq:
  #   Math.cos(x) -> numeric
  # 
  # Computes the cosine of _x_ (in radians) and returns its value in the range
  # -1..1.
  # 
  def self.cos(x)
    `Math.cos(x)`
  end
  
  # call-seq:
  #   Math.cosh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.cosh(x)
  end
  
  # call-seq:
  #   Math.erf(x) -> numeric
  # 
  # FIX: Incomplete
  def self.erf(x)
  end
  
  # call-seq:
  #   Math.erfc(x) -> numeric
  # 
  # FIX: Incomplete
  def self.erfc(x)
  end
  
  # call-seq:
  #   Math.exp(x) -> numeric
  # 
  # Returns e**(x).
  # 
  def self.exp(x)
    `Math.exp(x)`
  end
  
  # call-seq:
  #   Math.frexp(x) -> [fraction, exponent]
  # 
  # FIX: Incomplete
  def self.frexp(numeric)
  end
  
  # call-seq:
  #   Math.hypot(x,y) -> numeric
  # 
  # FIX: Incomplete
  def self.hypot(x,y)
  end
  
  # call-seq:
  #   Math.ldexp(flt,int) -> numeric
  # 
  # FIX: Incomplete
  def self.ldexp(flt,int)
  end
  
  # call-seq:
  #   Math.log(x) -> numeric
  # 
  # Returns the natural logarithm of _x_.
  # 
  def self.log(x)
    `if(x==0){return -Infinity;}`
    `Math.log(x)`
  end
  
  # call-seq:
  #   Math.log10(x) -> numeric
  # 
  # Returns the base 10 logarithm of _x_.
  # 
  def self.log10(x)
    `if(x==0){return -Infinity;}`
    `Math.log(x)/Math.log(10)`
  end
  
  # call-seq:
  #   Math.sin(x) -> numeric
  # 
  # Computes the sine of _x_ (in radians) and returns its value in the range
  # -1..1.
  # 
  def self.sin(x)
    `Math.sin(x)`
  end
  
  # call-seq:
  #   Math.sinh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.sinh(x)
  end
  
  # call-seq:
  #   Math.sqrt(x) -> numeric
  # 
  # Returns the non-negative square root of _x_.
  # 
  def self.sqrt(x)
    `Math.sqrt(x)`
  end
  
  # call-seq:
  #   Math.tan(x) -> numeric
  # 
  # Computes the tangent of _x_ (in radians) and returns its value.
  # 
  def self.tan(x)
    `Math.tan(x)`
  end
  
  # call-seq:
  #   Math.tanh(x) -> numeric
  # 
  # FIX: Incomplete
  def self.tanh(x)
  end
end

# Arrays are ordered, integer-indexed collections of any object. Array
# indexing starts at 0. A negative index is assumed to be relative to the end
# of the array -- that is, an index of -1 indicates the last element of the
# array, -2 is the next to last element in the array, and so on.
# 
class Array
  # call-seq:
  #   ary & other -> array
  # 
  # Set Intersection -- returns a new array containing elements common to
  # _ary_ and _other_, with no duplicates.
  # 
  #   [1,1,3,5] & [1,2,3]   #=> [1, 3]
  # 
  def &(ary)
    `for(var i=0,l=this.length,result=[],found=false,seen={};i<l;++i){var a=this[i],k=a.m$hash();for(var j=0,m=ary.length;j<m;++j){var b=this[j];if(a.m$_eql2(b)){found=true;break;};};if(found&&!seen[k]){seen[k]=true;result.push(a);found=false;};}`
    return `result`
  end
  
  # call-seq:
  #   ary | other -> array
  # 
  # Set Union -- returns a new array by joining _ary_ with _other_, removing
  # duplicates.
  # 
  #   [1,2,3] | [3,4,1]   #=> [1, 2, 3, 4]
  # 
  def |(ary)
    `for(var i=0,l=this.length,result=[],seen={};i<l;++i){var a=this[i],k=a.m$hash();if(!seen[k]){seen[k]=true;result.push(a);};}`
    `for(var i=0,l=ary.length;i<l;++i){var a=ary[i],k=a.m$hash();if(!seen[k]){seen[k]=true;result.push(a);};}`
    return `result`
  end
  
  # call-seq:
  #   ary * num -> array
  #   ary * str -> string
  # 
  # Repetition -- with a +String+ argument, equivalent to
  # <tt>self.join(str)</tt>. Otherwise, returns a new array built by
  # concatenating _num_ copies of self.
  # 
  #   [1,2,3] * ':'   #=> "1:2:3"
  #   [1,2,3] * 3     #=> [1, 2, 3, 1, 2, 3, 1, 2, 3]
  # 
  def *(arg)
    `if(arg.m$class()==c$String){return this.join(arg);}`
    `var result=[],i=0,l=parseInt(arg)`
    `while(i<l){result=result.concat(this);i++;}`
    return `result`
  end
  
  # call-seq:
  #   ary + other -> array
  # 
  # Concatenation -- returns a new array built by concatenating _ary_ and
  # _other_.
  # 
  #   [1,2,3] + [4,5]   #=> [1, 2, 3, 4, 5]
  # 
  def +(ary)
    `this.concat(ary)`
  end
  
  # call-seq:
  #   ary - other -> array
  # 
  # Difference -- returns a new array containing only items that appear in
  # _ary_ and not in _other_.
  # 
  #   [1,1,2,2,3,3,4,5] - [1,2,4]   #=> [3, 3, 5]
  # 
  def -(ary)
    `for(var i=0,l=ary.length,result=[],seen=[];i<l;++i){var a=ary[i],k=a.m$hash();if(!seen[k]){seen[k]=true;};};`
    `for(var i=0,l=this.length;i<l;++i){var a=this[i],k=a.m$hash();if(!seen[k]){result.push(a);};}`
    return `result`
  end
  
  # call-seq:
  #   ary << obj -> ary
  # 
  # Append -- pushes the given object onto the end of _ary_. This expression
  # returns _ary_ itself, so several appends may be chained together.
  # 
  #   [1,2] << 'c' << 'd' << [3,4]    #=> [1, 2, "c", "d", [3, 4]]
  # 
  def <<(object)
    `this[this.length]=object`
    return self
  end
  
  # call-seq:
  #   ary <=> other -> -1, 0, 1
  # 
  # Comparison -- returns -1, 0, or 1 depending on whether _ary_ is less than,
  # equal to, or greater than _other_. Each object in both arrays is compared
  # using <tt><=></tt>; if any comparison fails to return 0,
  # <tt>Array#<=></tt> returns the result of that comparison. If all the
  # values found are equal, returns the result of comparing the lengths of
  # _ary_ and _other_. Thus, <tt>ary <=> other</tt> returns 0 if and only if
  # both arrays are the same length and the value of each element is equal to
  # the value of the corresponding element in the other array.
  # 
  #   %w(a a c)     <=> %w(a b c)   #=> -1
  #   [1,2,3,4,5,6] <=> [1,2]       #=> 1
  # 
  def <=>(ary)
    `for(var i=0,l=this.length;i<l;++i){if(ary[i]==null){break;};var x=this[i].m$_ltgt(ary[i]);if(x!==0){return x;};}`
    return `this.length.m$_ltgt(ary.length)`
  end
  
  # call-seq:
  #   ary == other -> true or false
  # 
  # Equality -- returns +true+ if _ary_ and _other_ contain the same number of
  # elements and if for every index <tt>i</tt> in _ary_, <tt>ary[i] ==
  # other[i]</tt>.
  # 
  #   ['a','c']    == ['a', 'c', 7]     #=> false
  #   ['a','c', 7] == ['a', 'c', 7]     #=> true
  #   ['a','c', 7] == ['a', 'd', 'f']   #=> false
  # 
  def ==(ary)
    `if(ary.m$class()!==c$Array||ary.length!==this.length){return false;}`
    `for(var i=0,l=this.length;i<l;++i){if(!(this[i].m$_eql2(ary[i]))){return false;};}`
    return true
  end
  
  # call-seq:
  #   ary[index]               -> object or nil
  #   ary[start, length]       -> array or nil
  #   ary[range]               -> array or nil
  #   ary.slice(index)         -> object or nil
  #   ary.slice(start, length) -> array or nil
  #   ary.slice(range)         -> array or nil
  # 
  # Element Reference -- returns the element at _index_, or an array of the
  # elements in _range_ or from _start_ to _start_ plus _length_. Returns
  # +nil+ if the index is out of range.
  # 
  #   a = %w(a b c d e)
  #   
  #   a[2] + a[0] + a[1]    #=> "cab"
  #   a[6]                  #=> nil
  #   a[1,2]                #=> ["b", "c"]
  #   a[1..3]               #=> ["b", "c", "d"]
  #   a[4..7]               #=> ["e"]
  #   a[6..10]              #=> nil
  #   a[-3,3]               #=> ["c", "d", "e"]
  #   # special cases
  #   a[5]                  #=> nil
  #   a[5,1]                #=> []
  #   a[5..10]              #=> []
  # 
  def [](index, length)
    `var l=this.length`
    `if(index.m$class()==c$Range){
      var start=index._start,end=index._exclusive?index._end-1:index._end;
      index=start<0?start+l:start;
      length=(end<0?end+l:end)-index+1;
      if(length<0){length=0};
    }else{
      if(index<0){index+=l;};
    }`
    `if(index>=l||index<0){return nil;}`
    `if($T(length)){
      if(length<=0){return [];};
      result=this.slice(index,index+length);
    }else{
      result=this[index];
    }`
    return `result`
  end
  
  # call-seq:
  #   ary[index] = obj                         -> obj
  #   ary[start, length] = obj or array or nil -> obj or array or nil
  #   ary[range] = obj or array or nil         -> obj or array or nil
  # 
  # Element Assignment -- sets the element at _index, or replaces the elements
  # in _range_ or from _start_ to _start_ plus _length_, truncating or
  # expanding _ary_ as necessary. If +nil+ is used in the second and third
  # form, deletes elements. See also <tt>Array#push</tt>, and
  # <tt>Array#unshift</tt>.
  # 
  #   a = []
  #   
  #   a[4]     = '4'         #=> [nil, nil, nil, nil, "4"]
  #   a[0,3]   = %w(a b c)   #=> ["a", "b", "c", nil, "4"]
  #   a[1..2]  = [1,2]       #=> ["a", 1, 2, nil, "4"]
  #   a[0,2]   = '?'         #=> ["?", 2, nil, "4"]
  #   a[0..2]  = 'A'         #=> ["A", "4"]
  #   a[-1]    = 'Z'         #=> ["A", "Z"]
  #   a[1..-1] = nil         #=> ["A"]
  # 
  def []=(index, length, object)
    `var l=this.length`
    `if(object==null){object=length;length=$u;}`
    `if(index.m$class()==c$Range){var start=index._start,end=index._exclusive?index._end-1:index._end;index=start<0?start+l:start;length=(end<0?end+l:end)-index+1;if(length<0){length=0};}else{if(index<0){index+=l;};if(length<0){throw('IndexError: negative length')}}`
    `if(index<0){throw('RangeError: out of range');}`
    `while(this.length<index){this.push(nil);}`
    `if($T(length)){var l=this.length,final=(index+length>l)?l:index+length;this._replace(this.slice(0,index).concat(object===nil?[]:(object.m$class()==c$Array?object:[object])).concat(this.slice(final,l)))}else{this[index]=object}`
    return `object`
  end
  
  # call-seq:
  #   ary.assoc(obj) -> array or nil
  # 
  # Searches through _ary_, comparing _obj_ with the first element of each
  # _ary_ element that is also an array. Returns the first array such that
  # <tt>array[0] == obj</tt>, or +nil+ if no match is found. See also
  # <tt>Array#rassoc</tt>.
  # 
  #   a  = [%w(colors red blue green), %w(letters a b c), 'foo']
  #   
  #   a.assoc('letters')    #=> ["letters", "a", "b", "c"]
  #   a.assoc('foo')        #=> nil
  # 
  def assoc(obj)
    `for(var i=0,l=this.length;i<l;++i){var x=this[i];if(x.m$class()==c$Array&&x[0]!=null&&x[0].m$_eql2(obj)){return x;}}`
    return nil
  end
  
  # call-seq:
  #   ary.at(index) -> object or nil
  # 
  # Returns the element at _index_. A negative _index_ counts from the end of
  # _ary_. Returns +nil+ if _index_ is out of range. See also
  # <tt>Array#[].</tt> (<tt>Array#at</tt> is slightly faster than
  # <tt>Array#[]</tt>, because it does not accept ranges and so on.)
  # 
  #   %w(a b c d e).at(0)     #=> "a"
  #   %w(a b c d e).at(-1)    #=> "e"
  # 
  def at(index)
    `if(index<0){index+=this.length;}`
    `if(index<0||index>=this.length){return nil;}`
    return `this[index]`
  end
  
  # call-seq:
  #   ary.clear -> ary
  # 
  # Removes all elements from _ary_.
  # 
  #   a = %w(a b c d e)
  #   
  #   a.clear     #=> []
  #   a           #=> []
  # 
  def clear
    `this.length=0`
    return self
  end
  
  # call-seq:
  #   ary.collect { |element| block } -> array
  #   ary.map     { |element| block } -> array
  # 
  # Calls _block_ once for each element in _ary_, then returns a new array
  # containing the values returned by the block. See also
  # <tt>Enumerable#collect</tt>.
  # 
  #   a = [1,2,3,4]
  #   
  #   a.collect {|x| x + 100 }    #=> [101, 102, 103, 104]
  #   a                           #=> [1, 2, 3, 4]
  # 
  def collect
    `for(var i=0,l=this.length,result=[];i<l;++i){try{result[i]=#{yield `this[i]`};}catch(e){switch(e.__keyword__){case 'next':result[i]=e._value;break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return `result`
  end
  
  # call-seq:
  #   ary.collect! { |element| block } -> ary
  #   ary.map!     { |element| block } -> ary
  # 
  # Calls _block_ once for each element in _ary_, replacing the element with
  # the value returned by the block, then returns _ary_. See also
  # <tt>Enumerable#collect</tt>.
  # 
  #   a = [1,2,3,4]
  #   
  #   a.collect! {|x| x + 100 }   #=> [101, 102, 103, 104]
  #   a.collect! {|x| x + 100 }   #=> [201, 202, 203, 204]
  # 
  def collect!
    `for(var i=0,l=this.length;i<l;++i){try{this[i]=#{yield `this[i]`};}catch(e){switch(e.__keyword__){case 'next':this[i]=e._value;break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   ary.compact -> array
  # 
  # Returns a copy of _ary_ with all +nil+ elements removed.
  # 
  #   ['a',nil,'b',nil,'c',nil].compact   #=> ["a", "b", "c"]
  # 
  def compact
    `for(var i=0,l=this.length,result=[];i<l;++i){if(!(this[i]===nil)){result.push(this[i]);};}`
    return `result`
  end
  
  # call-seq:
  #   ary.compact! -> ary or nil
  # 
  # Removes +nil+ elements and returns _ary_, or +nil+ if no changes were
  # made.
  # 
  #   a = ['a',nil,'b',nil,'c']
  #   
  #   a.compact!    #=> ["a", "b", "c"]
  #   a.compact!    #=> nil
  # 
  def compact!
    `for(var i=0,l=this.length,temp=[];i<l;++i){if(!(this[i]===nil)){temp.push(this[i]);};}`
    `this._replace(temp)`
    return `l===this.length?nil:this`
  end
  
  # call-seq:
  #   ary.concat(other) -> ary
  # 
  # Appends the elements in _other_ to _ary_ and returns _ary_.
  # 
  #   [1,2].concat([3,4]).concat([5,6])   #=> [1, 2, 3, 4, 5, 6]
  # 
  def concat(ary)
    `for(var i=0,l=ary.length;i<l;++i){this.push(ary[i]);}`
    return self
  end
  
  # call-seq:
  #   ary.delete(obj)           -> obj or nil
  #   ary.delete(obj) { block } -> obj or block.call
  # 
  # Deletes items from _ary_ that are equal to _obj_. If one or more objects
  # are deleted from _ary_, returns _obj_; otherwise returns +nil+ or the
  # result of the optional code block.
  # 
  #   a = %w(a b b b c)
  #   
  #   a.delete('b')               #=> "b"
  #   a                           #=> ["a", "c"]
  #   a.delete('z')               #=> nil
  #   a.delete('z') { 'FAIL' }    #=> "FAIL"
  # 
  def delete(obj)
    `for(var i=0,l=this.length,temp=[];i<l;++i){if(!(this[i].m$_eql2(obj))){temp.push(this[i]);};}`
    `this._replace(temp)`
    return `l===this.length?(blockGivenBool?#{yield}:nil):obj`
  end
  
  # call-seq:
  #   ary.delete_at(index) -> object or nil
  # 
  # Deletes the element at the specified _index_, returning that element or
  # +nil+ if the index is out of range. See also <tt>Array#slice!</tt>.
  # 
  #   a = %w(a b c d)
  #   
  #   a.delete_at(2)    #=> "c"
  #   a                 #=> ["a", "b", "d"]
  #   a.delete_at(99)   #=> nil
  # 
  def delete_at(index)
    `var l=this.length`
    `if(index<0){index+=this.length;}`
    `if(index<0||index>=this.length){return nil;}`
    `var result=this[index],temp=[]`
    `for(var i=0;i<l;++i){if(i!==index){temp.push(this[i]);};}`
    `this._replace(temp)`
    return `result`
  end
  
  # call-seq:
  #   ary.delete_if { |element| block } -> ary
  # 
  # Deletes every element in _ary_ for which _block_ evaluates to +true+, then
  # returns _ary_.
  # 
  #   a = %w(a b c)
  #   
  #   a.delete_if {|element| element >= 'b' }   #=> ["a"]
  # 
  def delete_if
    `for(var temp=[],i=0,l=this.length;i<l;++i){try{if(!$T(#{yield `this[i]`})){temp.push(this[i]);};}catch(e){switch(e.__keyword__){case 'next':if(!$T(e._value)){temp.push(this[i]);};break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    `this._replace(temp)`
  end
  
  # call-seq:
  #   ary.each { |element| block } -> ary
  # 
  # Calls _block_ once for each element in _ary_, then returns _ary_.
  # 
  #   %(a b c).each {|element| puts element.upcase }    #=> ["a", "b", "c"]
  # 
  # produces:
  # 
  #   A
  #   B
  #   C
  # 
  def each
    `for(var i=0,l=this.length;i<l;++i){try{#{yield `this[i]`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   ary.each_index { |index| block } -> ary
  # 
  # Calls _block_ once for each index in _ary_, then returns _ary_.
  # 
  #   %(a b c).each {|index| puts index + 100 }   #=> ["a", "b", "c"]
  # 
  # produces:
  # 
  #   100
  #   101
  #   102
  # 
  def each_index
    `for(var i=0,l=this.length;i<l;++i){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   ary.empty? -> true or false
  # 
  # Returns +true+ if _ary_ contains no elements.
  # 
  #   [''].empty?   #=> false
  #   [].empty?     #=> true
  # 
  def empty?
    `this.length==0`
  end
  
  # call-seq:
  #   ary.eql?(other) -> true or false
  # 
  # Equality -- returns +true+ if _ary_ and _other_ contain the same number of
  # elements and if for every index <tt>i</tt> in _ary_,
  # <tt>ary[i].eql?( other[i] )</tt>.
  # 
  #   ['a','c'].eql?    ['a','c', 7]    #=> false
  #   ['a','c', 7].eql? ['a','c', 7]    #=> true
  #   ['a','c', 7].eql? ['a','d','f']   #=> false
  # 
  def eql?(ary)
    `if(ary.m$class()!==c$Array||ary.length!==this.length){return false;}`
    `for(var i=0,l=this.length;i<l;++i){if(!(this[i].m$eqlBool(ary[i]))){return false;};}`
    return true
  end
  
  # call-seq:
  #   ary.fetch(index)                   -> object or nil
  #   ary.fetch(index, default)          -> object or default
  #   ary.fetch(index) { |index| block } -> object or block.call(index)
  # 
  # Tries to return the element at position _index_. Negative values of
  # _index_ count from the end of the array.
  # 
  #   a = [100,101,102,103]
  #   
  #   a.fetch(1)                        #=> 101
  #   a.fetch(-1)                       #=> 103
  #   a.fetch(5, 'FAIL')                #=> "FAIL"
  #   a.fetch(5) {|i| "FAIL: #{i}" }    #=> "FAIL: 5"
  # 
  def fetch(index, &block)
    `var i=index`
    `if(index<0){index+=this.length;}`
    `if(index<0||index>=this.length){return typeof(block)=='function'?#{yield(`i`)}:block||nil;}`
    return `this[index]`
  end
  
  # call-seq:
  #   ary.fill(obj)                                 -> ary
  #   ary.fill(obj, start [, length])               -> ary
  #   ary.fill(obj, range )                         -> ary
  #   ary.fill { |index| block }                    -> ary
  #   ary.fill(start [, length] ) { |index| block } -> ary
  #   ary.fill(range) { |index| block }             -> ary
  # 
  # The first three forms set the selected elements of _ary_ (which may be the
  # entire array) to _obj_. A _start_ of +nil+ is equivalent to zero. A
  # _length_ of +nil+ is equivalent to <tt>ary.length</tt>. The last three
  # forms fill _ary_ with the value of the block. The block is passed the
  # absolute index of each element to be filled.
  # 
  #   a = %w(a b c d)
  #   
  #   a.fill("x")              #=> ["x", "x", "x", "x"]
  #   a.fill("z", 2, 2)        #=> ["x", "x", "z", "z"]
  #   a.fill("y", 0..1)        #=> ["y", "y", "z", "z"]
  #   a.fill {|i| i*i}         #=> [0, 1, 4, 9]
  #   a.fill(-2) {|i| i*i*i}   #=> [0, 1, 8, 27]
  # 
  # FIX: Incomplete -> doesn't accept ranges or handle loop control keywords
  def fill(object, index = 0, length = nil)
    `if(!(typeof(object)=='function'||typeof(index)=='function'||typeof(length)=='function')){if(index<0){index+=this.length;};for(var i=index,final=($T(length)?index+length:this.length);i<final;++i){this[i]=object;};return(this);}`
    `var final=this.length,_block=$u`
    `if(typeof(object)=='function'){_block=object;}`
    `if(typeof(index)=='function'){_block=index;index=object;}`
    `if(typeof(length)=='function'){_block=length;length=index;index=object;if(index<0){index+=this.length;if(index<0){throw('IndexError: out of range')}};final=index+length;}`
    `if(index<0){index+=this.length;}`
    `for(var i=index;i<final;++i){this[i]=_block(i);}`
    return self
  end
  
  # call-seq:
  #   ary.first    -> object or nil
  #   ary.first(n) -> array
  # 
  # Returns the first element of _ary_, or an array of the first _n_ elements
  # of _ary_. If _ary_ is empty, the first form returns +nil+ and the second
  # form returns an empty array.
  # 
  #   a = %w(a b c d)
  #   
  #   a.first       #=> "a"
  #   a.first(1)    #=> ["a"]
  #   a.first(3)    #=> ["a", "b", "c"]
  # 
  def first(n)
    `if(n!=null){for(var i=0,l=this.length,result=[],max=l<n?l:n;i<max;++i){result.push(this[i]);};return result;}`
    return `this.length==0?nil:this[0]`
  end
  
  # call-seq:
  #   ary.flatten -> array
  # 
  # Returns a new array that is a one-dimensional flattening of _ary_, by
  # extracting the elements of each _ary_ element that is also an array into
  # the new array.
  # 
  #   a = [1,2,3]         #=> [1, 2, 3]
  #   b = [4,5,6,[7,8]]   #=> [4, 5, 6, [7, 8]]
  #   c = [a,b,9,10]      #=> [[1, 2, 3], [4, 5, 6, [7, 8]], 9, 10]
  #   
  #   c.flatten           #=> [1, 2, 3, 4, 5, 6, 7, 8, 9, 10]
  # 
  def flatten
    `for(var i=0,l=this.length,result=[];i<l;++i){if(this[i].m$class()==c$Array){result=result.concat(this[i].m$flatten());}else{result.push(this[i]);};}`
    return `result`
  end
  
  # call-seq:
  #   ary.flatten! -> ary or nil
  # 
  # Extracts the elements of each element that is also an array and
  # returns _ary_, or +nil+ if no changes were made.
  # 
  #   a = [1,2,[3,[4,5]]]
  #   
  #   a.flatten!   #=> [1, 2, 3, 4, 5]
  #   a.flatten!   #=> nil
  # 
  def flatten!
    `for(var i=0,l=this.length,result=[];i<l;++i){if(this[i].m$class()==c$Array){result=result.concat(this[i].m$flattenBang());}else{result.push(this[i]);};}`
    return `this.length==result.length?nil:this._replace(result)`
  end
  
  def hash # :nodoc:
  end
  
  # call-seq:
  #   ary.include?(obj) -> true or false
  # 
  # Returns +true+ if any object in _ary_ <tt>==</tt> _obj_, +false+
  # otherwise.
  # 
  #   a = %w(a b c)
  #   
  #   a.include?('b')   #=> true
  #   a.include?('z')   #=> false
  # 
  def include?(obj)
    `for(var i=0,l=this.length;i<l;++i){if(this[i].m$_eql2(obj)){return true;};}`
    return false
  end
  
  # call-seq:
  #   ary.index(obj) -> integer or nil
  # 
  # Returns the index of the first object in _ary_ that <tt>==</tt> _obj_, or
  # +nil+ if no match is found.
  # 
  #   a = %w(a b c)
  #   
  #   a.index('b')    #=> 1
  #   a.index('z')    #=> nil
  # 
  def index(obj)
    `for(var i=0,l=this.length;i<l;++i){if(this[i].m$_eql2(obj)){return i;};}`
    return nil
  end
  
  # call-seq:
  #   ary.insert(index, obj...) -> ary
  # 
  # Inserts the given values before the element at _index_ and returns _ary_.
  # 
  #   a = [1,2,3,4]
  #   
  #   a.insert(2, 99)             #=> [1, 2, 99, 3, 4]
  #   a.insert(-2,'a','b','c')    #=> [1, 2, 99, 3, "a", "b", "c", 4]
  # 
  def insert(index, *args)
    `if(index<0){index+=this.length;if(index<0){throw('IndexError: out of range');};}`
    `while(this.length<index){this.push(nil);}`
    `this._replace(this.slice(0,index).concat(args).concat(this.slice(index,this.length)))`
  end
  
  # call-seq:
  #   ary.inspect -> string
  # 
  # Returns a printable version of _ary_ created by calling <tt>inspect</tt>
  # on each element.
  # 
  #   [1,2,3].inspect   #=> "[1, 2, 3]"
  # 
  def inspect
    `for(var i=1,l=this.length,result='['+(this[0]!=null?this[0].m$inspect()._value:'');i<l;++i){result+=', '+this[i].m$inspect()._value;}`
    return `$q(result+']')`
  end
  
  # call-seq:
  #   ary.join(str = '') -> string
  # 
  # Returns a string version of _ary_ created by calling <tt>to_s</tt> on each
  # element (or <tt>join(str)</tt> if the element is also an array), then
  # concatenating the resulting strings with _str_ between them.
  # 
  #   %w(a b c).join        #=> "abc"
  #   %w(a b c).join('.')   #=> "a.b.c"
  # 
  def join(str = '')
    `var result=this[0]!=null?this[0].m$join?this[0].m$join(str._value)._value:this[0].m$toS()._value:''`
    `for(var i=1,l=this.length;i<l;++i){result+=(str._value||'')+(this[i].m$join?this[i].m$join(str)._value:this[i].m$toS()._value);}`
    return `$q(result)`
  end
  
  # call-seq:
  #   ary.last    -> object or nil
  #   ary.last(n) -> array
  # 
  # Returns the last element of _ary_, or an array of the last _n_ elements of
  # _ary_. If _ary_ is empty, the first form returns +nil+ and the second
  # form returns an empty array.
  # 
  #   a = %w(a b c d)
  #   
  #   a.last      #=> "d"
  #   a.last(1)   #=> ["d"]
  #   a.last(3)   #=> ["b", "c", "d"]
  # 
  def last(n)
    `var l=this.length`
    `if(n!=null){for(var result=[],i=n>l?0:l-n;i<l;++i){result.push(this[i]);};return result;}`
    return `l==0?nil:this[l-1]`
  end
  
  # call-seq:
  #   ary.length -> integer
  #   ary.size   -> integer
  # 
  # Returns the number of elements in _ary_. May be zero.
  # 
  #   %w(a b c d e).length    #=> 5
  # 
  def length
    `this.length`
  end
  
  # call-seq:
  #   ary.collect { |element| block } -> array
  #   ary.map     { |element| block } -> array
  # 
  # Calls _block_ once for each element in _ary_, then returns a new array
  # containing the values returned by the block. See also
  # <tt>Enumerable#collect</tt>.
  # 
  #   a = [1,2,3,4]
  #   
  #   a.map {|x| x + 100 }    #=> [101, 102, 103, 104]
  #   a                       #=> [1, 2, 3, 4]
  # 
  def map
    `for(var i=0,l=this.length,result=[];i<l;++i){try{result[i]=#{yield `this[i]`};}catch(e){switch(e.__keyword__){case 'next':result[i]=e._value;break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return `result`
  end
  
  # call-seq:
  #   ary.collect! { |element| block } -> ary
  #   ary.map!     { |element| block } -> ary
  # 
  # Calls _block_ once for each element in _ary_, replacing the element with
  # the value returned by the block, then returns _ary_. See also
  # <tt>Enumerable#collect</tt>.
  # 
  #   a = [1,2,3,4]
  #   
  #   a.map! {|x| x + 100 }   #=> [101, 102, 103, 104]
  #   a.map! {|x| x + 100 }   #=> [201, 202, 203, 204]
  # 
  def map!
    `for(var i=0,l=this.length;i<l;++i){try{this[i]=#{yield `this[i]`};}catch(e){switch(e.__keyword__){case 'next':this[i]=e._value;break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   ary.nitems -> integer
  # 
  # Returns the number of non-+nil+ elements in _ary_. May be zero.
  # 
  #   [1, nil, 3, nil, 5].nitems    #=> 3
  # 
  def nitems
    `for(var i=0,l=this.length,result=0;i<l;++i){if(this[i]!==nil){result++;};}`
    return `result`
  end
  
  # call-seq:
  #   ary.pop -> object or nil
  # 
  # Removes the last element from _ary_ and returns it, or +nil+ if _ary_ is
  # empty.
  # 
  #   a = %w(a b c)
  #   
  #   a.pop   #=> "c"
  #   a.pop   #=> "b"
  #   a       #=> ["a"]
  # 
  def pop
    `if(this.length==0){return nil;}`
    `this.pop()`
  end
  
  # call-seq:
  #   ary.push(obj, ...) -> ary
  # 
  # Append -- pushes the given objects onto the end of _ary_. This expression
  # returns _ary_ itself, so several appends may be chained together.
  # 
  #   a = [1,2,3]
  #   
  #   a.push(4).push(5,6,7)   #=> [1, 2, 3, 4, 5, 6, 7]
  # 
  def push(*args)
    `for(var i=0,l=args.length;i<l;++i){this.push(args[i]);}`
    return self
  end
  
  # call-seq:
  #   ary.rassoc(obj) -> array or nil
  # 
  # Searches through _ary_, comparing _obj_ with the second element of each
  # _ary_ element that is also an array. Returns the first array such that
  # <tt>array[1] == obj</tt>, or +nil+ if no match is found. See also
  # <tt>Array#assoc</tt>.
  # 
  #   a  = [[1,'one'], [2,'two'], [:ii,'two']]
  #   
  #   a.rassoc('two')     #=> [2, "two"]
  #   a.rassoc('three')   #=> nil
  # 
  def rassoc(obj)
    `for(var i=0,l=this.length;i<l;++i){var x=this[i];if(x.m$class()==c$Array&&x[1]!=null&&x[1].m$_eql2(obj)){return x;};}`
    return nil
  end
  
  # call-seq:
  #   ary.reject { |element| block } -> array
  # 
  # Returns a new array containing only the items in _ary_ for which
  # <tt>block.call(element)</tt> evaluates to +nil+ or +false+.
  # 
  #   a = [1,2,3,4,5]
  #   
  #   a.reject {|x| x > 3 }   #=> [1, 2, 3]
  #   a                       #=> [1, 2, 3, 4, 5]
  # 
  def reject
    `for(var i=0,l=this.length,result=[];i<l;++i){try{if(!$T(#{yield `this[i]`})){result.push(this[i]);};}catch(e){switch(e.__keyword__){case 'next':if(!$T(e._value)){result.push(this[i]);};break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return `result`
  end
  
  # call-seq:
  #   ary.reject! { |element| block } -> ary or nil
  # 
  # Deletes every element in _ary_ for which _block_ evaluates to +true+, then
  # returns _ary_, or +nil+ if no changes were made.
  # 
  #   a = [1,2,3,4,5]
  #   
  #   a.reject! {|x| x > 3 }    #=> [1, 2, 3]
  #   a.reject! {|x| x > 3 }    #=> nil
  #   a                         #=> [1, 2, 3]
  # 
  def reject!
    `for(var i=0,l=this.length,temp=[];i<l;++i){try{if(!$T(#{yield `this[i]`})){temp.push(this[i]);};}catch(e){switch(e.__keyword__){case 'next':if(!$T(e._value)){temp.push(this[i]);};break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return `temp.length==l?nil:this._replace(temp)`
  end
  
  # call-seq:
  #   ary.replace(other) -> ary
  # 
  # Replaces the contents of _ary_ with the contents of _other_, truncating or
  # expanding if necessary.
  # 
  #   a = %w(a b c)
  #   
  #   a.replace(%w(w x y z))    #=> ["w", "x", "y", "z"]
  #   a                         #=> ["w", "x", "y", "z"]
  # 
  def replace(other)
    `this._replace(other)`
  end
  
  # call-seq:
  #   ary.reverse -> array
  # 
  # Returns a new array containing _ary_'s elements in reverse order.
  # 
  #   a = [1,2,3,4,5]
  #   
  #   a.reverse   #=> [5, 4, 3, 2, 1]
  #   a           #=> [1, 2, 3, 4, 5]
  # 
  def reverse
    `this.reverse()`
  end
  
  # call-seq:
  #   ary.reverse! -> ary
  # 
  # Returns _ary_ with its elements in reverse order.
  # 
  #   a = [1,2,3,4,5]
  #   
  #   a.reverse!    #=> [5, 4, 3, 2, 1]
  #   a             #=> [5, 4, 3, 2, 1]
  # 
  def reverse!
    `for(var i=0,l=this.length,last=l-1;i<l;++i){j=last-i;if(i>=j){break;};this._swap(i,j);}`
    return self
  end
  
  # call-seq:
  #   ary.reverse_each { |element| block } -> ary
  # 
  # Calls _block_ once for each element in _ary_ in reverse order, then
  # returns _ary_.
  # 
  #   %(a b c).reverse_each {|element| puts element.upcase }    #=> ["a", "b", "c"]
  # 
  # produces:
  # 
  #   C
  #   B
  #   A
  # 
  def reverse_each
    `for(var i=this.length;i>0;){try{#{yield `this[--i]`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':++i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   ary.rindex(obj) -> integer or nil
  # 
  # Returns the highest index such that <tt>ary[index] == obj</tt>, or +nil+
  # if _obj_ is not found in _ary_.
  # 
  #   a = %w(a b b b c)
  #   
  #   a.rindex('b')   #=> 3
  #   a.rindex('z')   #=> nil
  # 
  def rindex(obj)
    `for(var i=this.length;i>0;){if(this[--i].m$_eql2(obj)){return i;};}`
    return nil
  end
  
  # call-seq:
  #   ary.select { |element| block } -> array
  # 
  # Returns a new array containing only the items in _ary_ for which
  # <tt>block.call(element)</tt> evaluates to +true+.
  # 
  #   [1,2,3,4,5].select {|x| x > 3 }   #=> [4, 5]
  # 
  def select
    `for(var i=0,l=this.length,result=[];i<l;++i){try{if($T(#{yield `this[i]`})){result.push(this[i]);};}catch(e){switch(e.__keyword__){case 'next':if($T(e._value)){result.push(this[i]);};break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return `result`
  end
  
  # call-seq:
  #   ary.shift -> object or nil
  # 
  # Removes the first element of _ary_ and returns it, shifting the indices of
  # all other elements down by one. Returns +nil+ if _ary_ is empty.
  # 
  #   a = %w(a b c)
  #   
  #   a.shift   #=> "a"
  #   a         #=> ["b", "c"]
  # 
  def shift
    `if(this.length==0){return nil;}`
    `this.shift()`
  end
  
  # call-seq:
  #   ary.length -> integer
  #   ary.size   -> integer
  # 
  # Returns the number of elements in _ary_. May be zero.
  # 
  #   %w(a b c d e).size    #=> 5
  # 
  def size
    `this.length`
  end
  
  # call-seq:
  #   ary[index]               -> object or nil
  #   ary[start, length]       -> array or nil
  #   ary[range]               -> array or nil
  #   ary.slice(index)         -> object or nil
  #   ary.slice(start, length) -> array or nil
  #   ary.slice(range)         -> array or nil
  # 
  # Element Reference -- returns the element at _index_, or an array of the
  # elements in _range_ or from _start_ to _start_ plus _length_. Returns
  # +nil+ if the index is out of range.
  # 
  #   a = %w(a b c d e)
  #   
  #   a[2] + a[0] + a[1]    #=> "cab"
  #   a[6]                  #=> nil
  #   a[1,2]                #=> ["b", "c"]
  #   a[1..3]               #=> ["b", "c", "d"]
  #   a[4..7]               #=> ["e"]
  #   a[6..10]              #=> nil
  #   a[-3,3]               #=> ["c", "d", "e"]
  #   # special cases
  #   a[5]                  #=> nil
  #   a[5,1]                #=> []
  #   a[5..10]              #=> []
  # 
  # FIX: Check so-called "special cases"
  def slice(index, length)
    `c$Array.prototype.m$_brac.apply(this,arguments)`
  end
  
  # call-seq:
  #   ary.slice!(index)         -> object or nil
  #   ary.slice!(start, length) -> array or nil
  #   ary.slice!(range)         -> array or nil
  # 
  # Deletes the element at _index_, or the series of elements in _range_ or
  # from _start_ to _start_ plus _length_. Returns the deleted object,
  # subarray, or +nil+ if the index is out of range.
  # 
  #   a = %w(a b c d)
  #   
  #   a.slice!(1)     #=> "b"
  #   a               #=> ["a", "c", "d"]
  #   a.slice!(-1)    #=> "d"
  #   a               #=> ["a", "c"]
  #   a.slice!(100)   #=> nil
  #   a               #=> ["a", "c"]
  # 
  def slice!(index, length)
    `var l=this.length`
    `if(index.m$class()==c$Range){var start=index._start,end=index._exclusive?index._end-1:index._end;index=start<0?start+l:start;length=(end<0?end+l:end)-index+1;if(length<0){length=0};}else{if(index<0){index+=l;};if(length<0){throw('IndexError: negative length')};}`
    `if(index>=l){return nil;}`
    `if(index<0){throw('RangeError: out of range');}`
    `if($T(length)){if(length<=0){return [];};result=this.slice(index,index+length);this._replace(this.slice(0,index).concat(this.slice(index+length)));}else{result=this[index];this._replace(this.slice(0,index).concat(this.slice(index+1,l)));}`
    return `result`
  end
  
  # call-seq:
  #   ary.sort                 -> array
  #   ary.sort { |a,b| block } -> array
  # 
  # Returns a new array containing the elements in _ary_ sorted either by the
  # <tt><=></tt> operator or by the optional _block_, which should compare _a_
  # and _b_ and return -1, 0, or 1. See also <tt>Enumerable#sort_by</tt>.
  # 
  #   strings = %w(x z w y)                     #=> ["x", "z", "w", "y"]
  #   symbols = strings.map {|x| x.to_sym }     #=> [:x, :z, :w, :y]
  #   
  #   strings.sort                              #=> ["w", "x", "y", "z"]
  #   symbols.sort {|a,b| b.to_s <=> a.to_s }   #=> [:z,:y,:x,:w]
  # 
  # FIX: Doesn't handle loop control keywords
  def sort(block)
    `c$Array.apply(null,this)._quickSort(0,this.length,block)`
  end
  
  # call-seq:
  #   ary.sort!                 -> ary
  #   ary.sort! { |a,b| block } -> ary
  # 
  # Returns _ary_ with its elements sorted either by the <tt><=></tt> operator
  # or by the optional _block_, which should compare _a_ and _b_ and return
  # -1, 0, or 1. See also <tt>Enumerable#sort_by</tt>.
  # 
  #   a = [3, 2, 4, 1]
  #   
  #   a.sort!                     #=> [1, 2, 3, 4]
  #   a.sort! {|a,b| b <=> a }    #=> [4, 3, 2, 1]
  #   a                           #=> [4, 3, 2, 1]
  # 
  # FIX: Doesn't handle loop control keywords
  def sort!(block)
    `this._quickSort(0,this.length,block)`
  end
  
  # call-seq:
  #   ary.to_a -> ary or array
  # 
  # Returns _ary_. If called on an instance of a subclass of +Array+, converts
  # the receiver to an +Array+ object.
  # 
  #   [1,2,3].to_a    #=> [1, 2, 3]
  # 
  def to_a
    `if(this.m$class()==c$Array){return this;}`
    return `c$Array.apply(nil,this)`
  end
  
  # call-seq:
  #   ary.to_ary -> ary
  # 
  # Returns _ary_.
  # 
  #   [1,2,3].to_ary    #=> [1, 2, 3]
  # 
  def to_ary
    return self
  end
  
  # call-seq:
  #   ary.to_s -> string
  # 
  # Returns <tt>ary.join</tt>.
  # 
  #   %w(a b c).to_s    #=> "abc"
  # 
  def to_s
    return self.join
  end
  
  # call-seq:
  #   ary.transpose -> array
  # 
  # Assumes that _ary_ contains only arrays of equal lengths and returns a new
  # array with their rows and columns transposed.
  # 
  #   [[1,2],[3,4],[5,6]].transpose   #=> [[1, 3, 5], [2, 4, 6]]
  # 
  def transpose
    `if(this.length==0){return [];}`
    `var result=[],a=this[0].length,n=this.length`
    `while(result.length<a){result.push([])}`
    `for(var i=0;i<a;++i){for(var j=0;j<n;++j){if(this[j].length!=this[0].length){throw('IndexError: element size differs')};result[i][j]=this[j][i];};}`
    return `result`
  end
  
  # call-seq:
  #   ary.uniq -> array
  # 
  # Returns a new array containing the elements of _ary_, with no duplicates.
  # 
  #   %w(a b b c c c).uniq    #=> ["a", "b", "c"]
  # 
  def uniq
    `for(var i=0,l=this.length,result=[],seen={};i<l;++i){var a=this[i],k=a.m$hash();if(!seen[k]){seen[k]=true;result.push(a);};}`
    return `result`
  end
  
  # call-seq:
  #   ary.uniq! -> ary or nil
  # 
  # Returns _ary_ with duplicate elements removed, or +nil+ if no changes were
  # made.
  # 
  #   a = %w(a b b c c c)
  #   
  #   a.uniq!   #=> ["a", "b", "c"]
  #   a.uniq!   #=> nil
  #   a         #=> ["a", "b", "c"]
  # 
  def uniq!
    `for(var i=0,l=this.length,result=[],seen={};i<l;++i){var a=this[i],k=a.m$hash();if(!seen[k]){seen[k]=true;result.push(a);};}`
    return `result.length==l?nil:this._replace(result)`
  end
  
  # call-seq:
  #   ary.unshift(obj, ...) -> ary
  # 
  # Prepends objects to the front of _ary_, shifting the indices of _ary_'s
  # other elements up one, then returns _ary_.
  # 
  #   a = %w(b c)
  #   
  #   a.unshift('a')      #=> ["a", "b", "c"]
  #   a.unshift(1,2,3)    #=> [1, 2, 3, "a", "b", "c"]
  # 
  def unshift(*args)
    `for(var i=args.length;i>0;){this.unshift(args[--i]);}`
    return self
  end
  
  # Returns an array containing the elements in _self_ corresponding to the given selector(s). The selectors may be either integer indices or ranges. See also Array#select.
  # FIX: Incomplete
  def values_at(args)
  end
  
  # FIX: Incomplete
  def zip
  end
  
  `_._partition=function(first,last,pivot,block){var value=this[pivot],store=first;this._swap(pivot,last);for(var i=0,l=this.length;i<l;++i){if(i<first||i>=last){continue;};var cmp=block?block(this[i],value):this[i].m$_ltgt(value);if(cmp==-1||cmp==0){this._swap(store++,i);};};this._swap(last,store);return(store);}`
  `_._quickSort=function(start,finish,block){if(finish-1>start){var pivot=start+Math.floor(Math.random()*(finish-start));pivot=this._partition(start,(finish-1),pivot,block);this._quickSort(start,pivot,block);this._quickSort((pivot+1),finish,block);};return(this);}`
  `_._replace=function(ary){this.length=0;for(var i=0,l=ary.length;i<l;++i){this.push(ary[i])};return this;}`
  `_._swap=function(x,y){var z=this[x];this[x]=this[y];this[y]=z;return this;}`
end

# Instances of +Exception+ and its descendants are used to communicate between
# +raise+ methods and +rescue+ statements in +begin+/+end+ blocks. +Exception+
# objects carry information about the exception -- its type (the exception's
# class name), an optional descriptive string, and optional traceback
# information. Applications may subclass +Exception+ to add additional
# information.
# 
class Exception
  # call-seq:
  #   Exception.exception(arg) -> exception
  # 
  # Equivalent to <tt>Exception::new</tt>.
  # 
  def self.exception(arg)
    `this.m$new(arg)`
  end
  
  # call-seq:
  #   Exception.new(message = nil) -> exception
  # 
  # Returns a new +Exception+ object, with an optional _message_.
  # 
  def initialize(msg)
    `if(msg!=null){this._message=msg._value;}`
  end
  
  # call-seq:
  #   exc.backtrace -> array
  # 
  # Returns any backtrace associated with the exception. The backtrace is an
  # array of strings, each containing <i>"/path/to/filename:line"</i>.
  # 
  def backtrace
    `if(this._stack==null){return [];}`
    `for(var i=0,lines=this._stack.match(/@[^\\n]+:\\d+/g),l=lines.length,result=[];i<l;++i){result.push($q(lines[i].match(/@\\w+:\\/*(\\/[^\\n]+:\\d+)/)[1]));}`
    return `result`
  end
  
  # call-seq:
  #   exc.exception(arg) -> exception or exc
  # 
  # If _arg_ is absent or equal to _exc_, returns the receiver. Otherwise
  # returns a new +Exception+ object of the same class as the receiver, but
  # with a message equal to <tt>arg.to_str</tt>.
  # 
  def exception(arg)
    `if(arg==null||arg==this){return this;}`
    `this.m$class().m$new(arg.m$toStr())`
  end
  
  # call-seq:
  #   exc.inspect -> string
  # 
  # Returns _exc_'s class name and message.
  # 
  def inspect
    `var class_name=this.m$class().__name__.replace(/\\./g,'::')`
    `this._message==''?$q(class_name):$q('#<'+class_name+': '+(this._message||class_name)+'>')`
  end
  
  # call-seq:
  #   exc.to_message -> string
  #   exc.to_s       -> string
  #   exc.to_str     -> string
  # 
  # Returns _exc_'s message (or the name of the exception class if no message
  # is set).
  # 
  def message
    `this._message==null?$q(this.m$class().__name__.replace(/\\./g,'::')):$q(this._message)`
  end
  
  # call-seq:
  #   exc.set_backtrace(array) -> array
  # 
  # Sets the backtrace information associated with _exc_. The argument must be
  # an array of +String+ objects in the format described in
  # <tt>Exception#backtrace</tt>.
  def set_backtrace(ary)
    `for(var i=0,l=ary.length,result='';i<l;++i){result=result+'@xx://'+ary[i]._value+'\\n';}`
    `this._stack=result`
    return `ary`
  end
  
  # call-seq:
  #   exc.to_message -> string
  #   exc.to_s       -> string
  #   exc.to_str     -> string
  # 
  # Returns _exc_'s message (or the name of the exception class if no message
  # is set).
  # 
  def to_s
    `this._message==null?$q(this.m$class().__name__.replace(/\\./g,'::')):$q(this._message)`
  end
  
  # call-seq:
  #   exc.to_message -> string
  #   exc.to_s       -> string
  #   exc.to_str     -> string
  # 
  # Returns _exc_'s message (or the name of the exception class if no message
  # is set).
  # 
  def to_str
    `this._message==null?$q(this.m$class().__name__.replace(/\\./g,'::')):$q(this._message)`
  end
end

class StandardError < Exception     ; end
class ArgumentError < StandardError ; end
class IndexError < StandardError    ; end
class RangeError < StandardError    ; end
class RuntimeError < StandardError  ; end
class TypeError < StandardError     ; end

# The global value +false+ is the only instance of class +FalseClass+ and
# represents a logically false value in boolean expressions. The class
# provides operators allowing +false+ to participate correctly in logical
# expressions.
# 
class FalseClass
  # call-seq:
  #   false & obj -> false
  # 
  # And -- returns +false+. Because _obj_ is the argument to a method call, it
  # is always evaluated; there is no short-circuit evaluation.
  # 
  #   false &  a = "A assigned"   #=> false
  #   false && b = "B assigned"   #=> false
  #   [a, b].inspect              #=> ["A assigned", nil]
  #
  def &(object)
    # `this.valueOf()&&$T(object)` // implemented in TrueClass
  end
  
  # call-seq:
  #   false | obj -> !!obj
  # 
  # Or -- returns +false+ if _obj_ is +nil+ or +false+, +true+ otherwise.
  # 
  def |(object)
    # `this.valueOf()||$T(object)` // implemented in TrueClass
  end
  
  # call-seq:
  #   false ^ obj -> !!obj
  # 
  # Exclusive Or -- returns +false+ if _obj_ is +nil+ or +false+, +true+
  # otherwise.
  # 
  def ^(object)
    # `this.valueOf()?!$T(object):$T(object)` // implemented in TrueClass
  end
  
  def hash # :nodoc:
    # `'b_'+this.valueOf()` // implemented in TrueClass
  end
  
  def object_id # :nodoc:
    # `this.valueOf()?2:0` // implemented in TrueClass
  end
  
  # call-seq:
  #   false.to_s -> "false"
  # 
  # The string representation of +false+ is "false".
  # 
  def to_s
    # `$q(''+this)` // implemented in TrueClass
  end
  
  undef initialize
end

# A +Hash+ is a collection of key-value pairs. It is similar to an +Array+,
# except that indexing is done not by an integer index but by arbitrary keys
# of any object type.
# 
# Hashes have a default value that is returned when accessing keys that do not
# exist in the hash, which is +nil+ unless otherwise assigned.
# 
class Hash
  # call-seq:
  #   Hash[ [key (, | =>) value]* ] -> hash
  # 
  # Creates a new hash populated with the given objects. Equivalent to the
  # literal <tt>{key, value, ...}</tt>. Keys and values occur in pairs, so
  # there must be an even number of arguments.
  # 
  #    Hash[:a, 100, 'b', 200]        #=> {:a => 100, "b" => 200}
  #    Hash[:a => 100, 'b' => 200]    #=> {:a => 100, "b" => 200}
  #    {:a => 100, 'b' => 200}        #=> {:a => 100, "b" => 200}
  # 
  def self.[](*args)
    `if(args.length==1&&args[0].m$class()==c$Hash){return args[0];}`
    `for(var i=0,l=args.length,result=c$Hash.m$new(),c=result._contents;i<l;i+=2){var k=args[i],v=args[i+1],h=k.m$hash();c[h]=[k,v]}`
    return `result`
  end
  
  # call-seq:
  #   Hash.new                      -> hash
  #   Hash.new(obj)                 -> hash
  #   Hash.new { |hash, key| block } -> hash
  # 
  # Returns a new, empty hash. If this hash is subsequently accessed with a
  # key that doesn't correspond to an existing hash entry, the value returned
  # depends on the style of +new+ used to create the hash. In the first form,
  # the access returns +nil+. If _obj_ is specified, this single object will
  # be used for all default values. If a block is specified, it will be called
  # with the hash object and the key, and should return the default value. It
  # is the block's responsibility to store the value in the hash if required.
  # 
  #   h1 = Hash.new("No value for that key")
  #   
  #   h1[:a] = 100      #=> 100
  #   h1[:b] = 200      #=> 200
  #   h1[:a]            #=> 100
  #   h1[:c]            #=> "No value for that key"
  #   # The following alters the single default object
  #   h1[:c].upcase!    #=> "NO VALUE FOR THAT KEY"
  #   h1[:d]            #=> "NO VALUE FOR THAT KEY"
  #   # Values from defaults are not stored in the hash
  #   h1.keys           #=> [:a, :b]
  #   
  #   h2 = Hash.new { |hash, key| hash[key] = "No value at #{key}" }
  #   
  #   h2[:c]            #=> "No value at c"
  #   # A new object is created by the default block each time
  #   h2[:c].upcase!    #=> "NO VALUE AT C"
  #   h2[:d]            #=> "No value at d"
  #   # Values from defaults are stored in the hash
  #   h2.keys           #=> [:c, :d]
  # 
  def initialize(&block)
    `this._default=(block==null?nil:block)`
    `this._contents={}`
  end
  
  # call-seq:
  #   hsh == other -> true or false
  # 
  # Equality -- two hashes are equal if they contain the same number of keys
  # and if for every key, <tt>hsh[key] == other[key]</tt>.
  # 
  #   h1 = {:a => 1, :b => 2}
  #   h2 = {7 => 35, :b => 2, :a => 1}
  #   h3 = {:a => 1, :b => 2, 7 => 35}
  #   h4 = {:a => 1, :c => 2, :f => 35}
  #   
  #   h1 == h2    #=> false
  #   h2 == h3    #=> true
  #   h3 == h4    #=> false
  # 
  def ==(other)
    `var c=this._contents,o=other._contents`
    `for(var x in o){if(x.slice(1,2)=='_'&&c[x]==null){return false;};}`
    `for(var x in c){if(x.slice(1,2)=='_'&&!c[x][1].m$_eql2(o[x][1])){return false;};}`
    return true
  end
  
  # call-seq:
  #   hsh[key] -> value
  # 
  # Element Reference -- retrieves the _value_ object corresponding to the
  # _key_ object. If not found, returns the default value (see
  # <tt>Hash::new</tt> for details).
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h[:a]   => 100
  #   h[:c]   => nil
  # 
  def [](k)
    `var kv=this._contents[k.m$hash()]`
    `if(!kv){var d=this._default;return(typeof(d)=='function'?d(this,kv[0]):d);}`
    return `kv[1]`
  end
  
  # call-seq:
  #   hsh[key] = value     -> value
  #   hsh.store(key,value) -> value
  # 
  # Element Assignment -- associates the value given by _value_ with the key
  # given by _key_. The object _key_ should not have its value changed while
  # it is in use as a key.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h[:a] = 150   #=> 150
  #   h[:c] = 300   #=> 300
  #   h             #=> {:a => 150, :b => 200, :c => 300}
  # 
  def []=(k,v)
    `this._contents[k.m$hash()]=[k,v]`
    return `v`
  end
  
  # call-seq:
  #   hsh.clear -> hsh
  # 
  # Removes all key-value pairs from _hsh_.
  # 
  #   h = {:a => 1, :b => 2}
  #   
  #   h.clear   #=> {}
  #   h         #=> {}
  # 
  def clear
    `this._contents={}`
    return self
  end
  
  # call-seq:
  #   hsh.default(key = nil) -> obj
  # 
  # Returns the default value, the value that would be returned by
  # <tt>hsh[key]</tt> if key did not exist in hsh. See also <tt>Hash::new</tt>
  # and <tt>Hash#default=</tt>.
  # 
  #   h = Hash.new                              #=> {}
  #   h.default                                 #=> nil
  #   h.default(2)                              #=> nil
  #   
  #   h = Hash.new('FAIL')                      #=> {}
  #   h.default                                 #=> 'FAIL'
  #   h.default(2)                              #=> 'FAIL'
  #   
  #   h = Hash.new {|h,k| h[k] = k.to_i * 10}   #=> {}
  #   h.default                                 #=> 0
  #   h.default(2)                              #=> 20
  # 
  def default(key = nil)
    `var d=this._default`
    return `typeof(d)=='function'?d(this,key):d`
  end
  
  # call-seq:
  #   hsh.default = obj -> hsh
  # 
  # Sets the default value, the value returned for a key that does not exist
  # in the hash. It is not possible to set the a default to a +Proc+ that will
  # be executed on each key lookup.
  # 
  #   h = {:a => 100, :b => 200}
  #   h.default = 'Nothing'
  #   
  #   h[:a]       #=> 100
  #   h[:z]       #=> 'Nothing'
  #   
  #   # This doesn't do what you might hope...
  #   h.default = proc {|h,k| h[k] = k + k }
  #   
  #   h[2]        #=> #<Proc:201>
  #   h['foo']    #=> #<Proc:201>
  # 
  def default=(obj)
    `this._default=obj`
    return self
  end
  
  # call-seq:
  #   hsh.default_proc -> proc
  # 
  # If <tt>Hash::new</tt> was invoked with a block, return that block,
  # otherwise return +nil+.
  # 
  #    h = Hash.new {|h,k| h[k] = k*k }   #=> {}
  #    p = h.default_proc                 #=> #<Proc:201>
  #    a = []                             #=> []
  #    p.call(a, 2)
  #    a                                  #=> [nil, nil, 4]
  # 
  def default_proc
    `var d=this._default`
    return `typeof(d)=='function'?c$Proc.m$new(d):nil`
  end
  
  # call-seq:
  #   hsh.delete(key)                 -> value
  #   hsh.delete(key) { |key| block } -> value
  # 
  # Deletes and returns a key-value pair from _hsh_ whose key is equal to
  # _key_. If the key is not found, returns the default value, or if the
  # optional code block is given, pass in the requested key and return the
  # result of _block_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.delete(:a)                                    #=> 100
  #   h.delete(:z)                                    #=> nil
  #   h.delete(:z) {|k| "#{k.inspect} not found" }    #=> ":z not found"
  # 
  def delete(k)
    `var c=this._contents,d=this._default,x=k.m$hash(),kv=c[x]`
    `if(kv!=null){var result=kv[1];delete(c[x]);return result;}`
    return `typeof(_block)=='function'?#{yield `k`}:(typeof(d)=='function'?d(this,k):d)`
  end
  
  # call-seq:
  #   hsh.delete_if { |key, value| block } -> hsh
  # 
  # Deletes every key-value pair from _hsh_ for which _block_ evaluates to
  # +true+, then returns _hsh_.
  # 
  #   h = {:a => 100, :b => 200, :c => 300 }
  #   
  #   h.delete_if {|k,v| v >= 200 }    #=> {:a => 100}
  # 
  def delete_if
    `var c=this._contents`
    `for(var x in c){try{if(x.slice(1,2)=='_'&&$T(#{yield(`c[x][0]`,`c[x][1]`)})){delete(c[x]);};}catch(e){switch(e.__keyword__){case 'next':if($T(e._value)){delete(c[x]);};break;case 'break':return e._value;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   hsh.each { |key, value| block } -> hsh
  #   hsh.each { |kv_array| block }   -> hsh
  # 
  # Calls _block_ once for each key in _hsh_, passing the key and value to the
  # block as a two-element array, or as separate key and value elements if the
  # block has two formal parameters. See also <tt>Hash.each_pair</tt>, which
  # will be marginally more efficient for blocks with two parameters.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.each {|k,v| puts "key is #{k.inspect}, value is #{v.inspect}" }   #=> {:a => 100, :b => 200}
  #   h.each {|kv|  puts "key-value array is #{kv.inspect}" }             #=> {:a => 100, :b => 200}
  # 
  # produces:
  # 
  #   key is :a, value is 100
  #   key is :b, value is 200
  #   key-value array is [:a, 100]
  #   key-value array is [:b, 100]
  # 
  def each
    `var c=this._contents`
    `for(var x in c){try{if(x.slice(1,2)=='_'){var kv=c[x];_block._arity==1?#{yield(`[kv[0],kv[1]]`)}:#{yield(`kv[0],kv[1]`)}};}catch(e){switch(e.__keyword__){case 'next':;break;case 'break':return e._value;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   hsh.each_key { |key| block } -> hsh
  # 
  # Calls _block_ once for each key in _hsh_, passing the key as a parameter.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.each_key {|k| puts k.inspect }    #=> {:a => 100, :b => 200}
  # 
  # produces:
  # 
  #   :a
  #   :b
  # 
  def each_key
    `var c=this._contents`
    `for(var x in c){try{if(x.slice(1,2)=='_'){#{yield `c[x][0]`}};}catch(e){switch(e.__keyword__){case 'next':;break;case 'break':return e._value;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   hsh.each_key { |key| block } -> hsh
  # 
  # Calls _block_ once for each key in _hsh_, passing the key and value as
  # parameters.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.each_pair {|k,v| puts "#{k.inspect} is #{v.inspect}" }    #=> {:a => 100, :b => 200}
  # 
  # produces:
  # 
  #   :a is 100
  #   :b is 200
  # 
  def each_pair
    `var c=this._contents`
    `for(var x in c){try{if(x.slice(1,2)=='_'){var kv=c[x];#{yield(`kv[0]`,`kv[1]`)}};}catch(e){switch(e.__keyword__){case 'next':;break;case 'break':return e._value;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   hsh.each_key { |key| block } -> hsh
  # 
  # Calls _block_ once for each key in _hsh_, passing the value as a
  # parameter.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.each_value {|v| puts v.inspect }    #=> {:a => 100, :b => 200}
  # 
  # produces:
  # 
  #   100
  #   200
  # 
  def each_value
    `var c=this._contents`
    `for(var x in c){try{if(x.slice(1,2)=='_'){#{yield `c[x][1]`}};}catch(e){switch(e.__keyword__){case 'next':;break;case 'break':return e._value;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   hsh.empty? -> true or false
  # 
  # Returns +true+ if _hsh_ contains no key-value pairs.
  # 
  #   {}.empty?   #=> true
  # 
  def empty?
    `for(var x in this._contents){if(x.slice(1,2)=='_'){return false;};}`
    return true
  end
  
  # call-seq:
  #   hsh.fetch(key [, default])     -> obj
  #   hsh.fetch(key) { |key| block } -> obj
  # 
  # Returns a value from _hsh_ for the given key. If the key is not found,
  # returns the _default_ object or evaluates _block_, or raises +IndexError+
  # if neither are given.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.fetch(:a)                                     #=> 100
  #   h.fetch(:z, 'No value')                         #=> "No value"
  #   h.fetch(:z) { |k| "No value at #{k.inspect}"}   #=> "No value at :z"
  # 
  def fetch(key, &block)
    `var c=this._contents,k=key.m$hash(),kv=c[k]`
    `if(kv!=null){return kv[1];}`
    return `typeof(block)=='function'?block(key):block`
  end
  
  # call-seq:
  #   hsh.has_key?(key) -> true or false
  #   hsh.include?(key) -> true or false
  #   hsh.key?(key)     -> true or false
  #   hsh.member?(key)  -> true or false
  # 
  # Returns +true+ if the given key is present in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.has_key?(:a)    #=> true
  #   h.has_key?(:z)    #=> false
  # 
  def has_key?(k)
    `!!this._contents[k.m$hash()]`
  end
  
  # call-seq:
  #   hsh.has_value?(value) -> true or false
  #   hsh.value?(value)     -> true or false
  # 
  # Returns +true+ if there is any key in _hsh_ such that <tt>hsh[key] ==
  # value</tt>.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.has_value?(100)   #=> true
  #   h.has_value?(999)   #=> false
  # 
  def has_value?(value)
    `var c=this._contents`
    `for(var x in c){if(x.slice(1,2)=='_'&&c[x][1].m$_eql2(value)){return true;};}`
    return false
  end
  
  def hash # :nodoc:
  end
  
  # call-seq:
  #   hsh.has_key?(key) -> true or false
  #   hsh.include?(key) -> true or false
  #   hsh.key?(key)     -> true or false
  #   hsh.member?(key)  -> true or false
  # 
  # Returns +true+ if the given key is present in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.include?(:a)    #=> true
  #   h.include?(:z)    #=> false
  # 
  def include?(k)
    `!!this._contents[k.m$hash()]`
  end
  
  # call-seq:
  #   hsh.index(value) -> key or nil
  # 
  # Returns the key for a given value. If not found, returns +nil+.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.index(100)    #=> :a
  #   h.index(999)    #=> nil
  # 
  def index(value)
    `var c=this._contents`
    `for(var x in c){var kv=c[x];if(x.slice(1,2)=='_'&&kv[1].m$_eql2(value)){return kv[0];};}`
    return nil
  end
  
  # call-seq:
  #   hsh.inspect -> string
  # 
  # Return the contents of _hsh_ as a string.
  # 
  #   h = Hash[:a,100,:b,200]
  #   
  #   h.inspect   #=> "{:a => 100, :b => 200}"
  # 
  def inspect
    `var contents=[],c=this._contents`
    `for(var x in c){if(x.slice(1,2)=='_'){var kv=c[x];contents.push(kv[0].m$inspect()._value+' => '+kv[1].m$inspect()._value);};}`
    return `$q('{'+contents.join(', ')+'}')`
  end
  
  # call-seq:
  #   hsh.invert -> hash
  # 
  # Returns a new hash created by using _hsh_'s values as keys, and its keys
  # as values.
  # 
  #   h = {:n => 100, :m => 100, :y => 300, :d => 200, :a => 0 }
  #   
  #   h.invert    #=> {100 => :m, 300 => :y, 200 => :d, 0 => :a}
  # 
  def invert
    `var c=this._contents,result=c$Hash.m$new()`
    `for(var x in c){if(x.slice(1,2)=='_'){var ckv=c[x],rkv=result._contents[ckv[1].m$hash()]=[];rkv[0]=ckv[1];rkv[1]=ckv[0]};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.has_key?(key) -> true or false
  #   hsh.include?(key) -> true or false
  #   hsh.key?(key)     -> true or false
  #   hsh.member?(key)  -> true or false
  # 
  # Returns +true+ if the given key is present in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.key?(:a)    #=> true
  #   h.key?(:z)    #=> false
  # 
  def key?(k)
    `!!this._contents[k.m$hash()]`
  end
  
  # call-seq:
  #   hsh.keys -> array
  # 
  # Returns a new array populated with the keys in _hsh_. See also
  # <tt>Hash#values</tt>.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.keys    #=> [:a, :b]
  # 
  def keys
    `var c=this._contents,result=[]`
    `for(var x in c){if(x.slice(1,2)=='_'){result.push(c[x][0]);};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.length -> integer
  #   hsh.size   -> integer
  # 
  # Returns the number of key-value pairs in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.length    #=> 2
  #   h.clear     #=> {}
  #   h.length    #=> 0
  # 
  def length
    `var c=this._contents,result=0`
    `for(var x in c){if(x.slice(1,2)=='_'){result++;};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.has_key?(key) -> true or false
  #   hsh.include?(key) -> true or false
  #   hsh.key?(key)     -> true or false
  #   hsh.member?(key)  -> true or false
  # 
  # Returns +true+ if the given key is present in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.member?(:a)   #=> true
  #   h.member?(:z)   #=> false
  # 
  def member?(k)
    `!!this._contents[k.m$hash()]`
  end
  
  # call-seq:
  #   hsh.merge(other)                                       -> hash
  #   hsh.merge(other) { |key, old_value, new_value| block } -> hash
  # 
  # Returns a new hash containing the contents of _other_ and the contents of
  # _hsh_, using the value from _other_ in the case of duplicate keys.
  # 
  #   h1 = {:a => 100, :b => 200}
  #   h2 = {:a => 150, :c => 300}
  #   
  #   h1.merge(h2)                                #=> {:a => 150, :b => 200, :c => 300}
  #   h1.merge(h2) {|k,oldv,newv| oldv * newv }   #=> {:a => 15000, :b => 200, :c => 300}
  #   h1                                          #=> {:a => 100, :b => 200}
  # 
  # FIX: Doesn't handle loop control keywords
  def merge(other)
    `var c=this._contents,o=other._contents,result=c$Hash.m$new(),r=result._contents`
    `for(var x in c){if(x.slice(1,2)=='_'){r[x]=c[x];};}`
    `for(var x in o){var ckv=c[x],okv=o[x];if(x.slice(1,2)=='_'){typeof(_block)=='function'&&ckv!=null?r[x]=[ckv[0],#{yield(`ckv[0]`,`ckv[1]`,`okv[1]`)}]:r[x]=okv;};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.merge!(other)                                       -> hash
  #   hsh.merge!(other) { |key, old_value, new_value| block } -> hash
  #   hsh.update(other)                                       -> hash
  #   hsh.update(other) { |key, old_value, new_value| block } -> hash
  # 
  # Returns _hsh_ with the contents of _other_ added to it, overwriting
  # duplicate entries in _hsh_ with those from _other_.
  # 
  #   h1 = {:a => 100, :b => 200}
  #   h2 = {:a => 150, :c => 300}
  #   
  #   h1.merge!(h2)                                 #=> {:a => 150, :b => 200, :c => 300}
  #   h1.merge!(h2) {|k,oldv,newv| oldv * newv }    #=> {:a => 22500, :b => 200, :c => 90000}
  #   h1                                            #=> {:a => 22500, :b => 200, :c => 90000}
  # 
  # FIX: Doesn't handle loop control keywords
  def merge!(other)
    `var c=this._contents,o=other._contents`
    `for(var x in o){var ckv=c[x],okv=o[x];if(x.slice(1,2)=='_'){typeof(_block)=='function'&&ckv!=null?ckv[1]=#{yield(`ckv[0]`,`ckv[1]`,`okv[1]`)}:c[x]=okv;};}`
    return self
  end
  
  # call-seq:
  #   hsh.reject { |key, value| block } -> hash
  # 
  # Returns a new hash consisting of the key-value pairs for which _block_
  # evaluates to +nil+ or +false+.
  # 
  #   h = {:a => 100, :b => 200, :c => 300}
  #   
  #   h.reject {|k,v| v > 100 }   #=> {:a => 100}
  #   h.reject {|k,v| v < 200 }   #=> {:b => 200, :c => 300}
  #   h                           #=> {:a => 100, :b => 200, :c => 300}
  # 
  def reject
    `var c=this._contents,result=c$Hash.m$new()`
    `for(var x in c){try{var kv=c[x];if(x.slice(1,2)=='_'&&!$T(#{yield(`kv[0]`,`kv[1]`)})){result._contents[x]=kv;};}catch(e){switch(e.__keyword__){case 'next':if(!$T(e._value)){result._contents[x]=kv;};break;case 'break':return e._value;break;default:throw(e);};};}`
    return `result`
  end
  
  
  # call-seq:
  #   hsh.reject! { |key, value| block } -> hsh or nil
  # 
  # Removes key-value pairs for which _block_ evaluates to +nil+ or +false+
  # and returns _hsh_, or +nil+ if no changes were made.
  # 
  #   h = {:a => 100, :b => 200, :c => 300}
  #   
  #   h.reject! {|k,v| v > 100 }    #=> {:a => 100}
  #   h.reject! {|k,v| v > 100 }    #=> nil
  #   h                             #=> {:a => 100}
  # 
  def reject!
    `var c=this._contents,u=true`
    `for(var x in c){try{var kv=c[x];if(x.slice(1,2)=='_'&&$T(#{yield(`kv[0]`,`kv[1]`)})){u=false;delete(c[x]);};}catch(e){switch(e.__keyword__){case 'next':if($T(e._value)){u=false;delete(c[x]);};break;case 'break':return e._value;break;default:throw(e);};};}`
    return `u?nil:this`
  end
  
  # call-seq:
  #   hsh.replace(other) -> hsh
  # 
  # Replaces the contents of _hsh_ with the contents of _other_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.replace(:c => 300, :d => 400)   #=> {:c => 300, :d => 400}
  #   h                                 #=> {:c => 300, :d => 400}
  # 
  def replace(other)
    `this._contents={}`
    `var c=this._contents,o=other._contents`
    `for(var x in o){if(x.slice(1,2)=='_'){c[x]=o[x];};}`
    return self
  end
  
  # call-seq:
  #   hsh.select { |key, value| block } -> array
  # 
  # Returns an array consisting of <tt>[key,value]</tt> pairs for which the
  # block returns +true+. Also see <tt>Hash.values_at</tt>.
  # 
  #   h = {:a => 100, :b => 200, :c => 300}
  #   
  #   h.select {|k,v| v > 100 }   #=> [[:b, 200], [:c, 300]]
  #   h.select {|k,v| v < 200}    #=> [[:a, 100]]
  # 
  def select
    `var c=this._contents,result=[]`
    `for(var x in c){try{var kv=c[x];if(x.slice(1,2)=='_'&&$T(#{yield(`kv[0]`,`kv[1]`)})){result.push(kv);};}catch(e){switch(e.__keyword__){case 'next':if($T(e._value)){result.push(kv);};break;case 'break':return e._value;break;default:throw(e);};};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.shift -> array or object
  # 
  # Removes a key-value pair from _hsh_ and returns it as the two-item array
  # <tt>[key, value]</tt>, or returns the default value if _hsh_ is empty.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.shift   #=> [:a, 100]
  #   h.shift   #=> [:b, 200]
  #   h.shift   #=> nil
  #   h         #=> {}
  # 
  def shift
    `var c=this._contents,d=this._default,result=typeof(d)=='function'?d(nil):d`
    `for(var x in c){if(x.slice(1,2)=='_'){result=[c[x][0],c[x][1]];delete(c[x]);break;};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.length -> integer
  #   hsh.size   -> integer
  # 
  # Returns the number of key-value pairs in _hsh_.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.size    #=> 2
  #   h.clear   #=> {}
  #   h.size    #=> 0
  # 
  def size
    `var c=this._contents,result=0`
    `for(var x in c){if(x.slice(1,2)=='_'){result++;};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.sort                 -> array
  #   hsh.sort { |a,b| block } -> array
  # 
  # Converts _hsh_ to a nested array of <tt>[key, value]</tt> arrays and sorts
  # it, using <tt>Array#sort</tt>.
  # 
  #   h = {3 => 'a', 1 => 'b', 2 => 'c'}
  #   
  #   h.sort                          #=> [[1, "b"], [2, "c"], [3, "a"]]
  #   h.sort {|a,b| a[1] <=> b[1] }   #=> [[3, "a"], [1, "b"], [2, "c"]]
  # 
  # FIX: Doesn't handle loop control keywords
  def sort(&block)
    `var c=this._contents,result=[]`
    `for(var x in c){if(x.slice(1,2)=='_'){result.push(c[x]);};}`
    return `c$Array.prototype._quickSort.call(result,0,result.length,block)`
  end
  
  # call-seq:
  #   hsh[key] = value     -> value
  #   hsh.store(key,value) -> value
  # 
  # Element Assignment -- associates the value given by _value_ with the key
  # given by _key_. The object _key_ should not have its value changed while
  # it is in use as a key.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.store(:a,150)   #=> 150
  #   h.store(:c,300)   #=> 300
  #   h                 #=> {:a => 150, :b => 200, :c => 300}
  # 
  def store(k,v)
    `this._contents[k.m$hash()]=[k,v]`
    return `v`
  end
  
  # call-seq:
  #   hsh.to_a -> array
  # 
  # Converts _hash_ to a nested array of <tt>[key, value]</tt> arrays.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.to_a    #=> [[:a, 100], [:b, 200]]
  # 
  def to_a
    `var c=this._contents,result=[]`
    `for(var x in c){if(x.slice(1,2)=='_'){result.push(c[x]);};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.to_hash -> hsh
  # 
  # Returns _hsh_.
  # 
  def to_hash
    self
  end
  
  # call-seq:
  #   hsh.to_s -> string
  # 
  # Converts _hsh_ to a string by converting the hash to an array of <tt>[key,
  # value]</tt> pairs and then converting that array to a string using
  # <tt>Array#join</tt> with the default separator.
  # 
  def to_s
    `var c=this._contents,result=[]`
    `for(var x in c){if(x.slice(1,2)=='_'){result.push(c[x]);};}`
    return `c$Array.prototype.m$join.call(result)`
  end
  
  # call-seq:
  #   hsh.merge!(other)                                       -> hash
  #   hsh.merge!(other) { |key, old_value, new_value| block } -> hash
  #   hsh.update(other)                                       -> hash
  #   hsh.update(other) { |key, old_value, new_value| block } -> hash
  # 
  # Returns _hsh_ with the contents of _other_ added to it, overwriting
  # duplicate entries in _hsh_ with those from _other_.
  # 
  #   h1 = {:a => 100, :b => 200}
  #   h2 = {:a => 150, :c => 300}
  #   
  #   h1.update(h2)                                 #=> {:a => 150, :b => 200, :c => 300}
  #   h1.update(h2) {|k,oldv,newv| oldv * newv }    #=> {:a => 22500, :b => 200, :c => 90000}
  #   h1                                            #=> {:a => 22500, :b => 200, :c => 90000}
  # 
  # FIX: Doesn't handle loop control keywords
  def update(other)
    `var c=this._contents,o=other._contents`
    `for(var x in o){var ckv=c[x],okv=o[x];if(x.slice(1,2)=='_'){typeof(_block)=='function'&&ckv!=null?ckv[1]=#{yield(`ckv[0]`,`ckv[1]`,`okv[1]`)}:c[x]=okv;};}`
    return self
  end
  
  # call-seq:
  #   hsh.has_value?(value) -> true or false
  #   hsh.value?(value)     -> true or false
  # 
  # Returns +true+ if there is any key in _hsh_ such that <tt>hsh[key] ==
  # value</tt>.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.value?(100)   #=> true
  #   h.value?(999)   #=> false
  # 
  def value?(value)
    `var c=this._contents`
    `for(var x in this._contents){if(x.slice(1,2)=='_'&&c[x][1].m$_eql2(value)){return true;};}`
    return false
  end
  
  # call-seq:
  #   hsh.values -> array
  # 
  # Returns a new array populated with the values of _hsh_. See also
  # <tt>Hash#keys</tt>.
  # 
  #   h = {:a => 100, :b => 200}
  #   
  #   h.values    #=> [100, 200]
  # 
  def values
    `var c=this._contents,result=[]`
    `for(var x in c){if(x.slice(1,2)=='_'){result.push(c[x][1]);};}`
    return `result`
  end
  
  # call-seq:
  #   hsh.values_at(key, ...) -> array
  # 
  # Returns an array containing the values associated with the given keys.
  # See also <tt>Hash.select</tt>.
  # 
  #   h = {:a => 100, :b => 200, :c => 300}
  #   
  #   h.values_at(:a,:c)    #=> [100,300]
  # 
  def values_at(*args)
    `for(var i=0,l=args.length,c=this._contents,d=this._default,result=[];i<l;++i){var h=args[i].m$hash(),kv=c[h];result.push(kv?kv[1]:(typeof(d)=='function'?d(this,args[i]):d))}`
    return `result`
  end
end

# MatchData is the class of the object returned by <tt>String#match</tt>,
# <tt>Regexp#match</tt>, and <tt>Regexp#last_match</tt>. It encapsulates all
# the results of a pattern match.
# 
class MatchData
  def initialize # :nodoc:
    `this._captures=[]`
  end
  
  # call-seq:
  #   mtch[i]             -> object
  #   mtch[start, length] -> array
  #   mtch[range]         -> array
  # 
  # Match Reference -- MatchData acts as an array, and may be accessed using
  # the normal array indexing techniques. <tt>mtch[0]</tt> returns the entire
  # matched string, while <tt>mtch[1]</tt>, <tt>mtch[2]</tt>, and so on return
  # the values of the matched backreferences (portions of the pattern between
  # parentheses).
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m[0]       #=> "HX1138"
  #   m[1, 2]    #=> ["H", "X"]
  #   m[1..3]    #=> ["H", "X", "113"]
  #   m[-3, 2]   #=> ["X", "113"]
  # 
  def [](*args)
    `c$Array.prototype.m$_brac.apply(this._captures,args)`
  end
  
  # FIX: Incomplete
  def begin(n)
  end
  
  # call-seq:
  #   mtch.captures -> array
  # 
  # Returns the array of captures.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.").captures
  #   
  #   m[0]    #=> "H"
  #   m[1]    #=> "X"
  #   m[2]    #=> "113"
  #   m[3]    #=> "8"
  # 
  def captures
    `this._captures.slice(1)`
  end
  
  # FIX: Incomplete
  def end(n)
  end
  
  # call-seq:
  #   mtch.length -> integer
  #   mtch.size   -> integer
  # 
  # Returns the number of elements in the match array.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m.length    #=> 5
  # 
  def length
    `this._captures.length`
  end
  
  def inspect # :nodoc:
    `c$Object.prototype.m$toS.apply(this)`
  end
  
  # FIX: Incomplete
  def offset(n)
  end
  
  # call-seq:
  #   mtch.post_match -> string
  # 
  # Returns the portion of the original string after the current match.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138: The Movie")
  #   
  #   m.post_match    #=> ": The Movie"
  # 
  def post_match
    `this._post`
  end
  
  # call-seq:
  #   mtch.pre_match -> string
  # 
  # Returns the portion of the original string before the current match.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m.pre_match   #=> "T"
  # 
  def pre_match
    `this._pre`
  end
  
  # FIX: Incomplete
  def select
  end
  
  # call-seq:
  #   mtch.length -> integer
  #   mtch.size   -> integer
  # 
  # Returns the number of elements in the match array.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m.size    #=> 5
  # 
  def size
    `this._captures.length`
  end
  
  # call-seq:
  #   mtch.string -> string
  # 
  # Returns a copy of the string that was matched against a pattern to produce
  # _mtch_.
  # 
  #   m1 = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   m2 = "THX1138.".match(/(.)(.)(\d+)(\d)/)
  #   
  #   m1.string   #=> "THX1138."
  #   m2.string   #=> "THX1138."
  # 
  def string
    `$q(this._string)`
  end
  
  # call-seq:
  #   mtch.to_a -> array
  # 
  # Returns the MatchData's internal array.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m.to_a    #=> ["HX1138", "H", "X", "113", "8"]
  #
  def to_a
    `this._captures`
  end
  
  # call-seq:
  #   mtch.to_s -> string
  # 
  # Returns the entire matched string.
  # 
  #   m = /(.)(.)(\d+)(\d)/.match("THX1138.")
  #   
  #   m.to_s    #=> "HX1138"
  #
  def to_s
    `this._captures[0]`
  end
  
  # FIX: Incomplete
  def values_at
  end
end

# The class of the singleton object +nil+.
# 
class NilClass
  def initialize # :nodoc:
    `this.__id__=4`
  end
  
  # call-seq:
  #   nil & obj -> false
  # 
  # And -- returns +false+. _obj_ is always evaluated as it is the argument to a method call -- there is no short-circuit evaluation in this case.
  # 
  def &(object)
    false
  end
  
  # call-seq:
  #   nil | obj -> true or false
  # 
  # Or -- returns +false+ if _obj_ is +nil+ or +false+; +true+ otherwise.
  # 
  def |(object)
    `$T(object)`
  end
  
  # call-seq:
  #   nil ^ obj -> true or false
  # 
  # Exclusive Or -- if _obj_ is +nil+ or +false+, returns +false+; otherwise, returns +true+.
  # 
  def ^(object)
    `$T(object)`
  end
  
  # call-seq:
  #   nil.inspect -> "nil"
  # 
  # Always returns the string "nil".
  # 
  def inspect
    'nil'
  end
  
  # call-seq:
  #   nil.nil? -> true
  # 
  # Only the object _nil_ responds +true+ to <tt>nil?</tt>.
  # 
  def nil?
    true
  end
  
  # call-seq:
  #   nil.to_a -> []
  # 
  # Always returns an empty array.
  # 
  def to_a
    []
  end
  
  # call-seq:
  #   nil.to_f -> 0
  # 
  # Always returns zero.
  # 
  def to_f
    0
  end
  
  # call-seq:
  #   nil.to_i -> 0
  # 
  # Always returns zero.
  # 
  def to_i
    0
  end
  
  # call-seq:
  #   nil.to_s -> ''
  # 
  # Always returns the empty string.
  # 
  def to_s
    ''
  end
  
  `nil=c$NilClass.m$new()`
  `c$Object.__superclass__=nil`
  
  undef initialize
end

# +Numeric+ objects represent native JavaScript numbers. Class +Numeric+
# subsumes the methods of Ruby's +Float+, +Integer+, +Bignum+, and +Fixnum+.
# 
class Numeric
  self.include Comparable
  
  # call-seq:
  #   num % other       -> numeric
  #   num.modulo(other) -> numeric
  # 
  # Returns _num_ modulo _other_. See <tt>Numeric#divmod</tt> for more
  # information.
  # 
  def %(n)
    `this%n`
  end
  
  # call-seq:
  #   num & other -> integer
  # 
  # Performs bitwise +AND+ between _num_ and _other_. Floats are truncated to
  # integers before operation.
  # 
  def &(n)
    `this&n`
  end
  
  # call-seq:
  #   num | other -> integer
  # 
  # Performs bitwise +OR+ between _num_ and _other_. Floats are truncated to
  # integers before operation.
  # 
  def |(n)
    `this|n`
  end
  
  # call-seq:
  #   num ^ other -> integer
  # 
  # Performs bitwise +XOR+ between _num_ and _other_. Floats are truncated to
  # integers before operation.
  # 
  def ^(n)
    `this^n`
  end
  
  # call-seq:
  #   ~num -> integer
  # 
  # Performs bitwise +NOT+ on _num_. Floats are truncated to integers before
  # operation.
  # 
  def ~
    `~this`
  end
  
  # call-seq:
  #   num / other    -> integer
  #   num.div(other) -> integer
  # 
  # Divides _num_ by _other_, then truncates the result to an integer. (See
  # also <tt>Numeric#quo</tt>.)
  # 
  def /(n)
    `parseInt(this/n)`
  end
  
  # call-seq:
  #   num * other -> numeric
  # 
  # Multiplies _num_ by _other_, then returns the result.
  # 
  def *(n)
    `this*n`
  end
  
  # call-seq:
  #   num ** n -> numeric
  # 
  # Raises _num_ to the <i>n</i>th power, which may be negative or fractional.
  # 
  def **(n)
    `Math.pow(this,n)`
  end
  
  # call-seq:
  #   num + other -> numeric
  # 
  # Adds _num_ to _other_, then returns the result.
  # 
  def +(n)
    `this+n`
  end
  
  # call-seq:
  #   +num -> num
  # 
  # Unary Plus -- returns the value of _num_.
  # 
  def +@()
    `this`
  end
  
  # call-seq:
  #   num - other -> numeric
  # 
  # Subtracts _other_ from _num_, then returns the result.
  # 
  def -(n)
    `this-n`
  end
  
  # call-seq:
  #   -num -> numeric
  # 
  # Unary Minus -- returns the value of _num_ negated.
  # 
  def -@()
    `-this`
  end
  
  # call-seq:
  #   num << n -> integer
  # 
  # Shifts _num_ left _n_ positions (right if _n_ is negative). Floats are
  # truncated to integers before operation.
  # 
  def <<(n)
    `Math.floor(parseInt(this)*Math.pow(2,parseInt(n)))`
  end
  
  # call-seq:
  #   num << n -> integer
  # 
  # Shifts _num_ right _n_ positions (left if _n_ is negative). Floats are
  # truncated to integers before operation.
  # 
  def >>(n)
    `Math.floor(parseInt(this)/Math.pow(2,parseInt(n)))`
  end
  
  # call-seq:
  #   num <=> numeric -> -1, 0, 1
  # 
  # Comparison -- returns -1, 0, or 1 depending on whether _num_ is less than,
  # equal to, or greater than _numeric_. This is the basis for the tests in
  # +Comparable+.
  # 
  def <=>(n)
    `if(n.constructor!=Number){return nil;}`
    `if(this>n){return 1;}`
    `if(this<n){return -1;}`
    return 0
  end
  
  def ==(n) # :nodoc:
    `this.valueOf()===n.valueOf()`
  end
  
  def ===(n) # :nodoc:
    `this.valueOf()===n.valueOf()`
  end
  
  # call-seq:
  #   num[n] -> 0, 1
  # 
  # Bit Reference -- returns the <i>n</i>th bit in the binary representation of
  # _num_, where <tt>num[0]</tt> is the least significant bit. Floats are
  # truncated to integers before operation.
  # 
  #   a = 1234
  #   "%b" % a    #=> "10011010010"
  #   
  #   15.downto(0) {|n| puts a[n] }
  # 
  # produces:
  # 
  #   0000010011010010
  # 
  def [](n)
    `var str=parseInt(this).toString(2)`
    `if(n>=str.length){return 0;}`
    `parseInt(str[(str.length-n-1)])`
  end
  
  # call-seq:
  #   num.abs -> numeric
  # 
  # Returns the absolute value of _num_.
  # 
  #   -1234.abs   #=> 1234
  #   1234.abs    #=> 1234
  # 
  def abs
    `Math.abs(this)`
  end
  
  # call-seq:
  #   num.ceil -> integer
  # 
  # Returns the smallest integer greater than or equal to _num_.
  # 
  def ceil
    `Math.ceil(this)`
  end
  
  # call-seq:
  #   num.chr -> string
  # 
  # Returns a string containing the ASCII character represented by _num_.
  # Floats are truncated to integers before operation.
  # 
  #   65.chr    #=> "A"
  #   ?a.chr    #=> "a"
  # 
  def chr
    `String.fromCharCode(parseInt(this))`
  end
  
  # call-seq:
  #   num.coerce -> array
  # 
  # Returns an array containing _num_ and _other_. This method is used by Ruby
  # to handle mixed-type numeric operations and is included in Red for
  # compatibility reasons only.
  # 
  def coerce(n)
    `[this,n]`
  end
  
  # call-seq:
  #   num./(other)   -> integer
  #   num.div(other) -> integer
  # 
  # Performs division, then truncates the result to an integer. (See also
  # <tt>Numeric#quo</tt>.)
  # 
  def div(n)
    `parseInt(this/n)`
  end
  
  # FIX: Incomplete
  def divmod
  end
  
  # call-seq:
  #   num.downto(limit) { |i| block } -> num
  # 
  # Iterates _block_, passing decreasing values from _num_ down to and
  # including _limit_, then returns _num_.
  # 
  #   5.downto(1) { |n| puts "#{n}.." }    #=> 5
  # 
  # produces:
  # 
  #   5..
  #   4..
  #   3..
  #   2..
  #   1..
  # 
  def downto(limit)
    `for(var i=this.valueOf();i>=limit;--i){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':++i;break;default:throw(e);};};}`
    return self
  end
  
  def eql?(n) # :nodoc:
    `this.valueOf()===n.valueOf()`
  end
  
  def equal?(n) # :nodoc:
    `this.valueOf()===n.valueOf()`
  end
  
  # call-seq:
  #   num.finite? -> true or false
  # 
  # Returns +true+ if _num_ is not infinite and <tt>num.nan?</tt> is false.
  # 
  def finite?
    `if(this.valueOf()===Infinity||this.valueOf()===-Infinity||this.toString()==='NaN'){return false;}`
    return true
  end
  
  # call-seq:
  #   num.floor -> integer
  # 
  # Returns the largest integer less than or equal to _num_.
  # 
  def floor
    `Math.floor(this)`
  end
  
  def hash # :nodoc:
    `'n_'+this`
  end
  
  # FIX: Incomplete
  def id2name
  end
  
  # call-seq:
  #   num.infinite? -> -1, nil, 1
  # 
  # Returns -1, +nil+, or +1 depending on whether _num_ is -infinity, finite,
  # or +infinity.
  # 
  #   (0).infinite?       #=> nil
  #   (-1/0).infinite?    #=> -1
  #   (+1/0).infinite?    #=> 1
  # 
  def infinite?
    `if(this.valueOf()===Infinity){return 1;}`
    `if(this.valueOf()===-Infinity){return -1;}`
    return nil
  end
  
  # call-seq:
  #   num.integer? -> true or false
  # 
  # Returns +true+ if _num_ is an integer.
  # 
  def integer?
    `this%1===0`
  end
  
  # call-seq:
  #   num % other       -> numeric
  #   num.modulo(other) -> numeric
  # 
  # Returns _num_ modulo _other_. See <tt>Numeric#divmod</tt> for more
  # information.
  # 
  def modulo(n)
    `this%n`
  end
  
  # call-seq:
  #   num.nan? -> true or false
  # 
  # Returns +true+ if _num_ is +NaN+.
  # 
  #   (0/0).nan?    #=> true
  # 
  def nan?
    `this.toString()==='NaN'`
  end
  
  # call-seq:
  #   num.next -> integer
  #   num.succ -> integer
  # 
  # Returns the integer equal to <tt>num.truncate + 1</tt>.
  # 
  #   num = 1.5
  #   num = num.next    #=> 2
  #   num = num.next    #=> 3
  # 
  def next
    `parseInt(this)+1`
  end
  
  # call-seq:
  #   num.nonzero? -> num or nil
  # 
  # Returns _num_ if _num_ is not zero, +nil+ otherwise. This behavior is
  # useful when chaining comparisons:
  # 
  #   a = %w(z Bb bB bb BB a aA Aa AA A)
  #   b = a.sort {|a,b| (a.downcase <=> b.downcase).nonzero? || a <=> b }
  #   b   #=> ["A", "a", "AA", "Aa", "aA", "BB", "Bb", "bB", "bb", "z"]
  # 
  def nonzero?
    `this.valueOf()===0?nil:this`
  end
  
  # call-seq:
  #   num.quo(numeric) -> float
  # 
  # Returns the floating point result of dividing _num_ by _numeric_.
  # 
  #   654321.quo(13731)      #=> 47.6528293642124
  #   654321.quo(13731.24)   #=> 47.6519964693647
  # 
  def quo(n)
    `this/n`
  end
  
  # FIX: Incomplete
  def remainder
  end
  
  # call-seq:
  #   num.round -> integer
  # 
  # Rounds _num_ to the nearest integer.
  # 
  def round
    `Math.round(this)`
  end
  
  # call-seq:
  #   num.step(limit, step ) {|i| block } -> num
  # 
  # Invokes block with the sequence of numbers starting at _num_, incremented
  # by _step_ on each call, then returns self. The loop finishes when the value to be passed to
  # the block is greater than _limit_ (if _step_ is positive) or less than
  # _limit_ (if _step_ is negative).
  # 
  #    1.step(5, 2) { |i| puts i }
  #    Math::E.step(Math::PI, 0.2) { |f| puts i }
  # produces:
  # 
  #   1
  #   3
  #   5
  #   2.71828182845905
  #   2.91828182845905
  #   3.11828182845905
  # 
  def step(limit, step)
    `var i=this.valueOf()`
    `if(step>0){if(i<limit){for(;limit>=i;i+=step){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':i-=step;break;default:throw(e);};};};};}else{if(i>limit){for(;limit<=i;i+=step){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':i-=step;break;default:throw(e);};}};;};}`
    return self
  end
  
  # call-seq:
  #   num.next -> integer
  #   num.succ -> integer
  # 
  # Returns the integer equal to <tt>num.truncate + 1</tt>.
  # 
  #   num = 1.5
  #   num = num.succ    #=> 2
  #   num = num.succ    #=> 3
  # 
  def succ
    `parseInt(this)+1`
  end
  
  # call-seq:
  #   num.times { |i| block } -> num
  # 
  # Iterates block _num_ times, passing in values from zero to
  # <tt>num - 1</tt>, then returns _num_.
  # 
  #    5.times do |i|
  #      puts i
  #    end
  # 
  # produces:
  # 
  #   0
  #   1
  #   2
  #   3
  #   4
  # 
  def times
    `for(var i=0,l=this.valueOf();i<l;++i){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};}}`
    return self
  end
  
  # call-seq:
  #   num.to_f -> float
  # 
  #   Returns _self_.
  # 
  def to_f
    `this`
  end
  
  # call-seq:
  #   num.to_i     -> integer
  #   num.to_int   -> integer
  #   num.truncate -> integer
  # 
  # Returns _num_ truncated to an integer.
  # 
  def to_i
    `parseInt(this)`
  end
  
  # call-seq:
  #   num.to_i     -> integer
  #   num.to_int   -> integer
  #   num.truncate -> integer
  # 
  # Returns _num_ truncated to an integer.
  # 
  def to_int
    `parseInt(this)`
  end
  
  # call-seq:
  #   num.to_s(base = 10) -> aString
  # 
  # Returns a string containing the representation of _num_ radix _base_
  # (between 2 and 36).
  # 
  #   12345.to_s       #=> "12345"
  #   12345.to_s(2)    #=> "11000000111001"
  #   12345.to_s(8)    #=> "30071"
  #   12345.to_s(10)   #=> "12345"
  #   12345.to_s(16)   #=> "3039"
  #   12345.to_s(36)   #=> "9ix"
  # 
  def to_s(base = 10)
    `$q(this.toString(base))`
  end
  
  # FIX: Incomplete
  def to_sym
  end
  
  # call-seq:
  #   num.to_i     -> integer
  #   num.to_int   -> integer
  #   num.truncate -> integer
  # 
  # Returns _num_ truncated to an integer.
  # 
  def truncate
    `parseInt(this)`
  end
  
  # call-seq:
  #   num.upto(limit) { |i| block } -> num
  # 
  # Iterates _block_, passing increasing values from _num_ up to and
  # including _limit_, then returns _num_.
  # 
  #   98.upto(100) { |n| puts "#{n}.." }    #=> 98
  # 
  # produces:
  # 
  #   98..
  #   99..
  #   100..
  # 
  def upto(limit)
    `for(var i=this.valueOf();i<=limit;++i){try{#{yield `i`};}catch(e){switch(e.__keyword__){case 'next':break;case 'break':return e._value;break;case 'redo':--i;break;default:throw(e);};};}`
    return self
  end
  
  # call-seq:
  #   num.zero? -> true or false
  # 
  # Returns +true+ if _num_ is zero.
  # 
  def zero?
    `this.valueOf()===0`
  end
end

# +Proc+ objects are blocks of code that have been bound to a set of local
# variables. Once bound, the code may be called in different contexts and
# still access those variables.
# 
#   def gen_times(factor)
#     return Proc.new {|n| n * factor }
#   end
#   
#   times3 = gen_times(3)
#   times5 = gen_times(5)
#   
#   times3.call(12)               #=> 36
#   times5.call(5)                #=> 25
#   times3.call(times5.call(4))   #=> 60
# 
class Proc
  # call-seq:
  #   Proc.new {|...| block } -> proc
  # 
  # Creates a new +Proc+ object, bound to the current context.
  # 
  def initialize(func)
    `this._block=func`
  end
  
  # FIX: Incomplete
  def ==
  end
  
  # call-seq:
  #   prc.call(params, ...) -> obj
  #   prc[params, ...]      -> obj
  # 
  # Invokes the block, setting the block's parameters to the values in params
  # using something close to method calling semantics.
  # 
  # Returns the value of the last expression evaluated in the block.
  # 
  #   proc = Proc.new {|x| x * 100 }
  #   
  #   proc[4]   #=> 400
  # 
  def []()
    `this._block.apply(this,arguments)`
  end
  
  # FIX: Incomplete
  def arity
  end
  
  # call-seq:
  #   prc.call(params, ...) -> obj
  #   prc[params, ...]      -> obj
  # 
  # Invokes the block, setting the block's parameters to the values in params
  # using something close to method calling semantics.
  # 
  # Returns the value of the last expression evaluated in the block. See
  # also <tt>Proc#yield</tt>.
  # 
  #   proc = Proc.new {|x| x * 100 }
  #   
  #   proc.call(4)    #=> 400
  # 
  def call
    `this._block.apply(this,arguments)`
  end
  
  # call-seq:
  #   proc.to_proc -> proc
  # 
  # Part of the protocol for converting objects to +Proc+ objects. Instances
  # of class +Proc+ simply return themselves.
  # 
  def to_proc
    return self
  end
end

# A +Range+ represents an interval -- a set of values with a start and an end.
# Ranges may be constructed using the <tt>s..e</tt> and <tt>s...e</tt>
# literals, or with <tt>Range::new</tt>. Ranges constructed using <tt>..</tt>
# run from the start to the end inclusively. Those created using <tt>...</tt>
# exclude the end value. When used as an iterator, ranges return each value in
# the sequence.
# 
#   (-1..-5).to_a      #=> []
#   (-5..-1).to_a      #=> [-5, -4, -3, -2, -1]
#   ('a'..'e').to_a    #=> ["a", "b", "c", "d", "e"]
#   ('a'...'e').to_a   #=> ["a", "b", "c", "d"]
# 
# Ranges can be constructed using objects of any type, as long as the
# <tt><=></tt> comparison operator and the <tt>succ</tt> method (to return the
# next object in sequence) are defined.
# 
#   class XChain
#     attr :length
#     
#     def initialize(n)
#       @length = n
#     end
#     
#     def succ
#       one_more = @length + 1
#       XChain.new(one_more)
#     end
#     
#     def <=>(other)
#       @length <=> other.length
#     end
#     
#     def inspect
#       'x' * @length
#     end
#   end
#   
#   r = XChain.new(2)..XChain.new(5)    #=> xx..xxxxx
#   r.to_a                              #=> [xx, xxx, xxxx, xxxxx]
#   r.member? XChain.new(4)             #=> true
# 
class Range
  # call-seq:
  #   Range.new(start, end, exclusive=false) -> range
  # 
  # Constructs a range using the given _start_ and _end_. If _exclusive_ is
  # omitted or is +false+, the _range_ will include the end object; otherwise,
  # it will be excluded.
  # 
  def initialize(start,finish,exclusive=false)
    `this._start=start`
    `this._end=finish`
    `this._exclusive=exclusive`
  end
  
  # call-seq:
  #   rng == obj -> true or false
  # 
  # Returns +true+ only if _obj_ is a +Range+, has equivalent beginning and
  # end items (by comparing them with <tt>==</tt>), and has the same
  # <tt>exclude_end?</tt> setting as _rng_.
  # 
  #   (0..2) == (0..2)            #=> true
  #   (0..2) == Range.new(0,2)    #=> true
  #   (0..2) == (0...2)           #=> false
  # 
  def ==(object)
    `if(object.constructor!==c$Range){return false;}`
    `this._start.m$_eql2(object._start)&&this._end.m$_eql2(object._end)&&this._exclusive==object._exclusive`
  end
  
  # call-seq:
  #   rng === obj       -> true or false
  #   rng.include?(obj) -> true or false
  #   rng.member?(obj)  -> true or false
  # 
  # Returns +true+ if _obj_ is an element of _rng_, +false+ otherwise.
  # Conveniently, <tt>===</tt> is the comparison operator used by +case+
  # statements.
  # 
  #   case 79
  #     when 1..50   : puts "low"
  #     when 51..75  : puts "medium"
  #     when 76..100 : puts "high"
  #   end
  # 
  # produces:
  # 
  #   high
  # 
  def ===(obj)
    `var s=#{obj <=> `this._start`},e=#{obj <=> `this._end`}`
    `s==0||s==1?(this._exclusive?e==-1:e==-1||e==0):false`
  end
  
  # call-seq:
  #   rng.begin -> obj
  #   rng.first -> obj
  # 
  # Returns the first object in _rng_.
  # 
  #   (1..10).begin   #=> 1
  # 
  def begin
    `this._start`
  end
  
  # FIX: Incomplete
  def each
    `var start=this._start,end=this._end`
    `if(typeof(start)=='number'&&typeof(end)=='number'){if(!this._exclusive){end++;};for(var i=start;i<end;i++){#{yield `i`};};}`
    return self
  end
  
  # call-seq:
  #   rng.end  -> obj
  #   rng.last -> obj
  # 
  # Returns the object that defines the end of _rng_.
  # 
  #   (1..10).end     #=> 10
  #   (1...10).end    #=> 10
  # 
  def end()
    `this._end`
  end
  
  # call-seq:
  #   rng.exclude_end? -> true or false
  # 
  # Returns +true+ if _rng_ excludes its end value.
  # 
  def exclude_end?
    `this._exclusive`
  end
  
  # call-seq:
  #   rng.eql?(obj) -> true or false
  # 
  # Returns +true+ only if _obj_ is a +Range+, has equivalent beginning and
  # end items (by comparing them with <tt>eql?</tt>), and has the same
  # <tt>exclude_end?</tt> setting as _rng_.
  # 
  #   (0..2).eql?(0..2)             #=> true
  #   (0..2).eql? Range.new(0,2)    #=> true
  #   (0..2).eql?(0...2)            #=> false
  # 
  def eql?(object)
    `if(object.constructor!==c$Range){return false;}`
    `this._start.m$eqlBool(object._start)&&this._end.m$eqlBool(object._end)&&this._exclusive==object._exclusive`
  end
  
  # call-seq:
  #   rng.begin -> obj
  #   rng.first -> obj
  # 
  # Returns the first object in _rng_.
  # 
  #   (1..10).first   #=> 1
  # 
  def first
    `this._start`
  end
  
  # FIX: Incomplete
  def hash # :nodoc:
  end
  
  # call-seq:
  #   rng === obj       -> true or false
  #   rng.include?(obj) -> true or false
  #   rng.member?(obj)  -> true or false
  # 
  # Returns +true+ if _obj_ is an element of _rng_, +false+ otherwise.
  # 
  #   (1..10).include?(10)    #=> true
  #   (1...10).include?(10)   #=> false
  # 
  def include?(obj)
    `var s=#{obj <=> `this._start`},e=#{obj <=> `this._end`}`
    `s==0||s==1?(this._exclusive?e==-1:e==-1||e==0):false`
  end
  
  # call-seq:
  #   rng.inspect -> string
  # 
  # Converts _rng_ to a printable form (using +inspect+ to convert the start
  # and end objects).
  # 
  def inspect
    `$q(''+this._start.m$inspect()+(this._exclusive?'...':'..')+this._end.m$inspect())`
  end
  
  # call-seq:
  #   rng.end  -> obj
  #   rng.last -> obj
  # 
  # Returns the object that defines the end of _rng_.
  # 
  #   (1..10).last    #=> 10
  #   (1...10).last   #=> 10
  # 
  def last
    `this._end`
  end
  
  # call-seq:
  #   rng === obj       -> true or false
  #   rng.include?(obj) -> true or false
  #   rng.member?(obj)  -> true or false
  # 
  # Returns +true+ if _obj_ is an element of _rng_, +false+ otherwise.
  # 
  #   (1..10).member?(10)    #=> true
  #   (1...10).member?(10)   #=> false
  # 
  def member?(obj)
    `var s=#{obj <=> `this._start`},e=#{obj <=> `this._end`}`
    `s==0||s==1?(this._exclusive?e==-1:e==-1||e==0):false`
  end
  
  # FIX: Incomplete
  def step
  end
  
  # call-seq:
  #   rng.to_s -> string
  # 
  # Converts _rng_ to a printable form.
  # 
  def to_s
    `$q(''+this._start+(this._exclusive?'...':'..')+this._end)`
  end
end

# A +Regexp+ holds a regular expression, used to match a pattern against
# strings. Regexps are created using the <tt>/.../</tt> and <tt>%r{...}</tt>
# literals or the <tt>Regexp::new</tt> constructor.
# 
# In Red, as in Ruby, <tt>^</tt> and <tt>$</tt> always match before and after
# newlines -- this is the equivalent of JavaScript's _m_ flag being always
# turned on -- so matching at the start or the end of a string is accomplished
# using <tt>\A</tt> and <tt>\Z</tt>. Ruby's _m_ flag, the equivalent of an _s_
# flag in Perl ("dot matches newline"), is not supported by JavaScript; to
# match any character including newlines, use <tt>[\s\S]</tt> in place of dot
# (<tt>.</tt>). Red does not currently support the _x_ flag ("ignore
# whitespace and allow comments"), the _o_ flag ("evaluate regexp once"), or
# the _s_, _u_, _n_, and _e_ character-encoding flags.
# 
class Regexp
  IGNORECASE = 1
  EXTENDED   = 2
  MULTILINE  = 4
  
  # call-seq:
  #   Regexp.compile(string, ignore_case = false) -> regexp
  #   Regexp.compile(regexp)                      -> regexp
  #   Regexp.new(string, ignore_case = false)     -> regexp
  #   Regexp.new(regexp)                          -> regexp
  # 
  # Constructs a new regular expression from _pattern_, which can be either a
  # +String+ or a +Regexp+ (in which case that regexp's options are
  # propagated, and new options may not be specified). Red currently supports
  # only the _i_ option flag. (See class-level documentation for details.)
  # 
  #   r1 = Regexp.compile('^a-z+:\\s+\w+')    #=> /^a-z+:\s+\w+/
  #   r2 = Regexp.compile('cat', true)        #=> /cat/i
  #   r3 = Regexp.compile(r2)                 #=> /cat/i
  # 
  def self.compile(value,options)
    Regexp.new(value,options)
  end
  
  # call-seq:
  #   Regexp.escape(str) -> string
  #   Regexp.quote(str)  -> string
  # 
  # Escapes any characters that would have special meaning in a regular
  # expression. Returns a new escaped string, or _str_ if no characters are
  # escaped. For any string, <tt>Regexp.escape(str) =~ str</tt> will be true.
  # 
  #   Regexp.escape('\\*?{}.')   #=> \\\\\*\?\{\}\.
  # 
  def self.escape(str)
    `$q(str._value.replace(/([-.*+?^${}()|[\\]\\/\\\\])/g, '\\\\$1'))`
  end
  
  # FIX: Incomplete
  def self.last_match
  end
  
  # call-seq:
  #   Regexp.escape(str) -> string
  #   Regexp.quote(str)  -> string
  # 
  # Escapes any characters that would have special meaning in a regular
  # expression. Returns a new escaped string, or _str_ if no characters are
  # escaped. For any string, <tt>Regexp.quote(str) =~ str</tt> will be true.
  # 
  #   Regexp.quote('\\*?{}.')   #=> \\\\\*\?\{\}\.
  # 
  def self.quote(str)
    `str._value.replace(/([-.*+?^${}()|[\\]\\/\\\\])/g, '\\\\$1')`
  end
  
  # FIX: Incomplete
  def self.union
  end
  
  # call-seq:
  #   Regexp.compile(string, ignore_case = false) -> regexp
  #   Regexp.compile(regexp)                      -> regexp
  #   Regexp.new(string, ignore_case = false)     -> regexp
  #   Regexp.new(regexp)                          -> regexp
  # 
  # Constructs a new regular expression from _pattern_, which can be either a
  # +String+ or a +Regexp+ (in which case that regexp's options are
  # propagated, and new options may not be specified). Red currently supports
  # only the _i_ option flag. (See class-level documentation for details.)
  # 
  #   r1 = Regexp.new('^a-z+:\\s+\w+')            #=> /^a-z+:\s+\w+/
  #   r2 = Regexp.new('cat', true)                #=> /cat/i
  #   r3 = Regexp.new(r2)                         #=> /cat/i
  # 
  def initialize(regexp, options)
    `switch(options){case 0:this._options='';break;case 1:this._options='i';break;case 2:this._options='x';break;case 3:this._options='ix';break;case 4:this._options='s';break;case 5:this._options='si';break;case 6:this._options='sx';break;case 7:this._options='six';break;default:this._options=options?'i':'';}`
    `this._source=regexp._value||regexp`
    `this._value=new(RegExp)(this._source,'m'+(/i/.test(this._options)?'i':''))`
  end
  
  # call-seq:
  #   rxp == other    -> true or false
  #   rxp.eql?(other) -> true or false
  # 
  # Equality -- two regexps are equal if their patterns are identical and
  # their +IGNORECASE+ values are the same.
  # 
  #   /abc/ == /abc/    #=> true
  #   /abc/ == /abc/i   #=> false
  # 
  def ==(rxp)
    `this._source===rxp._source&&this._options===rxp._options`
  end
  
  # call-seq:
  #   rxp === str -> true or false
  # 
  # Case Equality -- synonym for <tt>Regexp#=~</tt> used in +case+ statements.
  # 
  #    case "HELLO"
  #      when /^[a-z]*$/ : puts "Lower case"
  #      when /^[A-Z]*$/ : puts "Upper case"
  #      else              puts "Mixed case"
  #    end
  # 
  # produces:
  # 
  #   Upper case
  # 
  # FIX: Incomplete
  def ===(string)
    `var c=$u,result=c$MatchData.m$new()`
    `if(!$T(c=string._value.match(this._value))){return nil;}`
    `for(var i=0,l=c.length;i<l;++i){result._captures[i]=$q(c[i])}`
    `result._string=string._value`
    return `result`
  end
  
  # call-seq:
  #   rxp =~ str     -> matchdata or nil
  #   rxp.match(str) -> matchdata or nil
  # 
  # Returns a +MatchData+ object describing the match, or +nil+ if there was
  # no match.
  # 
  #   (/(.)(.)(.)/ =~ "abc")[2]   #=> "b"
  # 
  # FIX: Incomplete
  def =~(string)
    `var c=$u,result=c$MatchData.m$new()`
    `if(!$T(c=string._value.match(this._value))){return nil;}`
    `for(var i=0,l=c.length;i<l;++i){result._captures[i]=$q(c[i])}`
    `result._string=string._value`
    return `result`
  end
  
  # FIX: Incomplete
  def ~
  end
  
  # call-seq:
  #   rxp.casefold? -> true or false
  # 
  # Returns the status of the +IGNORECASE+ flag.
  # 
  def casefold?
    `/i/.test(this._options)`
  end
  
  # call-seq:
  #   rxp == other    -> true or false
  #   rxp.eql?(other) -> true or false
  # 
  # Equality -- two regexps are equal if their patterns are identical and
  # their +IGNORECASE+ values are the same.
  # 
  #   /abc/.eql? /abc/    #=> true
  #   /abc/.eql? /abc/i   #=> false
  # 
  def eql?(rxp)
    `this._source===rxp._source&&this._options===rxp._options`
  end
  
  def hash # :nodoc:
  end
  
  # call-seq:
  #   rxp.inspect -> string
  # 
  # Returns a representation of _rxp_ as a +Regexp+ literal.
  #
  #   /ab+c/i.inspect   #=> /ab+c/i
  #
  def inspect
    `$q(''+this)`
  end
  
  # call-seq:
  #   rxp =~ str     -> matchdata or nil
  #   rxp.match(str) -> matchdata or nil
  # 
  # Returns a +MatchData+ object describing the match, or +nil+ if there was
  # no match.
  # 
  #   /(.)(.)(.)/.match("abc")[2]   #=> "b"
  # 
  def match(string)
    `var c=$u,result=c$MatchData.m$new()`
    `if(!$T(c=string._value.match(this._value))){return nil;}`
    `for(var i=0,l=c.length;i<l;++i){result._captures[i]=$q(c[i])}`
    `result._string=string._value`
    `result._pre=RegExp.leftContext`
    `result._post=RegExp.rightContext`
    return `result`
  end
  
  # call-seq:
  #   rxp.options -> num
  # 
  # Returns the set of bits corresponding to the options used when creating
  # this +Regexp+. Red currently supports only the _i_ option flag. (See
  # <tt>Regexp::new</tt> for details.)
  # 
  #   Regexp::IGNORECASE                #=> 1
  #   Regexp::EXTENDED                  #=> 2
  #   Regexp::MULTILINE                 #=> 4
  #   
  #   /cat/.options                     #=> 0
  #   /cat/i.options                    #=> 1
  #   Regexp.new('cat', true).options   #=> 1
  #   
  #   r = /cat/i
  #   Regexp.new(r.source, r.options)   #=> /cat/i
  # 
  def options
    `var result=0`
    `if(/i/.test(this._options)){result+=1}`
    `if(/x/.test(this._options)){result+=2}`
    `if(/s/.test(this._options)){result+=4}`
    return `result`
  end
  
  # call-seq:
  #   rxp.source -> str
  # 
  # Returns the original string of the pattern.
  # 
  #   /ab+c/i.source   #=> "ab+c"
  # 
  def source
    `$q(this._source)`
  end
  
  # call-seq:
  #   rxp.to_s -> str
  # 
  # Returns a string containing the regular expression and its options (using
  # the <tt>(?xxx:yyy)</tt> notation. <tt>Regexp#inspect</tt> produces a
  # generally more readable version of _rxp_.
  # 
  #   /ab+c/i.to_s   #=> "(?i-mx:ab+c)"
  # 
  def to_s
    `var o=this._options.replace('s','m'),c=o.match(/(m)?(i)?(x)?/)`
    `$q('(?'+o+(c[0]=='mix'?'':'-')+(c[1]?'':'m')+(c[2]?'':'i')+(c[3]?'':'x')+':'+this._source+')')`
  end
end

# A +String+ object holds and manipulates an arbitrary sequence of bytes,
# typically representing characters. +String+ objects may be created using
# <tt>String::new</tt> or as literals. Typically, methods with names ending in
# "<tt>!</tt>" modify their receiver, while those without a "<tt>!</tt>"
# return a new +String+.
# 
class String
  # call-seq:
  #   String.new(str = '') -> string
  # 
  # Returns a new string object containing a copy of _str_.
  # 
  def initialize(string = `''`)
    `this._value=string._value||string`
  end
  
  # call-seq:
  #   str % arg -> string
  # 
  # Format -- uses _str_ as a format specification, and returns the result of
  # applying it to _arg_. If the format specification contains more than one
  # substitution, then _arg_ must be an +Array+ containing the values to be
  # substituted. See <tt>Kernel::sprintf</tt> for details of the format
  # string.
  # 
  #   "%05d" % 123                        #=> "00123"
  #   "%s: %08x" % ['ID', self.__id__]    #=> "ID: 200e14d6"
  # 
  def %(arg)
    `arg.m$class()==c$Array?arg.unshift(this):arg=[this,arg]`
    `m$sprintf.apply(null,arg)`
  end
  
  # call-seq:
  #   str * num -> string
  # 
  # Copy -- returns a new string containing _num_ copies of _str_.
  # 
  #   'abc ' * 3    #=> "abc abc abc "
  # 
  def *(n)
    `for(var i=0,str=this._value,result='';i<n;++i){result+=str;}`
    return `$q(result)`
  end
  
  # call-seq:
  #   str + other -> string
  # 
  # Concatenation -- returns a new string containing _other_ concatenated to
  # _str_.
  # 
  #   'abc' + 'def'   #=> 'abcdef'
  # 
  def +(str)
    `$q(this._value + str._value)`
  end
  
  # call-seq:
  #   str << num      -> str
  #   str << obj      -> str
  #   str.concat(num) -> str
  #   str.concat(obj) -> str
  # 
  # Append -- concatenates the given object to _str_. If the object is an
  # integer between 0 and 255, it is converted to a character before
  # concatenation.
  # 
  #    s = 'abc'
  #    
  #    s << 'def'         #=> "abcdef"
  #    s << 103 << 104    #=> "abcdefgh"
  # 
  def <<(obj)
    `this._value+=(typeof(obj)=='number'?String.fromCharCode(obj):obj._value)`
    return self
  end
  
  # call-seq:
  #   str <=> other -> -1, 0, 1
  # 
  # Comparison -- returns -1 if _other_ is less than, 0 if _other_ is equal
  # to, and 1 if _other_ is greater than _str_. If the strings are of
  # different lengths, and the strings are equal when compared up to the
  # shortest length, then the longer string is considered greater than the
  # shorter one.
  # 
  # <tt><=></tt> is the basis for the methods <tt><</tt>, <tt><=</tt>,
  # <tt>></tt>, <tt>>=</tt>, and <tt>between?</tt>, included from module
  # +Comparable+. The method <tt>String#==</tt> does not use
  # <tt>Comparable#==</tt>.
  # 
  #    'abcdef' <=> 'abcde'     #=> 1
  #    'abcdef' <=> 'abcdef'    #=> 0
  #    'abcdef' <=> 'abcdefg'   #=> -1
  #    'abcdef' <=> 'ABCDEF'    #=> 1
  # 
  def <=>(str)
    `if(str.m$class()!=c$String){return nil;}`
    `var tv=this._value,sv=str._value`
    `if(tv>sv){return 1;}`
    `if(tv==sv){return 0;}`
    `if(tv<sv){return -1;}`
    return nil
  end
  
  # call-seq:
  #   str == other -> true or false
  # 
  # Equality -- if _other_ is not a +String+, returns false. Otherwise,
  # returns +true+ if <tt>str <=> obj</tt> returns zero.
  # 
  def ==(str)
    `if(str.m$class()!=c$String){return false;}`
    return `this.m$_ltgt(str)==0`
  end
  
  # FIX: Incomplete
  def =~(str)
  end
  
  # call-seq:
  #   str[num]               -> integer or nil
  #   str[num, num]          -> string or nil
  #   str[range]             -> string or nil
  #   str[regexp]            -> string or nil
  #   str[regexp, num]       -> string or nil
  #   str[other]             -> string or nil
  #   str.slice(num)         -> integer or nil
  #   str.slice(num, num)    -> string or nil
  #   str.slice(range)       -> string or nil
  #   str.slice(regexp)      -> string or nil
  #   str.slice(regexp, num) -> string or nil
  #   str.slice(other)       -> string or nil
  # 
  # FIX: Incomplete
  def []
  end
  
  # call-seq:
  #   str[num] = num            -> num
  #   str[num] = string         -> string
  #   str[num, num] = string    -> string
  #   str[range] = string       -> string
  #   str[regexp] = string      -> string
  #   str[regexp, num] = string -> string
  #   str[other] = string       -> string
  # 
  # FIX: Incomplete
  def []=
  end
  
  # call-seq:
  #   str.capitalize -> string
  # 
  # Returns a copy of _str_ with the first character converted to uppercase
  # and the remainder to lowercase.
  # 
  #   'abcdef'.capitalize   #=> "Abcdef"
  #   'ABCDEF'.capitalize   #=> "Abcdef"
  #   '123ABC'.capitalize   #=> "123abc"
  # 
  def capitalize
    `var v=this._value`
    `$q(v.slice(0,1).toUpperCase()+v.slice(1,v.length).toLowerCase())`
  end
  
  # call-seq:
  #   str.capitalize! -> str or nil
  # 
  # Returns _str_ with the first character converted to uppercase and the
  # remainder to lowercase, or +nil+ if no changes were made.
  # 
  #   s = 'abcdef'
  #   
  #   s.capitalize!   #=> "Abcdef"
  #   s.capitalize!   #=> nil
  #   s               #=> "Abcdef"
  # 
  def capitalize!
    `var v=this._value`
    `this._value=v.slice(0,1).toUpperCase()+v.slice(1,v.length).toLowerCase()`
    return `v==this._value?nil:this`
  end
  
  # call-seq:
  #   str.casecmp(other) -> -1, 0, 1
  # 
  # Case-insensitive version of <tt>String#<=></tt>.
  # 
  #   'abcdef'.casecmp('abcde')     #=> 1
  #   'aBcDeF'.casecmp('abcdef')    #=> 0
  #   'abcdef'.casecmp('abcdefg')   #=> -1
  #   'abcdef'.casecmp('ABCDEF')    #=> 0
  # 
  def casecmp(str)
    `if(str.m$class()!=c$String){return nil;}`
    `var tv=this._value.toLowerCase(),sv=str._value.toLowerCase()`
    `if(tv>sv){return 1;}`
    `if(tv==sv){return 0;}`
    `if(tv<sv){return -1;}`
    return nil
  end
  
  # FIX: Incomplete
  def center
  end
  
  # FIX: Incomplete
  def chomp
  end
  
  # FIX: Incomplete
  def chomp!
  end
  
  # FIX: Incomplete
  def chop
  end
  
  # FIX: Incomplete
  def chop!
  end
  
  # call-seq:
  #   str << num      -> str
  #   str << obj      -> str
  #   str.concat(num) -> str
  #   str.concat(obj) -> str
  # 
  # Append -- concatenates the given object to _str_. If the object is an
  # integer between 0 and 255, it is converted to a character before
  # concatenation.
  # 
  #    a = 'abc'
  #    
  #    a.concat('def')              #=> "abcdef"
  #    a.concat(103).concat(104)    #=> "abcdefgh"
  # 
  def concat(obj)
    `this._value+=(typeof(obj)=='number'?String.fromCharCode(obj):obj._value)`
    return self
  end
  
  # FIX: Incomplete
  def count
  end
  
  # FIX: Incomplete
  def crypt
  end
  
  # FIX: Incomplete
  def delete
  end
  
  # FIX: Incomplete
  def delete!
  end
  
  # call-seq:
  #   str.downcase -> string
  # 
  # Returns a copy of _str_ with all uppercase letters replaced with their
  # lowercase counterparts.
  # 
  #   'aBCDEf'.downcase   #=> "abcdef"
  # 
  def downcase
    `$q(this._value.toLowerCase())`
  end
  
  # call-seq:
  #   str.downcase! -> str or nil
  # 
  # Returns _str_ with all uppercase letters replaced with their lowercase
  # counterparts, or +nil+ if no changes were made.
  # 
  #   s = 'aBCDEf'
  #   
  #   s.downcase!   #=> "abcdef"
  #   s.downcase!   #=> nil
  #   s             #=> "abcdef"
  # 
  def downcase!
    `var v=this._value`
    `this._value=v.toLowerCase()`
    return `v==this._value?nil:this`
  end
  
  # FIX: Incomplete
  def each
  end
  
  # FIX: Incomplete
  def each_byte
  end
  
  # FIX: Incomplete
  def each_line
  end
  
  # call-seq:
  #   str.empty? -> true or false
  # 
  # Returns +true+ if _str_ has a length of zero.
  # 
  #   'abcdef'.empty?   #=> false
  #   ''.empty?         #=> true
  # 
  def empty?
    `this._value==''`
  end
  
  # call-seq:
  #   str.eql?(other) -> true or false
  # 
  # Two strings are equal if they have the same length and content.
  # 
  def eql?(str)
    `if(str.m$class()!=c$String){return false;}`
    `this._value==str._value`
  end
  
  # FIX: Incomplete
  def gsub
  end
  
  # FIX: Incomplete
  def gsub!
  end
  
  def hash # :nodoc:
    `'q_'+this._value`
  end
  
  # call-seq:
  #   str.hex -> num
  # 
  # Treats leading characters from _str_ as a string of hexadecimal digits
  # (with an optional sign and an optional 0x) and returns the corresponding
  # number. Zero is returned on error.
  # 
  #   '0x0a'.hex      #=> 10
  #   '-1234'.hex     #=> -4660
  #   '0'.hex         #=> 0
  #   'abcdef'.hex    #=> 0
  # 
  def hex
    `var result=parseInt(this._value,16)`
    return `result.toString()=='NaN'?0:result`
  end
  
  # call-seq:
  #   str.include?(other) -> true or false
  #   str.include?(num)   -> true or false
  # 
  # Returns +true+ if _str_ contains the given string or character.
  # 
  #   'abcdef'.include?('bc')   #=> true
  #   'abcdef'.include?('xy')   #=> false
  #   'abcdef'.include?(?c)     #=> true
  # 
  def include?(obj)
    `new(RegExp)(typeof(obj)=='number'?String.fromCharCode(obj):obj._value.replace(/([-.*+?^${}()|[\\]\\/\\\\])/g, '\\\\$1')).test(this._value)`
  end
  
  # FIX: Incomplete
  def index
  end
  
  # FIX: Incomplete
  def insert
  end
  
  # FIX: Incomplete
  def inspect
    `$q('"'+this._value.replace(/\\\\/g,'\\\\\\\\').replace(/"/g,'\\\\"')+'"')`
  end
  
  # call-seq:
  #   str.intern -> symbol
  #   str.to_sym -> symbol
  # 
  # Returns the +Symbol+ corresponding to _str_, creating the symbol if it did
  # not previously exist. See also <tt>Symbol#id2name</tt>.
  # 
  #   'abcdef'.intern   #=> :abcdef
  # 
  def intern
    `$s(this._value)`
  end
  
  # call-seq:
  #   str.length -> integer
  #   str.size   -> integer
  # 
  # Returns the number of characters in _str_.
  # 
  #   'abcdef'.length   #=> 6
  #   'ab\ncd'.length   #=> 5
  # 
  def length
    `this._value.length`
  end
  
  # FIX: Incomplete
  def ljust
  end
  
  # call-seq:
  #   str.lstrip -> string
  # 
  # Returns a copy of _str_ with leading whitespace removed.
  # 
  #   '  abcdef'.lstrip   #=> "abcdef"
  #   '\tabcdef'.lstrip   #=> "abcdef"
  # 
  def lstrip
    `$q(this._value.replace(/^\\s*/,''))`
  end
  
  # call-seq:
  #   str.lstrip! -> str
  # 
  # Returns _str_ with leading whitespace removed, or +nil+ if no changes were
  # made.
  # 
  #   s = '    abcdef'
  #   
  #   s.lstrip!   #=> "abcdef"
  #   s.lstrip!   #=> nil
  #   s           #=> "abcdef"
  # 
  def lstrip!
    `var v=this._value`
    `this._value=v.replace(/^\\s*/,'')`
    return `this._value==v?nil:this`
  end
  
  # call-seq:
  #   str.match(pattern) -> matchdata or nil
  # 
  # Converts pattern to a +Regexp+ (if it isn't already one), then invokes its
  # match method on _str_.
  # 
  #   'abcdee'.match('(.)\1')       #=> #<MatchData:120>
  #   'abcdee'.match('(.)\1')[0]    #=> "ee"
  #   'abcdee'.match(/(.)\1/)[0]    #=> "ee"
  #   'abcdee'.match('xx')          #=> nil
  # 
  def match(pattern)
    `$r(pattern._source||pattern._value,pattern._options).m$match(this)`
  end
  
  # call-seq:
  #   str.next -> string
  #   str.succ -> string
  # 
  # Returns the successor to _str_. The successor is calculated by
  # incrementing characters starting from the rightmost alphanumeric (or the
  # rightmost character if there are no alphanumerics) in the string.
  # Incrementing a digit always results in another digit, and incrementing a
  # letter results in another letter of the same case.
  # 
  # If the increment generates a "carry," the character to the left is also
  # incremented. This process repeats until there is no carry, adding an
  # additional character of the same type as the leftmost alphanumeric, if
  # necessary.
  # 
  #   'abcdef'.next     #=> 'abcdeg'
  #   '<<kit9>>'.next   #=> '<<kit10>>'
  #   '1999zzz'.next    #=> '2000aaa'
  #   'ZZZ9999'.next    #=> 'AAAA0000'
  # 
  def next
    `var v=this._value`
    `if(!/[a-zA-Z0-9]/.test(v)){return $q(v);}`
    `if(/^\\d+$/.test(v)){return $q(''+(+v+1))}`
    `for(var i=v.length-1,carry=i>=0,result='';i>=0;--i){var c=v[i],lc=/[a-z]/.test(c),uc=/[A-Z]/.test(c),n=/[0-9]/.test(c);if($T(carry)&&(lc||uc||n)){if(lc||uc){if(c=='z'||c=='Z'){result=(lc?'a':'A')+result;carry=i;}else{result=String.fromCharCode(c.charCodeAt()+1)+result;carry=false;};}else{if(c=='9'){result='0'+result;carry=i}else{result=''+(+c+1)+result;carry=false;};};}else{result=c+result;};}`
    `if($T(carry)){var c=v[carry],insert=/[a-z]/.test(c)?'a':(/[A-Z]/.test(c)?'A':'1');result=result.slice(0,carry)+insert+result.slice(carry,result.length);}`
    return `$q(result)`
  end
  
  # call-seq:
  #   str.next! -> str
  #   str.succ! -> str
  # 
  # Returns _str_ with its contents replaced by its successor. See
  # <tt>String#next</tt> for details.
  # 
  def next!
    `var v=this._value`
    `if(!/[a-zA-Z0-9]/.test(v)){return $q(v);}`
    `if(/^\\d+$/.test(v)){return $q(''+(+v+1))}`
    `for(var i=v.length-1,carry=i>=0,result='';i>=0;--i){var c=v[i],lc=/[a-z]/.test(c),uc=/[A-Z]/.test(c),n=/[0-9]/.test(c);if($T(carry)&&(lc||uc||n)){if(lc||uc){if(c=='z'||c=='Z'){result=(lc?'a':'A')+result;carry=i;}else{result=String.fromCharCode(c.charCodeAt()+1)+result;carry=false;};}else{if(c=='9'){result='0'+result;carry=i}else{result=''+(+c+1)+result;carry=false;};};}else{result=c+result;};}`
    `if($T(carry)){var c=v[carry],insert=/[a-z]/.test(c)?'a':(/[A-Z]/.test(c)?'A':'1');result=result.slice(0,carry)+insert+result.slice(carry,result.length);}`
    `this._value=result`
    return self
  end
  
  # call-seq:
  #   str.oct -> num
  # 
  # Treats leading characters from _str_ as a string of hexadecimal digits
  # (with an optional sign) and returns the corresponding number. Zero is
  # returned on error.
  # 
  #   '0123'.oct      #=> 83
  #   '-337'.hex      #=> -255
  #   '0'.hex         #=> 0
  #   'abcdef'.hex    #=> 0
  # 
  def oct
    `var result=parseInt(this._value,8)`
    return `result.toString()=='NaN'?0:result`
  end
  
  # call-seq:
  #   str.replace(other) -> str
  # 
  # Replaces the contents of _str_ with the contents of _other_.
  # 
  #   s = 'abc'
  #   
  #   s.replace('def')    #=> "def"
  #   s                   #=> "def"
  # 
  def replace(str)
    `this._value=str._value`
  end
  
  # call-seq:
  #   str.reverse -> string
  # 
  # Returns a new string with the characters from _str_ in reverse order.
  # 
  #   'abcdef'.reverse    #=> 'fedcba'
  # 
  def reverse
    `$q(this._value.split('').reverse().join(''))`
  end
  
  # call-seq:
  #   str.reverse! -> str
  # 
  # Returns _str_ with its characters reversed.
  # 
  #   s = 'abcdef'
  #   
  #   s.reverse!    #=> 'fedcba'
  #   s             #=> 'fedcba'
  # 
  def reverse!
    `this._value=this._value.split('').reverse().join('')`
    return self
  end
  
  # FIX: Incomplete
  def rindex
  end
  
  # FIX: Incomplete
  def rjust
  end
  
  # call-seq:
  #   str.rstrip -> string
  # 
  # Returns a copy of _str_ with trailing whitespace removed.
  # 
  #   'abcdef    '.rstrip   #=> "abcdef"
  #   'abcdef\r\n'.rstrip   #=> "abcdef"
  # 
  def rstrip
    `$q(this._value.replace(/\\s*$/,''))`
  end
  
  # call-seq:
  #   str.rstrip! -> str
  # 
  # Returns _str_ with trailing whitespace removed, or +nil+ if no changes
  # were made.
  # 
  #   s = 'abcdef    '
  #   
  #   s.rstrip!   #=> "abcdef"
  #   s.rstrip!   #=> nil
  #   s           #=> "abcdef"
  # 
  def rstrip!
    `var v=this._value`
    `this._value=v.replace(/\\s*$/,'')`
    return `this._value==v?nil:this`
  end
  
  # FIX: Incomplete
  def scan
  end
  
  # call-seq:
  #   str.length -> integer
  #   str.size   -> integer
  # 
  # Returns the number of characters in _str_.
  # 
  #   'abcdef'.size   #=> 6
  #   'ab\ncd'.size   #=> 5
  # 
  def size
    `this._value.length`
  end
  
  # call-seq:
  #   str[num]               -> integer or nil
  #   str[num, num]          -> string or nil
  #   str[range]             -> string or nil
  #   str[regexp]            -> string or nil
  #   str[regexp, num]       -> string or nil
  #   str[other]             -> string or nil
  #   str.slice(num)         -> integer or nil
  #   str.slice(num, num)    -> string or nil
  #   str.slice(range)       -> string or nil
  #   str.slice(regexp)      -> string or nil
  #   str.slice(regexp, num) -> string or nil
  #   str.slice(other)       -> string or nil
  # 
  # FIX: Incomplete
  def slice
  end
  
  # call-seq:
  #   str.slice!(num)      -> num or nil
  #   str.slice!(num, num) -> string or nil
  #   str.slice!(range)    -> string or nil
  #   str.slice!(regexp)   -> string or nil
  #   str.slice!(other)    -> string or nil
  # 
  # FIX: Incomplete
  def slice!
  end
  
  # FIX: Incomplete
  def split(pattern = /\s+/, limit = nil)
    `var a=this._value.split(pattern._value),result=[]`
    `for(var i=0,l=a.length;i<l;++i){result.push($q(a[i]));}`
    return `result`
  end
  
  # FIX: Incomplete
  def squeeze
  end
  
  # call-seq:
  #   str.strip -> string
  # 
  # Returns a copy of _str_ with leading and trailing whitespace removed.
  # 
  #   '   abcdef   '.strip    #=> "abcdef"
  #   '\tabcdef\r\n'.strip    #=> "abcdef"
  # 
  def strip
    `$q(this._value.replace(/^\\s*|\\s*$/,''))`
  end
  
  # call-seq:
  #   str.strip! -> str
  # 
  # Returns _str_ with leading and trailing whitespace removed, or +nil+ if no
  # changes were made.
  # 
  #   s = '   abcdef   '
  #   
  #   s.strip!    #=> "abcdef"
  #   s.strip!    #=> nil
  #   s           #=> "abcdef"
  # 
  def strip!
    `var v=this._value`
    `this._value=v.replace(/^\\s*|\\s*$/,'')`
    return `this._value==v?nil:this`
  end
  
  # FIX: Incomplete
  def sub
  end
  
  # FIX: Incomplete
  def sub!
  end
  
  # call-seq:
  #   str.next -> string
  #   str.succ -> string
  # 
  # Returns the successor to _str_. The successor is calculated by
  # incrementing characters starting from the rightmost alphanumeric (or the
  # rightmost character if there are no alphanumerics) in the string.
  # Incrementing a digit always results in another digit, and incrementing a
  # letter results in another letter of the same case.
  # 
  # If the increment generates a "carry," the character to the left is also
  # incremented. This process repeats until there is no carry, adding an
  # additional character of the same type as the leftmost alphanumeric, if
  # necessary.
  # 
  #   'abcdef'.succ     #=> 'abcdeg'
  #   '<<kit9>>'.succ   #=> '<<kit10>>'
  #   '1999zzz'.succ    #=> '2000aaa'
  #   'ZZZ9999'.succ    #=> 'AAAA0000'
  # 
  def succ
    `var v=this._value`
    `if(!/[a-zA-Z0-9]/.test(v)){return $q(v);}`
    `if(/^\\d+$/.test(v)){return $q(''+(+v+1))}`
    `for(var i=v.length-1,carry=i>=0,result='';i>=0;--i){var c=v[i],lc=/[a-z]/.test(c),uc=/[A-Z]/.test(c),n=/[0-9]/.test(c);if($T(carry)&&(lc||uc||n)){if(lc||uc){if(c=='z'||c=='Z'){result=(lc?'a':'A')+result;carry=i;}else{result=String.fromCharCode(c.charCodeAt()+1)+result;carry=false;};}else{if(c=='9'){result='0'+result;carry=i}else{result=''+(+c+1)+result;carry=false;};};}else{result=c+result;};}`
    `if($T(carry)){var c=v[carry],insert=/[a-z]/.test(c)?'a':(/[A-Z]/.test(c)?'A':'1');result=result.slice(0,carry)+insert+result.slice(carry,result.length);}`
    return `$q(result)`
  end
  
  # call-seq:
  #   str.next! -> str
  #   str.succ! -> str
  # 
  # Returns _str_ with its contents replaced by its successor. See
  # <tt>String#next</tt> for details.
  # 
  def succ!
    `var v=this._value`
    `if(!/[a-zA-Z0-9]/.test(v)){return $q(v);}`
    `if(/^\\d+$/.test(v)){return $q(''+(+v+1))}`
    `for(var i=v.length-1,carry=i>=0,result='';i>=0;--i){var c=v[i],lc=/[a-z]/.test(c),uc=/[A-Z]/.test(c),n=/[0-9]/.test(c);if($T(carry)&&(lc||uc||n)){if(lc||uc){if(c=='z'||c=='Z'){result=(lc?'a':'A')+result;carry=i;}else{result=String.fromCharCode(c.charCodeAt()+1)+result;carry=false;};}else{if(c=='9'){result='0'+result;carry=i}else{result=''+(+c+1)+result;carry=false;};};}else{result=c+result;};}`
    `if($T(carry)){var c=v[carry],insert=/[a-z]/.test(c)?'a':(/[A-Z]/.test(c)?'A':'1');result=result.slice(0,carry)+insert+result.slice(carry,result.length);}`
    `this._value=result`
    return self
  end
  
  # FIX: Incomplete
  def sum
  end
  
  # call-seq:
  #   str.swapcase -> string
  # 
  # Returns a copy of _str_ with uppercase alphabetic characters converted to
  # lowercase and lowercase characters converted to uppercase.
  # 
  #   'aBc123'.swapcase   #=> "AbC123"
  # 
  def swapcase
    `$q(this._value.replace(/([a-z]+)|([A-Z]+)/g,function($0,$1,$2){return $1?$0.toUpperCase():$0.toLowerCase();}))`
  end
  
  # call-seq:
  #   str.swapcase! -> str or nil
  # 
  # Returns _str_ with its uppercase alphabetic characters converted to
  # lowercase and its lowercase characters converted to uppercase, or +nil+ if
  # no changes were made.
  # 
  #   s1 = 'abcDEF'
  #   s2 = '123'
  #   
  #   s1.swapcase!    #=> "ABCdef"
  #   s2.swapcase!    #=> nil
  #   s1              #=> "ABCdef"
  #   s2              #=> "123"
  # 
  def swapcase!
    `var v=this._value`
    `this._value=v.replace(/([a-z]+)|([A-Z]+)/g,function($0,$1,$2){return $1?$0.toUpperCase():$0.toLowerCase();})`
    return `this._value==v?nil:this`
  end
  
  # call-seq:
  #   str.to_f -> float
  # 
  # Returns the result of interpreting leading characters in _str_ as a
  # floating point number, or 0 if there is not a valid number at the start of
  # _str_.
  # 
  #   '1.2345e3'.to_f       #=> 1234.5
  #   '98.6 degrees'.to_f   #=> 98.6
  #   'abc123'.to_f         #=> 0
  # 
  def to_f
    `var result=parseFloat(this)`
    return `result.toString()=='NaN'?0:result`
  end
  
  # call-seq:
  #   str.to_i -> integer
  # 
  # Returns the result of interpreting leading characters in _str_ as an
  # integer of base _base_, or 0 if there is not a valid number at the start
  # of _str_.
  # 
  #   '12345'.to_i          #=> 12345
  #   '76 trombones'.to_i   #=> 76
  #   '0a'.to_i             #=> 0
  #   '0a'.to_i(16)         #=> 10
  #   'abcdef'.to_i         #=> 0
  #   '1100101'.to_i(2)     #=> 101
  #   '1100101'.to_i(8)     #=> 294977
  #   '1100101'.to_i(10)    #=> 1100101
  #   '1100101'.to_i(16)    #=> 17826049
  # 
  def to_i(base = 10)
    `var result=parseInt(this,base)`
    return `result.toString()=='NaN'?0:result`
  end
  
  # call-seq:
  #   str.to_s   -> str
  #   str.to_str -> str
  # 
  # Returns _str_.
  # 
  def to_s
    return self
  end
  
  # call-seq:
  #   str.to_s   -> str
  #   str.to_str -> str
  # 
  # Returns _str_.
  # 
  def to_str
    return self
  end
  
  # call-seq:
  #   str.intern -> symbol
  #   str.to_sym -> symbol
  # 
  # Returns the +Symbol+ corresponding to _str_, creating the symbol if it did
  # not previously exist. See also <tt>Symbol#id2name</tt>.
  # 
  #   'abcdef'.to_sym   #=> :abcdef
  # 
  def to_sym
    `$s(this._value)`
  end
  
  # FIX: Incomplete
  def tr
  end
  
  # FIX: Incomplete
  def tr!
  end
  
  # FIX: Incomplete
  def tr_s
  end
  
  # FIX: Incomplete
  def tr_s!
  end
  
  # call-seq:
  #   str.upcase -> string
  # 
  # Returns a copy of _str_ with all lowercase letters replaced with their
  # uppercase counterparts.
  # 
  #   'aBCDEf'.upcase   #=> "ABCDEF"
  # 
  def upcase
    `$q(this._value.toUpperCase())`
  end
  
  # call-seq:
  #   str.upcase! -> str or nil
  # 
  # Returns _str_ with all lowercase letters replaced with their uppercase
  # counterparts, or +nil+ if no changes were made.
  # 
  #   s = 'aBCDEf'
  #   
  #   s.upcase!   #=> "ABCDEF"
  #   s.upcase!   #=> nil
  #   s           #=> "ABCDEF"
  # 
  def upcase!
    `var v=this._value`
    `this._value=v.toUpperCase()`
    return `v==this._value?nil:this`
  end
  
  # FIX: Incomplete
  def upto(str,&block)
  end
end

# +Symbol+ objects represent names and some strings inside the Red
# interpreter. They are generated using the <tt>:name</tt> and
# <tt>:"string"</tt> literals syntax, and by the various +to_sym+ methods. The
# same +Symbol+ object will be created for a given name or string for the
# duration of an application's execution, regardless of the context or meaning
# of that name. Thus if +Foo+ is a constant in one context, a method in
# another, and a class in a third, the +Symbol+ <tt>:Foo</tt> will be the same
# object in all three contexts.
# 
#   module One
#     class Foo
#     end
#     $f1 = :Foo
#   end
#   
#   module Two
#     Foo = 1
#     $f2 = :Foo
#   end
#   
#   def Foo
#   end
#   $f3 = :Foo
#   
#   $f1.object_id   #=> 4190
#   $f2.object_id   #=> 4190
#   $f3.object_id   #=> 4190
# 
class Symbol
  # call-seq:
  #   Symbol.all_symbols -> array
  # 
  # Returns an array of all the symbols currently in Red's symbol table.
  # 
  def self.all_symbols
    `var result=[]`
    `for(var x in c$Symbol._table){if(c$Symbol._table[x].m$class()==c$Symbol){result.push(c$Symbol._table[x]);}}`
    return `result`
  end
  
  def initialize(value) # :nodoc:
    `this._value=value`
    `c$Symbol._table[value]=this`
  end
  
  def hash # :nodoc:
    `'s_'+this._value`
  end
  
  # call-seq:
  #   sym.id2name -> string
  #   sym.to_s    -> string
  # 
  # Returns the name or string corresponding to _sym_.
  # 
  #   :foo.id2name    #=> "foo"
  # 
  def id2name
    `$q(this._value)`
  end
  
  # call-seq:
  #   sym.inspect -> string
  # 
  # Returns the representation of _sym_ as a symbol literal.
  # 
  #   :foo.inspect    #=> ":foo"
  # 
  def inspect
    `$q(''+this)`
  end
  
  # call-seq:
  #   sym.to_i -> fixnum
  # 
  # Returns an integer that is unique for each symbol within a particular
  # execution of a program.
  # 
  #   :foo.to_i   #=> 2019
  # 
  def to_i
    `this.__id__`
  end
  
  # call-seq:
  #   sym.id2name -> string
  #   sym.to_s    -> string
  # 
  # Returns the name or string corresponding to _sym_.
  # 
  #   :foo.to_s   #=> "foo"
  # 
  def to_s
    `$q(this._value)`
  end
  
  # call-seq:
  #   sym.to_sym -> sym
  # 
  # In general, <tt>to_sym</tt> returns the +Symbol+ corresponding to an
  # object. As _sym_ is already a symbol, +self+ is returned in this case.
  # 
  def to_sym
    return self
  end
  
  `c$Symbol._table=new(Object)`
  
  undef dup
  undef clone
end

# Time
# 
class Time
  # call-seq:
  #   Time.at(a_time)                   -> time
  #   Time.at(seconds [, microseconds]) -> time
  # 
  # Creates a new time object with the value given by <i>a_time</i>, or the
  # given number of _seconds_ (and optional _milliseconds_) from epoch. A
  # non-portable feature allows the offset to be negative on some systems.
  # 
  #   Time.at(0)            #=> Wed Dec 31 1969 19:00:00 GMT-0500 (EST)
  #   Time.at(946702800)    #=> Sat Jan 01 2000 00:00:00 GMT-0500 (EST)
  #   Time.at(-284061600)   #=> Sat Dec 31 1960 01:00:00 GMT-0500 (EST)
  # 
  def self.at(seconds,milliseconds)
    `var t=c$Time.m$new()`
    `t._value=typeof(seconds)=='number'?new(Date)(seconds*1000+(milliseconds||0)):seconds._value`
    return `t`
  end
  
  # call-seq:
  #   Time.new -> time
  #   Time.now -> time
  # 
  # Returns a Time object initialized to the current system time. The object
  # created will include fractional seconds to the thousandths place.
  # 
  #   t1 = Time.now   #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t2 = Time.now   #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t1 == t2        #=> false
  #   t1.to_f         #=> 1222222222.989
  #   t2.to_f         #=> 1222222222.991
  # 
  def self.now
    Time.new
  end
  
  # call-seq:
  #   Time.new -> time
  #   Time.now -> time
  # 
  # Returns a Time object initialized to the current system time. The object
  # created will include fractional seconds to the thousandths place.
  # 
  #   t1 = Time.new   #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t2 = Time.new   #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t1 == t2        #=> false
  #   t1.to_f         #=> 1222222222.989
  #   t2.to_f         #=> 1222222222.991
  # 
  def initialize
    `this._value=new(Date)`
  end
  
  # call-seq:
  #   time + numeric -> time
  # 
  # Addition -- adds some number of seconds (possibly fractional) to _time_
  # and returns that value as a new time.
  # 
  #   t = Time.now         #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t + (60 * 60 * 24)   #=> Wed Sep 24 2008 22:10:22 GMT-0400 (EDT)
  # 
  def +(numeric)
    `var t=c$Time.m$new()`
    `t._value=new(Date)(numeric*1000+this._value.valueOf())`
    return `t`
  end
  
  # call-seq:
  #   time - other   -> float
  #   time - numeric -> time
  # 
  # Difference -- returns a new time that represents the difference between
  # two times, or subtracts the given number of seconds in _numeric_ from
  # _time_.
  #
  #   t = Time.now       #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t2 = t + 2592000   #=> Thu Oct 23 2008 22:10:22 GMT-0400 (EDT)
  #   t2 - t             #=> 2592000.0
  #   t2 - 2592000       #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  # 
  def -(time)
    `typeof(time)=='number'?new(Date)(this._value.valueOf()-(time*1000)):(this._value.valueOf()-time._value.valueOf())/1000`
  end
  
  # call-seq:
  #   time <=> other   -> -1, 0, 1
  #   time <=> numeric -> -1, 0, 1
  # 
  # Comparison -- compares _time_ with _other_ or with _numeric_, which is the
  # number of seconds (possibly fractional) since epoch.
  # 
  #   t1 = Time.now       #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t2 = t1 + 2592000   #=> Thu Oct 23 2008 22:10:22 GMT-0400 (EDT)
  #   t1 <=> t2           #=> -1
  #   t2 <=> t1           #=> 1
  #   t1 <=> t1           #=> 0
  # 
  def <=>(time)
    `var v=this._value.valueOf(),ms=typeof(time)=='number'?time*1000:time._value.valueOf()`
    `if(v<ms){return -1;}`
    `if(v==ms){return 0;}`
    `if(v>ms){return 1;}`
    return nil
  end
  
  # call-seq:
  #   time.day  -> integer
  #   time.mday -> integer
  # 
  # Returns the day of the month (1..n) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.day           #=> 23
  # 
  def day
    `this._value.getDate()`
  end
  
  # FIX: Incomplete
  def dst?
  end
  
  # call-seq:
  #   time.eql?(other) -> true or false
  # 
  # Return +true+ if _time_ and _other_ are both +Time+ objects with the same
  # seconds and fractional seconds.
  # 
  def eql?(time)
    `if(time.constructor!=c$Time){return false;}`
    `this._value.valueOf()==time._value.valueOf()`
  end
  
  # FIX: Incomplete
  def getgm
  end
  
  # FIX: Incomplete
  def getlocal
  end
  
  # FIX: Incomplete
  def getutc
  end
  
  # FIX: Incomplete
  def gmt?
  end
  
  # call-seq:
  #   time.gmt_offset -> integer
  #   time.gmtoff     -> integer
  #   time.utc_offset -> integer
  # 
  # Returns the offset in seconds between the timezone of _time_ and UTC.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.gmt_offset    #=> -14400
  # 
  def gmt_offset
    `this._value.getTimezoneOffset() * -60`
  end
  
  # FIX: Incomplete
  def gmtime
  end
  
  # call-seq:
  #   time.gmt_offset -> integer
  #   time.gmtoff     -> integer
  #   time.utc_offset -> integer
  # 
  # Returns the offset in seconds between the timezone of _time_ and UTC.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.gmtoff        #=> -14400
  # 
  def gmtoff
    `this._value.getTimezoneOffset() * -60`
  end
  
  def hash # :nodoc:
    `'t_'+this._value.valueOf()/1000`
  end
  
  # call-seq:
  #   time.hour -> integer
  # 
  # Returns the hour of the day (0..23) for _time_.
  # 
  #    t = Time.now   #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #    t.hour         #=> 22
  # 
  def hour
    `this._value.getHours()`
  end
  
  # call-seq:
  #   time.inspect -> string
  #   time.to_s    -> string
  # 
  # Returns a string representing _time_.
  # 
  #   Time.now.inspect    #=> "Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)"
  # 
  def inspect
    `$q(''+this)`
  end
  
  # FIX: Incomplete
  def isdst
  end
  
  # FIX: Incomplete
  def localtime
  end
  
  # call-seq:
  #   time.day  -> integer
  #   time.mday -> integer
  # 
  # Returns the day of the month (1..n) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.mday          #=> 23
  # 
  def mday
    `this._value.getDate()`
  end
  
  # call-seq:
  #   time.min -> integer
  # 
  # Returns the minute of the hour (0..59) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.min           #=> 10
  # 
  def min
    `this._value.getMinutes()`
  end
  
  # call-seq:
  #   time.mon   -> integer
  #   time.month -> integer
  # 
  # Returns the month of the year (1..12) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.mon           #=> 9
  # 
  def mon
    `this._value.getMonth()`
  end
  
  # call-seq:
  #   time.mon   -> integer
  #   time.month -> integer
  # 
  # Returns the month of the year (1..12) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.month         #=> 9
  # 
  def month
    `this._value.getMonth()`
  end
  
  # call-seq:
  #   time.sec -> integer
  # 
  # Returns the second of the minute (0..59) for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.sec           #=> 22
  # 
  def sec
    `this._value.getSeconds()`
  end
  
  # FIX: Incomplete
  def strftime
  end
  
  # call-seq:
  #   time.succ -> new_time
  # 
  # Returns a new time object, one second later than _time_.
  # 
  def succ
    `var t=c$Time.m$new()`
    `t._value=new(Date)(1000+this._value.valueOf())`
    return `t`
  end
  
  # call-seq:
  #   time.to_a -> array
  # 
  # Returns a ten-element _array_ of values for _time_: <tt>[ sec, min, hour,
  # day, month, year, wday, yday, isdst, zone ]<tt/>. The ten elements can be
  # passed directly to <tt>Time::utc</tt> or <tt>Time::local</tt> to create a
  # new Time.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.to_a          #=> [22, 10, 22, 23, 9, 2008, 2, 267, true, "EDT"]
  # 
  # FIX: Incomplete
  def to_a
    []
  end
  
  # call-seq:
  #   time.to_f -> numeric
  # 
  # Returns the value of _time_ as a floating point number of seconds since
  # epoch.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.to_f          #=> 1222222222.989
  # 
  def to_f
    `this._value.valueOf()/1000`
  end
  
  # call-seq:
  #   time.to_i -> integer
  # 
  # Returns the value of _time_ as an integer number of seconds since epoch.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.to_i          #=> 1222222222
  # 
  def to_i
    `parseInt(this._value.valueOf()/1000)`
  end
  
  # call-seq:
  #   time.inspect -> string
  #   time.to_s    -> string
  # 
  # Returns a string representing _time_.
  # 
  #   Time.now.to_s   #=> "Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)"
  # 
  def to_s
    `$q(''+this._value)`
  end
  
  # call-seq:
  #   time.to_i -> integer
  # 
  # Returns the value of _time_ as an integer number of seconds since epoch.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.tv_sec        #=> 1222222222
  # 
  def tv_sec
    `parseInt(this._value.valueOf()/1000)`
  end
  
  # call-seq:
  #   time.tv_usec -> integer
  #   time.usec    -> integer
  # 
  # Returns just the number of microseconds for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.to_f          #=> 1222222222.989
  #   t.tv_usec       #=> 989000
  # 
  def tv_usec
    `parseInt(this._value.valueOf()/1000)`
  end
  
  # call-seq:
  #   time.tv_usec -> integer
  #   time.usec    -> integer
  # 
  # Returns just the number of microseconds for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.to_f          #=> 1222222222.989
  #   t.usec          #=> 989000
  # 
  def usec
    `var v = this._value.valueOf()`
    `(v*1000)-parseInt(v/1000)*1000000`
  end
  
  # FIX: Incomplete
  def utc
  end
  
  # FIX: Incomplete
  def utc?
  end
  
  # call-seq:
  #   time.gmt_offset -> integer
  #   time.gmtoff     -> integer
  #   time.utc_offset -> integer
  # 
  # Returns the offset in seconds between the timezone of _time_ and UTC.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.utc_offset    #=> -14400
  # 
  def utc_offset
    `this._value.getTimezoneOffset() * -60`
  end
  
  # call-seq:
  #   time.wday -> integer
  # 
  # Returns an integer representing the day of the week, 0..6, with Sunday == 0.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.wday          #=> 2
  # 
  def wday
    `this._value.getDay()`
  end
  
  # call-seq:
  #   time.yday -> integer
  # 
  # Returns an integer representing the day of the year, 1..366.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.yday          #=> 267
  # 
  def yday
    `var d2=new Date(),d1=new Date(new Date(new Date().setFullYear(d2.getFullYear(),0,0)).setHours(0,0,0,0))`
    `parseInt((d2-d1)/1000/60/60/24)`
  end
  
  # call-seq:
  #   time.year -> integer
  # 
  # Returns the four-digit year for _time_.
  # 
  #   t = Time.now    #=> Tue Sep 23 2008 22:10:22 GMT-0400 (EDT)
  #   t.year          #=> 2008
  # 
  def year
    `this._value.getFullYear()`
  end
  
  # FIX: Incomplete
  def zone
  end
end

# The global value +true+ is the only instance of class +TrueClass+ and
# represents a logically true value in boolean expressions. The class provides
# operators allowing +true+ to participate correctly in logical expressions.
# 
class TrueClass
  # call-seq:
  #   true & obj -> !!obj
  # 
  # And -- returns +false+ if _obj_ is +nil+ or +false+, +true+ otherwise.
  # 
  def &(object)
    `this.valueOf()&&$T(object)`
  end
  
  # call-seq:
  #   true | obj -> true
  # 
  # Or -- returns +true+. Because _obj_ is an argument to a method call, it is
  # always evaluated; there is no short-circuit evaluation.
  # 
  #   true |  a = "A assigned"    #=> true
  #   true || b = "B assigned"    #=> true
  #   [a, b].inspect              #=> ["A assigned", nil]
  #
  def |(object)
    `this.valueOf()||$T(object)`
  end
  
  # call-seq:
  #   true ^ obj -> !obj
  # 
  # Exclusive Or -- returns +true+ if _obj_ is +nil+ or +false+, +false+
  # otherwise.
  # 
  def ^(object)
    `this.valueOf()?!$T(object):$T(object)`
  end
  
  def hash # :nodoc:
    `'b_'+this.valueOf()`
  end
  
  def object_id # :nodoc:
    `this.valueOf()?2:0`
  end
  
  # call-seq:
  #   true.to_s -> "true"
  # 
  # The string representation of +true+ is "true".
  # 
  def to_s
    `$q(''+this)`
  end
  
  undef initialize
end
`

c$Exception.prototype.toString=function(){var class_name=this.m$class().__name__.replace(/\\./g,'::'),str=class_name+': '+(this._message||class_name);console.log(str+(this._stack!=null?'\\n        from '+this.m$backtrace().join('\\n        from '):''));return '#<'+str+'>';}
c$NilClass.prototype.toString=function(){return 'nil';};
c$Range.prototype.toString=function(){return ''+this._start+(this._exclusive?'...':'..')+this._end;};
c$Regexp.prototype.toString=function(){return '/'+this._source+'/'+(/s/.test(this._options)?'m':'')+(/i/.test(this._options)?'i':'')+(/x/.test(this._options)?'x':'');};
c$String.prototype.toString=function(){return this._value;};
c$Symbol.prototype.toString=function(){var v=this._value,str=/\\s/.test(v)?'"'+v+'"':v;return ':'+str ;};
c$Time.prototype.toString=function(){return ''+this._value;};

`
