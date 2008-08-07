module Red # :nodoc:
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
