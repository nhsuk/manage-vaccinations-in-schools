# Manage vaccinations in schools – Prototype

This is a service for recording children vaccinations with the NHS. This version
is a prototype used for testing service designs and implementation technology.

# Development

## Prerequisites

This project depends on:

- [Ruby](https://www.ruby-lang.org/)
- [Ruby on Rails](https://rubyonrails.org/)
- [NodeJS](https://nodejs.org/)
- [Yarn](https://yarnpkg.com/)
- [Postgres](https://www.postgresql.org/)

The instructions below assume you are using `asdf` to manage the necessary
versions of the above.

## Application architecture

We keep track of architecture decisions in [Architecture Decision Records
(ADRs)](/adr/).

We use `rladr` to generate the boilerplate for new records:

```bash
bin/bundle exec rladr new title
```

## Development toolchain

### asdf

This project uses `asdf`. Use the following to install the required tools:

```sh
# Install dependencies
brew install gcc readline zlib curl ossp-uuid # Mac-specific
export HOMEBREW_PREFIX=/opt/homebrew          # Mac-specific

# The first time
brew install asdf                             # Mac-specific
asdf plugin add aws-copilot
asdf plugin add awscli
asdf plugin add nodejs
asdf plugin add postgres
asdf plugin add ruby
asdf plugin add yarn

# To install (or update, following a change to .tool-versions)
asdf install
```

When installing the `pg` gem, bundle changes directory outside of this
project directory, causing it lose track of which version of postgres has
been selected in the project's `.tool-versions` file. To ensure the `pg` gem
installs correctly, you'll want to set the version of postgres that `asdf`
will use:

```sh
# Temporarily set the version of postgres to use to build the pg gem
ASDF_POSTGRES_VERSION=13.5 bundle install
```

After installing Postgres via `asdf`, run the database in the background, and
connect to it to create a user:

```sh
$ pg_ctl start
$ psql -U postgres
> CREATE USER myuser;
> ALTER USER myuser WITH SUPERUSER;
```

### Local development

To set the project up locally:

```bash
bin/setup
bin/dev
```

#### Yarn

If you encounter:

```sh
No yarn executable found for nodejs 18.1.0
```

You need to reshim nodejs:

```sh
asdf reshim nodejs
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
system-started services, such as `asdf` which is our default. Note that this is
meant to be a handy script to manage PostgreSQL, not run a console like `rails db`
does.

```
$ bin/db
pg_ctl: no server running
$ bin/db start
waiting for server to start.... done
server started
$ bin/db
pg_ctl: server is running (PID: 79113)
/Users/misaka/.asdf/installs/postgres/13.5/bin/postgres
```

This script attempts to be installation agnostic by relying on `pg_config` to
determine postgres's installation directory and setting up logging accordingly.

### Development server

This application comes with a `concurrently` script for development
environments. Use script `bin/dev` to run it:

```bash
$ bin/dev
[web] rails server
[css] yarn build:css --watch
[js] yarn build --watch
[sw] yarn build:serviceworker --watch
...
```

### Testing

To run all the test:

```bash
bin/test
```

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

## Example campaigns

You can generate an example campaign with a few sessions in development by visiting `/reset`.

### Adding a test user

You can add a new user to an environment using the `add_new_user` rake task:

```
rails add_new_user['user@example.com','password123','John Doe',1]
```

## Previewing view components

[ViewComponent previews](https://viewcomponent.org/guide/previews.html) are enabled in development and test environments. In development, they are here:

    http://localhost:4000/rails/view_components

The previews are defined in `spec/components/previews`.

## Deploying

This app can be deployed to AWS using AWS Copilot. Once authenticated, you can
run:

```sh
$ bin/deploy test
```

See [docs/aws-copilot.md](docs/aws-copilot.md) for more information.

## Notify

When developing locally, emails are sent using the `:file` delivery method, and
logged to `STDOUT`.

If you want to use Notify, you'll need to set up a test API key, and then set
up a `config/settings/development.local.yml` file:

```yml
govuk_notify:
  enabled: true
  api_key: YOUR_KEY_HERE
```

You should set it to `enabled: false` when you're done testing Notify locally,
because it's easier to work offline without it.

## Care Identity Service (CIS2)

This service uses [NHS's CIS2 Care Identity Authentication
service](https://digital.nhs.uk/developer/api-catalogue/nhs-cis2-care-identity-authentication)
to perform OIDC authentication for users.

You can retrieve the issuer URL from the appropriate endpoint listed on [CIS2 Guidance Discovery
page](https://digital.nhs.uk/services/care-identity-service/applications-and-services/cis2-authentication/guidance-for-developers/detailed-guidance/discovery):

```sh
$ curl -s https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk/openam/oauth2/realms/root/realms/oidc/.well-known/openid-configuration | jq ".issuer"
"https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc"
```

New client ids and secrets can be obtained from the NHS CIS2 Authentication team
(<nhscareidentityauthentication@nhs.net>).

Put the `issuer`, `client_id` and `secret` into the Settings for your env:

```yml
cis2:
  issuer: "https://am.nhsdev.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/oidc"
  client_id: CLIENT_ID
  secret: SECRET
```

The `cis2` feature flag also needs to be enabled in Flipper for CIS2 logins to work.

### Reply-To

GOVUK Notify can store reply-to email addresses and use them when sending mail.
Once you've added the reply-to email in GOVUK Notify, get the UUID and add it to
the team.

## Licence

[MIT](LICENCE).
