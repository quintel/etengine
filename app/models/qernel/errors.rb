module Qernel
  # Error class which serves as a base for all errors which occur in the Qernel.
  class Error < RuntimeError
    def initialize(*args) ; super(make_message(*args)) end
    def make_message(msg) ; msg end
  end

  # Internal: Creates a new error class which inherits from Qernel::Error,
  # whose message is created by evaluating the block you give.
  #
  # For example
  #
  #   MyError = error_class do |weight, limit|
  #     "#{ weight } exceeds #{ limit }"
  #   end
  #
  #   fail MyError.new(5000, 2500)
  #   # => #<Qernel::MyError: 5000 exceeds 2500>
  #
  # Returns an exception class.
  def self.error_class(superclass = Error, &block)
    Class.new(superclass) { define_method(:make_message, &block) }
  end

  # ----------------------------------------------------------------------------

  IllegalValueError = error_class do |obj, attr, value|
    "#{ value } is not a legal value for the #{ attr } attribute " \
    "for #{ obj }"
  end

  IllegalZeroError = error_class(IllegalValueError) do |obj, attr|
    super(obj, attr, 'Zero')
  end

  IllegalNegativeError = error_class(IllegalValueError) do |obj, attr, value|
    super(obj, attr, "Negative value (#{ value })")
  end
end # Qernel
