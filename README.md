# PadlockAuth

PadlockAuth allows you to secure your Rails application using access tokens provided by an external provider.

## Usage

PadlockAuth separates the __how__ of token verification from the __where__ authentication occurs. You configure an authentication strategy in an initializer and use callbacks in controllers to secure endpoints, allowing strategy changes without modifying your controllers.

Designed for lightweight use, PadlockAuth is ideal for microservices or high-volume APIs, with support ranging from simple token matching to more complex JWT-based authentication. Unlike [Devise](https://github.com/heartcombo/devise) or [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper), PadlockAuth doesn't require a database, making it more suitable for microservices and lightweight scenarios.

### Configuring a Basic Token Strategy

The Basic Token Strategy is a simple authentication mechanism where the token received in the request is compared with a pre-configured secret key. This strategy is ideal for straightforward use cases where you only need to validate the presence of a valid token. It does not provide any scopes to be authenticated against.

#### Example Configuration

```ruby
# config/initializers/padlock_auth.rb
PadlockAuth.configure do
  secure_with :token do
    secret_key "MySecretKey"
  end
end
```

In this example:

- The `:token` strategy validates the request's token by comparing it with the configured `secret_key`.

### Configuring a Custom Strategy

A Custom Strategy in PadlockAuth allows you to implement your own authentication logic. This requires creating a custom Strategy class that generates an Access Token class.

#### 1. Define the Strategy Class

The Strategy class should inherit from `PadlockAuth::AbstractStrategy` and implement the following methods:

- `build_access_token`: Builds an access token from a provided String access token.
- `build_access_token_from_credentials`: Builds an access token from provided username and password.

Both methods should return an `AccessToken` object.

```ruby
class MyCustomStrategy < PadlockAuth::AbstractStrategy
  def build_access_token(token_string)
    # Logic to build an access token from a string token
    MyAccessToken.new(token_string)
  end

  def build_access_token_from_credentials(username, password)
    # Logic to build an access token from provided credentials
    MyAccessToken.new(generate_token_from_credentials(username, password))
  end
end
```

#### 2. Define the AccessToken Class

The `AccessToken` class should inherit from `PadlockAuth::AbstractAccessToken` and implement the following methods:

- `accessible?`: Returns `true` if the access token is valid. This means the token:
  - Matches the expected token value, and
  - Contains any required attributes, and
  - Has not expired.
- `includes_scope?`: Returns `true` if the access token matches at least one of the provided scope values.

```ruby
class MyAccessToken < PadlockAuth::AbstractAccessToken
  def accessible?
    # Check token validity logic
    valid_token? && required_attributes_present? && not_expired?
  end

  def includes_scope?(scopes)
    # Check if the token includes at least one of the provided scopes
    (scopes & token_scopes).any?
  end
end
```

#### 3. Configure the Custom Strategy

Finally, configure PadlockAuth to use your custom strategy within the initializer:

```ruby
# config/initializers/padlock_auth.rb
PadlockAuth.configure do
  secure_with MyCustomStrategy.new
end
```

This configuration allows you to implement a fully custom authentication strategy that integrates with PadlockAuth.

### Securing a Rails Controller

The `padlock_authorize!` method secures your API endpoints and optionally enforces scope requirements. The verification of scopes is managed by the configured authentication strategy.

#### Example: Specifying Scopes

You can specify multiple scopes in a single call:

```ruby
before_action { padlock_authorize! :read, :write }
```

In this example:

- The action requires the access token to include either the :read **or** :write scope.

Alternatively, you can require multiple scopes by calling padlock_authorize! separately for each:

```ruby
before_action :require_read_and_write_scopes

private

def require_read_and_write_scopes
  padlock_authorize! :read
  padlock_authorize! :write
end
```

In this case:

The action requires the access token to include **both** the :read and :write scopes.

#### Example: Using Default Scopes

When no scopes are provided to `padlock_authorize!`, the default_scopes configuration will be applied. You can configure the default_scopes value during setup:

```ruby
PadlockAuth.configure do
  secure_with MyCustomStrategy
  default_scopes [:read] # Optional, defines the default required scopes
end
```

In this case:

If `padlock_authorize!` is called without explicit scopes, the `:read` scope will be enforced by default.

For example:

```ruby
before_action :padlock_authorize!
```

- If the token includes the `:read` scope, the action will proceed.
- If `default_scopes` is not set, no scopes are enforced by default when padlock_authorize! is called without scopes..

### Providing Access Token Credentials

You can configure PadlockAuth to support different ways of extracting a single access token by specifying an array of access_token_methods:

```ruby
PadlockAuth.configure do
  access_token_methods [
    :from_bearer_authorization, # Extracts token from Authorization header with Bearer token
    :from_access_token_param,   # Extracts token from access_token param
    :from_bearer_param          # Extracts token from bearer param
  ]
end
```

#### Token Extraction Methods

- `from_bearer_authorization`: Extracts the token from an `Authorization` header with a Bearer token (i.e. Bearer VALID_ACCESS_TOKEN).
- `from_access_token_param`: Extracts the token from an `access_token` parameter in the query string or form data.
- `from_bearer_param`: Extracts the token from a `bearer` parameter in the query string or form data.

These methods will call `build_access_token` with the provided strategy to create an AccessToken object.

#### Example: Calling an Endpoint with a Bearer Token

Here’s an example of how to call an endpoint with an access token using the `from_bearer_authorization` method. The token will be extracted from the Authorization header:

```ruby
require 'net/http'
require 'uri'

uri = URI.parse("http://example.com/api/endpoint")
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Get.new(uri)
request["Authorization"] = "Bearer VALID_ACCESS_TOKEN"

response = http.request(request)
puts response.body
```

In this example:

- The Bearer token `VALID_ACCESS_TOKEN` is passed in the Authorization header.
- PadlockAuth will extract the token using the `from_bearer_authorization` method and validate it

#### Example: Calling an Endpoint with a Token Parameter

You can also pass the token as a query parameter. Here’s an example of how to call the same endpoint with the token passed in the `access_token` parameter:

```ruby
uri = URI.parse("http://example.com/api/endpoint?access_token=VALID_ACCESS_TOKEN")
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Get.new(uri)
response = http.request(request)
puts response.body
```

PadlockAuth will extract the token from the `access_token` parameter and validate it.

### Providing Credentials with Username and Password

 You can also provide username and password credentials by adding the `from_basic_authorization` method:

 ```ruby
PadlockAuth.configure do
  access_token_methods [
    :from_basic_authorization # Extracts token from a HTTP BASIC AUTHORIZATION header
  ]
end
```

- `from_basic_authorization`: Extracts the Username and Password from a Basic Authorization header.

#### Example: Calling an Endpoint with Basic Authentication

If you need to authenticate with a username and password, you can send the credentials in the `Authorization` header using Basic Authentication:

```ruby
uri = URI.parse("http://example.com/api/endpoint")
http = Net::HTTP.new(uri.host, uri.port)

request = Net::HTTP::Get.new(uri)
request.basic_auth 'username', 'secret'

response = http.request(request)
puts response.body
```

PadlockAuth will extract the username and password using the `from_basic_authorization` method and use them to generate an access token.

### Securing an Action Cable Connection

You can use PadlockAuth to secure your Action Cable connections by verifying an access token during the connection process. The access token can be provided via the `"access_token"` or `"bearer_token"` parameters.

Not all access tokens provide a `subject` method, it is entirely dependent on the implementation.

Here’s an example implementation:

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :access_token_subject

    def connect
      self.access_token_subject = find_verified_subject
    end

    private

    def find_verified_subject
      if padlock_authorized? "websocket"
        padlock_auth_token.subject
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

#### Explanation

- `padlock_authorized?`: Checks if the access token is valid and optionally verifies the required scope (`"websocket"` in this example).
- `padlock_auth_token`: Provides access to the verified token, allowing you to retrieve attributes such as `subject`.

This ensures that only clients with valid access tokens can establish a WebSocket connection. The access token `sub` can then be used to identify the connected client throughout the session.

#### Example: Connecting to the Action Cable Connection via JS

```js
import { createConsumer } from "@rails/actioncable"

// Use a function to dynamically generate the URL
createConsumer(getWebSocketURL)

function getWebSocketURL() {
  const token = localStorage.get('access-token')
  return `wss://example.com/cable?token=${token}`
}
```

### Securing an ActionCable Channel

PadlockAuth can secure individual Action Cable channels by verifying an access token when a client subscribes. The access token can be provided via the `"access_token"` or `"bearer_token"` parameters.

Here’s an example implementation:

```ruby
class AuthorizedChannel < ApplicationCable::Channel
  def subscribed
    if padlock_authorized? "channel"
      stream_from "authorized_stream"
    else
      reject
    end
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end
end
```

#### Explanation

- `padlock_authorized?`: Validates the access token and ensures it includes the required scope (`"channel"` in this example).

By leveraging these features, PadlockAuth ensures only authenticated users with the proper access scope can subscribe and receive messages on the channel.

#### Example: Connecting to the Action Cable Channel via JS

```js
import consumer from "./consumer"

const token = localStorage.get('access-token')
consumer.subscriptions.create({ channel: "AuthorizedChannel", access_token: token })
```

## Installation

Add this line to your application's Gemfile:

```ruby
gem "padlock_auth"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install padlock_auth
```

## Development

After checking out the repo, run `bundle install` to install dependencies. Then, run `rake` to run the tests and code quality checks.

Generate documentaion using `rake yard`, which can be found in the `/doc` directory.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bmorrall/padlock_auth. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bmorrall/padlock_auth/blob/main/CODE_OF_CONDUCT.md).

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the PadlockAuth project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bmorrall/padlock_auth/blob/main/CODE_OF_CONDUCT.md).
