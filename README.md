# MultipleDbs
So your rails application need to handle n databases, well my friend
this is your solution. This gem allow you to handle all your databases
connections, either for different databases that share the same entity
relationship model or for different databases with different entity
relationship models.

## Usage

#### Install the gem


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
rails g multiple_dbs_initializer my_database1 my_database2

If you need to configure the database conections, things like the adapter, user,
etc, pass the options you want. Allowed options are: adapter,encoding,pool,username,password

Run in your terminal
rails g multiple_dbs_initializer my_database1 my_database2 --development=username:goku password:ukog adapter:mysql2 --test=username:gohan password:nahog adapter:postgresql pool:2 --production=username:seriusname password:enviromentvariablepls pool:20

Check the help for more information. Run in your terminal
rails g multiple_dbs_initializer --help



## Contributing
Contribution directions go here.

## License
The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
