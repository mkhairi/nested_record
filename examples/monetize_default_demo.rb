#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'nested_record'

puts "=== NestedRecord Monetize Default Values Demo ==="
puts

# Define models with default money values
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  monetize :price, currency: 'USD', default: 9.99          # Default $9.99
  monetize :shipping, currency: 'USD', default: 500        # Default 500 cents = $5.00
  monetize :tax, default: Money.new(299, 'USD')            # Default Money object = $2.99
  monetize :discount, with: false, default: 0              # Default $0.00, no currency attribute
end

class ProductWithNestedDefaults
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  has_one_nested :pricing do
    monetize :amount, currency: 'EUR', default: 19.99      # Default €19.99
    monetize :discount, default: Money.new(199, 'GBP')     # Default £1.99
    attribute :description, :string, default: 'Standard pricing'
  end
end

class UserWithDefaults
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  nested_accessors from: :financial_info do
    monetize :salary, currency: 'USD', default: 50000.00   # Default $50,000
    monetize :bonus, default: 5000.00                      # Default $5,000
    monetize :allowance, default: 0                        # Default $0
    attribute :department, :string, default: 'General'
  end
end

puts "1. Simple Model with Default Values:"
product = Product.new
puts "   Price: #{product.price} (default: $9.99)"
puts "   Shipping: #{product.shipping} (default: 500 cents = $5.00)"
puts "   Tax: #{product.tax} (default: Money object $2.99)"
puts "   Discount: #{product.discount} (default: $0.00, no currency attr)"
puts "   Has discount_currency method: #{product.respond_to?(:discount_currency)}"

puts "\n2. Overriding Default Values:"
product.price = 15.99
product.shipping = 750
product.tax = Money.new(399, 'CAD')
puts "   Updated Price: #{product.price}"
puts "   Updated Shipping: #{product.shipping}"
puts "   Updated Tax: #{product.tax} (currency changed to CAD)"

puts "\n3. Nested Record with Default Values:"
nested_product = ProductWithNestedDefaults.new
nested_product.build_pricing  # Build the nested record first
puts "   Pricing Amount: #{nested_product.pricing.amount} (default: €19.99)"
puts "   Pricing Discount: #{nested_product.pricing.discount} (default: £1.99)"
puts "   Pricing Description: #{nested_product.pricing.description}"

puts "\n4. nested_accessors with Default Values:"
user = UserWithDefaults.new
puts "   Salary: #{user.salary} (default: $50,000)"
puts "   Bonus: #{user.bonus} (default: $5,000)"
puts "   Allowance: #{user.allowance} (default: $0)"
puts "   Department: #{user.department}"

puts "\n5. Explicit nil Assignment (should use defaults):"
product_nil = Product.new(price: nil, shipping: nil)
puts "   Price with nil: #{product_nil.price} (should be default $9.99)"
puts "   Shipping with nil: #{product_nil.shipping} (should be default $5.00)"

puts "\n6. Empty String Assignment (should be nil, not default):"
product_empty = Product.new(price: '', shipping: '')
puts "   Price with empty string: #{product_empty.price.inspect} (should be nil)"
puts "   Shipping with empty string: #{product_empty.shipping.inspect} (should be nil)"

puts "\n7. Serialization with Defaults:"
puts "   Product JSON:"
puts "   #{product.as_json}"
puts "\n   Nested Product JSON:"
puts "   #{nested_product.as_json}"

puts "\n=== Benefits of Default Values ==="
puts "✅ No need to manually set common values in initializers"
puts "✅ Consistent behavior across instances" 
puts "✅ Supports all money value formats (decimals, integers, Money objects)"
puts "✅ Works with nested records and nested_accessors"
puts "✅ Defaults are applied during attribute casting, not initialization"
puts "✅ Explicit nil triggers defaults, empty string returns nil"
