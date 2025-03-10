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

or 

```
make dev
```

#### Train Routes

I love traveling in Europe by train.  When I plan trips, I want a better way to figure out routes from city to city based on time and train changes.  I added train routes to Neo4j and built a visual interface with a simple query language to get answers to some of my most common questions.

Example 1 - Where can I go from Munich with at most 1 train change:

![Graph Nodes Example](https://ik.imagekit.io/notme001/readme/graph_nodes_munich.png "graph nodes query")

Example 2 - Find all routes from Munich to Paris with at most 2 train changes:

![Graph Routes Example](https://ik.imagekit.io/notme001/readme/graph_routes_munich_paris.png "graph routes query")


#### Places and Maps

I love traveling and Google maps is my navigation tool when I explore different cities.  But Google maps doesn't allow me to export my data (or at least not easily via an api).  I want a tool to save places, add tags and notes, and own this data.

I used a maps api and a places api to build an interface to search places in any city, add and label them, and then be able to search them and view them in a maps view.

Search Places Example - Find places named 'Louvre' near Paris:

![Search Places Example](https://ik.imagekit.io/notme001/readme/paris_louvre_search.png "search places")

Search Saved Places - Search places by name or tag near Paris:

![Search Saved Places Example](https://ik.imagekit.io/notme001/readme/paris_places_view.png "search saved places")

Map Saved Places - Show map of saved places near Paris:

![Map Saved Places Example](https://ik.imagekit.io/notme001/readme/paris_maps_view.png "map saved places")


#### Weather App

Sign up for an [openweather](https://openweathermap.org) api token and update .env.dev.

```
OPENWEATHER_API_TOKEN="<your_token_here>"
```

Open [http://localhost:5000/weather](http://localhost:5000/weather) in your browser.
