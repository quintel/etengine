# ruby lib/optimizer.rb
# ruby lib/optimizer.rb POPULATION=40 MUTATION_RATE=0.11 BREED_MUTATE=0.5

require 'rubygems'
require 'ostruct'
require 'pry'
require 'open-uri'
require 'json'

# Some settings for our algorithm
POPULATION    = ENV.fetch('POPULATION', 40)
MUTATION_RATE = ENV.fetch('MUTATION_RATE', 0.11)
BREED_MUTATE  = ENV.fetch('BREED_MUTATE', 0.5)

class Optimizer
  attr_accessor :population

  def initialize(inputs, count = 10)
    @population = Population.seed(inputs, count)
  end

  def evolve
    @population.calculate
    @population.save
    @population = @population.evolve_population
  end
end

class Population
  attr_reader :inputs, :genes
  @@counter = 0

  def initialize(genes, count = 10)
    @count = count
    @genes = genes
    @id = @@counter += 1
  end

  def self.seed(inputs, count = 10)
    genes = (0...count).map{ Gene.new(inputs) }
    Population.new(genes, count).tap(&:seed)
  end

  def ordered_genes
    @genes.sort_by(&:fitness).reverse
  end

  # this can be improved quite a bit.
  # by evolving population smarter we get to a better result.
  def evolve_population
    fittest = ordered_genes[0...2] # take the two fittest genes
    genes = [fittest]
    # takes 40% of the population. The fitter
    genes += (ordered_genes - [fittest]).flatten.select{ rand < 0.4}
    genes.flatten!
    genes = genes[0..@count/2]
    while genes.length < @count
      a = fittest.sort_by{rand}.first
      b = (genes - [a]).sort_by{rand}.first
      genes << a.breed(b)
    end
    genes.each(&:mutate)
    Population.new(genes, @count)
  end

  def calculate
    puts "#{@id} ------------------------------\n"
    @genes.each do |gene|
      gene.fitness
      puts gene
    end
    puts "+> #{ordered_genes.first}"
  end

  def seed
    @genes.each(&:seed)
  end

  def save
    File.open("tmp/pulation_#{@id}.dump", 'w') {|f|
      f.write Marshal.dump(self)
    }
  end

  def self.load(file)
    Marshal.load(File.read(file))
  end

end

# A gene holds settings for every input. 
class Gene
  attr_reader :inputs

  def initialize(inputs)
    @inputs = inputs.map(&:dup)
  end

  # initial gene with random settings
  def seed
    @inputs.each(&:randomize)
  end

  # randomly mutates genomes.
  def mutate
    @inputs.each do |input|
      input.randomize if rand < MUTATION_RATE
    end
    @fitness = nil
  end

  def input(input)
    @inputs.detect{|i| i.id == input.id}
  end

  # creates a copy
  def dup
    Gene.new(@inputs)
  end

  # create a child from two genes. randomly switches single chromosomes.
  def breed(other)
    g = dup
    g.inputs.each do |input|
      input.update(other.input(input).value) if rand < BREED_MUTATE
    end
    g
  end

  def to_s
    "Fitness: #{fitness.round(0)}, #{@inputs.map(&:value)}"
  end

  def fitness
    unless @fitness
      inputs = [@inputs, @inputs.map(&:subordinates)].flatten.compact
      params = inputs.map{|i| "input[#{i.id}]=#{i.value}"}.join("&")
      begin
        result = open("http://beta.ete.io/api/v2/api_scenarios/test.json?settings[end_year]=2030&#{params}&result[]=etflex_score")
        json = JSON.parse result.read
        @fitness = json['result']['etflex_score'].last.last
        # binding.pry if @fitness.round == 0
      rescue => e
        @fitness = -1
      end
    end
    @fitness
  end
end

# --- Slider and Slider Balancer methods. Taken from the etflex coffee scripts.

class Array
  def sum
    inject(0) {|a,b| a + b}
  end
end

class Input
  attr_accessor :id, :value, :min, :max, :step, :subordinates

  def initialize(attributes)
    attributes    = OpenStruct.new(attributes)
    @subordinates = attributes.subordinates || []
    @id    = attributes.id
    @value = attributes.value or attributes.start or attributes.min or 0
    @value = @value.to_f
    @min   = attributes.min.to_f
    @max   = attributes.max.to_f
    @step  = attributes.step.to_f
  end

  def dup
    input = super
    input.subordinates = input.subordinates.map(&:dup)
    input
  end

  def steps
    ((@max - @min) / @step).to_i
  end

  def randomize
    update(@min + (@step*rand(steps)).round(1))
  end

  def update(val)
    @value = val.to_f
    b = Balancer.new([self, *subordinates])
    # repeat a 100 times for a proper balance. i think 
    # i introduced a bug when porting the balancer from coffee.
    100.times { b.balance(self) }
    @value
  end

  def group_sum
    subordinates.map(&:value).sum
  end
end

class Balancer
  attr_reader :inputs

  def initialize(inputs)
    @inputs = inputs
    @max = 100.0
  end

  def balance(master)
    subordinates    = self.subordinates(master)
    balanced_inputs = subordinates.map{|s| BalancedInput.new(s)}
    return [] if subordinates.empty?

    sum  = inputs.map(&:value).sum
    flex = @max - sum

    iterationInputs = balanced_inputs.dup

    100.times do |i|
      nextIterationInputs = []
      iterStartFlex       = flex
      iterDelta           = cumulative_delta(iterationInputs)

      iterationInputs.each do |input|
        flexPerSlider = iterStartFlex * (input.delta / iterDelta)
        prevValue = input.value
        newValue  = input.value = (prevValue + flexPerSlider)
        flex     -= newValue - prevValue

        nextIterationInputs << input if input.canChangeDirection(flex)
        iterationInputs = nextIterationInputs
        #binding.pry
        #break if flex == 0.0 || flex == iterStartFlex
      end
      
      if flex >= 0.1 or flex <= -0.1 
        [] 
      else
        balanced_inputs.each(&:commit)
        subordinates
      end
    end
  end

  def subordinates(master)
    inputs.select{|i| i.id != master.id}
  end

  def cumulative_delta(inputs)
    inputs.map(&:delta).sum
  end
end


class BalancedInput
  attr_accessor :input, :precision, :id, :value, :delta

  def initialize(input, precision = 1)
    @input     = input
    @precision = precision
    @id        = @input.id
    @value     = @input.value
    @delta     = @input.max - @input.min
  end

  def value=(newValue)
    newValue = @input.min if newValue < @input.min
    newValue = @input.max if newValue > @input.max
    @value = newValue
  end

  def canChangeDirection(flex)
    (flex < 0 and @value != @input.min) or
       (flex > 0 and @value != @input.max)
  end

  def commit
    @input.value = @value
  end
end



# Slider settings

i1 = Input.new(id: 250, value: 3,   min: 0, max: 10,   step: 1.0) # coal
i2 = Input.new(id: 257, value: 5,   min: 0, max: 10,   step: 1.0) # gas
i3 = Input.new(id: 259, value: 0.4, min: 0, max: 2.0,  step:  0.1) # nuclear
i4 = Input.new(id: 265, value: 60,  min: 0, max: 2000, step: 20.0) # wind
i5 = Input.new(id:  47, value: 6,   min: 0, max: 100,  step:  1.0) # solar
i6 = Input.new(id: 488, value: 0.0602654,   min: 0, max: 10,  step:  0.1, subordinates: [
  Input.new(id: 489, value: 99.9397,  min: 0, max: 100, step: 0.1),
])

d1 = Input.new(id: 336, value: 1.0,   min: 1, max: 3.0,   step: 0.01)
d2 = Input.new(id: 146, value: 0.0,   min: 0, max: 100,   step: 1.0, subordinates: [
  Input.new(id: 147, value: 47.1526,  min: 0, max: 100, step: 1.0),
  Input.new(id: 148, value: 48.1261,  min: 0, max: 100, step: 1.0),
  Input.new(id: 238, value: 4.57154,  min: 0, max: 100, step: 1.0),
  Input.new(id: 239, value: 0.149704, min: 0, max: 100, step: 1.0)
]) # electric cars
d3 = Input.new(id: 43,  value: 20,   min: 0, max: 100, step: 1.0, subordinates: [
     Input.new(id: 44,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 245, value: 80,   min: 0, max: 100, step: 1.0)
]) # electric cars
d4 = Input.new(id: 439,  value: 0,   min: 0, max: 100, step: 1.0, subordinates: [
     Input.new(id: 347,  value: 7.09204,   min: 0, max: 100, step: 1.0),
     Input.new(id: 420,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 421,  value: 2.38406,   min: 0, max: 100, step: 1.0),
     Input.new(id: 435,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 346,  value: 13.5786,   min: 0, max:  50, step: 1.0),
     Input.new(id: 443,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 444,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 445,  value:  0,   min: 0, max: 100, step: 1.0),
     Input.new(id: 446,  value: 76.9453,   min: 0, max: 100, step: 1.0)
])
d5 = Input.new(id: 338,  value: 0.0748925, min: 0, max: 100, step: 1.0, subordinates: [
     Input.new(id: 48,   value: 0,         min: 0, max: 15,  step: 1.0),
     Input.new(id: 51,   value: 0,         min: 0, max: 60,  step: 1.0),
     Input.new(id: 52,   value: 1.75997,   min: 0, max: 100, step: 1.0),
     Input.new(id: 248,  value: 1.24269,   min: 0, max: 100, step: 1.0),
     Input.new(id: 317,  value: 0.00301047,min: 0, max: 100, step: 1.0),
     Input.new(id: 333,  value: 82.1009,   min: 0, max: 100, step: 1.0),
     Input.new(id: 339,  value: 0.0374463, min: 0, max: 60,  step: 1.0),
     Input.new(id: 340,  value: 2.55678,   min: 0, max: 100, step: 1.0),
     Input.new(id: 375,  value: 0,         min: 0, max: 100, step: 1.0),
     Input.new(id: 411,  value: 0.0615576, min: 0, max: 100, step: 1.0),
     Input.new(id: 441,  value: 9.12235,   min: 0, max: 100, step: 1.0),
     Input.new(id: 582,  value: 3.04041,   min: 0, max: 100, step: 1.0)
])
d6 = Input.new(id: 336, value: 1.0,   min: 0.0, max: 100.0,   step: 1.0)

opt = Optimizer.new([d1,d2,d3,d4,d5,d6,i1,i2,i3,i4,i5,i6], POPULATION)
20.times { opt.evolve }
binding.pry # pry inside in case you want to iterate more.
