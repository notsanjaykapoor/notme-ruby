Sequel.migration do
  change do
    create_table(:places) do
      primary_key :id
      String :country_code, null: true, size: 25
      String :city, null: false, size: 100
      Jsonb :data
      Jsonb :geo_json
      column :lat, "numeric(12,6)", default: 0.0
      column :lon, "numeric(12,6)", default: 0.0
      String :name, null: false, size: 100
      String :source_id, null: false, size: 100
      String :source_name, null: false, size: 100
      column :tags, "text[]"
      column :updated_at, DateTime # timestamp

      index :city
      index :name, unique: true
      index [:source_id, :source_name], unique: true
      index :updated_at
    end
  end
end
