# ETengine

The Calculation Engine that is used by the Energy Transition Model. 

Copyright (C) Quintel Intelligence. All rights reserved.

## Design

### Caching

The ETEngine uses heavily caching of calculated values by using the
[fetch_and_rescue](https://github.com/quintel/etengine/blob/51b321f6d43a2d2a626aa268845b775fca051ae0/app/models/qernel/dataset_attributes.rb#L205-L237)
function that stores and retrieves calculated values and makes sure
that possible errors do not block execution. This needless to say,
also has heavy drawbacks.

### Scenario



### Present and future

The ETEngine uses two graphs that store all the data: one for the present
year and one for the future year. In this sense, the ETengine is a 'two
state' model. An exception to this is [Merit](http://github.com/quintel/merit)
which contains time series at 1 hour resolution for one year.

### Inputs

A user can alter the start scenario with the use of **inputs**. Every input has
a key and a value can be sent to ETEngine. For example a user can tell ETengine:

    number_of_energy_power_nuclear_gen3_uranium_oxide = 2

This means that the user wants to 'set' the number of nuclear power plants to `2`
in his/her current scenario.

The current set of inputs can be found on
[etsource](https://github.com/quintel/etsource/tree/master/data/inputs).


Every times the user requests some output, **all** the inputs that have been
touched by that user for that scenario are applied again. The order in which
they are applied can be controlled if necessary.

The priority of every input defaults to 0, and can be set a manual value
(e.g. 100) on inputs which need to be executed first. For example, an input
with `priority=100` gets executed before an input with `priority=99`, etc...

This is someting to keep in mind when designing your input statements.

#### Competing inputs

For example, when you have two inputs:

* input `A`: update attribute `X` to have value `1`
* input `B`: update attribute `X` to have value `2`

The outcome of this `X` will be `1` **or** `2` depending on the priority of
these inputs (if they both have no priority or the same priority), this will
be randomly determined.

#### Complementary inputs

For example, when you have two inputs:

* input `A`: update attribute `X` to **increase** with `1%`
* input `B`: update attribute `X` to **increase** with `2%`

Then the outcome of the `X` will be 1.01 * 1.02.

## Installation

Assuming you can run a 'normal' rails application on your local machine,
you have to follow these steps to run ET-Engine.
* `$> bundle install` to install dependencies if you haven't done already
* `$> rake db:create` to create your database
* `$> cap staging db2local` to fill your database with records from staging
  server
* create a directory to clone etsource into, I advise to use
  a dedicated etsource copy in the etengine root folder:
  `git clone git@github.com:quintel/etsource.git`
* create an empty directory as a working copy for your etsource directory
  `mdkir etsource_export`
* `$> cd config`
* `$> cp config.sample.yml config.yml; cp database.sample.yml database.yml`
* open up these two files in your favorite text-editor and fill in the
  details of the directories you just created. You can leave the defaults as
  they are, unless you want something else
* make sure you have memcached running (using `memcached -d`)
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
