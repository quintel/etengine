# frozen_string_literal: true

RSpec.describe FieldErrorsComponent, type: :component do
  let(:record) { User.new }

  context 'when the record attribute has no errors' do
    let(:rendered) do
      render_inline(described_class.new(record:, attribute: :password))
    end

    it 'renders nothing' do
      expect(rendered.to_s).to be_blank
    end
  end

  context 'when the record attribute has two errors' do
    before do
      record.errors.add(:password, :blank)
      record.errors.add(:password, :invalid)
    end

    let(:rendered) do
      render_inline(described_class.new(record:, attribute: :password))
    end

    it 'renders the first error' do
      expect(rendered).to have_css('li', text: "Password can't be blank")
    end

    it 'renders the second error' do
      expect(rendered).to have_css('li', text: 'Password is invalid')
    end
  end
end
