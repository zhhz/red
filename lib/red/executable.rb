module Red
  module Executable # :nodoc:
    def build_red_plugin_for_rails
      unless File.exists?('vendor/plugins')
        puts "Directory vendor/plugins does not exist."
        exit
      end
      
      begin
        Dir.mkdir('vendor/plugins/red') unless File.exists?('vendor/plugins/red')
      rescue SystemCallError
        puts "Unable to create directory in vendor/plugins"
        exit
      end
      
      File.open('vendor/plugins/red/init.rb', 'w') { |f| f.write("require 'rubygems'\nrequire 'red'\n\n# Red is not yet supported for Rails projects.\n")} #Red.for_rails(binding)\n") }
      
      puts "Red plugin added to project."
      exit
    end
    
    def direct_translate(string)
      js_output = hush_warnings { string.string_to_node }.compile_node
      print_js(js_output, 'test')
      exit
    end
    
    def hush_warnings
      $stderr = File.open('spew', 'w')
      output = yield
      $stderr = $>
      
      File.delete('spew')
      
      return output
    end
    
    def print_js(js_output, filename) # :nodoc:
      puts <<-OUTPUT.%([("- #{filename}.js" unless filename == 'test'), js_output, @@red_errors ||= ''])

%s
=================================

%s

=================================
%s

      OUTPUT
    end
    
    def compile_red_to_js(filename)
      unless File.exists?(file = "%s.red" % [filename]) || File.exists?(file = "%sred/%s.red" % [(dir = "public/javascripts/"), filename])
        puts "File #{filename}.red does not exist."
        exit
      end
      
      source = File.read(file)
      js_output = hush_warnings { source.string_to_node }.compile_node
      
      File.open("%s%s.js" % [dir, filename], 'w') {|f| f.write(js_output)} unless filename == 'test'
      
      print_js(js_output, filename)
    end
  end
end
