Sequel.migration do
  up do
    create_table :images do
      primary_key :id
      String :title
      String :file
    end
  end

  down do
    drop_table :images
  end
end
