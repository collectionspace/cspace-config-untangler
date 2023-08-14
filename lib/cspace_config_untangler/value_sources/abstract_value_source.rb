# frozen_string_literal: true

require_relative 'reportable'

module CspaceConfigUntangler
  module ValueSources
    # basic value object to represent an authority
    class AbstractValueSource
      include CCU::ValueSources::Reportable
      attr_reader :name, :type, :subtype, :source_type

      def inspect
        included = %i[@name @type @subtype @source_type]
        attributes = instance_variables.unshift([]).inject do |info, attribute|
          if included.include?(attribute)
            info << "#{attribute}=#{instance_variable_get(attribute).inspect}"
          else
            info
          end
        end

        %(#<#{self.class}:#{object_id} #{attributes.join(", ")}>)
      end
    end
  end
end
