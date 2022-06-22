require 'sinatra'
require 'yaml'
require_relative 'lib/config'

module MockWS
 

  class Service < Sinatra::Base
    @@config_file = './config/mockws.yml'
    @@environment = ENV['RACK_ENV'] ? ENV['RACK_ENV'].to_sym : :development
    set :config, MockWS::Config::Factory.new(config_file: @@config_file, stage: @@environment, root: :mockws).settings

    settings.config.services.each do |_key, value|
      case value[:type]
      when :static
        send(value[:verb], value[:route]) do
          ext = File.extname(value[:path])[1..-1].to_sym
          data = File.readlines(value[:path]).join('\n')
          content_type = settings.config.type_map[ext]
          sleep(settings.config.static_response_time_seconds) if settings.config.static_response_time_seconds
          status value[:status]
          return data
        end
      when :inline
        send(value[:verb], value[:route]) do
          content_type = settings.config.type_map[value[:to]]
          status value[:status]
          sleep(settings.config.static_response_time_seconds) if settings.config.static_response_time_seconds
          return value[:data].send(settings.config.serializer[value[:to]])
        end
      when :proc
        send(value[:verb], value[:route]) do
          record = Hash::new
          content_type = settings.config.type_map[value[:to]]
          status value[:status]
          if value[:definition][:inline] then
            data = value[:definition][:inline][:data]
            value[:definition][:rules].each do |field, rule|
              myproc = eval("lambda { #{rule} } ")
              record[field] = myproc.call({:data => data})
            end
            sleep(settings.config.static_response_time_seconds) if settings.config.static_response_time_seconds
            return record.send(settings.config.serializer[value[:to]])
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
