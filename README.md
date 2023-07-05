# Manage vaccinations for school-aged children -- Prototype

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
# The first time
brew install asdf # Mac-specific
asdf plugin add ruby
asdf plugin add nodejs
asdf plugin add yarn
asdf plugin add postgres

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

### Loading example data

You can run a rake task to load data from the example campaign file
`db/sample_data/example-campaign.json`.`

```bash
$ rake load_campaign_example
```

The importer will `find_or_create` the records, using specific attributes to match records:

- **campains** -- a combination of `type`, `location` and `date`
- **children** -- `nhs_number`
- **schools** -- `urn`

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

## Deploying

This app can be deployed to AWS using Terraform.

```sh
terraform -chdir=terraform plan
terraform -chdir=terraform apply
```

See [docs/terraform.md](docs/terraform.md) for more informations.

## Licence

[MIT](LICENCE).
