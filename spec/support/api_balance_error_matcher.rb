RSpec::Matchers.define :have_api_balance_error do
  match do |actual|
    errors = actual['errors']

    if @group.nil?
      errors.any? { |error| error.match(/group does not balance/) }
    else
      group_re = Regexp.escape(@group.to_s)

      errors.any? do |error|
        error.match(/^"#{ group_re }" group does not balance/)
      end
    end
  end

  failure_message_for_should do |actual|
    if @group.nil?
      'expected a group not to balance, but all did'
    else
      "expected group #{ @group.inspect } to not balance, but it did"
    end
  end

  description do
    if @group.nil?
      'have an API balance error'
    else
      "have an API balance error on the #{ @group.inspect } group"
    end
  end

  # Specify a group which we expect not to balance.
  #
  # For example:
  #   expect(...).to have_api_balance_error.on(:my_share_group)
  #
  def on(group)
    @group = group
    self
  end
end # :have_api_balance_error
