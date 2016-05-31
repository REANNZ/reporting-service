# frozen_string_literal: true
require 'rails_helper'

RSpec.describe Organization, type: :model do
  context 'validations' do
    let(:factory) { :organization }

    subject { build(:organization) }

    it { is_expected.to validate_presence_of(:identifier) }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:identifier) }

    it 'only permits the urlsafe base64 alphabet for `identifier`' do
      expect(subject).to allow_value('abcdefg').for(:identifier)
      expect(subject).to allow_value('abcdefg-_').for(:identifier)
      expect(subject).not_to allow_value('abcdefg-@').for(:identifier)
    end

    it_behaves_like 'a federation object'
  end

  describe '::find_by_identifying_attribute' do
    let!(:org) { create(:organization) }

    it 'finds by entity id' do
      expect(described_class.find_by_identifying_attribute(org.identifier))
        .to eq(org)
    end

    it 'returns nil when not found' do
      expect(described_class.find_by_identifying_attribute('urn:nonexistent'))
        .to be_nil
    end
  end
end
