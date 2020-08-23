# frozen_string_literal: true

class ContainerizedItem < ApplicationRecord
  belongs_to :item, optional: false
  belongs_to :container, optional: false
  belongs_to :user, optional: false

  delegate :generated_name, to: :item
end
