require 'spec_helper'

describe CsvImporter do
  it { should validate_presence_of :zip_file }
end
