require 'spec_helper'
require 'pact/consumer/configuration'

module Pact::Consumer::Configuration

   describe MockService do

      let(:world) { Pact::Consumer::World.new }
      before do
         Pact.clear_configuration
         Pact::Consumer::AppManager.instance.stub(:register_mock_service_for)
         allow(Pact).to receive(:consumer_world).and_return(world)
      end

      describe "configure_consumer_contract_builder" do
         let(:consumer_name) {'consumer'}
         subject {
            MockService.build :mock_service, consumer_name, provider_name do
               port 1234
               standalone true
               verify true
            end
         }

         let(:provider_name) { 'Mock Provider'}
         let(:consumer_contract_builder) { instance_double('Pact::Consumer::ConsumerContractBuilder')}
         let(:url) { "http://localhost:1234"}

         it "adds a verification to the Pact configuration" do
            Pact::Consumer::ConsumerContractBuilder.stub(:new).and_return(consumer_contract_builder)
            subject.finalize
            consumer_contract_builder.should_receive(:verify)
            Pact.configuration.provider_verifications.first.call
         end

         context "when standalone" do
            it "does not register the app with the AppManager" do
               Pact::Consumer::AppManager.instance.should_not_receive(:register_mock_service_for)
               subject.finalize
            end
         end
         context "when not standalone" do
            subject {
               MockService.build :mock_service, consumer_name, provider_name do
                  port 1234
                  standalone false
                  verify true
               end
            }
            it "registers the app with the AppManager" do
               Pact::Consumer::AppManager.instance.should_receive(:register_mock_service_for).with(provider_name, url)
               subject.finalize
            end
         end
      end
   end
end