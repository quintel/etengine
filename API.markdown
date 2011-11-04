http://developer.github.com/v3/

# API

API access is over HTTP and data is sent and received in various formats. Following the Rails' conventions, the format is usually appended to the URL:
  
    http://etengine.dev/api/v2/api_scenarios/new => HTML Response
    http://etengine.dev/api/v2/api_scenarios/new.json => JSON Response

The preferred format is JSON and the documentation will use it as default format.

## JSONP Callbacks

Most API requests are actually called with JSONP since the Cross-Domain Policy forbids an XmlHttpRequest to an external domain. Unless you setup a web proxy to handle this issue, pass a `callback` parameter to any GET call to have the results wrapped in a JSON function.

Example:

    curl http://etengine.dev/api/v2/api_scenarios/new.json
    {"api_scenario":{"country":"nl","end_year":2040,"id":7806,"region":null,"use_fce":false,"user_values":{}}}                                                 
  
    curl http://etengine.dev/api/v2/api_scenarios/new.json\?callback\=foobar
    foobar({"api_scenario":{"country":"nl","end_year":2040,"id":7807,"region":null,"use_fce":false,"user_values":{}}})

## Create a new session

    GET /api/v2/api_scenarios/new.json

### Parameters

    settings:
      country:
      region:
      start_year:
      end_year:
      use_fce:
      preset_scenario_id:

### Response

    {
      "api_scenario":{
        "country":"nl",
        "end_year":2040,
        "id":7766,
        "region":null,
        "use_fce":false,
        "user_values": {}
      }
    }

## Update inputs and run gqueries

    GET /API/v2/api_scenarios/:id

### Parameters

* `id`: scenario id, received creating a new session 
* `r`: a string that joins gquery ids with a `;`
* `result`: an array of gquery ids and/or keys
* `input`: a hash of slider values in this form: `input[slider_id]=slider_value`

The function of the `r` parameter is to make the query string shorter. Internet Explorer truncates URLs longer than 8192 chars. With JSONP requests such lengths can be reached easily.

### Response

    http://etengine.dev/api/v2/api_scenarios/7809.json?r=76988 =>
    
    {
      "result":{
        "76988":
          [
            [2010,0.0],[2040,0.0]
          ]},
      "settings":{
        "country":"nl",
        "end_year":2040,
        "preset_scenario_id":null,
        "region":null,
        "use_fce":false,
        "user_values":{}},
      "errors":[]
    }

The most important values are inside the `result` hash, that contains a dictionary of the gqueries we requested using the `r` and `result` parameters.

## User values

    GET /api/v2/api_scenarios/7808/user_values.json

This action is only used on the ETM to setup the sliders with the proper attributes and values.

### Response

    {
      "1":{
        "max_value":5.0,
        "min_value":0.0,
        "start_value":0.0,
        "full_label":null
        },
      "6":{
        "max_value":96.0,
        "min_value":-57.0,
        "start_value":0.0,
        "full_label":null
      },
      ...
    }

The hash index is the input id.

# ActiveResource Controllers

The ETE also has some controllers that respond with ActiveResource objects. They follow the common rails conventions and RESTful actions.
At the moment they respond in XML format, but as soon as we'll upgrade to Rails 3.1 JSON will be the default format.

## Gqueries

### Gquery list

    GET /api/v2/gqueries.xml

Returns an AR-XML with all the available gqueries. The only visible attributes are `id`, `key` and `deprecated_key`.

## Inputs

### Input list

    GET /api/v2/inputs.xml

### Input details

    GET /api/v2/inputs/:input_id.xml

## Areas

### Area list

    GET /api/v2/areas.xml

#### Parameters

* `country`: to get only the areas that belong to a specific country

### Area details

    GET /api/v2/areas/:area_id.xml

## Scenarios

### Scenario Index

    GET /api/v2/scenarios/index.xml

Returns the predefined scenarios, ie those that have not been created through the API. Paginates per 20 items.

#### Parameters

* `page`: pagination offset

### Homepage scenarios

    GET /api/v2/scenarios/homepage.xml

Returns the scenarios that should be shown on the ETM homepage.


Other ActiveResource actions. Check if they're still used.

### Show

    GET /api/v2/scenarios/:id.xml

### Create

    POST /api/v2/scenarios.xml

### Update

    PUT /api/v2/scenarios/:id.xml

### Load

    GET /api/v2/scenarios/:id/load.xml



# TODO

* Disable non-JSON format. Since Rails 3.1 has replaces XML with JSON for ActiveResource, it makes sense to use JSON eclusively
* Make the API more REST-ful; better use of HTTP actions
* Error handling is still very limited