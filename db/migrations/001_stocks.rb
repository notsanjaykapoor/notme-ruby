Sequel.migration do
  change do
    create_table(:stocks) do
      primary_key :id
      String :name, null: false, unique: true  # stock symbol
      Float :price, null: false
    end
  end
end
