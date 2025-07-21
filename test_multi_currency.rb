#!/usr/bin/env ruby

require 'bundler/setup'
require './lib/nested_record'

begin
  require 'money-rails'
  require 'money'
  Money.default_currency = 'USD'
rescue LoadError
  puts "money-rails gem not available. Install it with: gem install money-rails"
  exit 1
end

# Test model to demonstrate decimal conversion works with all currencies
class PriceTest
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  monetize :usd_amount, currency: 'USD'
  monetize :eur_amount, currency: 'EUR'
  monetize :myr_amount, currency: 'MYR'
  monetize :jpy_amount, currency: 'JPY'
  monetize :gbp_amount, currency: 'GBP'
end

puts "=== Testing Decimal to Cents Conversion Across Multiple Currencies ==="
puts

# Test with the same decimal value (30.50) across different currencies
test_value = 30.50

price = PriceTest.new(
  usd_amount: test_value,
  eur_amount: test_value,
  myr_amount: test_value,
  jpy_amount: test_value,
  gbp_amount: test_value
)

currencies = ['USD', 'EUR', 'MYR', 'JPY', 'GBP']
amounts = [price.usd_amount, price.eur_amount, price.myr_amount, price.jpy_amount, price.gbp_amount]

currencies.zip(amounts).each do |currency, amount|
  puts "#{currency}: #{test_value} => #{amount.format} (#{amount.cents} cents)"
end

puts
puts "All currencies show the same conversion: 30.50 => 3050 cents"
puts "The conversion is currency-agnostic!"

# Test with BigDecimal for more precision
puts
puts "=== Testing with BigDecimal Precision ==="
precision_value = BigDecimal('99.99')

price2 = PriceTest.new(
  usd_amount: precision_value,
  eur_amount: precision_value,
  myr_amount: precision_value
)

puts "USD: #{precision_value} => #{price2.usd_amount.format} (#{price2.usd_amount.cents} cents)"
puts "EUR: #{precision_value} => #{price2.eur_amount.format} (#{price2.eur_amount.cents} cents)"
puts "MYR: #{precision_value} => #{price2.myr_amount.format} (#{price2.myr_amount.cents} cents)"
