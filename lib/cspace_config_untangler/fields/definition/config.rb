# frozen_string_literal: true

require_relative "namespace"

module CspaceConfigUntangler
  module Fields
    module Definition
      # Parameter object used to pass around all the stuff needed to
      # create a field definition
      class Config
        # @return [String, nil]
        attr_reader :name

        # @return [CCU::Fields::Def::Namespace]
        attr_reader :namespace

        # @return [Hash]
        attr_reader :hash

        # @return [CCU::Fields::Def::Parser]
        attr_reader :parser

        # @return [CCU::Fields::Def::NamespaceFieldParser,
        #   CCU::Fields::Def::Grouping]
        attr_reader :parent

        # @param rectype [CCU::RecordType]
        # @param namespace [String]
        # @param field_hash [Hash]
        # @param parser [CCU::Fields::Def::Parser]
        # @param name [String]
        # @param parent [CCU::Fields::Def::NamespaceFieldParser,
        #   CCU::Fields::Def::Grouping]
        def initialize(rectype:, namespace:, field_hash:, parser:, name: nil,
          parent: nil)
          @rectype = rectype
          @hash = field_hash
          @parser = parser
          @name = name
          @parent = parent
          @namespace = Namespace.new(namespace, field_hash)
        end

        # returns a copy of itself that can be safely passed on and modified
        def derive_child(field_hash:, name:, parent:)
          self.class.new(
            rectype: @rectype,
            namespace: @namespace.literal,
            field_hash: field_hash,
            parser: @parser,
            name: name,
            parent: parent
          )
        end

        def signature
          return namespace_signature unless @name

          namespace_signature + " - #{@name}"
        end

        def namespace_signature
          "#{profile} - #{rectype} - #{namespace.literal}"
        end

        def profile
          @rectype.profile.name
        end

        def profile_config
          @rectype.profile.config
        end

        def profile_object
          @rectype.profile
        end

        def messages
          @rectype.profile.messages
        end

        def rectype
          @rectype.name
        end

        def update_field_hash(hash)
          @hash = CCU.safe_copy(hash)
        end

        def to_s
          "<##{self.class}:#{object_id.to_s(8)} #{signature}>"
        end
        alias_method :inspect, :to_s
      end
    end
  end
end
