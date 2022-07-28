def get_config
  return ApplicationController.configuration.settings
end

Dir[File.dirname(__FILE__) + '/*.rb'].each {|file| require file  unless File.basename(file) == 'init.rb'}
