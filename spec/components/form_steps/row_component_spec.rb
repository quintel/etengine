# frozen_string_literal: true

RSpec.describe FormSteps::RowComponent, type: :component do
  context 'with title="Password" and content="Some content"' do
    let(:rendered) do
      render_inline(
        described_class.new(title: 'Password', label_for: 'password')
          .with_content('<p>Some content</p>'.html_safe)
      )
    end

    it 'renders the label' do
      expect(rendered).to have_css('label', text: 'Password')
    end

    it 'renders the title' do
      expect(rendered).to have_text('Some content')
    end
  end

  context 'with hint="Some help"' do
    let(:rendered) do
      render_inline(
        described_class.new(title: 'Password', label_for: 'password', hint: 'Some help')
          .with_content('<p>Some content</p>'.html_safe)
      )
    end

    it 'renders the hint text' do
      expect(rendered).to have_text('Some help')
    end
  end
end
