#!/usr/bin/env ruby

# Example script demonstrating money-rails compatibility in NestedRecord

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

puts "=== NestedRecord Money-Rails Compatibility Demo ==="
puts

# Example 1: NestedRecord (ActiveModel attributes) - uses NestedRecord's monetize
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  has_one_nested :price do
    monetize :amount, currency: 'USD'
    monetize :discount, with: :discount_currency
    attribute :name, :string
  end

  attribute :name, :string
end

product = Product.new(
  name: "Awesome Widget",
  price_attributes: {
    name: "Standard Price",
    amount: 2999,  # $29.99 in cents
    discount: Money.new(500, 'USD')  # $5.00
  }
)

puts "=== NestedRecord Implementation (ActiveModel) ==="
puts "Product: #{product.name}"
puts "Price: #{product.price.amount.format}"
puts "Discount: #{product.price.discount.format}"
puts "Price amount type: #{product.price.amount.class}"
puts

# Example 2: Simulated ActiveRecord behavior
# Note: This would work if we had a real ActiveRecord model with database columns
puts "=== Potential ActiveRecord Usage ==="
puts "For ActiveRecord models with database columns like 'price_cents':"
puts "- The monetize method would delegate to money-rails"
puts "- NestedRecord's monetize is only used for nested attributes"
puts "- No conflicts occur because the method detection works properly"
puts

puts "=== Method Resolution Logic ==="
puts "NestedRecord's monetize method checks:"
puts "1. Multiple arguments (money-rails style) -> delegate to money-rails"
puts "2. Class has column_names method (ActiveRecord) -> delegate to money-rails"
puts "3. Otherwise -> use NestedRecord's implementation for nested attributes"
