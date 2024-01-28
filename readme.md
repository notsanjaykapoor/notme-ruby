### Intro


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

Start api server on a port of your choice:

```
./bin/api-server --port 5000
```

The app should now be accessible:

```
http://localhost:5000
```





