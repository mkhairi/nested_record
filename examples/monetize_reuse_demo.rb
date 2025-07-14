#!/usr/bin/env ruby
# frozen_string_literal: true

require 'bundler/setup'
require 'nested_record'

puts "=== NestedRecord Monetize Implementation Now Reuses money-rails/monetize Logic ==="
puts

# Demonstrate the refactored implementation using monetize gem's conversion logic
class Product
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  monetize :price, currency: 'USD'
  monetize :wholesale_price, currency: 'EUR'
end

puts "1. Backward Compatibility - Integers are still treated as cents:"
product = Product.new(price: 100)
puts "   Price set to integer 100 → #{product.price} (#{product.price.cents} cents)"

puts "\n2. Decimal Values - Now using monetize gem's to_money conversion:"
product.price = 30.00
puts "   Price set to decimal 30.00 → #{product.price} (#{product.price.cents} cents)"

product.price = 25.50
puts "   Price set to decimal 25.50 → #{product.price} (#{product.price.cents} cents)"

puts "\n3. BigDecimal Support - Leveraging monetize gem's parsing:"
require 'bigdecimal'
product.price = BigDecimal('99.99')
puts "   Price set to BigDecimal('99.99') → #{product.price} (#{product.price.cents} cents)"

puts "\n4. Multi-Currency Support with Currency-Aware Conversion:"
# EUR with decimals
product.wholesale_price = 45.75
puts "   Wholesale price (EUR) set to 45.75 → #{product.wholesale_price} (#{product.wholesale_price.cents} cents)"

# JPY special handling (no fractional parts)
class JapaneseProduct
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  monetize :price, currency: 'JPY'
end

jp_product = JapaneseProduct.new(price: 25.75)
puts "   Japanese price (JPY) set to 25.75 → #{jp_product.price} (#{jp_product.price.cents} yen)"
puts "     ↳ JPY correctly rounds fractional amounts since yen has no cents"

puts "\n5. Money Object Assignment (unchanged):"
product.price = Money.new(5000, 'USD')
puts "   Price set to Money.new(5000, 'USD') → #{product.price}"

puts "\n=== Benefits of Reusing monetize gem logic ==="
puts "✅ Leverages proven conversion algorithms from monetize gem"
puts "✅ Handles currency-specific rounding rules (e.g., JPY has no fractional parts)"
puts "✅ Maintains backward compatibility for integer values"
puts "✅ Reduces code duplication and maintenance burden"
puts "✅ Gets automatic updates when monetize gem improves"
puts "✅ Consistent behavior with money-rails and other monetize-based libraries"
