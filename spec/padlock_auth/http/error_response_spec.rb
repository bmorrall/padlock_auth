require "rails_helper"

RSpec.describe PadlockAuth::Http::ErrorResponse do
  describe "#description" do
    it "provides a default error message" do
      expect(described_class.new.description).to eq("An error occurred while processing your request.")
    end
  end

  describe "#status" do
    it "defaults to :bad_request" do
      expect(described_class.new.status).to eq(:bad_request)
    end
  end

  describe "#raise_exception!" do
    it "requires subclasses to define #exception_class" do
      expect { described_class.new.raise_exception! }.to raise_error(NotImplementedError, "error response must define #exception_class")
    end
  end
end
