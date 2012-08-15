## GQL

Gql::Gql handles a set of present and future graph, it is initialized with a scenario instance.

    gql = Gql::Gql.new(Scenario.default)
    # Assigns datasets and updates present/future graphs with the inputs
    # defined in the scenario
    gql.prepare
    # Now we can query the gql
    gql.query( "V(1.0)" )
    gql.query( "present:V(3.0)" )
    gql.query( Gquery.new(:key => 'foo', :query => "V(1.0)"))
    # Query only present/future:
    gql.query_present('V(3.0)')
    gql.query_future('V(3.0)')

## QueryInterface

The GQL updates and queries a single graph through the QueryInterface. Gql Runtime functions access the graph and other parts (notably subqueries) through the methods defined in QueryInterface, especially query_interface/lookup.rb.

