# Authentication

## Introduction

ETEngine is used to authenticate users. The management of user accounts is handled by [Devise](https://github.com/heartcombo/devise). Devise takes care of handling new registrations, verifying a user's password, and remembering their credentials.

[Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) is used to provide support for OAuth2 and authorizing users, with [Doorkeeper::OpenIDConnect](https://github.com/doorkeeper-gem/doorkeeper-openid_connect) taking care of authentication with OpenID Connect.

## Terminology

- **Provider**: The OpenID Connect provider exposed by ETEngine. This issues tokens allowing access to the API.
- **Application**: A client application registered with ETEngine. This is used to store the client's credentials, and to allow the client to request tokens. Applications include ETModel, Transition Paths, and (potentially) third-party services.
- **Client**: An application that uses the API. This could be a web application, a mobile application, or a third-party service.
- **Access token**: A token issued by the provider which allows access to the API.
- **Refresh token**: A token issued by the provider which allows a new access token to be requested without the user having to re-authenticate.
- **Scopes**: A list of permissions granted to the access token. These are defined by the provider and are used to limit the actions which can be performed with the token.

## Tokens

The provider issues tokens to clients which allow access to the API. The tokens are a random Base58 string. Base58 was selected as it contains only alphanumeric characters, and is therefore safe to use in URLs. Unlike Base64, Base58 does not contain any characters which are likely to be confused with each other, such as 0 and O, nor characters which cause problems when double-clicking the token to copy/paste (such as dashes).

### Token scopes

Each token is assigned one or more [scopes](https://github.com/quintel/etengine/blob/ab6f07f23c8ff5d7bf9fe8fd95c3eff2ade4721e/config/initializers/doorkeeper.rb#L238-L245) that limit what actions may be performed with the token. The following scopes are available:

- `public`: A default scope which allows public data to be retrieved.
- `profile`: Allows the user's name and email address to be retrieved.
- `email`: Allows the user's email address to be retrieved.
- `openid`: Allows the user's ID to be retrieved.
- `roles`: Allows the user's roles to be retrieved (intended for first-party apps only).
- `scenarios:read`: Allows the user's public and scenarios to be read.
- `scenarios:write`: Allows the token to be used to create and update the user's public and private scenario.
- `scenarios:delete`: Allows the token to be used to delete the user's public and private scenarios.

For the moment, each level of `scenarios` scope requires all lower levels. This means that a token with `scenarios:write` must also have `scenarios:read` or else the `scenarios:write` permissions will not apply. This is not enforced, except through the web interface for generating personal tokens.

The `roles` scope is intended for use by ETM and Quintel Intelligence applications only. It provides an array of roles which have been assigned to the user. For most this will be `["user"]`, but for ETM staff it will be `["user", "admin"]`.

### Token expiry and refresh tokens

Access tokens issued by Doorkeeper are limited to a two hour duration, with refresh tokens also being issued. Refresh tokens allow clients to request a new access token without the user having to re-authenticate. A relatively short duration has been selected for access tokens as this ensures that if a user accidentally exposes their access token, it will expire relatively quickly.

Refresh tokens are not available to the browser in ETEngine, ETModel, or Transition Paths and are held only on the server. This ensures that only the signed-in user can create a new access token with a refresh token.

Both ETModel and Transition Paths take care of refreshing the access token when it expires, and storing the new access token and refresh token in the browser's local storage.

### Personal access tokens

Some users wish to be able to use the API without having to go to the trouble of setting up an OAuth application. For this reason, personal access tokens are available. These are tokens which are not associated with a client, and can be used to access the API directly.

Users can generate personal access tokens from their profile page. These tokens are stored in the database and are not visible after they are generated. If a user loses their token, they can generate a new one.

Authenticated requests to the API are sent with an `Authorization` header containing the token:

```bash
curl https://engine.energytransitionmodel.com/api/v3/scenarios \
  -H 'Accept: application/json' \
  -H 'Authorization: Bearer etm_abc123'
```

Internally, personal access tokens are implemented as ordinary OAuth access tokens, with a second model – `PersonalAccessToken` – used to store additional data. The access tokens allow us to generate a unique token, assign the expiry and scopes, and revoke the token if necessary. The second model allows us to more easily identify which tokens are personal access tokens, and permit users to assign a name to their token.

Users will be e-mailed three days prior to the expiry of their token with a list of the assigned permissions. This is intended to remind users that they should generate a new token if they wish to continue using the API.

### API requests to ETModel

While users can sign in to ETModel and interact with the web application using ETEngine's authentication, private data held in ETModel cannot be exposed this way: an API request knows nothing about the user who made the request. Additionally, the personal access tokens issued to users are random strings and do not disclose any information about the user.

[JSON Web Tokens (JWT)](https://jwt.io/introduction) were initially considered for this purpose, but suffer from the drawback that once issued, it is not possible for force the expiry of a token. This means that if a user's access token is compromised, their data could be accessed by the attacker until the token expires.

For these reasons, all API requests – even those intended for ETModel – are sent to ETEngine. ETEngine looks up the user by their personal access token, and then forwards the request to ETModel with [a short-life JWT containing the user information](https://github.com/quintel/etengine/blob/ab6f07f23c8ff5d7bf9fe8fd95c3eff2ade4721e/lib/etengine/auth.rb#L38-L55). This ensures that the user's identity is known to ETModel, and that the user's access token can be revoked if necessary.

These JWTs are never exposed to end-users and contain the following information:

* `sub`: The user's ID.
* `iat`: The time the token was issued.
* `exp`: The time the token expires.
* `iss`: The issuer of the token (ETEngine).
* `aud`: The audience of the token (ETModel).
* `scopes`: The scopes granted to the token. These exactly match the scopes granted to the user's personal access token.
* `user`: An object containing the user ID and name. These are always provided even if the personal access token does not include the `profile` scope.

All JWTs are signed with ETEngine's private key. The public key is available at [`/oauth/discovery/keys`](https://engine.energytransitionmodel.com/oauth/discovery/keys). ETModel retrieves this key (ideally when it starts up) and uses it to verify the signature of the JWT. This ensures that the token has not been tampered with and cannot be forged by an attacker.

ETModel will also verify that the token was issued (`iss`) by ETEngine, and was intended for ETModel (`aud`).

#### Request-response flow

1. ETEngine receives request from API user.
2. ETEngine checks the scopes of the token to verify that the user has permission to access the requested data.
3. ETEngine generates a JWT containing the user information and forwards the request to ETModel.
4. ETModel receives the request, verifies the JWT using ETEngine's public key, and checks the token scope.
5. ETModel responds with the requested data.
6. ETEngine receives the response from ETModel and adds additional information if necessary and replies to the API user.

ETModel [has dedicated controllers](https://github.com/quintel/etmodel/tree/master/app/controllers/api) (the API namespace) for handling requests from ETEngine.

#### Sending a request to ETModel

ETEngine provides helper methods to create a Faraday client which can send authenticated requests to ETModel:

```ruby
user = User.find(123)
client = ETEngine::Auth.etmodel_client(user)

# The client is automatically configured with the ETModel URL and the signed
# JWT as a bearer token.
client.get('/api/v1/saved_scenarios')
```

## Identity gem

A Ruby Gem - [Identity](https://github.com/quintel/identity_rails) – has been written which takes care of the details of authenticating with the provider, and requesting access tokens. The Gem is a Rails engine which provides a controller and views for authenticating with the provider, and requesting access tokens. It also provides an HTTP client ([via Faraday](https://lostisland.github.io/faraday/)) for making requests to the API.

```ruby
Identity.http_client.get('/api/v3/scenarios')
# => #<Faraday::Response {
#      "id": 1,
#      "title": "My scenario",
#      "area_code": "nl",
#      etc
#    }>
```

If you have the `Identity::AccessToken` available, it too exposes an HTTP client which will automatically add the access token to the request:

```ruby
access_token.http_client.get('/api/v3/scenarios')
```

### Use of Identity in ETModel

ETModel further abstracts this complexity by [providing an `engine_client` helper method](https://github.com/quintel/etmodel/blob/35f22bcbfebc39e55ac9b0e5f813f7cac06ceee7/app/controllers/application_controller.rb#L99-L107) to all controllers. This will send authenticated requests when the user is signed in, and unauthenticated requests when the user is not.

Furthermore, ETModel also stores a minimal copy of the user information: the user ID and their name. This allows us to associate data with users and show their name without having to make an API request to ETEngine. When the user updates their profile, ETEngine [will forward this information to ETModel](https://github.com/quintel/etengine/blob/master/app/jobs/identity/sync_user_job.rb) ensuring the data is kept up-to-date. In the event this fails, the user's name will be updated the next time they sign in.

### Configuring Identity

Since ETModel authenticates with ETEngine, it is necesssary for staff to create an OAuth application and configure ETModel with the `client_id` and `client_secret`. This is simplified by allowing staff to create an "ETModel (Local)" application in ETEngine. They will be provided with a config snippet which includes all necessary configuration for connecting to ETEngine.

When running locally, ETEngine will seek to preserve any such "staff applications" and their secrets, avoiding the need for staff to generate a new secret each time they import a new database.

## Changes to ETEngine

The authentication project introduced many changes to ETEngine.

### Private and public key

ETEngine now has a private key which is used by OpenID Connect and to sign JWTs. This key is expected to exist at `tmp/openid.key`.

- In production environments, this key is stored on the server and mounted in the Docker container.
- In local environments, ETEngine [will generate and store an RSA key pair](https://github.com/quintel/etengine/blob/ab6f07f23c8ff5d7bf9fe8fd95c3eff2ade4721e/lib/etengine/auth.rb#L22-L27) if one does not exist avoiding the need for staff to do this manually.

### Authenticated API requests

ETEngine can continue to be used as before; users can send unauthenticated requests to the API to create and update scenarios. However, unauthenticated requests have some limitations:

- They will only be able to access public scenarios.
- They cannot modify scenarios which belong to a user.
- They cannot list scenarios.
- They cannot delete scenarios.

When a request is authenticated, and assuming it has the necessary scopes, it will be able to access all scenarios belonging to the user, list their scenarios and saved scenarios, and delete scenarios. Naturally, authenticated requests cannot access private scenarios belonging to other users, nor delete scenarios which belong to other users.

The result is that for authenticated users, the scenarios API is significantly more powerful. They can easily list and delete their scenarios, and control who is allowed to access their scenarios.

Scenarios created with an access token are associated with the user who created them. Only this user can change the scenario. This prevents other users from modifying scenarios which belong to others. Critically, this ensures that users can be confident their scenarios have not been modified by other people and are exactly as they left them.

### Private scenarios

Authenticated users can create private scenarios and saved scenarios. This allow only the user to view the data.

Transition paths have no private/public setting, but can only be listed, viewed, modified, or deleted through the API by their owner and are therefore effectively **private**.

### User preferences

Users can set their e-mail address and name. Changes to their e-mail address will trigger a message to both addresses, and will require the new address to be confirmed before it becomes active.

Users can also set whether they wish their scenarios to be public or private by default. API users can set this on a per-scenario basis, and all users can override this setting per-scenario when they save the scenario in ETModel. At the time of writing, the default setting is **public**.

### User data

User data from ETModel has been imported into ETEngine. This ensures that the existing userbase can continue using the ETM without interruption. The user data is stored in a new `users` table in the ETEngine database.

Unfortunately, the authentication system used by ETEngine stored passwords as a salted SHA256 hash whereas Devise uses the superior BCrypt algorithm. This means that we had to store the SHA256 hash and salt for each user, and [migrate them to BCrypt the next time they sign in](https://github.com/quintel/etengine/blob/ab6f07f23c8ff5d7bf9fe8fd95c3eff2ade4721e/app/controllers/users/sessions_controller.rb#L50-L66). In time, this can likely be removed with any unmigrated users expected to reset their password.

### User pages

New user pages have been added, allowing users to view and edit their profile and settings. These pages make extensive use of features added in Rails 7: Turbo, Turbo Frames, and Stimulus, to provide a nice user experience. ViewComponent has been adopted along with Tailwind CSS for styling. This keep view code simple and (where needed) easily testable.

## Future improvements

### Delete accounts

GDPR requires that users have the ability to delete their account. It does not require that this process be automated, but it is a good idea to provide this functionality. This is not currently implemented.

Account deletion should require the user to verify their request (by re-entering their password). Then, ETEngine should delete all data associated with the account and send a request to ETModel to do likewise. A new authenticated API endpoint will need to be added to ETModel to allow this.

### Move transition paths to ETEngine

Transition Path data could be moved out of ETModel and in to ETEngine. The pages used to select an existing transition part could be moved to the Transition Path application, with it querying the ETEngine API for the data. This would allow the Transition Path application to be used independently of ETModel.

### Allow third-party applications

There is no web interface for creating new OAuth applications. It would be nice to allow third-parties (for example, the CTM) to be able to register their own applications and access ETM data (when authorized by the user).

A page already exists which shows users [their authorized applications](https://engine.energytransitionmodel.com/oauth/authorized_applications) and allows them to revoke access.

### Single sign-out

Currently, users must sign out of each application separately. It would be nice to allow users to sign out of all applications at once.

- If a user signs out of ETModel or the Transition Paths application, they will also be signed out of ETEngine.
- If a user signs out of ETEngine, they will not be signed out of ETModel or the Transition Paths application.

I believe this could be implemented in Doorkeeper by keeping track of which applications a user has signed in to. When a user signs out of one application, it could send a request to the other applications to sign the user out. This would require a new API endpoint in ETEngine and ETModel.

```ruby
# config/initializers/doorkeeper.rb

after_successful_authorization do |controller, context|
  controller.session[:logout_application_ids] <<
    Doorkeeper::Application.find_by(controller.request.params.slice(:client_id)).id
end
```

When a user signs out:

1. Retrieve the list of applications IDs from the session.
2. With the first application in the list:
    - Get the logout URL for the application.
    - Redirect the user to the logout URL.
    - The client application must now redirect back to ETEngine.
3. If there are more applications from which to sign out, go to step 2, otherwise to step 4.
3. When there are no more applications from which to sign out, remove the ETEngine session signing the user out.

A downside of this is that each application needs to have a GET endpoint for signing the user out and most browsers limit the number of allowed redirects per request (Chrome sets this to 20).
