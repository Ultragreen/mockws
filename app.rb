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
    p get_config.services
    get_config.services.each do |_key, value|
      case value[:type]
      when :static
        send(value[:verb], value[:route]) do
          ext = File.extname(value[:path])[1..-1].to_sym
          data = File.readlines(value[:path]).join('\n')
          content_type = get_config.type_map[ext]
          sleep(get_config.static_response_time_seconds) if get_config.static_response_time_seconds
          status value[:status]
          return data
        end
      when :inline
        send(value[:verb], value[:route]) do
          content_type = get_config.type_map[value[:to]]
          status value[:status]
          sleep(get_config.static_response_time_seconds) if get_config.static_response_time_seconds
          return value[:data].send(get_config.serializer[value[:to]])
        end
      when :proc
        send(value[:verb], value[:route]) do
          record = Hash::new
          content_type = get_config.type_map[value[:to]]
          status value[:status]
          if value[:definition][:inline] then
            data = value[:definition][:inline][:data]
            value[:definition][:rules].each do |field, rule|
              myproc = eval("lambda { #{rule} } ")
              record[field] = myproc.call({:data => data})
            end
            sleep(get_config.static_response_time_seconds) if get_config.static_response_time_seconds
            return record.send(get_config.serializer[value[:to]])
          end
        end
      else
        p 'type not defined or type not recognize'
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
