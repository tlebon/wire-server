THIS FILE ACCUMULATES THE RELEASE NOTES FOR THE UPCOMING RELEASE.

# [2021-xx-xx]

## Release Notes

## API Changes

* Remove the long-deprecated `message` field in `POST /connections` (#1726)
* Add `PUT /conversations/:domain/:cnv/name` (#1737)
* Deprecate `PUT /conversations/:cnv/name` (#1737)

## Features

## Bug fixes and other updates

## Documentation

## Internal changes

* Rewrite the `POST /connections` endpoint to Servant (#1726)

## Federation changes

* Ensure clients only receive messages meant for them in remote convs (#1739)