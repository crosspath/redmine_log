# Redmine Log plugin

This plugin writes a record in database at every page load. You may see it in table ```logs```.

You may filter rows by method ('GET', 'POST', ...), query (url), parameters (example: {"controller":"groups","action":"index"}),
controller, response code (200, 404, ...), referer, referer controller, user id, dates.
Also you may see chains (example: ```Log.where(first_id: Log.first.id).order(:id)```).

## Alternatives

[```redmine_access_logger```](https://github.com/kiwamu/redmine_access_logger)
