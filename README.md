# unival

A no-frills RESTful validation service for ActiveModel. Helps for the cases where you found that doing client-side
validations is a bad idea. It is just an endpoint.

# How to use it

Mount it into your application (Rails or otherwise). Then, send it a request like so:

    POST /?model=User

with a JSON body of:
   
    {"name": "John Doe"}

`POST` implies you want to check if you are able to create an object.
The app is going to instantiate a blank User model object, perform `user#attributes = your_attributes` and is going to call
`valid?` on it. If it isn't valid, you are going to receive the errors back:

    {
      "model": "User",
      "is_create": true,
      "valid": false,
      "errors": {
        "name": [
          "has already been taken"
        ]
      }
    }

If it is valid, you the `valid` property in the JSON response will be `true`, and the `errors` property will be set to `null`.
To perform a check for a modification, use `PUT` or `PATCH` (`ActiveModel#attributes=` works rather like a `Hash#merge`, not like a
full-on replace assignment).

    PUT /?model=User&id=123

will give the same response as the POST example, except that `is_create` will be set to `true`.

## Concerns

This approach is relatively insecure as it allows for probing. Use something like `Rack::Attack` to limit the number of
checks from a single IP/browser combination. Even then, use this sparingly. You may also restrict the models that can be validated
from this endpoint by overriding `model_accessible?(model_module)`

## Contributing to unival
 
* Check out the latest master to make sure the feature hasn't been implemented or the bug hasn't been fixed yet.
* Check out the issue tracker to make sure someone already hasn't requested it and/or contributed it.
* Fork the project.
* Start a feature/bugfix branch.
* Commit and push until you are happy with your contribution.
* Make sure to add tests for it. This is important so I don't break it in a future version unintentionally.
* Please try not to mess with the Rakefile, version, or history. If you want to have your own version, or is otherwise necessary, that is fine, but please isolate to its own commit so I can cherry-pick around it.

## Copyright

Copyright (c) 2016 Julik Tarkhanov. See LICENSE.txt for
further details.

