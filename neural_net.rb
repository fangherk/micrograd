require "./value.rb"

module ZeroGrad
  def zero_grad
    self.parameters.each { |param| param.gradient = 0 }
  end

  def parameters
    raise "This is not implemented in #{self.class}"
  end
end


class Neuron
  include ZeroGrad

  attr_accessor :w, :b
  def initialize(n_inputs)
    @w = n_inputs.times.map { |n| Value.new(Random.rand * 2 - 1) } # -1 to 1
    @b = Value.new(Random.rand * 2 - 1)
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
  include ZeroGrad
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
  include ZeroGrad
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


n = MLP.new(3, [4,4,1])

xs = [
  [2.0, 3.0, -1.0],
  [3.0, -1.0, 0.5],
  [0.5, 1.0, 1.0],
  [1.0, 1.0, -1.0],
]
ys = [1.0, -1.0, -1.0, 1.0]
ypred = xs.map { |x| n.run(x) }.flatten
loss = 0

100.times do |i|
  ypred = xs.map { |x| n.run(x) }.flatten
  loss = ys.zip(ypred).map do |ygt, yout|
    (yout - ygt)**2
  end.sum

  n.zero_grad
  # Forward pass
  loss.backwards

  n.parameters.each { |param| param.data += -0.05 * param.gradient}
  # puts "#{i} #{loss.data}"
end
puts loss.data

pp ypred