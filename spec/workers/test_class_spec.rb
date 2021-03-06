# frozen_string_literal: true

require "spec_helper"
RSpec.describe TestClass do
  describe ".run" do
    subject { described_class.run(arg) }

    let(:arg) { "the one" }

    it { is_expected.to eq("the one") }
  end
end
