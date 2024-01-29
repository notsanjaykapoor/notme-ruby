### Intro

A Ruby app built using [Roda](https://github.com/jeremyevans/roda) and [Sequel](https://github.com/jeremyevans/sequel).

The api server supports both rest and graphql endpoints.  The websockets server supports a simple terminal interface.

The app also supports a front-end using the [Tilt](https://github.com/rtomayko/tilt) template engine.

### Setup

This repo uses ruby 3.3 but should work with any recent ruby version.

Install ruby gems:

```
bundle install
```

Copy .env.example to .env.dev. Set DATABASE_URL to a suitable postgres instance.  Get an openweather token if you want to see the weather example:

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
./bin/test
```

Start server on a port of your choice:

```
./bin/api-server --port 5000
```

The app should now be accessible:

```
http://localhost:5000/ping
```





