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
          status value[:status]
          return data
        end
      when :inline
        send(value[:verb], value[:route]) do
          content_type = settings.config.type_map[value[:to]]
          status value[:status]
          return value[:data].send(settings.config.serializer[value[:to]])
        end
      else
        p 'type not defined or type not recognize'
      end
    end
  end
end
