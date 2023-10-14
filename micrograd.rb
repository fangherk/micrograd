
require 'pry'

class Value
  attr_accessor :data, :gradient, :_backwards, :prev

  def initialize(data:, gradient: 0, prev: [])
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
    other = other.is_a?(Value) ? other : Value.new(data: other)
    output = Value.new(data:data + other.data, prev: [self, other])

    _backwards = Proc.new do
      self.gradient += 1.0 * output.gradient
      other.gradient += 1.0 * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def -(other)
    other = other.is_a?(Value) ? other : Value.new(data: other)
    other.data = -other.data
    self + other
  end

  def *(other)
    other = other.is_a?(Value) ? other : Value.new(data: other)
    output = Value.new(data:data * other.data, prev: [self, other])
    _backwards = Proc.new do
      self.gradient += other.data * output.gradient
      other.gradient += data * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def **(other)
    output = Value.new(data: @data**other, prev: [self])
    _backwards = Proc.new do
      self.gradient += other * @data ** (other-1) * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def tanh
    t = (Math.exp(2*@data)- 1)/ (Math.exp(2*@data) + 1)
    output = Value.new(data: t, prev: [self])

    _backwards = Proc.new do
      self.gradient += (1 - t**2) * output.gradient
    end
    output._backwards = _backwards
    output
  end

  def inspect
    "Value(data=#{{data:,gradient:, _backwards: }})"
  end

  def to_s
    "#{inspect}"
  end

  def coerce(other)
    [self, other]
  end
end

class Neuron
  attr_accessor :w, :b
  def initialize(n_inputs)
    @w = n_inputs.times.map { |n| Value.new(data:Random.rand * 2 - 1) } # -1 to 1
    @b = Value.new(data:Random.rand * 2 - 1)
  end

  def run(x)
    weights =w.zip(x).map { |wi, xi| wi * xi }
    act = ([weights, b]).flatten.sum
    act.tanh
  end

  def parameters
    @w + [@b]
  end
end

class Layer
  attr_accessor :neurons
  def initialize(n_inputs, n_outputs)
    @neurons = n_outputs.times.map { Neuron.new(n_inputs) }
  end

  def run(x)
    outs = neurons.map { |n| n.run(x) }
    outs.size == 0 ? outs[0] : outs
  end

  def parameters
    neurons.map { |neuron| neuron.parameters }.flatten
  end
end

class MLP
  attr_accessor :sz, :layers
  def initialize(n_inputs, n_outputs)
    @sz = [n_inputs] + n_outputs
    @layers = (0...n_outputs.size).map { |i| Layer.new(sz[i], sz[i+1]) }
  end

  def run(x)
    @layers.each { |layer| x = layer.run(x) }
    x
  end

  def parameters
    @layers.map do |layer|
      layer.parameters.map do |parameter|
        parameter
      end
    end.flatten
  end
end

# a = Value.new(data:2.0)
# x = Value.new(data:3.0)
# b = Value.new(data:4.0)
# o = a * x
# y = o + b
# y.gradient = 1
# # dy / db
# puts "y: #{y}"
# y.backwards
# result = {a:, x:, b:, o:}
# pp result


n = MLP.new(3, [4,4,1])

xs = [
  [2.0, 3.0, -1.0],
  [3.0, -1.0, 0.5],
  [0.5, 1.0, 1.0],
  [1.0, 1.0, -1.0],
]
ys = [1.0, -1.0, -1.0, 1.0]
ypred = xs.map { |x| n.run(x) }.flatten

100.times do |i|
  ypred = xs.map { |x| n.run(x) }.flatten
  loss = ys.zip(ypred).map do |ygt, yout|
    (yout - ygt)**2
  end.sum

  n.parameters.each do |param|
    param.gradient = 0
  end
  # Forward pass
  loss.backwards

  # puts y
  # puts y.gradient

  n.parameters.each { |param| param.data += -0.05 * param.gradient}
  puts "#{i} #{loss.data}"
end

pp ypred