# frozen_string_literal: true

class ModalComponent < ApplicationComponent
  include Turbo::FramesHelper

  StimulusConfig = Struct.new(
    :controller,
    :turbo_frame_id,
    :backdrop_close_action,
    :keyboard_close_action,
    :button_close_action,
    keyword_init: true
  ) do
    def enabled?
      !controller.nil?
    end
  end

  option :title

  def stimulus
    @stimulus ||=
      if turbo_modal?
        StimulusConfig.new(
          controller: 'modal',
          turbo_frame_id: :modal,
          button_close_action: 'click->modal#close',
          backdrop_close_action: 'mousedown->modal#closeWithBackdrop',
          keyboard_close_action: 'keyup@window->modal#closeWithKeyboard'
        )
      else
        StimulusConfig.new(turbo_frame_id: :static_modal)
      end
  end

  def close_link(inline_content, url = nil, **kwargs)
    kwargs[:data] ||= {}
    kwargs[:data][:action] = stimulus.button_close_action
    kwargs[:data][:turbo_frame] = stimulus.enabled? ? stimulus.turbo_frame_id : nil

    link_to(inline_content || content, url, **kwargs)
  end

  private

  def turbo_modal?
    request.headers['Turbo-Frame'] == 'modal'
  end
end
