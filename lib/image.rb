class Image < Sequel::Model
  mount_uploader :file, ImageUploader
  many_to_many :tags
end