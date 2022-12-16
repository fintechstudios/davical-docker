# davical-docker

[![GitHub Repo stars](https://img.shields.io/github/stars/fintechstudios/davical-docker?style=social)](https://github.com/fintechstudios/davical-docker)
[![GitHub branch checks state](https://img.shields.io/github/checks-status/fintechstudios/davical-docker/main)](https://gitlab.com/fintechstudios/davical-docker/-/pipelines?page=1&scope=all&ref=main)
[![Docker Image Version (latest semver)](https://img.shields.io/docker/v/fintechstudios/davical?sort=semver)](https://hub.docker.com/r/fintechstudios/davical)

Standalone [DAViCal](https://davical.org/) docker image (based on official PHP image).

## Tags

Images are tagged with the DAViCal version, AWL version, PHP version, and distribution.

The `latest` tag points to the most recent version of the image on the current stable Debian.

The `nightly` tag points to builds from the master branches of DAViCal and AWL on the current stable Debian.

See the most recently pushed images on [Docker Hub as `fintechstudios/davical`](https://hub.docker.com/r/fintechstudios/davical) 
and via the [GitLab CI pipelines](https://gitlab.com/fintechstudios/davical-docker/-/pipelines?page=1&scope=all&ref=main).

## Usage

The image runs DAViCal built on the official [`php:apache`](https://github.com/docker-library/php/blob/master/8.1/bullseye/apache/Dockerfile)
image, so all that needs to be supplied is a PostgreSQL database. By default, this is
specified using the environment variables listed below, but this behavior can be overridden
by providing your own [DAViCal `config.php`](https://wiki.davical.org/index.php?title=Configuration).

The image also contains scripts to set up the database and apply the necessary migrations for
DAViCal updates. Doing so requires privileged access to postgres - which is not always desirable
in production applications - so must be enabled by separate environment variables.

### Environment Variables

The following variables are used to connect to postgres, although some sane defaults
are supplied to match typical DAViCal usage:

- `PGHOST` - the database host
- `PGPASSWORD` - the password for `PGUSER`
- `PGUSER` - (*default:* `davical_app`) the database user
- `PGDATABASE` - (*default:* `davical`) the database name
- `PGPORT` - (*default:* `5432`) the database port

You may also want to supply any of the following variables to override default behavior:

- `HOST_NAME` - (*default:* `localhost`) used as Apache `ServerName`
- `ADMIN_EMAIL` - (*default:* `admin@davical.example.com`) [email displayed on login page and in "From" for password reset emails](https://wiki.davical.org/index.php?title=Configuration/settings/admin_email)
- `TZ` - (*default:* `UTC`) system [timezone name](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

#### DB Creation/Migrations

If you want to run the database migrations, supply the following variables (as well as the
previous mentioned variables):

- `ROOT_PGUSER` - postgres user with permissions to create users and databases
- `ROOT_PGPASSWORD` - password for `ROOT_PGUSER`
- `DAVICAL_ADMIN_PASS` - password you would like to use for DAViCal `admin` user
- `DBA_PGUSER` - (*default:* `davical_dba`) the PG (super)user used by DAViCal for database operations
- `DBA_PGPASSWORD` - (*default:* value of `PGPASSWORD`) the password for `DBA_PGUSER`
- `RUN_MIGRATIONS_AT_STARTUP` - (*default: none*) if set to "true", the migrations will be run each time the image starts.
This behavior is disabled by default.

## Examples

The [`docker-compose.yml`](./docker-compose.yml) provided in this repo shows the minimum needed configuration.
You can run it directly and access the DAViCal instance at http://localhost:4080

```shell
docker-compose up
```

In production, you'll typically want to disable `RUN_MIGRATIONS_AT_STARTUP` and only run those as-needed
(to ensure migrations are run intentionally). You can do so using docker-compose like so:

```shell
# just start postgres
docker-compose up -d postgres
# run the migrations, then exit
docker-compose run --rm -e RUN_MIGRATIONS_AT_STARTUP= davical run-migrations
# just run davical (no migrations)
docker-compose run --service-ports -e RUN_MIGRATIONS_AT_STARTUP= davical
```

If you would like to specify your own `config.php`, simply mount it to `/etc/davical/config.php` to overwrite the
existing file:

```shell
docker-compose run --service-ports -v ./my-config.php:/etc/davical/config.php davical 
```

## Building

To build the image, simply run the `docker-compose` or `docker` build command:

```shell
docker-compose build davical
# or
docker build -t fintechstudios/davical .
```

Build args can be specified to build a different version of DAViCal. You should be able to specify
tag names, branch names, or commit hashes from the [DAViCal](https://gitlab.com/davical-project/davical) / [AWL](https://gitlab.com/davical-project/awl) 
repos as the version names. For example:

```shell
docker-compose build \
  --build-arg DAVICAL_VERSION="r1.1.10" \
  --build-arg DAVICAL_SHA512="20a4a473b12d467131a3b93aed1828ae978cf3b34feedecda384a974814b285c1b842d1ec0d2638b14388a94643ed6f5566a5993884b6e71bdaf6789ce43bd63" \
  --build-arg AWL_VERSION="r0.62" \
  --build-arg AWL_SHA512="c4de99e627ba3bd0a0ace1feef89a341d1bb29c79e4f1f0dc786da890b7540577444a19f10d0ae118d53ae723bd61538e82fee15aa689d1a4b7fc13a39c4a559" \
  davical
```

You can skip the SHA512 check by setting the sha values to be empty:

```shell
docker-compose build \
  --build-arg DAVICAL_VERSION="e8b43e60dbbd7bf6860b00a820556ef484aca9e5" \
  --build-arg DAVICAL_SHA512= \
  --build-arg AWL_VERSION="3f044e2dc8435c2eeba61a3c41ec11c820711ab3" \
  --build-arg AWL_SHA512= \
  davical
```

That said, a utility is provided to easily get the SHA512 for a set of releases, e.g.
```shell
./helpers/get-release-sha.sh e8b43e60dbbd7bf6860b00a820556ef484aca9e5 3f044e2dc8435c2eeba61a3c41ec11c820711ab3
```

## Prior Art

- [IridiumXOR/davical](https://github.com/IridiumXOR/davical) (+ forks)
- [Elrondo46/davical-docker-standalone](https://github.com/Elrondo46/davical-docker-standalone)
