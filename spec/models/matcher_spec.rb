require 'spec_helper'

describe "increase" do
  specify { expect(-1.0).not_to increase}
  specify { expect(0.0).not_to increase}
  specify { expect(1.0).to increase}
  specify { expect(nil).not_to increase}
end

describe "increase" do
  specify { expect(-1.0).to decrease}
  specify { expect(0.0).not_to decrease}
  specify { expect(1.0).not_to decrease}
  specify { expect(nil).not_to decrease}
end
