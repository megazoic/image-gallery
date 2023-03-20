Sequel.migration do
  up do
    create_table :tags do
      primary_key :id
      String :name
    end
    create_join_table(image_id: :images, tag_id: :tags)
  end

  down do
    drop_join_table(image_id: :images, tag_id: :tags)
    drop_table :tags
  end
end
