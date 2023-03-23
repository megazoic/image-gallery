class ImageUploader < CarrierWave::Uploader::Base
  include CarrierWave::RMagick
  process resize_to_fit: [1000, 1000]
  version :small do
    process resize_to_fit: [720, 720]
  end
end