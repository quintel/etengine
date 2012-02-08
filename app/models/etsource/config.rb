module Etsource
  module Config
    # Should ETsource::Wizards be included? 
    # true:  this makes the input_module work. 
    # false: turn off to make sure the ETengine is not affected by the input_module
    LOAD_WIZARDS  = APP_CONFIG.fetch(:etsource_load_wizards, false)

    # If you work on the input module, this disables caching and will
    # always reload the Etsource from scratch.
    CACHE_DATASET = APP_CONFIG.fetch(:etsource_cache_dataset, true)
  end
end