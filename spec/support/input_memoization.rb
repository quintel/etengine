# frozen_string_literal: true

# Input memoizes data derived from `all` -- share groups, coupling groups,
# before-update inputs -- in class-level instance variables which nothing
# invalidates. A spec which stubs `Input.all` and then triggers one of these
# lookups leaves the memo behind after RSpec unwinds the stub, so every later
# example in the process sees the stubbed subset. An empty `inputs_grouped`
# makes ScenarioUpdater::ShareGroups yield nothing, and share group validation
# silently passes without checking anything.
#
# Once the memos move into NastyCache (so `Etsource::Reloader` invalidates them
# together with `all` and `records`), this becomes `Input.clear!`.
module InputMemoizationHelper
  DERIVED_MEMOS = %i[
    @before_inputs
    @inputs_grouped
    @coupling_inputs_keys
    @coupling_groups
  ].freeze

  def self.clear!
    DERIVED_MEMOS.each { |memo| Input.instance_variable_set(memo, nil) }
  end
end

RSpec.configure do |config|
  config.before { InputMemoizationHelper.clear! }
end
