Sequel.migration do
  change do
    create_table(:stocks) do
      primary_key :id
      Jsonb :data
      String :name, null: true
      Float :price, null: false
      column :tags, "text[]"
      String :ticker, null: false, unique: true  # stock symbol
    end
  end
end
