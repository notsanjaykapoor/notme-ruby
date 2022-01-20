Sequel.migration do
  change do
    create_table(:cities) do
      primary_key :id
      String :country, null: true
      Jsonb :data
      column :lat, "numeric(10,5)", default: 0.0
      column :lon, "numeric(10,5)", default: 0.0
      String :name, null: false, unique: true
      String :region, null: true
      column :tags, "text[]"
      Float :temp, null: false
      column :updated_at, DateTime # timestamp

      index :name, unique: true
      index :temp
      index :updated_at
    end
  end
end
