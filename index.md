---
layout: default
title: Jamie White
---

# JAMIE WHITE

---

Programmer at [HashiCorp](https://hashicorp.com)

---

## Contact

- [jamie@jgwhite.co.uk](mailto:jamie@jgwhite.co.uk)
- [github.com/jgwhite](https://github.com/jgwhite)
- [soundcloud.com/jgwhite](http://soundcloud.com/jgwhite)
- <a rel="me" href="https://indieweb.social/@jgwhite">indieweb.social/@jgwhite</a>

---

## Projects

- [Melody Paths](https://melody-paths.jgwhite.co.uk)
- [Fretboard](https://fretboard.jgwhite.co.uk)

---

## Essays

{% for post in site.posts %}

- [{{post.title}}]({{post.url}}) <small>— {{post.date | date_to_long_string}}</small>

  {% endfor %}
