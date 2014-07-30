if Rails.env.production?
  Merit::LoadProfile.reader = Merit::LoadProfile::CachingReader.new
end
