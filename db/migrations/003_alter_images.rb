Sequel.migration do
  up do
    alter_table(:images) do
      add_column :description, String
    end
  end
  down do
    alter_table(:images) do
      drop_column :description
    end
  end
end