#!/usr/bin/env ruby

# Example script demonstrating monetize support in NestedRecord

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

# Define a Product with a nested Price model that uses monetize
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  has_one_nested :price do
    monetize :amount, currency: 'USD'
    monetize :discount, with: :discount_currency
    monetize :tax, with: false  # No currency field

    attribute :name, :string
  end

  attribute :name, :string
end

puts "=== NestedRecord Monetize Support Demo ==="
puts

# Create a product with price
product = Product.new(
  name: "Awesome Widget",
  price_attributes: {
    name: "Standard Price",
    amount: 2999,  # $29.99 in cents
    discount: Money.new(500, 'USD'),  # $5.00
    tax: 299  # $2.99 in cents
  }
)

puts "Product: #{product.name}"
puts "Price Name: #{product.price.name}"
puts "Amount: #{product.price.amount} (#{product.price.amount.format})"
puts "Amount Currency: #{product.price.amount_currency}"
puts "Discount: #{product.price.discount} (#{product.price.discount.format})"
puts "Discount Currency: #{product.price.discount_currency}"
puts "Tax: #{product.price.tax} (#{product.price.tax.format})"
puts "Tax has currency attribute: #{product.price.respond_to?(:tax_currency)}"
puts

# Demonstrate serialization
puts "=== Serialization Demo ==="
json_data = product.as_json
puts "Serialized as JSON:"
require 'json'
puts JSON.pretty_generate(json_data)
puts

# Create from Money objects
puts "=== Money Object Assignment ==="
product.price.amount = Money.new(3999, 'EUR')
puts "Updated amount: #{product.price.amount} (#{product.price.amount.format})"
puts "Updated currency: #{product.price.amount_currency}"
puts

puts "Demo completed successfully!"
