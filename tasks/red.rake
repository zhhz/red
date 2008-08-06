require 'lib/red'
require 'rake'

namespace :red do
  desc 'Convert {filename}.rb to {filename}.js'
  task :js, :filename, :needs => :red_env do |task, args|
    source = File.read("#{args[:filename]}.rb")
    js_output = hush_warnings { source.string_to_node }.compile_node
    
    File.open("#{args[:filename]}.js", 'w') {|f| f.write(js_output)}
    
    print_js(js_output, args[:filename])
  end
  
  desc 'Print JavaScript output of test.rb'
  task :test => :red_env do
    source = File.read("test.rb")
    js_output = hush_warnings { source.string_to_node }.compile_node
    
    print_js(js_output, 'test')
  end
  
  task :red_env do
    include Red
    def hush_warnings # :nodoc:
      $stderr = File.open('spew', 'w')
      output = yield
      $stderr = $>
      
      File.delete('spew')
      
      return output
    end
    
    def print_js(js_output, filename) # :nodoc:
      puts <<-EOF.%([filename, js_output, @@red_errors ||= ''])

- %s.js
=================================

%s

=================================
%s

EOF
    end
  end
end
