# Redmine Log plugin

This plugin writes a record in database at every page load. You may see it in table ```logs```.

Write your home server name in ```config/servers.rb``` to deactivate writing logs on dev machine.

Also, you may use additional methods of ApplicationController (and all his children): ```prod?```, ```dev?```, ```test?```.

## Alternatives

[```redmine_access_logger```](https://github.com/kiwamu/redmine_access_logger)
