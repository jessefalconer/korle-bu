# frozen_string_literal: true

# Server side of the delete dialog: refuses to delete anything still in use
# (Deletable#deletion_blockers), and anything that reaches beyond itself unless
# "delete" was typed (sent as params[:confirm_delete]). The page normally stops
# both before they get here; this keeps a stray or crafted request from skipping it.
# Include after load_and_authorize_resource, which loads the record.
module ConfirmsDeletion
  extend ActiveSupport::Concern

  included do
    # Every controller that includes this defines destroy
    before_action :confirm_deletion, only: :destroy # rubocop:disable Rails/LexicallyScopedActionFilter
  end

  private

  def confirm_deletion
    record = instance_variable_get(:"@#{controller_name.singularize}")
    return unless record

    error = if (blockers = record.deletion_blockers).any?
      "#{deletion_name(record)} can't be deleted: #{blockers.to_sentence}."
    elsif record.requires_typed_delete? && params[:confirm_delete].to_s.strip.downcase != Deletable::CONFIRM_WORD
      "Type \"#{Deletable::CONFIRM_WORD}\" to confirm deleting #{deletion_name(record)}."
    end
    redirect_back_or_to(polymorphic_path(record), flash: { error: error }) if error
  end

  def deletion_name(record)
    record.respond_to?(:generated_name) ? record.generated_name : record.try(:name) || record.class.model_name.human
  end
end
