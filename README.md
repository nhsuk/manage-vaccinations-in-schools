# Manage vaccinations in schools – Prototype

This is a service for recording children vaccinations with the NHS. This version
is a prototype used for testing service designs and implementation technology.

## Environments

| Name                                                                                         | `RAILS_ENV`                                       |
| -------------------------------------------------------------------------------------------- | ------------------------------------------------- |
| [Production](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/production) | [`production`](config/environments/production.rb) |
| [Test](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/test)             | [`staging`](config/environments/staging.rb)       |
| [Training](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/training)     | [`staging`](config/environments/staging.rb)       |

## Development

### Prerequisites

This project depends on:

- [Ruby](https://www.ruby-lang.org/)
- [Ruby on Rails](https://rubyonrails.org/)
- [NodeJS](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Postgres](https://www.postgresql.org/)

The instructions below assume you are using `mise` to manage the necessary
versions of the above.

### Application architecture

We keep track of architecture decisions in [Architecture Decision Records
(ADRs)](/adr/).

We use `rladr` to generate the boilerplate for new records:

```bash
bin/bundle exec rladr new title
```

### Development toolchain

#### mise

This project uses `mise`. Use the following to install the required tools
(replace `brew` and package names depending on your platform):

```sh
# Dependencies for ruby
brew install libyaml

# Dependencies for postgres
brew install gcc readline zlib curl ossp-uuid icu4c pkg-config

# Env vars for postgres
export OPENSSL_PATH=$(brew --prefix openssl)
export CMAKE_PREFIX_PATH=$(brew --prefix icu4c)
export PATH="$OPENSSL_PATH/bin:$CMAKE_PREFIX_PATH/bin:$PATH"
export LDFLAGS="-L$OPENSSL_PATH/lib $LDFLAGS"
export CPPFLAGS="-I$OPENSSL_PATH/include $CPPFLAGS"
export PKG_CONFIG_PATH="$CMAKE_PREFIX_PATH/lib/pkgconfig"

# Version manager
brew install mise

# Yarn via brew as this skips installing `gpg`
brew install yarn

# To install (or update, following a change to .tool-versions)
mise install
```

When installing the `pg` gem, bundle changes directory outside of this
project directory, causing it lose track of which version of postgres has
been selected in the project's `.tool-versions` file. To ensure the `pg` gem
installs correctly, you'll want to set the version of postgres that `mise`
will use:

```sh
# Temporarily set the version of postgres to use to build the pg gem
MISE_POSTGRES_VERSION=17.2 bundle install
```

After installing Postgres via `mise`, run the database in the background, and
connect to it to create a user:

```sh
$ pg_ctl start
$ psql -U postgres -c "CREATE USER $(whoami); ALTER USER $(whoami) WITH SUPERUSER;"
```

### Local development

To run the project locally:

```bash
$ bin/setup
```

### Linting

To run the linters:

```bash
bin/lint
```

### Intellisense

[solargraph](https://github.com/castwide/solargraph) is bundled as part of the
development dependencies. You need to [set it up for your
editor](https://github.com/castwide/solargraph#using-solargraph), and then run
this command to index your local bundle (re-run if/when we install new
dependencies and you want completion):

```sh
bin/bundle exec yard gems
```

You'll also need to configure your editor's `solargraph` plugin to
`useBundler`:

```diff
+  "solargraph.useBundler": true,
```

### PostgreSQL

The script `bin/db` is included to start up PostgreSQL for setups that don't use
system-started services. Note that this is meant to be a handy script to manage
PostgreSQL, not run a console like `rails db` does.

```
$ bin/db
pg_ctl: no server running
$ bin/db start
waiting for server to start.... done
server started
$ bin/db
pg_ctl: server is running (PID: 79113)
```

This script attempts to be installation agnostic by relying on `pg_config` to
determine postgres's installation directory and setting up logging accordingly.

### Development server

This application comes with a `Procfile.dev` for use with `foreman` in
development environments. Use the script `bin/dev` to run it:

```bash
$ bin/dev
13:07:31 web.1  | started with pid 73965
13:07:31 css.1  | started with pid 73966
13:07:31 js.1   | started with pid 73967
...
```

#### Debugging with `binding.pry`

TTY echo can get mangled when using `binding.pry` in `bin/dev`. To work around
this, you can run `rails s` directly if you're not working with any JS or CSS
assets.

Alternatively, you can install `tmux` and
[`overmind`](https://github.com/DarthSim/overmind#connecting-to-a-process) which
is compatible with our `Procfile.dev`:

```bash
$ overmind start -f Procfile.dev
$ overmind connect web
```

### Testing

To run the Rails tests:

```bash
bin/bundle exec rspec
```

To run the JS unit tests:

```bash
yarn test
```

To run the Playwright end to end tests use:

```bash
yarn test:e2e
```

To [generate tests interactively by clicking in a live browser](https://playwright.dev/docs/codegen):

```bash
yarn playwright codegen http://localhost:4000
```

#### Load testing

Install [artillery](https://www.artillery.io):

```bash
yarn global add artillery
```

We don't package it alongside the other devDependencies because it's quite heavy
and used infrequently.

To run the load tests:

```bash
USERNAME=username PASSWORD=password SESSION=slug artillery run tests/load.yml --target=http://test.mavistesting.com
```

### Example programmes

You can generate an example programme with a few sessions in development by visiting `/reset`.

#### Adding a test user

You can add a new user to an environment using the `users:create` rake task:

```
rails users:create['user@example.com','password123','John Doe',1]
```

### Previewing view components

[ViewComponent previews](https://viewcomponent.org/guide/previews.html) are enabled in development and test environments. In development, they are here:

    http://localhost:4000/rails/view_components

The previews are defined in `spec/components/previews`.

### Deploying

This app can be deployed to AWS using AWS Copilot. Once authenticated, you can
run:

```sh
$ bin/deploy test
```

See [docs/aws-copilot.md](docs/aws-copilot.md) for more information.

### Notify

When developing locally, emails are sent using the `:file` delivery method, and
logged to `STDOUT`.

If you want to use Notify, you'll need to set up a test API key, and then set
up a `config/settings/development.local.yml` file:

```yml
govuk_notify:
  enabled: true
  test_key: YOUR_KEY_HERE
```

You should set it to `enabled: false` when you're done testing Notify locally,
because it's easier to work offline without it.

#### Reply-To

GOV.UK Notify can store reply-to email addresses and use them when sending mail.
Once you've added the reply-to email in GOV.UK Notify, get the UUID and add it to
the organisation.

### Care Identity Service (CIS2)

This service uses [NHS's CIS2 Care Identity Authentication
service](https://digital.nhs.uk/developer/api-catalogue/nhs-cis2-care-identity-authentication)
to perform OIDC authentication for users.

You can retrieve the issuer URL from the appropriate endpoint listed on [CIS2
Guidance Discovery page]
(https://digital.nhs.uk/services/care-identity-service/applications-and-services/cis2-authentication/guidance-for-developers/detailed-guidance/discovery)
(note: the dev env is being deprecated and will be removed):

```sh
$ curl -s https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/.well-known/openid-configuration | jq .issuer
"https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare"
```

Clients in the INT environment can be configured via CIS2 Connection Manager,
please contact other organisation members to get the details for that. Mavis can
use either a client secret or a private key JWT when authenticating requests to
CIS2, these are configured via the Connection Manager.

To configure Mavis, put non-secret configuration into Settings:

```yml
cis2:
  enabled: true
  issuer: https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcareopenam/oauth2/realms/root/realms/oidc"
```

And once you have your client secrets, either via the Connection Manager or from
NHS support, put the `client_id` and `secret`/`private_key` into the Rails
credentials file for the environment you are configuring.

```yml
cis2:
  client_id: # Client ID, as provided by NHS
  secret: # Client secret, as provided by NHS
  private_key: # ... or RSA private key in PEM format
```

The `private_key` will automatically be used to generate a JWK on the
`/oidc/jwks` endpoint, which is used by CIS2 to validate the JWT we use to
request the access token from CIS2.

#### Key Rotation

Keys should be rotated regularly. When a new key is introduced it's JWK will
automatically be added to the JWKS generated for `/oidc/jwks`, but the old
public key can also be added to `JWKSController::EXTRA_JWK` to ensure a smooth
roll-over.

## Rake tasks

- `access_log:for_patient[id]`
- `access_log:for_user[id]`
- `clinics:create[name,address,town,postcode,ods_code,organisation_ods_code]`
- `schools:add_to_organisation[ods_code,team_name,urn,...]`
- `teams:create[ods_code,name,email,phone]`
- `users:create[email,password,given_name,family_name,organisation_ods_code]`
- `vaccines:seed[type]`

See the [Rake tasks documentation](docs/rake-tasks.md) for more information.

## MESH Connection

Mavis connects to the NHS MESH (Message Exchange for Social Care and Health) to
send data to DPS for upstream reporting of vaccination records.

See the [MESH documentation](docs/mesh.md) for more information.

## NHS Personal Demographic Service (PDS) Connection

Mavis is also configured to connect to PDS to retrieve patient information such
as NHS numbers.

See the [PDS documentation](docs/pds.md) for more information.

## Licence

[MIT](LICENCE).
