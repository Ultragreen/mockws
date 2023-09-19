require 'sinatra'
require 'yaml'
require 'carioca'
require_relative 'lib/config'
require_relative 'config/init'

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

    def self.get_response_time(value)
      if value[:response_time_method] == :random
        r = Random::new
        return r.rand(20)
      else value[:response_time_method] == :static
        if value[:res]
          return configuration.settings.static_response_time_seconds
        end
      end
    end

    output.info "Mock routes initialisation : "
    configuration.settings.services.each do |_key, value|
      response_time = get_response_time(value)
      case value[:type]
      when :static
        output.item "Adding static route #{value[:route]} on verb #{value[:verb]}"
        send(value[:verb], value[:route]) do
          ext = File.extname(value[:path])[1..-1].to_sym
          data = File.readlines(value[:path]).join('\n')
          content_type = configuration.settings.type_map[ext]
   
          sleep(response_time) if response_time
          status value[:status]
          return data
        end
      when :inline
        output.item "Adding inline route #{value[:route]} on verb #{value[:verb]}"
        send(value[:verb], value[:route]) do
          content_type = configuration.settings.type_map[value[:to]]
          status value[:status]
          sleep(response_time) if response_time
          return value[:data].send(configuration.settings.serializer[value[:to]])
        end
      when :proc
        output.item "Adding proc route #{value[:route]} on verb #{value[:verb]}"
        send(value[:verb], value[:route]) do
          record = Hash::new
          content_type = configuration.settings.type_map[value[:to]]
          status value[:status]
          if value[:definition][:inline] then
            data = value[:definition][:inline][:data]
            value[:definition][:rules].each do |field, rule|
              myproc = eval("lambda { #{rule} } ")
              record[field] = myproc.call({:data => data})
            end
            sleep(response_time) if response_time
            return record.send(configuration.settings.serializer[value[:to]])
          end
        end
      else
        output.error 'type not defined or type not recognize'
      end
    end
    
    private 
    def get_rules 
      rules = Array::new
      get_config.filters[@worker.to_sym].each do |item|
        
        rules.push eval("lambda { #{item[:definition]} } ")
      end
      return rules
    end
    
  end
end
