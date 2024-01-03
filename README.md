# erescat annual stats

Queries Sierra ILS database to generate collections stats reports.

## Setup

```bash
git clone https://github.com/UNC-Libraries/erescat-annual-stats
cd erescat-annual-stats
bundle install
```

Requires Sierra DB credentials set up per [sierra_postgres_utilities](https://github.com/UNC-Libraries/sierra-postgres-utilities)

## Usage

```bash
# run all queries
bundle exec rake run:all

# list individual queries
bundle exec rake -T

# run a single query, e.g.
bundle exec rake run:EbookOCA
```

Local documentation discusses further use/handling of the outputs.
