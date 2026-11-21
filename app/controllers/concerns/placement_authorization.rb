# frozen_string_literal: true

# Packed items, boxes and pallets sit inside other records (a box, pallet or
# container). Writing one needs permission on the record itself AND permission
# to pack into whatever it sits in, both before a move and after it, so nothing
# can be pulled out of, or pushed into, a box someone may not touch.
module PlacementAuthorization
  extend ActiveSupport::Concern

  PARENTS = %i[box pallet container].freeze

  private

  def authorize_placement!(action, record)
    authorize! action, record
    PARENTS.each do |parent|
      next unless record.respond_to?(parent)

      location = record.public_send(parent)
      authorize! :pack_into, location if location
    end
  end

  # Checks the current location, applies the change, then checks the new one.
  def assign_with_placement!(record, attributes)
    authorize_placement!(:update, record)
    record.assign_attributes(attributes)
    authorize_placement!(:update, record)
  end
end
