module Etsource
  class GqlTestCases
    def initialize(etsource)
      @etsource = etsource
    end

    def import!
      GqlTestCase.delete_all
      import
    end

    def import
      base_dir = "#{@etsource.export_dir}/test_suites"
      Dir.glob("#{base_dir}/**/*.js").each do |f|
        key = f.split('/').last.split('.').first
        GqlTestCase.create(:name => key, :instruction => File.read(f))
      end
    end
  end
end
