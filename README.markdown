# ETengine

Welcome.

## Changelog

- 2012-08-14: QUERY_FUTURE/PRESENT now accept a lambda - sb

    QUERY_PRESENT( -> { GRAPH(year) } )  # => 2010
    QUERY_FUTURE( -> { GRAPH(year) } )   # => 2050
    # Still works with gquery keys:
    QUERY_FUTURE( dashboard_total_costs )


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
* fire up your local rails server (use `$> rails s` on the console or use
  [pow](http://pow.cx)
* go to `http://etengine.dev/etsource` or equivalent
* Press 'import' (the latest commit or another one if you like that better)
* you're done!

### Auto-reloading your changes to etsource

Sometimes you want to play around or tweak some gqueries. Then, you don't
want to create commits every time and import them. Because when you are
satisfied, you'll probably have 10 commits, that needs to be cleaned up,
squashed.

You can add the option `etsource_live_reload: true` in your `config.yml`
file.

Change queries, inputs, datasets, gqueries, inputs or topology directory
in your **et_source_export** folder, and Etengine reloads your changes
automatically!

B.t.w. By default your *etsource_export* directory is not under version control.
In order to gain the advantages of Git, just point *etsource_export* to the
*etsource* directory, either by using a symbolic link or using the same directory
in your config.yml file. But **be carefull** NOT to use the interface's
'import' action on /etsource: that will delete/overwrite your etsource_export
directory!

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
