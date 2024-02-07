class AppPlaid < Roda
  route do |r|
    r.get "connect" do
      struct = ::Service::Plaid::Tokens::LinkCreate.new(client_name: "notme", user_id: "sanjay").call

      @text = "Plaid Sandbox"
      @token = struct.token

      view("plaid/connect", layout: "layouts/plaid")
    end
  end
end