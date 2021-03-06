# frozen_string_literal: true

class RapidConnectService < ApplicationRecord
  include FederationObject

  belongs_to :organization

  has_many :activations, as: :federation_object, dependent: :destroy

  valhammer

  def self.find_by_identifying_attribute(value)
    find_by(identifier: value)
  end
end
