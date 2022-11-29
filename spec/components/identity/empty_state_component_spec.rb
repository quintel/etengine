# frozen_string_literal: true

RSpec.describe Identity::EmptyStateComponent, type: :component do
  context 'with title="No posts yet" and content="Create your first post"' do
    let(:rendered) do
      render_inline(
        described_class.new(title: 'No posts yet')
          .with_content('<p>Create your first post</p>'.html_safe)
      )
    end

    it 'renders the title' do
      expect(rendered).to have_css('h3', text: 'No posts yet')
    end

    it 'renders the content' do
      expect(rendered).to have_css('p', text: 'Create your first post')
    end

    it 'renders no buttons wrapper' do
      expect(rendered).not_to have_css("[data-testid='buttons']")
    end
  end

  context 'with buttons' do
    let(:rendered) do
      render_inline(described_class.new(title: 'No posts yet')) do |component|
        component.buttons { 'Buttons' }
      end
    end

    it 'renders the buttons' do
      expect(rendered).to have_css("[data-testid='buttons']")
    end
  end
end
