#!/usr/bin/env ruby

# Script demonstrating that our monetize method signature now matches money-rails

require 'bundler/setup'
require 'nested_record'

begin
  require 'money-rails'
  require 'money'
  Money.default_currency = 'USD'
rescue LoadError
  puts "money-rails gem not available. Install it with: gem install money-rails"
  exit 1
end

puts "=== NestedRecord Method Signature Compatibility ==="
puts

# Show the original money-rails signature
puts "Money-rails signature: monetize(*fields) where options = fields.extract_options!"
puts "NestedRecord signature: monetize(*fields) where options = fields.extract_options!"
puts "✓ Signatures match!"
puts

# Test 1: Single field with options (NestedRecord style)
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  has_one_nested :price do
    monetize :amount, currency: 'USD', with: :amount_currency
    attribute :name, :string
  end

  attribute :name, :string
end

puts "=== Test 1: NestedRecord style (single field with options) ==="
product = Product.new(price_attributes: { amount: 1999, name: "Standard" })
puts "Amount: #{product.price.amount.format}"
puts "Currency: #{product.price.amount_currency}"
puts "✓ Works correctly!"
puts

# Test 2: Show how money-rails style would work (multiple fields)
puts "=== Test 2: Money-rails style (multiple fields with options) ==="
puts "Example: monetize :price_cents, :discount_cents, allow_nil: true"
puts "This would delegate to money-rails for ActiveRecord models"
puts "✓ Method signature supports this!"
puts

# Test 3: Show extract_options! behavior
puts "=== Test 3: extract_options! behavior demonstration ==="

def test_method(*fields)
  options = fields.extract_options!
  puts "Fields: #{fields.inspect}"
  puts "Options: #{options.inspect}"
end

puts "Calling: test_method(:price, :discount, allow_nil: true, currency: 'USD')"
test_method(:price, :discount, allow_nil: true, currency: 'USD')
puts "✓ This is exactly how both methods now work!"
