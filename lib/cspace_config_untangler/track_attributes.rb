module CspaceConfigUntangler
  module TrackAttributes
    def attr_readers
      self.class.instance_variable_get(:@attr_readers)
    end

    def attr_accessors
      self.class.instance_variable_get(:@attr_accessors)
    end

    def self.included(klass)
      klass.send :define_singleton_method, :attr_reader, ->(*params) do
        @attr_readers ||= []
        @attr_readers.concat params
        super(*params)
      end
      klass.send :define_singleton_method, :attr_accessor, ->(*params) do
        @attr_accessors ||= []
        @attr_accessors.concat params
        super(*params)
      end
    end
  end
end
