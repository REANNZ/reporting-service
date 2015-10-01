require 'rails_helper'

RSpec.describe Organization, type: :model do
  context 'validations' do
    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:name) }
  end
end
