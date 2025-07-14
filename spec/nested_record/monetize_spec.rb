require 'spec_helper'

RSpec.describe 'NestedRecord monetize support' do
  before(:all) do
    begin
      require 'money-rails'
      require 'money'
      Money.default_currency = 'USD'
    rescue LoadError
      skip "money-rails gem not available"
    end
  end

  nested_model(:PriceModel) do
    monetize :amount, currency: 'USD'
    monetize :discount_amount, with: :discount_currency
    monetize :total_amount, with: false  # No currency field
  end

  active_model(:Product) do
    has_one_nested :price, class_name: 'PriceModel'
  end

  describe 'monetize attribute' do
    it 'creates currency attribute automatically' do
      price = PriceModel.new
      expect(price).to respond_to(:amount_currency)
      expect(price.amount_currency).to eq('USD')
    end

    it 'uses custom currency attribute name' do
      price = PriceModel.new
      expect(price).to respond_to(:discount_currency)
    end

    it 'does not create currency attribute when disabled' do
      price = PriceModel.new
      expect(price).not_to respond_to(:total_amount_currency)
    end

    it 'creates money attribute with default currency' do
      price = PriceModel.new(amount: 1000)
      expect(price.amount).to be_a(Money)
      expect(price.amount.cents).to eq(1000)
      expect(price.amount.currency.to_s).to eq('USD')
    end

    it 'accepts Money objects directly' do
      money = Money.new(2000, 'EUR')
      price = PriceModel.new(amount: money)
      expect(price.amount).to eq(money)
    end

    it 'updates currency when Money object is assigned' do
      price = PriceModel.new(amount: 1000)  # USD by default
      expect(price.amount_currency).to eq('USD')

      # Assign Money with different currency
      price.amount = Money.new(2000, 'EUR')
      expect(price.amount_currency).to eq('EUR')
      expect(price.amount.currency.to_s).to eq('EUR')
    end

    it 'serializes and deserializes correctly' do
      price = PriceModel.new(amount: 1500)

      # Get the raw serialized value using the type
      type = price.class.type_for_attribute(:amount)
      serialized = type.serialize(price.amount)

      # Simulate loading from database
      deserialized = type.deserialize(serialized)

      expect(deserialized).to be_a(Money)
      expect(deserialized.cents).to eq(1500)
      expect(deserialized.currency.to_s).to eq('USD')
    end
  end

  describe 'nested record with monetize' do
    it 'works with nested records' do
      product = Product.new(price_attributes: { amount: 2500 })
      expect(product.price.amount).to be_a(Money)
      expect(product.price.amount.cents).to eq(2500)
    end

    it 'serializes nested money attributes' do
      product = Product.new
      product.build_price(amount: 3000)

      # This should not raise an error
      expect { product.as_json }.not_to raise_error
    end
  end
end
