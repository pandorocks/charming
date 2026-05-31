# Database

Charming can generate SQLite-backed apps with Active Record. Database support is opt-in; apps without it continue to use only session-backed state in `app/state`.

## New App

Generate an app with SQLite support:

```bash
charming new tasks_tui --database sqlite3
```

This adds:

```text
app/models/application_record.rb
config/database.rb
db/migrate/.keep
db/seeds.rb
```

`config/database.rb` establishes a local SQLite connection at `db/development.sqlite3`.

## Existing App

Install SQLite support into an existing Charming app from the app root:

```bash
charming db:install sqlite3
```

This creates the same database files, updates the generated gemspec with Active Record dependencies, and updates `lib/my_app.rb` to load `config/database.rb` and `app/models`.

## State vs Models

Use state classes for in-memory TUI state:

```ruby
def home
  state(:home, HomeState)
end
```

Use Active Record models for persisted data:

```ruby
def show
  render :show,
    home: home,
    tasks: Task.order(:created_at)
end
```

## Generate A Model

Generate a persisted model and migration:

```bash
charming generate model task title:string done:boolean
```

This creates:

```text
app/models/task.rb
db/migrate/20260531000000_create_tasks.rb
spec/models/task_spec.rb
```

Generated models inherit from `ApplicationRecord`:

```ruby
module TasksTui
  class Task < ApplicationRecord
  end
end
```

## Database Commands

Run database commands from the app root:

```bash
charming db:create
charming db:install sqlite3
charming db:migrate
charming db:rollback
charming db:drop
charming db:seed
```

`db:migrate` runs migrations in `db/migrate`. `db:seed` loads `db/seeds.rb`.
