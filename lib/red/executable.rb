module Red # :nodoc:
  def build_red_plugin_for_rails(display_message = true)
    @files ||= ''
    self.make_plugin_directory('vendor/plugins/red', true)
    self.create_plugin_file(:open, 'vendor/plugins/red/init.rb', "require 'rubygems'\nrequire 'red'\n\nRed.rails\n")
    self.make_plugin_directory('public/javascripts/red')
    
    return unless display_message
    puts @files && exit
  end
  
  def add_unobtrusive(library)
    @files ||= ''
    self.build_red_plugin_for_rails(false)
    self.create_plugin_file(:copy, 'public/javascripts/dom_ready.js', File.join(File.dirname(__FILE__), "../javascripts/#{(library || '').downcase}_dom_ready.js"))
    self.create_plugin_file(:copy, 'public/javascripts/red/unobtrusive.red', File.join(File.dirname(__FILE__), "../javascripts/red/unobtrusive.red"))
    
  rescue Errno::ENOENT
    puts "There is no Unobtrusive Red support for #{library}"
  ensure
    puts @files && exit
  end
  
  def make_plugin_directory(dir, only_this_directory = false)
    parent_dir = File.dirname(dir)
    self.make_plugin_directory(parent_dir) unless File.exists?(parent_dir) || only_this_directory
    directory_status = File.exists?(dir) ? 'exists' : Dir.mkdir(dir) && 'create'
    @files << "      %s  %s\n" % [directory_status, dir]
  rescue SystemCallError
    puts "Unable to create directory in #{parent_dir}" && exit
  end
  
  def create_plugin_file(operation, filename, contents)
    file_status = self.check_if_plugin_file_exists(filename)
    case operation
      when :open : File.open(filename, 'w') { |f| f.write(contents) } if file_status == 'create'
      when :copy : File.copy(contents, filename)
    end
    @files << "      %s  %s\n" % [file_status, filename]
  end
  
  def check_if_plugin_file_exists(filename)
    if File.exists?(filename)
      print "File #{filename} exists. Overwrite [yN]? "
      return (gets =~ /y/i ? 'create' : 'exists')
    else
      return 'create'
    end
  end
  
  def direct_translate(string)
    print_js(hush_warnings { string.translate_to_sexp_array }.red!)
    exit
  end
  
  def hush_warnings
    $stderr = File.open('spew', 'w')
    output = yield
    $stderr = $>
    File.delete('spew')
    return output
  end
  
  def convert_red_file_to_js(filename, dry_run = false)
    unless File.exists?(file = "%s.red" % [filename]) || File.exists?(file = "%sred/%s.red" % [(dir = "public/javascripts/"), filename])
      puts "File #{filename}.red does not exist."
      exit
    end
    js_output = hush_warnings { File.read(file).translate_to_sexp_array }.red!
    File.open("%s%s.js" % [dir, filename], 'w') {|f| f.write(js_output)} unless dry_run
    print_js(js_output, filename, dry_run)
  end
  
  def print_js(js_output, filename = nil, dry_run = true) # :nodoc:
    puts RED_MESSAGES[:output] % [("- #{filename}.js" unless dry_run), js_output, @@red_errors ||= '']
  end
  
  RED_MESSAGES = {}
  RED_MESSAGES[:banner] = <<-MESSAGE

Description:
  Red converts Ruby to JavaScript.
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
