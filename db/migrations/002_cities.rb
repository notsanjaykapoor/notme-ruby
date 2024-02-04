Sequel.migration do
  change do
    create_table(:cities) do
      primary_key :id
      column :bbox, "numeric(12,6)[]"
      String :country_code, null: true, size: 25
      Jsonb :data
      column :lat, "numeric(12,6)", default: 0.0
      column :lon, "numeric(12,6)", default: 0.0
      String :name, null: false, size: 100
      String :region, null: true, size: 100
      column :tags, "text[]"
      column :updated_at, DateTime # timestamp

      index :name, unique: true
      index :updated_at
    end
  end
end
