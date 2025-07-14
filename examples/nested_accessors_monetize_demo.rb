#!/usr/bin/env ruby

# Example script demonstrating monetize support in NestedRecord with nested_accessors

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

# Define a User model with nested_accessors that use monetize
class User
  include NestedRecord::Macro
  include ActiveModel::Model
  include ActiveModel::Attributes

  attribute :name, :string

  # Use nested_accessors with monetize attributes
  nested_accessors from: :financial_info do
    monetize :salary, currency: 'USD'
    monetize :bonus, with: :bonus_currency
    monetize :commission, with: false  # No currency field

    attribute :department, :string
    attribute :hire_date, :date
  end
end

puts "=== NestedRecord Monetize + nested_accessors Demo ==="
puts

# Create a user with financial information
user = User.new(name: "John Doe")

# Set financial data using nested_accessors
user.salary = 7500000  # $75,000 in cents
user.bonus = Money.new(500000, 'EUR')  # €5,000
user.commission = 150000  # $1,500 in cents
user.department = "Engineering"

puts "User: #{user.name}"
puts "Department: #{user.department}"
puts

puts "=== Monetize Attributes via nested_accessors ==="
puts "Salary: #{user.salary} (#{user.salary.format})"
puts "Salary Currency: #{user.salary_currency}"
puts "Bonus: #{user.bonus} (#{user.bonus.format})"
puts "Bonus Currency: #{user.bonus_currency}"
puts "Commission: #{user.commission} (#{user.commission.format})"
puts "Commission has currency attribute: #{user.respond_to?(:commission_currency)}"
puts

# Demonstrate currency update when Money object is assigned
puts "=== Currency Update Demo ==="
user.salary = Money.new(8000000, 'CAD')  # Change to Canadian dollars
puts "Updated salary: #{user.salary} (#{user.salary.format})"
puts "Updated currency: #{user.salary_currency}"
puts

# Demonstrate serialization
puts "=== Serialization Demo ==="
json_data = user.as_json
puts "Serialized as JSON:"
require 'json'
puts JSON.pretty_generate(json_data)
puts

puts "=== Method Delegation Verification ==="
puts "User responds to salary: #{user.respond_to?(:salary)}"
puts "User responds to salary=: #{user.respond_to?(:salary=)}"
puts "User responds to salary_currency: #{user.respond_to?(:salary_currency)}"
puts "User responds to bonus_currency: #{user.respond_to?(:bonus_currency)}"
puts "User responds to commission_currency: #{user.respond_to?(:commission_currency)}"
puts

puts "Demo completed successfully!"
