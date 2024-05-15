# frozen_string_literal: true

require_relative "field_config_child"
require_relative "../value_sources/type_extractor"
require_relative "../../track_attributes"

module CspaceConfigUntangler
  module Fields
    module Definition
      class FieldDefinition < FieldConfigChild
        include CCU::TrackAttributes
        attr_reader :name, :ns, :ns_for_id, :id,
          :schema_path,
          :repeats, :in_repeating_group,
          :data_type, :value_source, :value_list,
          :required,
          :profile

        # def initialize(fdp, name, config, parent)
        def initialize(config)
          super(config)
          @datahash = config.hash["[config]"]
          set_id
          @data_type = set_datatype
          @value_source = []
          @value_list = []
          set_value_sources
          @required = set_required
        end

        def to_h
          attrs = attr_readers.map { |e| "@" + e.to_s }.map { |e| e.to_sym }
          h = {}
          attrs.each { |a| h[a] = instance_variable_get(a) }
          h
        end

        def csv_header
          %w[profile record_type namespace field_id field_name
            schema_path required repeats group_repeats data_type data_source
            option_list_values]
        end

        def rectype
          @config.rectype
        end

        def to_csv
          arr = [@config.profile, @config.rectype, @config.namespace.literal,
            @id]
          arr << (@name || "")
          arr << (@schema_path ? @schema_path.join(" > ") : "")
          arr << (@required || "")
          arr << (@repeats || "")
          arr << (@in_repeating_group || "")
          arr << (@data_type || "")
          arr << if @value_source
            @value_source.map(&:fields_csv_label).compact.join(", ")
          else
            ""
          end
          arr << (@value_list ? @value_list.join(", ") : "")
          arr
        end

        def inspect
          omit = %i[@config @profile @hash @parent @datahash @name @ns_for_id
            @value_source @value_list]
          attributes = instance_variables.unshift([])
            .inject do |info, attribute|
            if omit.include?(attribute)
              info
            else
              info << "#{attribute}=#{instance_variable_get(attribute).inspect}"
            end
          end

          %(#<#{self.class}:#{object_id} #{attributes.join(", ")}>)
        end

        private

        def set_required
          if @datahash.dig("required") && @datahash["required"] == true
            "y"
          else
            "n"
          end
        end

        def set_value_sources
          type = CCU::Fields::ValueSources::TypeExtractor.call(@datahash)
          return unless type

          sources = CCU::Fields::ValueSources::SourceExtractor.call(
            type, @datahash, @config.profile_object
          ).reject do |source|
            source.source_type == "authority" && !source.configured?
          end

          @value_source = sources
          if type == "option list"
            @value_list = @value_source.first.options
            return
          end

          return unless @value_source.empty?

          if type == "authority"
            CCU.log.warn(
              "DATA SOURCES: #{@config.namespace_signature} - #{@id} - "\
                "Autocomplete defined with no configured source"
            )
          end

          @value_source = [CCU::ValueSources::NoSource.new]
        end

        def set_datatype
          val = @datahash.dig("dataType")
          val = val.sub("DATA_TYPE_", "") if val
          case val
          when nil
            return "structured date group" if is_structured_date?
            "string"
          when "INT"
            "integer"
          when "FLOAT"
            "float"
          when "BOOL"
            "boolean"
          when "DATE"
            "date"
          when "STRING"
            "string"
          when "STRUCTURED_DATE"
            "structured date group"
          else
            "TODO: handle unknown datatype: #{val}"
          end
        end

        def set_id
          if @parent.is_a?(CCU::Fields::Def::Grouping) &&
              @parent.is_structured_date?
            @id = "ext.structuredDate.#{@name}"
          elsif @parent.is_a?(CCU::Fields::Def::Grouping) &&
              @parent.schema_path.include?("localityGroupList")
            @id = "ext.locality.#{@name}"
          elsif @datahash.dig("extensionName")
            @id = "ext.structuredDate.#{@name}" if @datahash["extensionName"] == "structuredDate"
            @id = "ext.dimension.#{@name}" if @datahash["extensionName"] == "dimension"
            @id = "ext.address.#{@name}" if @datahash["extensionName"] == "address"
            @id = "ext.locality.#{@name}" if @datahash["extensionName"] == "locality"
            # handles weirdness described at:
            #  https://collectionspace.atlassian.net/browse/DRYD-863
          elsif @id == "approvalGroupField.approvalGroup"
            @id = "#{@ns.sub("ns2:", "")}.approvalGroup"
          else
            @id = "#{@ns_for_id.sub("ns2:", "")}.#{@name}"
          end
        end
      end
    end
  end
end
