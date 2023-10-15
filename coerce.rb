require 'pry'

class Temp
  attr_accessor :value
  def initialize(value)
    @value = value
  end

  def +(other)
    other = other.is_a?(Temp) ? other : Temp.new(other)
    Temp.new(self.value + other.value)
  end

  def -(other)
    other = other.is_a?(Temp) ? other : Temp.new(other)
    Temp.new(self.value - other.value)
  end

  def to_s
    "Temp(#{{value:}})"
  end

  def coerce(other)
    puts "other: #{other}"
    [Temp.new(other), self]
  end
end

n = Temp.new(2)
result = n + 1
puts "result: #{result}"
second_result = 5 - n
puts "second_result: #{second_result}"