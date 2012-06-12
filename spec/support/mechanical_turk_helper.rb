module MechanicalTurkHelper

  def some_tolerance
    @some_tolerance ||= ENV.fetch('TOLERANCE', 3.0)
  end

  def the_present(cmd = example.description)
    @proxy.the_present(cmd)
  end

  def the_future(cmd = example.description)
    @proxy.the_future(cmd)
  end

  def the_relative_increase(cmd = example.description)
    @proxy.the_relative_increase(cmd)
  end

  def the_absolute_increase(cmd = example.description)
    @proxy.the_absolute_increase(cmd)
  end

  def load_scenario(options = {}, &block)
    @proxy = MechanicalTurk::SpecDSL.new
    @proxy.load_scenario(options, &block)
  end

  # when passing a dynamically created input, make sure
  # to assign lookup_id and update_period.
  def move_slider(input, value)
    @proxy.move_slider(input, value)
  end
end
