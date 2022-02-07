class Hash
  # monkey patching
  def deep_symbolize
    target = dup
    target.each_with_object({}) do |(key, value), memo|
      value = value.deep_symbolize if value.is_a?(Hash)
      memo[key.to_sym] = value
    end
  end

  def method_missing(name, *args)
    if name.to_s =~ /(.+)=$/
      self[Regexp.last_match(1).to_sym] = args.first
    else
      self[name.to_sym]
    end
  end
end

module MockWS
  module Config
    class Settings < Hash
      attr_accessor :config_file, :stage

      def initialize(options = {})
        @@config_file = options[:config_file]
        @content = options[:content]
        @stage = options[:stage]
        @root = options[:root]
        initconf
      end

      def refresh
        initconf
      end

      def save!
        res = false
        File.open(@@config_file, 'w') do |f|
          res = true if f.write(to_yaml)
        end
        res
      end

      private

      def initconf
        newsets = {}
        @content = File.readlines(@@config_file).join if @@config_file && File.exist?(@@config_file)
        if @stage
          newsets = YAML.load(@content)[@root][:default]
          data = YAML.load(@content)[@root][@stage]
          deep_merge!(newsets, data)
        else
          newsets = YAML.load(@content)
        end
        deep_merge!(self, newsets)
      end

      def deep_merge!(target, data)
        merger = proc do |_key, v1, v2|
          v1.is_a?(Settings) && v2.is_a?(Settings) ? v1.merge(v2, &merger) : v2
        end
        target.merge! data, &merger
      end
    end

    class Factory
      def initialize(_opts = {})
        @@settings ||= MockWS::Config::Settings.new(_opts)
      end

      def save!
        @@settings.save!
      end

      def config_file
        @@settings.config_file
      end

      def config_file=(name)
        @@settings.config_file = name
      end

      def settings
        @@settings
      end

      def settings=(ahash)
        @@settings = ahash
      end
    end
  end
end
