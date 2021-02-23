require "rails_helper"

RSpec.describe EmailAuthentications::PasswordValidationsController, type: :request do

  describe "#create" do
    it "returns a list of all errors for the password" do
      post "/email_authentications/validate", params: {password: "I have no numbers"}
      body = JSON.parse(response.body)
      expected_response = {"errors" => ["must contain at least one number"]}
      expect(response.status).to eq 200
      expect(JSON.parse(response.body)).to eq(expected_response)
    end
  end

  it "returns no errors if the password is valid" do
    post "/email_authentications/validate", params: {password: "Resolve2SaveLives"}
    body = JSON.parse(response.body)
    expected_response = {"errors" => []}
    expect(response.status).to eq 200
    expect(JSON.parse(response.body)).to match_array(expected_response)
  end

end