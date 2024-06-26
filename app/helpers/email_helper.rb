module EmailHelper
  def email_inline_image_tag(image, **options)
    attachments.inline[image] = File.read(Rails.root.join("app/assets/images/#{image}"))
    image_tag(attachments[image].url, **options)
  end
end
