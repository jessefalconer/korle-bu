# frozen_string_literal: true

# "Unpack all" and "unpack selected": everything left on each packed item goes
# to one hospital, as one unpacking event per item.
module BulkUnpacking
  extend ActiveSupport::Concern

  private

  # Returns the flash to show: how many were unpacked, and any that failed.
  def unpack_everything(packed_items)
    return { error: "Please select a hospital/facility/clinic." } if params[:hospital_id].blank?

    unpacked = 0
    failures = []
    UnpackingEvent.transaction do
      packed_items.each do |pi|
        next unless pi.remaining_quantity.positive?

        authorize! :read, pi
        event = pi.unpacking_events.build(
          hospital_id: params[:hospital_id],
          notes: params[:notes],
          user: current_user,
          timestamp: params[:timestamp].presence,
          quantity: pi.remaining_quantity
        )
        # The hospital must be one this user may unpack to.
        authorize! :create, event if event.hospital
        if event.save
          unpacked += 1
        else
          failures << "#{pi.generated_name}: #{event.errors.full_messages.to_sentence}"
        end
      end
    end

    flash = { success: "#{unpacked} item(s) unpacked." }
    flash[:error] = "Not unpacked: #{failures.to_sentence}" if failures.any?
    flash
  end
end
