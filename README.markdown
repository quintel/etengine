# Energy Transition Engine (ETE)

This is the source code for the Calculation Engine that is used by the
[Energy Transition Model](http://energytransitionmodel.com) and its various
interfaces (clients).

It is an online web app that lets you create a future energy scenario for
various countries.  This software is [open source](LICENSE.txt), so you can
fork it and alter at your will.

ETEngine does not contain an easy-to-use frontend for creating and editing
these energy scenarios; that role is instead fulfilled by separate applications
such as [ETModel][etmodel], [ETFlex][etflex], and the [EnergyMixer][energymixer],
which each use ETEngine's REST API for manipulating and calculating scenarios.

[![Build Status](https://quintel.semaphoreci.com/badges/etengine/branches/master.svg)](https://quintel.semaphoreci.com/projects/etengine)

## License

The ETE is released under the [MIT License](LICENSE.txt).

## Installation with Docker

New users are recommended to use Docker to run ETEngine. Doing so will avoid the need to install additional dependencies.

1. Get a copy of [ETEngine](https://github.com/quintel/etengine) and [ETSource](https://github.com/quintel/etsource); placing them in the same parent directory:

    ```
    ├─ parent_dir
    │  ├─ etengine
    │  └─ etsource
    ```

    Place the ETSource decryption password in a file called `.password` in the ETSource directory. This is required to decrypt a small number of datasets for which we're not authorised to publicly release the source data.

    ```
    ├─ parent_dir
    │  ├─ etengine
    │  └─ etsource
    │     ├─ .password   # <- password goes here
    │     ├─ carriers
    │     ├─ config
    │     ├─ datasets
    │     ├─ ...
    ```

2. Build the ETEngine image:

    ```sh
    docker-compose build
    ```

3. Install dependencies and seed the database:

   ```sh
   docker-compose run --rm web bash -c 'bin/rails db:drop && bin/setup'
   ```

   The command drops any existing ETEngine database; be sure only to run this during the initial setup! This step will also provide you with an e-mail address and password for an administrator account.

4. Launch the containers:

   ```sh
   docker-compose up
   ```

   After starting application will become available at http://localhost:3000 after a few seconds. This is indicated by the message "Listening on http://0.0.0.0:3000".

Before the application can start serving scenarios, it must calculate the default dataset (Netherlands). This process will begin the first time a scenario is requested and will take several seconds. Signing in to the administrator account will also begin the calculation. Please be patient! Further requests to ETEngine will happen much faster.

## Installation without Docker

Installing ETEngine on a local machine can be a bit involved, owing to the
number of dependencies. Assuming you can run a 'normal' rails application on your local machine,
you have to follow these steps to run ETEngine.

1. Install the "Graphviz" library
   * Mac users with [Homebrew][homebrew]: `brew install graphviz`
   * Ubuntu: `sudo apt-get install graphviz libgraphviz-dev`

1. Install "MySQL" server
   * Mac: Install latest version using the [Native Package][mysql] (choose the 64-bit DMG version), or install via brew: `brew install mysql`
   * Ubuntu: `sudo apt-get install mysql-server-5.5 libmysqlclient-dev`

1. Clone this repository with `git clone git@github.com:quintel/etengine.git`

1. Run `bundle install` to install the dependencies required by ETEngine.

1. Clone a copy of [ETSource][etsource] –– which contains the data for each
   region:
   1. `cd ..; git clone git@github.com:quintel/etsource.git`
   1. `cd etsource; bundle install`

1. Create the database you specified in your "database.yml" file, and
   1. run `bundle exec rake db:setup` to create the tables and add an
      administrator account –– whose name and password will be output at the end –– OR
   1. run `bundle exec rake db:create` to create your database and
      contact the private Quintel slack channel to fill your database with records from staging server

1. You're now ready-to-go! Fire up the Rails process with `rails s` or better `bin/dev`.

1. If you run into an dataset error, check out this
   [explanation](https://github.com/quintel/etsource#csv-documents "Explanation on etsource CSV files") on CSV files

## Technical Design

### Caching

The ETEngine uses heavily caching of calculated values by using the
[fetch](https://github.com/quintel/etengine/blob/51b321f6d43a2d2a626aa268845b775fca051ae0/app/models/qernel/dataset_attributes.rb#L205-L237)
function that stores and retrieves calculated values. This has some drawbacks,
but is necessary to keep performance up.

### Scenario

When the user starts a new scenario, the user has to choose the `end_year`
and the `area` for which this scenario applies. This can/should *not* be
altered later.

### Present and future

The ETEngine uses *two* graphs that store all the data: one for the present
year and one for the future year. In this sense, the ETengine is a 'two
state' model: everything is calculated twice: once for the start year, and
once for the end year. It is important to note that ETengine therefor does
*not* calculate intermediate years. An exception to this is
[Merit](http://github.com/quintel/merit), a module for ETengine (that can
also be used independently which contains time series at a one hour resolution
for one year.

### Inputs

A user can alter the start scenario with the use of **inputs**. Every input has
a key and a value can be sent to ETEngine. For example a user can tell ETengine:

    number_of_energy_power_nuclear_gen3_uranium_oxide = 2

This means that the user wants to 'set' the number of nuclear power plants to `2`
in his/her current scenario.

The current set of inputs can be found on
[ETSource][etsource].


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

### Output

The user can request output from his/her scenario with the use of
*gqueries*. A gquery always returns the *present* and the *future*
output value, although there are exceptions to this.

E.g. when the user sends the `dashboard_co2_emissions` query to
ETEngine, it will receive the following feedback:

* present: 123
* future: 456
* unit: MJ

A **gquery** is nothing more then a stored statement. These statements are
written in our own language called the *Graph Query Language* (GQL) and
a recent list can be found on [ETSource][etsource].

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

[Node methods](http://beta.et-engine.com/doc/Qernel/NodeApi.html)

## Screencasts

Password for all the screencasts below is `quintel`.

#### [GQL Console](http://vimeo.com/40660438)

#### [GQL Docs](http://vimeo.com/40663213)

How to use this documentation.

#### [GQL Console and ETSource](http://vimeo.com/40707436)

How to work with different etsource directories, make changes and load them in
the gql console.

#### [ETSource: Create a new basic etmodel](http://vimeo.com/40709640)

We build a new etmodel with 3 nodes from scratch. This helps you
understand how the etsource works.

The result you can find in: etsource/models/sample

[etsource]:    http://github.com/quintel/etsource  "ETSource: database for the ETM."
[etmodel]:     http://github.com/quintel/etmodel
[etflex]:      http://github.com/quintel/etflex
[energymixer]: http://github.com/quintel/energymixer
[homebrew]:    http://brew.sh
[pow]:         http://pow.cx
[mysql]:       http://dev.mysql.com/downloads/mysql/5.5.html#macosx-dmg

