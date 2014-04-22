# Provider States

Provider states allow you to set up data on the provider before the interaction is run, so that it can make a response that matches what the consumer expects. It also allows the consumer to make the same request with different expected responses.

### Consumer codebase

For example, some code that creates the pact in a consumer project might look like this:

```ruby
describe MyServiceProviderClient do

  subject { MyServiceProviderClient.new }

  describe "get_something" do
    context "when a thing exists" do
      before do
        my_service.given("a thing exists").
          upon_receiving("a request for a thing").with(method: 'get', path: '/thing').
          will_respond_with(status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: { name: 'A small something'} )
      end

      it "returns a thing" do
        expect(subject.get_something).to eq(SomethingModel.new('A small something'))
      end
    end

    context "when a thing does not exist" do
      before do
        my_service.given("a thing does not exist").
          upon_receiving("a request for a thing").with(method: 'get', path: '/thing').
          will_respond_with(status: 404)
      end

      it "returns nil" do
        expect(subject.get_something).to be_nil
      end
    end
  end
end
```

### Provider codebase

To define service provider states that create the right data for the provider states described above, write the following in the service provider project. (The consumer name here must match the name of the consumer configured in your consumer project for it to correctly find these provider states.)

```ruby
# In /spec/service_consumers/provider_states_for_my_service_consumer.rb

Pact.provider_states_for 'My Service Consumer' do

  provider_state "a thing exists" do
    set_up do
      # Create a thing here using your framework of choice
      # eg. Sequel.sqlite[:somethings].insert(name: "A small something")
    end

    tear_down do
      # Any tear down steps to clean up your code
    end
  end

  provider_state "a thing does not exist" do
    no_op # If there's nothing to do because the state name is more for documentation purposes,
          # you can use no_op to imply this.
  end

end
```
Require your provider states file in the `pact_helper.rb`

```ruby
# In /spec/service_consumers/pact_helper.rb

require './spec/service_consumers/provider_states_for_my_service_consumer.rb'
```

### Base state

To define code that should run before/after each interaction for a given consumer, regardless of whether a provider state is specified or not, define set_up/tear_down blocks with no wrapping provider_state.

```ruby
Pact.provider_states_for 'My Service Consumer' do

  set_up do
    # This will run before the set_up for provider state specified for the interaction.
    # eg. create API user, set the expected basic auth details
  end

  tear_down do
    # ...
    # This will run after the tear_down for the specified provider state.
  end
end
```

### Global state

Global state will be set up before consumer specific base state. Avoid using the global set up for creating data as it will make your tests brittle when more than one consumer exists.

```ruby
Pact.set_up do
  # eg. start database cleaner transaction
end

Pact.tear_down do
  # eg. clean database
end
```

### Testing errors

It is important to test how your client will handle error responses.

```ruby
# Consumer codebase

describe MyServiceProviderClient do

  subject { MyServiceProviderClient.new }

  describe "get_something" do

    context "when an error occurs retrieving a thing" do
      before do
        my_service.given("an error occurs while retrieving a thing").
          upon_receiving("a request for a thing").with(method: 'get', path: '/thing').
          will_respond_with(
            status: 500,
            headers: { 'Content-Type' => 'application/json' },
            body: { message: "An error occurred!" } )
      end

      it "raises an error" do
        expect{ subject.get_something }.to raise_error /An error occurred!/
      end

    end
  end
end
```

```ruby
# Provider codebase

Pact.provider_states_for 'My Service Consumer' do
  provider_state "an error occurs while retrieving a thing" do
    set_up do
      # Stubbing is ususally the easiest way to generate an error with predictable error text.
      ThingRepository.stub(:find).and_raise("An error occurred!")
    end
  end
end
```

### Including modules

To use RSpec's `allow()` syntax, include `RSpec::Mocks::ExampleMethods` in the configuration.

```ruby
Pact.configure do | config |
  config.include RSpec::Mocks::ExampleMethods
end
```

You can also include modules to assist in data set up this way.

```ruby
Pact.configure do | config |
  config.include MyFactoryMethods
end
```