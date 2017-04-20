# MultipleDbs
So, your rails application needs to handle n databases. Well my friend,
this is your solution. This gem allows you to handle all your databases
connections, either for different databases that share the same entity
relationship model or for different databases with different entity
relationship models.

## Usage

multiple_dbs creates a subclass for the models you want to handle in multiple
databases and one subclass for each connection. By doing this, each connection is
handled by it's own subclass, preventing switching between connections, which add a high computational cost.

#### IMPORTANT.
The following examples assume that you define 3 databases: db1, db2 and db3.

Please read all this document, especially if your project is already running or
already has a database with migrations and stuff.

### Generate models.

If you want to generate a model for all the databases, run
```bash
$ rails g multiple_dbs_model user email:string
```

If you want to generate a model for a specific databases, run
```bash
$ rails g multiple_dbs_model user email:string --only=db1 db3
```

If you want to generate a model skipping a specific databases, run
```bash
$ rails g multiple_dbs_model user email:string --skip=db1 db3
```

You will find all migrations in the folder db/your_database/migrate.
The schema and seed files can be found in the folder db/your_database.

#### NOTE:
If you already have models, migrations and a schema file, and want to manage that
initial database with the multiple_dbs gem (recommended), you should create the database using the multiple_dbs_initializer generator and pass said database name as an argument. Check the "How to start if already have a database ?"  section for more information.

If you DO NOT want to override the default database.yml file, add as an option
--not_override=true


### Generate Migrations

If you want to generate a migration for all the databases, run
```bash
$ rails g multiple_dbs_migration add_column_password_to_users password:string
```

If you want to a generate migration for a specific database, run
```bash
$ rails g multiple_dbs_migration add_column_password_to_users password:string --only=db1 db3
```

If you want to generate a migration skipping a specific database, run
```bash
$ rails g multiple_dbs_migration add_column_password_to_users password:string --skip=db1 db2
```

#### NOTE:
If you already have models, migrations and a schema file, and want to manage that
initial database with the multiple_dbs gem (recommended), you should create the database using the multiple_dbs_initializer generator and pass said database name as an argument. Check the "How to start if already have a database ?"  section for more information.

If you DO NOT want to override the default database.yml file, add as an option
--not_override=true

### Setting up your models

Assuming that you create a User model and it has many Posts.

The User and Post models should look like this:
```ruby
# app/models/user.rb
class User < ApplicationRecord
  make_connectable_class do |db|
    has_many :posts, class_name: "Post#{db}"
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  make_connectable_class do |db|
    belongs_to :user, foreign_key: "user_id", class_name: "User#{db}"
  end
end
```
Here, you associate the models between databases, by using classes PostDb1, PostDb2 and PostDb3 associated with classes UserDb1, UserDb2 and UserDb3 respectively.

In case you don't need the association through all the databases, for example, the
database db1, your models should look like this.

```ruby
# app/models/user.rb
class User < ApplicationRecord
  make_connectable_class do |db|
    has_many :posts, class_name: "PostDb1"
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  make_connectable_class do |db|
    belongs_to :user, foreign_key: "user_id", class_name: "UserDb1"
  end
end
```
Here, you associate the models between databases, by using class PostDb1 associated with classes UserDb1, UserDb2 and UserDb3.

In case you don't need to define a class for all your databases, your models should look like this.
```ruby
# app/models/user.rb
class User < ApplicationRecord
  make_connectable_class(only: [:db1,:db3]) do |db|
    has_many :posts, class_name: "Post#{db}"
  end
end

# app/models/post.rb
class Post < ApplicationRecord
  make_connectable_class(only: [:db1,:db3]) do |db|
    belongs_to :user, foreign_key: "user_id", class_name: "User#{db}"
  end
end
```

Here, you associate the models between databases, by using classes PostDb1, PostDb2 and PostDb3 associated with classes UserDb1 and UserDb3.

### Using the subclasses

You have two options for using a subclass that handles a connection.

- 1. Using the raw constant

  Use the UserDb1 class as usual
  ```ruby
    UserDb1.create(email: "someone@email.com")
  ```

- 2. Get the class from the base model

  Use the model User to get the desired class.

  ```ruby
    user_class = User.multiple_class(:db1)
    user_class.create(email: "someone@email.com")
  ```
  This is useful if your client sends you the database for data storage or transaction runs.


## Installation

Add this line to your application's Gemfile:
```ruby
gem 'multiple_dbs'
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install multiple_dbs
```

Let's setup our connections. We are going to create all our configuration files
and all the stuff needed. Call the multiple_dbs_initializer generator and pass
as an argument the databases names. You can also pass as options the specific
database configuration.

Run in your terminal
```bash
$ rails g multiple_dbs_initializer my_database1 my_database2
```

If you need to configure the database connections (adapter, username,
etc), pass the options you want. Allowed options are: adapter,encoding,pool,username,password

Run in your terminal
```bash
$ rails g multiple_dbs_initializer my_database1 my_database2
--development=username:goku password:ukog adapter:mysql2
--test=username:gohan password:nahog adapter:postgresql pool:2
--production=username:seriusname password:enviromentvariablepls pool:20
```

Run the help command for more information
```bash
$ rails g multiple_dbs_initializer --help
```

### Rails >= 5.x.x

Add this line to your application_record.rb file so you ApplicationRecord class
looks like this.
```ruby
# app/models/application_record.rb
class ApplicationRecord < ActiveRecord::Base
  include MultipleDbs::MultiConnectable # this line
  self.abstract_class = true
end

```
### Rails >= 4.x.x < 5.x.x
You can create a class and make the models inherit from it, like this.
```ruby
# app/models/connection_base.rb
class ConnectionBase < ActiveRecord::Base
  include MultipleDbs::MultiConnectable
  self.abstract_class = true
end
```

And make your models inherit from that class.
```ruby
# app/models/your_model.rb
class YourModel < ConnectionBase
  # awesome code
end
```

### How to start if already have a database ?.

If you already have a database and want to replicate the entity relationship model in your new databases you can do the following:

- Install the gem.
- Run the multiple_dbs_initializer and configure your database connections.
- If you want to copy the migrations from the default folder db/migrate into all your new databases, run in your terminal
```bash
$ rails "mdbs:replicate_default_database"
```

This command will copy your db/migrate folder into each of your databases folders, like db/your_database.

- If you want to copy the migrations from the default folder db/migrate into an specific database, run in your terminal:
```bash
$ rails "mdbs:replicate_default_database_into[your_database]"
```

This command will copy your db/migrate folder into db/your_database

- If you want to copy a specific migration from the default folder db/migrate into all your databases, run in your terminal:
```bash
$ rails "mdbs:copy_migration_from_default[file_name.rb]"
```

- If you want to copy a specific migration from the default folder db/migrate into an specific database, run in your terminal:
```bash
$ rails "mdbs:copy_migration_from_default_into[file_name.rb, database_name]"
```

- after you copy the migrations you want into the databases you want, migrate your databases, run in your terminal:
```bash
$ rails mdbs:migrate
```


### Manage the databases
multiple_dbs comes with a list of useful tasks that you can find in your project
after the gem was installed.

Run in your terminal
```bash
$ rake --tasks
```

You will find all the tasks under the namespace "mdbs"

To create all the databases.
```bash
$ rails mdbs:create
```

To create a specific database
```bash
$ rails mdbs:your_database_name:create
```

To setup all the databases.
```bash
$ rails mdbs:setup
```

To setup a specific database.
```bash
$ rails mdbs:your_database_name:setup
```

To migrate all the databases.
```bash
$ rails mdbs:migrate
```

To migrate a specific database.
```bash
$ rails mdbs:your_database_name:migrate
```

You can pass the standard rails options as arguments to the tasks.

Please. Please! check the tasks under the namespace "mdbs"
Run in your terminal
```bash
$ rake --tasks
```



## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
