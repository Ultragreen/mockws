require 'sinatra'
require 'yaml'
require 'json'
require 'carioca'
require 'thor'
require 'csv'
require 'etc'

require_relative 'mockws/setup'


    # facility to find a file in gem path
    # @param [String] gem a Gem name
    # @param [String] file a file relative path in the gem
    # @return [String] the path of the file, if found.
    # @return [False] if not found
    def search_file_in_gem(gem, file)
      if Gem::Specification.respond_to?(:find_by_name)
        begin
          spec = Gem::Specification.find_by_name(gem)
        rescue LoadError
          spec = nil
        end
      else
        spec = Gem.searcher.find(gem)
      end
      if spec
        res = if Gem::Specification.respond_to?(:find_by_name)
                spec.lib_dirs_glob.split('/')
              else
                Gem.searcher.lib_dirs_for(spec).split('/')
              end
        res.pop
        services_path = res.join('/').concat("/#{file}")
        return services_path if File.exist?(services_path)

      end
      false
    end

module MockWS

  DEFAULT_PATH = '~/.mockws'
  DEFAULT_CONFIG_PATH = "#{DEFAULT_PATH}/config"
  DEFAULT_LOGS_PATH = "#{DEFAULT_PATH}/logs" 

  DEFAULT_LOG_FILENAME = "mockws.log"
  DEFAULT_SETTINGS_FILENAME = "mockws.yml"

end


unless File.exist? File.expand_path(MockWS::DEFAULT_CONFIG_PATH)
  puts "[W] MockWS not initialized for user #{Etc.getpwuid(Process.uid).name}, running setup"
  MockWS::Configuration.setup
end

context = ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :main

Carioca::Registry.configure do |spec|
  spec.debug = true
  spec.init_from_file = false
  spec.log_file = File.expand_path("#{MockWS::DEFAULT_LOGS_PATH}/mockws.log")
  spec.config_file = File.expand_path("#{MockWS::DEFAULT_CONFIG_PATH}/#{MockWS::DEFAULT_SETTINGS_FILENAME}")
  spec.config_root = :mockws
  spec.environment = context
  spec.default_locale = :en
  spec.log_level = :info
  spec.locales_load_path << Dir[search_file_in_gem('mockws', './config/locales') + "/*.yml"]
  spec.debugger_tracer = :logger
end


require_relative 'mockws/route_manager'
require_relative 'mockws/data_manager'
require_relative 'mockws/daemon_controller'


class ApplicationController < Carioca::Container
  inject service: :configuration
  inject service: :i18n
end


module MockWS
  class Service < Sinatra::Base
    extend Carioca::Injector
    inject service: :output
    inject service: :configuration

  

    def self.init
      MockWS::RouteManager::configure(self)
    end


    
   
  end
end



# method for daemonize blocks
    # @param [Hash] options the list of options, keys are symbols
    # @option  options [String] :description the description of the process, use for $0
    # @option  options [String] :pid_file the pid filename
    # @option  options [String] :daemon_user the user to change privileges
    # @option  options [String] :daemon_group the group to change privileges
    # @option  options [String] :stderr_trace the path of the file where to redirect STDERR
    # @option  options [String] :stdout_trace the path of the file where to redirect STDOUT
    # @option  options [Proc] :sigint_handler handler Proc for SIGINT signal
    # @option  options [Proc] :sigterm_handler handler Proc for SIGTERM signal
    # @option  options [Proc] :sighup_handler handler Proc for SIGHuP signal
    # @option  options [Bool] :foreground option to run foreground
    # @yield a process definion or block given
    # @example usage inline
    #    class Test
    #      include Splash::Helpers
    #      private :daemonize
    #      def initialize
    #        @loop = Proc::new do
    #          loop do
    #            sleep 1
    #          end
    #        end
    #      end
    #
    #      def run
    #        daemonize({:description => "A loop daemon", :pid_file => '/tmp/pid.file'}, &@loop)
    #      end
    #     end
    #
    # @example usage block
    #    class Test
    #      include Splash::Helpers
    #      include Dorsal::Privates
    #      private :daemonize
    #      def initialize
    #      end
    #
    #      def run
    #        daemonize :description => "A loop daemon", :pid_file => '/tmp/pid.file' do
    #          loop do
    #            sleep 1
    #          end
    #        end
    #      end
    #     end
    # @return [Fixnum] pid the pid of the forked processus
    def daemonize(options)
      {
       :sighup_handler => 'SIGHUP',
       :sigint_handler => 'SIGINT',
       :sigterm_handler => 'SIGTERM',
      }.each do |key,value|
        trap(value){
          if options[:sighup_handler].include? key then
            options[:sighup_handler].call
          else
            exit! 0
          end
        }
      end
      if options[:foreground]
        Process.setproctitle options[:description] if options[:description]
        return yield
      end
      fork do
        File.open(options[:pid_file],"w"){|f| f.puts Process.pid } if options[:pid_file]
        if options[:daemon_user] and options[:daemon_group] then
          uid = Etc.getpwnam(options[:daemon_user]).uid
          gid = Etc.getgrnam(options[:daemon_group]).gid
          Process::UID.change_privilege(uid)
          Process::GID.change_privilege(gid)
        end
        $stdout.reopen(options[:stdout_trace], "w") if options[:stdout_trace]
        $stderr.reopen(options[:stderr_trace], "w") if options[:stderr_trace]
        Process.setproctitle options[:description] if options[:description]
        yield
      end
      return 0
    end

     
