module Red # :nodoc:
  def build_red_plugin_for_rails(display_message = true)
    @files ||= ''
    self.make_rails_directory('vendor/plugins/red', true)
    
    self.create_plugin_file(:open, 'vendor/plugins/red/init.rb', "require 'rubygems'\nrequire 'red'\n\nRed.rails\n")
    
    self.make_rails_directory('public/javascripts/red')
    
    return unless display_message
    puts RED_MESSAGES[:rails] % @files
    exit
  end
  
  def add_unobtrusive(library)
    @files ||= ''
    self.build_red_plugin_for_rails(false)
    
    self.create_plugin_file(:copy, 'public/javascripts/dom_ready.js', File.join(File.dirname(__FILE__), "../javascripts/#{(library || '').downcase}_dom_ready.js"))
    self.create_plugin_file(:copy, 'public/javascripts/red/unobtrusive.red', File.join(File.dirname(__FILE__), "../javascripts/red/unobtrusive.red"))
    
  rescue Errno::ENOENT
    puts "There is no Unobtrusive Red support for #{library}"
  ensure
    puts RED_MESSAGES[:unobtrusive] % @files
    exit
  end
  
  def create_plugin_file(operation, filename, contents)
    file_status = self.check_if_plugin_file_exists(filename)
    case operation
      when :open : File.open(filename, 'w') { |f| f.write(contents) } if file_status == 'created'
      when :copy : File.copy(contents, filename)
    end
    @files << "\n%s  %s" % [file_status, filename]
  end
  
  def check_if_plugin_file_exists(filename)
    if File.exists?(filename)
      print "File #{filename} exists. Overwrite [yN]? "
      return (gets =~ /y/i ? 'created' : 'exists ')
    else
      return 'created'
    end
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
  
  def make_rails_directory(dir, only_this_directory = false)
    parent_dir = File.dirname(dir)
    self.make_rails_directory(parent_dir) unless File.exists?(parent_dir) || only_this_directory
    @files << (File.exists?(dir) ? "\nexists   %s" : Dir.mkdir(dir) && "\ncreated  %s") % dir
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
%s

Unobtrusive Red added to project.

  MESSAGE
  
  RED_MESSAGES[:rails] = <<-MESSAGE
%s

Red plugin added to project.

  MESSAGE
end
