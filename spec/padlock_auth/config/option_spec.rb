RSpec.describe PadlockAuth::Config::Option do
  context "with a configurable class" do
    let(:configurable_class) do
      Class.new do
        include PadlockAuth::Mixins::BuildWith

        build_with Class.new(PadlockAuth::Utils::AbstractBuilder)

        extend PadlockAuth::Config::Option
      end
    end

    it "overrides configuration methods" do
      configurable_class.option :foo, default: "foo"
      expect do
        configurable_class.option :foo, default: "bar"
      end.to output("[PADLOCK_AUTH] Option #foo already defined and will be overridden\n").to_stderr

      expect(configurable_class.build.foo).to eq("bar")
    end

    it "allows options to be deprecated" do
      configurable_class.option :foo, deprecated: true, default: "foo"
      expect do
        configurable_class.build do
          foo "foo"
        end
      end.to output("[PADLOCK_AUTH] #foo has been deprecated and will soon be removed\n").to_stderr
    end

    it "allows options to be deprecated with a custom message" do
      configurable_class.option :foo, deprecated: {message: "Use bar instead"}, default: "foo"
      expect do
        configurable_class.build do
          foo "foo"
        end
      end.to output("[PADLOCK_AUTH] #foo has been deprecated and will soon be removed\nUse bar instead\n").to_stderr
    end
  end

  it "raises an error when the class does not respond to builder class" do
    expect {
      Class.new do
        extend PadlockAuth::Config::Option
      end
    }.to raise_error(NotImplementedError, /Define `self.builder_class` method for/)
  end
end
