module Red # :nodoc:
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
    
    File.open('vendor/plugins/red/init.rb', 'w') { |f| f.write("require 'rubygems'\nrequire 'red'\n\nRed.rails\n") }
    
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
    puts RED_MESSAGES[:output] % [("- #{filename}.js" unless filename == 'test'), js_output, @@red_errors ||= '']
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
  
  RED_MESSAGES = {}
  RED_MESSAGES[:banner] = <<-MESSAGE

Description:
  Red is a Ruby-to-JavaScript transliterator.
  For more information see http://github.com/jessesielaff/red/wikis

Usage: red [filename] [options]

Options:
  MESSAGE
  
  RED_MESSAGES[:invalid] = <<-MESSAGE

You used an %s

Use red -h for help.

  MESSAGE
  
  RED_MESSAGES[:missing] = <<-MESSAGE

You had a %s <ruby-string>

Use red -h for help.

  MESSAGE
  
  RED_MESSAGES[:usage] = <<-MESSAGE

Usage: red [filename] [options]

Use red -h for help.

  MESSAGE
  
  RED_MESSAGES[:output] = <<-MESSAGE

%s
=================================

%s

=================================
%s

  MESSAGE
end
