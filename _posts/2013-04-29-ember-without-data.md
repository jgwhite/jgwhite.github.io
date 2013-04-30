---
layout: post
title: 'Ember Without Data'
---

**This post is a work-in-progress, [comments are welcome][0].**

---

## Disclaimer

This post assumes an entry-level familiarity with Ember and its
conventions. If you’ve yet to use Ember there are a [few][1]
[other][2] [articles][3] worth reading first.

If you’re already familiar with Ember, Ember-Data and the conversation
surrounding both, then all this will probably be old news.

Otherwise, read on…

---

Ember has crystalised into v1 maturity. Ember-Data, however, is not
yet production-ready and has become a [point of contention][4] within
the community. When it all works, it’s like magic. When it doesn’t,
it’s hard to know where to start debugging.

Many of the complaints and confusion so far have stemmed from a
misconception that Ember-Data is part of Ember core and therefore
Ember can’t be used without it. The team have been [working hard][5] to
dispel this perception and demonstrate Ember’s power without Data.

Most apps will need a data-layer at some point though, and it’s
undeniable that Ember works best in conjunction with Data.
Let’s qualify that statement a little though — in reference to a
framework like Ember, when we say *‘works best’* we really mean
*‘does as much work for us as possible’*.

With this in mind, let’s work out how we can get Ember to do all this
work for us without depending on Ember-Data.

---

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

---

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

This works nicely for our `records` route. When `App.Record.DATA` changes,
bindings ensure that the rendered content updates accordingly.
It does not work out so well for our singular `record`. Let’s have a look
what happens when we arrive directly at that route:

![Singular record problem](http://www.websequencediagrams.com/files/render?link=wtH0S-dEI_17kvLdsk-O)

We see that when the app transitions into the `/records/1` route, the
record with id ‘1’ is nowhere to be found. At some later stage, our
ajax request will receive a response and the data will arrive. In
fact, we could get lucky and the request could complete before we
get to our route. More likely than not though, it’ll arrive at the
wrong time.

It’s time to borrow another concept from Ember-Data: object materialization.
Also known object hydration, this is the process of returning a stand-in
value object from the data store that will, at some later stage, be
‘hydrated’ with its real data. At which point, Ember’s bindings will
ensure all rendered content updates accordingly.

This pattern is not unique to Ember-Data. A [quick][6] [Google][7] will
show many implementations across different languages and libraries.
Nonetheless, it’s extremely powerful. Let’s have a look about how our
app might flow with this in place.

![Singular record with materialization](http://www.websequencediagrams.com/files/render?link=aEb-LRIiyZehPQmVQD9E)

Note that a new collaborator has appeared, labelled `?`. Arguably, we
could hide all this behaviour in `App.Record`, but let’s not over-burden
that class. Instead, let’s borrow yet another concept, the Store.

Ember’s docs describe `DS.Store` as a [bookkeeping object][8]. For our
purposes, it’s main jobs are:

* Creating and keeping-track of dehydrated record objects
* Keeping track of all hydrated record objects

Let’s call our implementation `RecordStore`:

```javascript
App.RecordStore = Ember.Object.extend({
  idMap: {},
  hydratedObjects: [],

  init: function() {
    this._super();
    this._fetch();
  },

  find: function(id) {
    return this._objectFor(id);
  },

  all: function() {
    return this.get('hydratedObjects');
  },

  _objectFor: function(id) {
    var idMap = this.get('idMap');

    return idMap[id] = idMap[id] ||
                       App.Record.create({ id: id });
  },

  _fetch: function() {
    var self = this;

    $.getJSON('/api/records.json').then(function(data) {
      data.records.forEach(function(record) {
        self._hydrateObject(record.id, record);
      });
    });
  },

  _hydrateObject: function(id, properties) {
    var object = this._objectFor(id);
    object.setProperties(properties);
    object.set('isLoaded', true);
    this.get('hydratedObjects').addObject(object);
  }

});
```

Let’s adjust our `App.Record.find` implementation accordingly:

```javascript
// It’s up to us when we instantiate our store
// and where we keep it.
App.Record.store = App.RecordStore.create();

App.Record.find = function(id) {
  if (Ember.isNone(id)) {
    return App.Record.store.all();
  } else {
    return App.Record.store.find(id);
  }
}
```

* Conclusion:  
  learning from frameworks even if you don’t end up using them

[0]: https://github.com/jgwhite/jgwhite.github.com/issues
[1]: #TODO
[2]: #TODO
[3]: #TODO
[4]: http://discuss.emberjs.com/t/ember-data-endless-frustration/893
[5]: http://emberjs.com/blog/2013/03/22/stabilizing-ember-data.html
[6]: https://www.google.co.uk/search?q=object+materialization
[7]: https://www.google.co.uk/search?q=object+hydration
[8]: https://github.com/emberjs/data/blob/master/ARCHITECTURE.md#dsstore
