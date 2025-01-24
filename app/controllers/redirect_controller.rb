# frozen_string_literal: true

class RedirectController < ApplicationController

  # This action sets a cookie to track the last visited page
  # and then redirects the user to the specified destination.
  def set_cookie_and_redirect
    cookies[:last_visited_page] = {
      value: root_path,
      domain: :all,
      secure: Rails.env.production?,
      expires: 1.day.from_now
    }

    redirect_to "#{Settings.idp_url}/#{params[:page]}", allow_other_host: true
  end
end
