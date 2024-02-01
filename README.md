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

### Loading example data

You can run a rake task to load data from the example campaign file
`db/sample_data/example-hpv-campaign.json`. The following commands can be used to prepare a test environment with the example data:

```bash
# Load the default example campaign, currently HPV:
$ rails load_campaign_example in_progress=1

# Load the Flu campaign as an additional campaign:
$ rails load_campaign_example[db/sample_data/example-flu-campaign.json] new_campaign=1 in_progress=1
```

The importer will `find_or_create` the records by default, using specific attributes to match records:

- **campaigns** -- a combination of `type`, `location` and `date`
- **children** -- `nhs_number`
- **schools** -- `urn`

### Generating example data

There's also a rake task to generate example campaign data. The `seed` setting
allows identical campaign data be generated for the purpose of testing. The type
of campaign can be controlled by the `type` setting. Use `rails -D
generate_example_campaign` for more usage information.

```bash
# Generate a simple example campaign to stdout
$ rails generate_example_campaign

# Generate an hpv campaign. Default is flu.
$ rails generate_example_campaign type=hpv

# Get more information about commang usage, including which patient states are
# available.
$ rails -D generate_example_campaign

# Generate a specific number of patients in certain states.
$ rails generate_example_campaign patients_that_still_need_triage=2 patients_with_no_consent=2

# Generate the model office data set and write it to a given file
$ rails generate_example_campaign[db/sample_data/model-office.json] \
  type=hpv \
  seed=42 \
  users_json='[{ "full_name": "Nurse Chapel", "email": "nurse.chapel@example.com" }]' \
  presets=model_office

# Generate example campaign data with a specific random seed for repeatability
$ rails generate_example_campaign seed=42
```

### Adding a test user

You can add a new user to an environment using the `add_new_user` rake task:

```
rails add_new_user['user@example.com','password123','John Doe',1]
```

## Deploying

This app can be deployed to AWS using AWS Copilot. Once authenticated, you can run:

```sh
$ copilot svc deploy
Found only one service, defaulting to: webapp

  Select an environment  [Use arrows to move, type to filter]
  > staging
    test

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

## Licence

[MIT](LICENCE).
