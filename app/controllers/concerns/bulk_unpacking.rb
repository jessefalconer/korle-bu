# frozen_string_literal: true

# "Unpack all" and "unpack selected": everything left on each packed item goes
# to one hospital, as one unpacking event per item.
module BulkUnpacking
  extend ActiveSupport::Concern

  private

  # Returns the flash to show: how many were unpacked, and any that failed.
  def unpack_everything(packed_items)
    return { error: "Please select a hospital/facility/clinic." } if params[:hospital_id].blank?

    results = UnpackingEvent.transaction do
      packed_items.select { |pi| pi.remaining_quantity.positive? }.map { |pi| unpack_remaining(pi) }
    end
    failures = results.compact
    unpacked = results.size - failures.size

    remember_unpack(params[:hospital_id], params[:timestamp]) if unpacked.positive?
    flash = { success: "#{unpacked} item(s) unpacked." }
    flash[:error] = "Not unpacked: #{failures.to_sentence}" if failures.any?
    flash
  end

  # Unpacks what is left of one packed item. Returns nil, or why it failed.
  def unpack_remaining(packed_item)
    authorize! :read, packed_item
    event = packed_item.unpacking_events.build(
      hospital_id: params[:hospital_id],
      notes: params[:notes],
      user: current_user,
      timestamp: params[:timestamp].presence,
      quantity: packed_item.remaining_quantity
    )
    # The hospital must be one this user may unpack to.
    authorize! :create, event if event.hospital
    return if event.save

    "#{packed_item.generated_name}: #{event.errors.full_messages.to_sentence}"
  end
end
