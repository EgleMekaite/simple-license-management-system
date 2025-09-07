# frozen_string_literal: true

RSpec.describe Product, type: :model do
  describe 'associations' do
    it { is_expected.to have_many(:subscriptions).dependent(:destroy) }
    it { is_expected.to have_many(:license_assignments).dependent(:restrict_with_error) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe '.ordered_by_name' do
    let!(:product_alpha) { create(:product, name: 'Alpha') }
    let!(:product_beta) { create(:product, name: 'Beta') }
    let!(:product_gamma) { create(:product, name: 'Gamma') }

    it 'orders by name ascending' do
      expect(Product.ordered_by_name.pluck(:id)).to eq([product_alpha.id, product_beta.id, product_gamma.id])
    end
  end
end
