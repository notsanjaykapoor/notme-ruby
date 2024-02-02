A Ruby app built using [Roda](https://github.com/jeremyevans/roda), [Async](https://github.com/socketry/async), [Sequel](https://github.com/jeremyevans/sequel), and [Falcon](https://github.com/socketry/falcon).

The api server supports both rest and graphql endpoints.  The websockets server supports a simple terminal interface.

The app also supports a front-end using the [Tilt](https://github.com/rtomayko/tilt) template engine.

## Setup

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
./bin/test
```

Start server on a port of your choice:

```
./bin/api-server --port 5000
```


## Weather App

Sign up for an [openweather](https://openweathermap.org) api token and update .env.dev.

```
OPENWEATHER_API_TOKEN="<your_token_here>"
```

Open [http://localhost:5000/weather](http://localhost:5000/weather) in your browser.
