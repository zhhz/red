= Turn your JavaScript <span style="color:rgb(195,0,0)">Red</span>.

<span style="color:rgb(195,0,0)">Red</span> is a Ruby-to-JavaScript transliterator built on <a href=http://rubyforge.org/projects/parsetree/>ParseTree</a>.

=== Installation

To get <span style="color:rgb(195,0,0)">Red</span> working, install the rubygem.
<pre>sudo gem install red</pre>

=== Creating <tt>.js</tt> Files

Create a new <tt>.red</tt> file and edit it using your text editor.
  $ mate example.red
  
  1| class Foo
  2|   def initialize(foo)
  3|     @foo = foo
  4|   end
  5| end

Use the command-line executable to convert your Ruby into JavaScript.

  $ red example
  #=> var Foo = function(foo) { this.foo = foo; }

<span style="color:rgb(195,0,0)">Red</span> creates a <tt>.js</tt> file containing the output.

  $ ls
  #=> example.js   example.red

=== Previewing your JavaScript output

If you want to see what JavaScript a snippet of Ruby code will produce without creating a <tt>.js</tt> file, use the special filename <tt>test.red</tt>.

  $ mate test.red
  
  1| return false unless navigator[:user_agent].index_of('AppleWebKit/') > -1
  
  $ red test
  #=> if (!(navigator.userAgent.indexOf('AppleWebKit/') > -1)) { return false; }
  
  $ ls
  #=> example.js   example.red   test.red

You can test short code snippets from the command line without creating a test file by using the <tt>-s</tt> option.

  $ red -s "@foo"
  #=> this.foo

=== Tutorial

Check the <a href=http://github.com/jessesielaff/red/wikis/tutorial>Tutorial page</a> for an in-depth lesson in how to use <span style="color:rgb(195,0,0)">Red</span> to write your JavaScript in Ruby.

=== Documentation

The <a href=http://red-js.rubyforge.org/red/rdoc/>documentation</a> is currently rather nonexistent.

=== Bugs / Issues

Got a problem?  Tell us about it.  Submit a ticket to the project page at <a href=http://jessesielaff.lighthouseapp.com/projects/15182-red>Lighthouse</a>.

=== MIT License

Copyright (c) 2008 Jesse Sielaff

  Permission is hereby granted, free of charge, to any person obtaining
  a copy of this software and associated documentation files (the
  'Software'), to deal in the Software without restriction, including
  without limitation the rights to use, copy, modify, merge, publish,
  distribute, sublicense, and/or sell copies of the Software, and to
  permit persons to whom the Software is furnished to do so, subject to
  the following conditions:
  
  The above copyright notice and this permission notice shall be
  included in all copies or substantial portions of the Software.
  
  THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
  EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
  MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
  IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
  CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
  TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
  SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
