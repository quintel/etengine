## Creating specs
In the `config.yml` you can specify different collections of dataset.

You can see in the `spec/datasets_spec.rb` that for each country in the `countries` collection the emission validation will be run (`include_examples 'emissions', country`).

The emission validation can be found in `spec/validations/emissions.rb`.
These validations use all nodes from the specified node group `emissions` (`NodeGroup.new(:emissions, dataset)` will load up the nodes in the node group for a dataset).

## Running specs
You can run the specs by being in etengine in the terminal and running:

`bundle exec rspec lib/graph_data_validation/spec`

It will run against your local ETSource, and will print the dataset it is working on (as it takes a long time). But will only print all validation mistakes when it is done with all of them.
