require 'spec_helper'

RSpec.describe 'NestedRecord monetize default values' do
  before(:all) do
    begin
      require 'money-rails'
      require 'money'
      Money.default_currency = 'USD'
    rescue LoadError
      skip "money-rails gem not available"
    end
  end

  # Model with various default value types
  nested_model(:ProductWithDefaults) do
    monetize :price, currency: 'USD', default: 9.99           # Decimal default
    monetize :shipping, default: 500                          # Integer default (cents)  
    monetize :tax, default: Money.new(299, 'USD')             # Money object default
    monetize :discount, with: false, default: 0               # Zero default, no currency
    monetize :premium, currency: 'EUR', default: 19.99        # Different currency
  end

  # Model with nested defaults
  active_model(:ProductWithNestedDefaults) do
    has_one_nested :pricing do
      monetize :amount, currency: 'EUR', default: 29.99
      monetize :discount, default: Money.new(199, 'GBP')
      attribute :description, :string, default: 'Standard pricing'
    end
  end

  # Model with nested_accessors defaults
  active_model(:UserWithDefaults) do
    nested_accessors from: :financial_info do
      monetize :salary, currency: 'USD', default: 50000.00
      monetize :bonus, default: 5000.00
      monetize :allowance, with: false, default: 0
      attribute :department, :string, default: 'General'
    end
  end

  describe 'basic default value functionality' do
    it 'applies decimal default values' do
      product = ProductWithDefaults.new
      expect(product.price).to be_a(Money)
      expect(product.price.cents).to eq(999)  # 9.99 * 100
      expect(product.price.currency.to_s).to eq('USD')
    end

    it 'applies integer default values (treated as cents)' do
      product = ProductWithDefaults.new
      expect(product.shipping).to be_a(Money)
      expect(product.shipping.cents).to eq(500)
      expect(product.shipping.currency.to_s).to eq('USD')
    end

    it 'applies Money object default values' do
      product = ProductWithDefaults.new
      expect(product.tax).to be_a(Money)
      expect(product.tax.cents).to eq(299)
      expect(product.tax.currency.to_s).to eq('USD')
    end

    it 'applies zero default values' do
      product = ProductWithDefaults.new
      expect(product.discount).to be_a(Money)
      expect(product.discount.cents).to eq(0)
      expect(product.discount.currency.to_s).to eq('USD')
      expect(product).not_to respond_to(:discount_currency)  # with: false
    end

    it 'applies default values with different currencies' do
      product = ProductWithDefaults.new
      expect(product.premium).to be_a(Money)
      expect(product.premium.cents).to eq(1999)  # 19.99 * 100
      expect(product.premium.currency.to_s).to eq('EUR')
    end
  end

  describe 'overriding default values' do
    it 'allows overriding defaults during initialization' do
      product = ProductWithDefaults.new(price: 15.99, shipping: 750)
      expect(product.price.cents).to eq(1599)  # 15.99 * 100
      expect(product.shipping.cents).to eq(750)
    end

    it 'allows overriding defaults after initialization' do
      product = ProductWithDefaults.new
      expect(product.price.cents).to eq(999)   # Default
      
      product.price = 25.50
      expect(product.price.cents).to eq(2550)  # Overridden
    end

    it 'treats explicit nil assignment as trigger for default' do
      product = ProductWithDefaults.new(price: nil, shipping: nil)
      expect(product.price.cents).to eq(999)   # Default applied
      expect(product.shipping.cents).to eq(500) # Default applied
    end

    it 'treats empty string assignment as nil (not default)' do
      product = ProductWithDefaults.new(price: '', shipping: '')
      expect(product.price).to be_nil
      expect(product.shipping).to be_nil
    end
  end

  describe 'nested record defaults' do
    it 'applies defaults in nested records' do
      product = ProductWithNestedDefaults.new
      product.build_pricing
      
      expect(product.pricing.amount).to be_a(Money)
      expect(product.pricing.amount.cents).to eq(2999)  # 29.99 * 100
      expect(product.pricing.amount.currency.to_s).to eq('EUR')
      
      expect(product.pricing.discount).to be_a(Money)
      expect(product.pricing.discount.cents).to eq(199)
      expect(product.pricing.discount.currency.to_s).to eq('GBP')
      
      expect(product.pricing.description).to eq('Standard pricing')
    end

    it 'allows overriding nested defaults via attributes' do
      product = ProductWithNestedDefaults.new
      product.pricing_attributes = { amount: 39.99, description: 'Premium pricing' }
      
      expect(product.pricing.amount.cents).to eq(3999)  # 39.99 * 100
      expect(product.pricing.discount.cents).to eq(199) # Default still applied
      expect(product.pricing.description).to eq('Premium pricing')
    end
  end

  describe 'nested_accessors defaults' do
    it 'applies defaults in nested_accessors' do
      user = UserWithDefaults.new
      
      expect(user.salary).to be_a(Money)
      expect(user.salary.cents).to eq(5000000)  # 50000.00 * 100
      expect(user.salary.currency.to_s).to eq('USD')
      
      expect(user.bonus.cents).to eq(500000)    # 5000.00 * 100
      expect(user.allowance.cents).to eq(0)
      expect(user.department).to eq('General')
    end

    it 'allows overriding nested_accessors defaults' do
      user = UserWithDefaults.new
      user.salary = 75000.00
      user.department = 'Engineering'
      
      expect(user.salary.cents).to eq(7500000)  # 75000.00 * 100
      expect(user.bonus.cents).to eq(500000)    # Default still applied
      expect(user.department).to eq('Engineering')
    end
  end

  describe 'serialization with defaults' do
    it 'serializes default values correctly' do
      product = ProductWithDefaults.new
      json = product.as_json

      price_data = json['attributes']['price']
      expect(price_data['cents']).to eq(999)
      expect(price_data['currency_iso']).to eq('USD')

      shipping_data = json['attributes']['shipping']
      expect(shipping_data['cents']).to eq(500)
      expect(shipping_data['currency_iso']).to eq('USD')
    end

    it 'deserializes and applies defaults correctly' do
      # Create a product with some values set
      original = ProductWithDefaults.new(price: 12.99)
      
      # Get the type for manual serialization/deserialization testing
      type = ProductWithDefaults.type_for_attribute(:shipping)
      
      # Serialize current value (should be default)
      serialized = type.serialize(original.shipping)
      expect(serialized['cents']).to eq(500)  # Default value

      # Deserialize should reconstruct the Money object correctly
      deserialized = type.deserialize(serialized)
      expect(deserialized).to be_a(Money)
      expect(deserialized.cents).to eq(500)
      expect(deserialized.currency.to_s).to eq('USD')
    end
  end

  describe 'currency handling with defaults' do
    it 'applies currency from default Money objects' do
      product = ProductWithDefaults.new
      expect(product.tax_currency).to eq('USD')  # From Money.new(299, 'USD')
    end

    it 'applies currency from monetize currency option' do
      product = ProductWithDefaults.new
      expect(product.price_currency).to eq('USD')  # From currency: 'USD'
      expect(product.premium_currency).to eq('EUR') # From currency: 'EUR'
    end

    it 'updates currency when assigning Money object with different currency' do
      product = ProductWithDefaults.new
      expect(product.price_currency).to eq('USD')
      
      product.price = Money.new(1999, 'CAD')
      expect(product.price_currency).to eq('CAD')
    end
  end

  describe 'edge cases' do
    it 'handles BigDecimal defaults' do
      model_class = Class.new do
        include NestedRecord::Macro
        include ActiveModel::Model
        include ActiveModel::Attributes
        
        monetize :amount, default: BigDecimal('99.99')
      end

      instance = model_class.new
      expect(instance.amount.cents).to eq(9999)  # 99.99 * 100
    end

    it 'handles zero Money object defaults' do
      model_class = Class.new do
        include NestedRecord::Macro
        include ActiveModel::Model
        include ActiveModel::Attributes
        
        monetize :amount, default: Money.new(0, 'JPY')
      end

      instance = model_class.new
      expect(instance.amount.cents).to eq(0)
      expect(instance.amount.currency.to_s).to eq('JPY')
    end

    it 'handles default with JPY currency (no fractional parts)' do
      model_class = Class.new do
        include NestedRecord::Macro
        include ActiveModel::Model
        include ActiveModel::Attributes
        
        monetize :amount, currency: 'JPY', default: 25.75
      end

      instance = model_class.new
      expect(instance.amount.cents).to eq(26)  # Rounded by monetize gem
      expect(instance.amount.currency.to_s).to eq('JPY')
    end
  end
end
