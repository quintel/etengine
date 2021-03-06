module MechanicalTurkHelper

  def some_tolerance
    @some_tolerance ||= ENV.fetch('TOLERANCE', 3.0)
  end

  def print_comparison(endpoints)
    @proxy.print_comparison(endpoints)
  end

  def the_value(cmd = RSpec.current_example.description)
    @proxy.the_value(cmd)
  end

  def the_present(cmd = RSpec.current_example.description)
    @proxy.the_present(cmd)
  end

  def the_future(cmd = RSpec.current_example.description)
    @proxy.the_future(cmd)
  end

  def the_relative_increase(cmd = RSpec.current_example.description)
    @proxy.the_relative_increase(cmd)
  end

  def the_absolute_increase(cmd = RSpec.current_example.description)
    @proxy.the_absolute_increase(cmd)
  end

  def load_scenario(options = {}, &block)
    @proxy = MechanicalTurk::SpecDSL.new
    @proxy.load_scenario(options, &block)
  end

  # when passing a dynamically created input, make sure
  # to assign key and update_period.
  def move_slider(input, value)
    @proxy.move_slider(input, value)
  end
end
