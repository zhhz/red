module Red # :nodoc:
  def build_red_plugin_for_rails
    self.make_rails_directory('vendor/plugins/red')
    
    File.open('vendor/plugins/red/init.rb', 'w') { |f| f.write("require 'rubygems'\nrequire 'red'\n\nRed.rails\n") }
    
    puts "Red plugin added to project."
    exit
  end
  
  def add_unobtrusive(library)
    red_directory_created = self.make_rails_directory('public/javascripts/red')
    File.copy(File.join(File.dirname(__FILE__), "../javascripts/#{(library || '').downcase}_dom_ready.js"), "public/javascripts/dom_ready.js")
    File.copy(File.join(File.dirname(__FILE__), "../javascripts/red/unobtrusive.red"), 'public/javascripts/red/unobtrusive.red')
    
    puts RED_MESSAGES[:unobtrusive]
    exit
  rescue Errno::ENOENT
    puts "There is no Unobtrusive Red support for #{library}"
    Dir.rmdir('public/javascripts/red') if red_directory_created
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
  
  def make_rails_directory(dir)
    parent_dir = File.dirname(dir)
    unless File.exists?(parent_dir)
      puts "Directory #{parent_dir} does not exist."
      exit
    end
    Dir.mkdir(dir) unless File.exists?(dir)
  rescue SystemCallError
    puts "Unable to create directory in #{parent_dir}"
    exit
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
  
  RED_MESSAGES[:unobtrusive] = <<-MESSAGE

public/javascripts/dom_ready.js
public/javascripts/red
public/javascripts/red/unobtrusive.red

Unobtrusive Red added to project.

  MESSAGE
end
