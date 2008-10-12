desc 'Release the website and new gem version'
task :deploy => [:check_version, :publish_docs, :release] do
end

task :check_version do
  unless ENV['VERSION']
    puts 'Must pass a VERSION=x.y.z release version'
    exit
  end
  unless ENV['VERSION'] == VERS
    puts "Please update your version.rb to match the release version, currently #{VERS}"
    exit
  end
end

desc 'Install the package as a gem, without generating documentation(ri/rdoc)'
task :ig => [:clean, :package] do
  sh "#{'sudo ' unless Hoe::WINDOZE }gem install pkg/*.gem --no-rdoc --no-ri"
end

namespace :manifest do
  desc 'Recreate Manifest.txt to include ALL files'
  task :refresh do
    `rake check_manifest | patch -p0 > Manifest.txt`
  end
end