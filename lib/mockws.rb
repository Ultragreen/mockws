require 'sinatra'
require 'yaml'
require 'carioca'
require 'thor'


require_relative 'mockws/route_manager'

environment = ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development

Carioca::Registry.configure do |spec|
  spec.debug = true
  spec.init_from_file = false
  spec.log_file = '/tmp/mockws.log'
  spec.config_file = './config/mockws.yml'
  spec.config_root = :mockws
  spec.environment = environment
  spec.default_locale = :fr
  spec.log_level = :debug
  spec.locales_load_path << Dir[File.expand_path('./config/locales') + "/*.yml"]
  spec.debugger_tracer = :logger
end

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
      MockWS::RouteManager::new(self)
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