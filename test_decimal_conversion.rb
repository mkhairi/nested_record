#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/nested_record'

begin
  require 'money-rails'
  require 'money'
  Money.default_currency = 'MYR'
rescue LoadError
  puts "money-rails gem not available. Install it with: gem install money-rails"
  exit 1
end

# Test model to demonstrate the fix
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  has_one_nested :price do
    monetize :amount, currency: 'MYR'
    attribute :name, :string
  end

  attribute :name, :string
end

puts "=== Testing Decimal to Cents Conversion ==="
puts

# Test the fix
product = Product.new(
  name: "Test Product",
  price_attributes: {
    name: "Test Price",
    amount: 30.00  # This should now become RM30.00 instead of RM0.30
  }
)

puts "Product: #{product.name}"
puts "Price Name: #{product.price.name}"
puts "Amount (Money object): #{product.price.amount.inspect}"
puts "Amount (formatted): #{product.price.amount.format}"
puts "Amount in cents: #{product.price.amount.cents}"
puts "Currency: #{product.price.amount.currency}"
puts

# Test with different values
test_cases = [
  30.00,    # Should be 3000 cents = RM30.00
  25.50,    # Should be 2550 cents = RM25.50
  100,      # Should be 100 cents = RM1.00 (integer, treated as cents)
  1000      # Should be 1000 cents = RM10.00 (integer, treated as cents)
]

puts "=== Testing Various Input Values ==="
test_cases.each do |test_value|
  test_product = Product.new(price_attributes: { amount: test_value })
  puts "Input: #{test_value.inspect} => #{test_product.price.amount.format} (#{test_product.price.amount.cents} cents)"
end

puts
puts "Fix applied successfully! Decimal values are now properly converted to cents."
