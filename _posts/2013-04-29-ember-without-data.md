---
layout: post
title: 'Ember Without Data'
---

**This post is a work-in-progress, [comments are welcome][0].**

Ember has crystalised into v1 maturity. Ember-Data, however, is not
yet production-ready and has become a [point of contention][1] within
the community. When it all works, it’s like magic. When it doesn’t,
it’s hard to know where to start debugging.

Many of the complaints and confusion so far have stemmed from a
misconception that Ember-Data is part of Ember core and therefore
Ember can’t be used without it. The team have been [working hard][2] to
dispel this perception and demonstrate Ember’s power without Data.

Most apps will need a data-layer at some point though, and it’s
undeniable that Ember works best in conjunction with Data.
Let’s qualify that statement a little though — in reference to a
framework like Ember, when we say *‘works best’* we really mean
*‘does as much work for us as possible’*.

With this in mind, let’s work out how we can get Ember to do all this
work for us without depending on Ember-Data.

## Don’t Fear The Router

Ember’s Router is the heart of any app. Follow its conventions and the
Router will handle almost all of your glue code for you. This includes
fetching your models.

When we create a resourceful-route for one of our models…

```javascript
App.Router.map(function() {
  this.resource('record', { path: '/records/:record_id' });
});
```

Ember knows that the model for that route can be found by calling:

```javascript
App.Record.find(params.record_id);
```

In order to recreate this interface, we need to define
`App.Record.find` in such a way that it returns the right model object.

```javascript
App.Record = Ember.Object.extend();

App.Record.find = function(id) {
  return App.Record.DATA.findProperty('id', id);
}

App.Record.DATA = [
  App.Record.create({ id: 1, name: 'My First Record' }),
  App.Record.create({ id: 2, name: 'My Second Record' })
]
```

What happens when we want to add a route that displays all records?

```javascript
App.Router.map(function() {
  this.resource('records', function() {
    this.resource('record', { path: ':record_id' });
  });
});
```

For reasons that are not immediately clear, Ember does not automatically
handle fetching multiple models. Nevertheless, the convention is:

```javascript
App.RecordsRoute = Ember.Route.extend({
  model: function() {
    return App.Record.find();
  }
});
```

So we need to make our `find` method return an array-like collection of
models if no `id` argument is passed.

```javascript
App.Record.find = function(id) {
  if (Ember.isNone(id)) {
    return App.Record.DATA;
  } else {
    return App.Record.DATA.findProperty('id', id);
  }
});
```

With this in place, our app is now wired up to display all
records in `App.Record.DATA`, and fetch a particular record by `id`.

## The Real World

A static set of records is only going to be useful for a while.
Pretty soon, we’re going to want to fetch data from an external source.
It’s up to us when we perform the request, so let’s do it right after
our simple store is defined.

```javascript
App.Record.DATA = [];

$.getJSON('/api/records.json').then(function(records) {
  records.forEach(function(record) {
    App.Record.DATA.addObject(App.Record.create(record));
  });
});
```

Note that we don’t replace the `DATA` array. For all our bindings to
work correctly, objects must remain consistent throughout the lifecycle
of the app. The implications of this statement may not be totally clear
so let’s look at an example.

* Hydrating models
* Identity maps
* Conclusion:  
  learning from frameworks even if you don’t end up using them

[0]: https://github.com/jgwhite/jgwhite.github.com/issues
[1]: http://discuss.emberjs.com/t/ember-data-endless-frustration/893
[2]: http://emberjs.com/blog/2013/03/22/stabilizing-ember-data.html
