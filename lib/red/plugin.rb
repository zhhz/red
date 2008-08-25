module Red
  class << self
    def already_updated?
      @@red_updated ||= false
    end
    
    def update_javascripts
      @@red_updated = true
      red_dir = 'public/javascripts/red/'
      Dir.glob("#{red_dir}**/*[.rb|.red]").each do |filepath|
        if self.update_javascripts?(filename = filepath.gsub(red_dir,'').gsub(/.[rb|red]+$/,'')) || RAILS_ENV != 'production' || true
          js_output = (File.read(filepath).string_to_node.compile_node || '') << (@@red_errors ||= '')
          
          filename.split('/')[0...-1].inject('public/javascripts') do |string,dir|
            new_dir = string << '/' << dir
            Dir.mkdir(new_dir) unless File.exists?(new_dir)
            string
          end
          
          File.open("public/javascripts/#{filename}.js", 'w') { |f| f.write(js_output) }
          
          @@red_errors = ''
        end
      end
    end
    
    def update_javascripts?(filename)
      if File.exists?("public/javascripts/#{filename}.js")
        (File.mtime("public/javascripts/red/#{filename}.red") rescue File.mtime("public/javascripts/red/#{filename}.rb")) > File.mtime("public/javascripts/#{filename}.js")
      else
        return true
      end
    end
  end
  
  module RailsBase # :nodoc:
    def self.included(base)
      base.send('alias_method', :red_old_process, :process)
      base.class_eval do
        def process(*args)
          Red.update_javascripts #unless Red.already_updated?
          red_old_process(*args)
        end
      end
    end
  end
end

include Red

unless defined?(Red::RAILS_LOADED) || !defined?(ActionController)
  Red::RAILS_LOADED = true
  ActionController::Base.send(:include, Red::RailsBase)
end
