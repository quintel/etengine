module Etsource
  module Config
    # Should ETsource::Wizards be included? 
    # true:  this makes the input_module work. 
    # false: turn off to make sure the ETengine is not affected by the input_module
    LOAD_WIZARDS = true

    # If you work on the input module, this disables caching and will
    # always reload the Etsource from scratch.
    FORCE_DATASET_RELOAD = true
  end
end