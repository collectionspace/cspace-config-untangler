# frozen_string_literal: true

module CspaceConfigUntangler
  # Namespace for report generators
  module Report
    module_function

    def simplify_allfields(row)
      %w[fid namespace namespace_for_id field_id].each do |field|
        row.delete(field)
      end
      row
    end
  end
end
