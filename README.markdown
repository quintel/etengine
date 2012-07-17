# ETengine

Welcome.

## Installation

Assuming you can run a 'normal' rails application on your local machine, 
you have to follow these steps to run ET-Engine.
* `$> bundle install` to install dependencies if you haven't done already
* `$> rake db:create` to create your database
* `$> cap staging db2local` to fill your database with records from staging
  server
* create a directory to clone etsource into, I advise to use
  a dedicated etsource copy in the etengine root folder:
  `git clone git@github.com:dennisschoenmakers/etsource.git`
* create an empty directory as a working copy for your etsource directory
  `mdkir etsource_export`
* `$> cd config`
* `$> cp config.sample.yml config.yml; cp database.sample.yml database.yml`
* open up these two files in your favorite text-editor and fill in the
  details of the directories you just created. You can leave the defaults as
  they are, unless you want something else
* fire up your local rails server (use `rails s` on the console or use
  [pow](http://pow.cx)
* go to `http://etengine.dev/etsource` or equivalent
* import the latest commit or another one if you like that better
* you're done!

## GQL

[GQL Functions](http://beta.et-engine.com/doc/Gql/Grammar/Sandbox.html)

[Converter methods](http://beta.et-engine.com/doc/Qernel/ConverterApi.html)

## Screencasts

Password for all is: quintel

#### (GQL Console)[http://vimeo.com/40660438]

#### (GQL Docs)[http://vimeo.com/40663213]

How to use this documentation.

#### (GQL Console and ETsource)[http://vimeo.com/40707436]

How to work with different etsource directories, make changes and load them in
the gql console.

#### (ETsource: Create a new basic etmodel)[http://vimeo.com/40709640]

We build a new etmodel with 3 converters from scratch. This helps you
understand how the etsource works.

The result you can find in: etsource/models/sample
