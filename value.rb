
require 'pry'

class Value
  attr_accessor :data, :gradient, :_backwards, :prev

  def initialize(data, gradient: 0, prev: [])
    @data = data
    @gradient = gradient
    @prev = Set.new(prev)
    @_backwards = Proc.new {}
  end

  def backwards
    nodes = []
    visited = Set.new([])
    build_topo = Proc.new do |v, nodes, visited|
      if !visited.include?(v)
        visited.add(v)
        v.prev.each { |n| build_topo.call(n, nodes, visited) }
        nodes << v
      end
    end
    build_topo.call(self, nodes, visited)
    self.gradient = 1.0
    nodes.reverse.each { |n| n._backwards.call }
  end

  def +(other)
    other = other.is_a?(Value) ? other : Value.new(other)
    output = Value.new(data + other.data, prev: [self, other])

    _backwards = Proc.new do
      self.gradient += 1.0 * output.gradient
      other.gradient += 1.0 * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def -(other)
    other = other.is_a?(Value) ? other : Value.new(other)
    other.data = -other.data
    self + other
  end

  # This is a unary minus
  def -@
    Value.new(-data)
  end

  def *(other)
    other = other.is_a?(Value) ? other : Value.new(other)
    output = Value.new(data * other.data, prev: [self, other])
    _backwards = Proc.new do
      self.gradient += other.data * output.gradient
      other.gradient += data * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def /(other)
    other = other.is_a?(Value) ? other : Value.new(other)
    output = Value.new(data * (other.data ** (-1)), prev: [self, other])
    _backwards = Proc.new do
      self.gradient += other.data * output.gradient
      other.gradient += data * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def **(other)
    output = Value.new(@data**other, prev: [self])
    _backwards = Proc.new do
      self.gradient += other * @data ** (other-1) * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def tanh
    t = (Math.exp(2*@data)- 1)/ (Math.exp(2*@data) + 1)
    output = Value.new(t, prev: [self])

    _backwards = Proc.new do
      self.gradient += (1 - t**2) * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def inspect
    "Value(#{{data:,gradient:}})"
  end

  def to_s
    "#{inspect}"
  end

  def coerce(other)
    [Value.new(other), self]
  end
end



# a = Value.new(2.0)
# x = Value.new(3.0)
# b = Value.new(4.0)
# o = a * x
# y = o + b
# y.gradient = 1
# # dy / db
# puts "y: #{y}"
# y.backwards
# result = {a:, x:, b:, o:}
# pp result


