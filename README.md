# Manage vaccinations in schools

This is a service used within the NHS for managing and recording school-aged vaccinations.

## Environments

| Name                                                                                         | URL                                                                                                      | Purpose                      | Care Identity login | Code                           | Deployment | `RAILS_ENV`                                       |
| -------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------- | ---------------------------- | ------------------- | ------------------------------ | ---------- | ------------------------------------------------- |
| [Heroku](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/heroku)         | mavis-pr-xxxx.herokuapp.com                                                                              | PR review apps               | ❌                  | pull request branch            | automated  | [`staging`](config/environments/staging.rb)       |
| [Test](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/test)             | [test.mavistesting.com](https://test.mavistesting.com)                                                   | Internal testing (manual)    | ✅                  | `main` branch (latest)         | automated  | [`staging`](config/environments/staging.rb)       |
| [QA](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/qa)                 | [qa.mavistesting.com](https://qa.mavistesting.com)                                                       | Internal testing (automated) | ❌                  | `main` branch (latest)         | automated  | [`staging`](config/environments/staging.rb)       |
| [Preview](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/Preview)       | [preview.mavistesting.com](https://preview.mavistesting.com)                                             | External testing             | ❌                  | `release` or release candidate | manual     | [`staging`](config/environments/staging.rb)       |
| [Training](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/training)     | [training.manage-vaccinations-in-schools.nhs.uk](https://training.manage-vaccinations-in-schools.nhs.uk) | External training            | ❌                  | `release` branch               | manual     | [`staging`](config/environments/staging.rb)       |
| [Production](https://github.com/nhsuk/manage-vaccinations-in-schools/deployments/production) | [www.manage-vaccinations-in-schools.nhs.uk](https://www.manage-vaccinations-in-schools.nhs.uk)           | Live service                 | ✅                  | `release` branch               | manual     | [`production`](config/environments/production.rb) |

## Release Cycle

Our default branch for making changes is `main`: new features and non-urgent
bug fixes should be merged into here.

The `release` branch is a reference to what is in production at any point in
time. It usually tracks `main` but can also point to hotfix branches as
necessary.

Releasing basically follows these steps:

1. Create a release candidate by tagging `main` (e.g. `v1.0.0-rc1`)
2. Create a release in GitHub and add information about the changes. Update the
   assurance statement.
3. Create a release by fast-forwarding or resetting `release` to the release
   candidate, and creating a tag (e.g. `v1.0.0`)

Details below.

### Pre-release and testing

Changes merged into `main` are deployed to the `qa` and `test` environments for
testing. When there is a large batch of PRs to merge at once, after a
merge-freeze for example, only merge a few at a time to try to make it easier to
trace any issues that arise during testing.

### Release candidate

Once all the necessary changes are merged and have been tested, create a
release candidate by creating a tag on the `main` branch. e.g. `v1.0.0-rc1`.

Create a [release in GitHub](https://github.com/nhsuk/manage-vaccinations-in-schools/releases/)
using this tag, or if one has been created for this version already update the
tag in it. The assurance statement will also need to be updated with the tag URL
(if the tag changes, e.g. to `-rc2`, this will need to be updated).

At this point the changes in the release will go through the NHS assurance
processes, and possibly through external testing and assurance. If required it
can be deployed to the `preview` or `training` environements.

### Releasing

When we are ready to release, update the `release` branch and deploy it to
production. If there have been no hot-fixes since the last release then this is
a simple fast-forward merge that has to be done on your localhost (see below for
how to manage non-fast-forwardable situations):

```shell
git checkout release
git pull origin release

# Check that release can be fast-forwarded to the release candidate
git merge-base --is-ancestor release v1.0.0-rc1 && echo "safe to ff-merge"

git merge --ff-only v1.0.0-rc1
git tag v1.0.0
git push --tags origin release
```

Once this is done, you can deploy `release` to production.

#### When `release` and `main` have diverged

There are cases when `release` won't be fast-forwardable to the release
candidate on `main`. This will happen when a fix has been applied to the
`release` branch that circumvented the normal release cycle (AKA hot-fix, see
below).

In these cases the `release` branch will need to be reset to the latest release
candidate.

```sh
git checkout release
git pull origin release
git reset --hard v1.0.0-rc1
git tag v1.0.0
git push --tags origin release
```

### Hot-fixes

Hot-fixes are emergency fixes made to the current release that bypass changes
that are in `main`. These fixes should still go through the pull-request
process, but to a version-specific branch, e.g. `v1.1.1-hotfixes`. Once these
are merged in, the commits will need to be applied to `main`, e.g. via
cherry-picking, and `release` should be fast-forwarded/reset to the latest code
released.

At this point the histories of the `release` and `main` branches will have
diverged and it will not be possible to fast-forward the `release` branch when
releasing. It will have to be reset to the latest release candidate as
previously described.

## Development

### Branching workflow

We follow the patterns and conventions in [GitHub
Flow](https://docs.github.com/en/get-started/using-github/github-flow).

Try to only put related changes into a single PR and keep them as small and as focused
as is reasonable. If you start shaving yaks consider putting these changes into
a separate PR. Likewise if you find the change you're making is quite large, you
can spread it across multiple PRs, even if functionality is only partly
complete any one of them.

Include a link to the Trello card in a relevant commit message and in the PR
description.

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
(ADRs)](adr).

We use `rladr` to generate the boilerplate for new records:

```shell
bin/bundle exec rladr new title
```

### Development toolchain

#### Mise

This project uses `mise`. Use the following to set up (replace `brew` and
package names depending on your platform):

```shell
# Dependencies for ruby
brew install libyaml

# Dependencies for postgres
brew install gcc readline zlib curl ossp-uuid icu4c pkg-config

# Install pre-commit tool
brew install pre-commit

# Env vars for postgres
export OPENSSL_PATH=$(brew --prefix openssl)
export CMAKE_PREFIX_PATH=$(brew --prefix icu4c)
export PATH="$OPENSSL_PATH/bin:$CMAKE_PREFIX_PATH/bin:$PATH"
export LDFLAGS="-L$OPENSSL_PATH/lib $LDFLAGS"
export CPPFLAGS="-I$OPENSSL_PATH/include $CPPFLAGS"
export PKG_CONFIG_PATH="$CMAKE_PREFIX_PATH/lib/pkgconfig"
```

For ubuntu run
```shell
apt install curl libyaml-dev libreadline-dev zlib1g-dev \
libssl-dev libicu-dev cmake pkg-config uuid-dev flex bison \
pre-commit

export OPENSSL_PATH="/usr"
export CMAKE_PREFIX_PATH="/usr"
export PATH="$OPENSSL_PATH/bin:$CMAKE_PREFIX_PATH/bin:$PATH"
export LDFLAGS="-L$OPENSSL_PATH/lib $LDFLAGS"
export CPPFLAGS="-I$OPENSSL_PATH/include $CPPFLAGS"
export PKG_CONFIG_PATH="$CMAKE_PREFIX_PATH/lib/pkgconfig"
```

```shell
# Version manager
brew install mise

# Yarn via brew as this skips installing `gpg`
brew install yarn
```

Then to install the required tools (or update, following a change to
`.tool-versions`):

```shell
mise install
mise exec python -- pip install pre-commit
```
Next ensure you have the pre-commit hook installed by running
```shell
pre-commit install
```

After installing Postgres via `mise`, run the database in the background, and
connect to it to create a user:

```shell
pg_ctl start
psql -U postgres -c "CREATE USER $(whoami); ALTER USER $(whoami) WITH SUPERUSER;"
```

### Local development

To run the project locally:

```shell
bin/setup
```

### Linting

To run the linters:

```shell
bin/lint
```

### Intellisense

[solargraph](https://github.com/castwide/solargraph) is bundled as part of the
development dependencies. You need to [set it up for your
editor](https://github.com/castwide/solargraph#using-solargraph), and then run
this command to index your local bundle (re-run if/when we install new
dependencies and you want completion):

```shell
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

```shell
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

```shell
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

```shell
overmind start -f Procfile.dev
overmind connect web
```

### Testing

To run the Rails tests:

```shell
bin/bundle exec rspec
```

To run the JS unit tests:

```shell
yarn test
```

To run the Playwright end-to-end tests use:

```shell
yarn test:e2e
```

To [generate tests interactively by clicking in a live browser](https://playwright.dev/docs/codegen):

```shell
yarn playwright codegen http://localhost:4000
```

#### Load testing

Install [artillery](https://www.artillery.io):

```shell
yarn global add artillery
```

We don't package it alongside the other devDependencies because it's quite heavy
and used infrequently.

To run the load tests:

```shell
USERNAME=username PASSWORD=password SESSION=slug artillery run tests/load.yml --target=http://test.mavistesting.com
```

### Example programmes

You can generate an example programme with a few sessions in development by visiting `/reset`.

#### Adding a test user

You can add a new user to an environment using the `users:create` rake task:

```shell
rails users:create['user@example.com','password123','John Doe',1]
```

### Previewing view components

[ViewComponent previews](https://viewcomponent.org/guide/previews.html) are enabled in development and test environments. In development, they are here:

    http://localhost:4000/rails/view_components

The previews are defined in `spec/components/previews`.

### Deploying

This app can be deployed to AWS using AWS Copilot. Once authenticated, you can
run:

```shell
bin/deploy test
```

See [docs/aws-copilot.md](docs/aws-copilot.md) for more information.

### Notify

When developing locally, emails are sent using the `:file` delivery method, and
logged to `STDOUT`.

If you want to use Notify, you'll need to set up a test API key, and then set
up a `config/settings/development.local.yml` file:

```yaml
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

```shell
curl -s https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare/.well-known/openid-configuration | jq .issuer "https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk:443/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcare"
```

Clients in the INT environment can be configured via CIS2 Connection Manager,
please contact other organisation members to get the details for that. Mavis can
use either a client secret or a private key JWT when authenticating requests to
CIS2, these are configured via the Connection Manager.

To configure Mavis, put non-secret configuration into Settings:

```yaml
cis2:
  enabled: true
  issuer: https://am.nhsint.auth-ptl.cis2.spineservices.nhs.uk/openam/oauth2/realms/root/realms/NHSIdentity/realms/Healthcareopenam/oauth2/realms/root/realms/oidc"
```

And once you have your client secrets, either via the Connection Manager or from
NHS support, put the `client_id` and `secret`/`private_key` into the Rails
credentials file for the environment you are configuring.

```yaml
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

## Operations tasks

See the [Ops tasks documentation](docs/ops-tasks.md) for more information.

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
