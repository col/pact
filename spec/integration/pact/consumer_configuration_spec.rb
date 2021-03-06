require 'spec_helper'
require 'pact/configuration'
require 'pact/consumer/configuration'

describe "consumer side" do
  describe "configure" do

    class TestHelper
      include Pact::Consumer::ConsumerContractBuilders
    end

    let(:application) { double("App")}
    let(:world) { Pact::Consumer::World.new }

    before do
      Pact.clear_configuration
      Pact::Consumer::AppManager.instance.clear_all
      #Don't want processes actually spawning
      Pact::Consumer::AppRegistration.any_instance.stub(:spawn)
      allow(Pact).to receive(:consumer_world).and_return(world)

      my_app = application

      Pact.service_consumer "My Consumer" do
        app my_app
        port 1111

        has_pact_with "My Service" do
          mock_service :my_service do
            port 1234
            standalone true
          end
        end

        has_pact_with "My Other Service" do
          mock_service :my_other_service do
            port 1235
            standalone false
          end
        end
      end

    end

    describe "providers" do

      subject { TestHelper.new.my_service }

      it "should have defined methods in MockServices for the providers" do
        subject.should be_instance_of Pact::Consumer::ConsumerContractBuilder
      end

      context "when standalone is true" do
        it "is not registerd with the AppManager" do
          Pact::Consumer::AppManager.instance.app_registered_on?(1234).should be false
        end
      end

      context "when standalone is false" do
        it "should register the MockServices on their given ports if they are not" do
          Pact::Consumer::AppManager.instance.app_registered_on?(1235).should be true
        end
      end
    end
  end
end