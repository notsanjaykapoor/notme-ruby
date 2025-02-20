A Ruby app built using [Roda](https://github.com/jeremyevans/roda), [Async](https://github.com/socketry/async), [Sequel](https://github.com/jeremyevans/sequel), and [Falcon](https://github.com/socketry/falcon).

The api server supports both rest and graphql endpoints.  The websockets server supports a simple terminal interface.

The app also supports a front-end using the [Tilt](https://github.com/rtomayko/tilt) template engine.

#### Setup

This repo uses ruby 3.3 but should work with any recent ruby version.

Install ruby gems:

```
bundle install
```

Copy .env.example to .env.dev. Set DATABASE_URL to a suitable postgres instance.  Sign up for an openweather token to use the weather example:

```
https://openweathermap.org/
```

Run migrations for dev and tst environments:

```
RACK_ENV=dev ./bin/db-migrate

RACK_ENV=tst ./bin/db-migrate
```

Run tests:

```
make test
```

Start server on a specified port:

```
./bin/api-server --port 5000
```


#### Graph App

I like traveling by train and Europe is great for that.  When I plan trips, I want a better way to figure out routes from city to city based on time and train changes.  I used a graph database to do this.  I added train routes to Neo4j, with cities as nodes and times as edges.  I then built a visual interface with a simple query language to get answers to some of my common questions.

![Graph Interface Example](https://ik.imagekit.io/notme001/readme/graph_query_language.png "graph interface with query language")

Example 1 - Where can I go from Munich with at most 1 train change:

![Graph Nodes Example](https://ik.imagekit.io/notme001/readme/graph_nodes_munich.png "graph nodes query")

Example 2 - Find all routes from Munich to Paris with at most 2 train changes:

![Graph Routes Example](https://ik.imagekit.io/notme001/readme/graph_routes_munich_paris.png "graph routes query")


#### Weather App

Sign up for an [openweather](https://openweathermap.org) api token and update .env.dev.

```
OPENWEATHER_API_TOKEN="<your_token_here>"
```

Open [http://localhost:5000/weather](http://localhost:5000/weather) in your browser.
