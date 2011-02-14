public: yes
tags: [rstblog]
summary: New blog, some new projects.

================
No More Tumblr
================

A week or two ago I decided to stop using Tumblr and "roll my own" blog. Since I've been using flask_ to put `some projects`_ on the web, I decided to give rstblog_ a go. (Both written by the `same guy`_.)

rstblog is very much a very "small" blog app, with only very minimal documentation. Thankfully `Morten Siebuhr`_ put together a nice beginner's course on how to implement it. I referenced it heavily, though there were still some bumps on the road. Mostly, it took me awhile to realize you have to rm -r _build/ everytime you run-rstblog build. I was wondering why all of my links weren't updating; it was because when you do "run-rstblog build", it only seems to create templates that already exist. I don't have a great explanation. But if you're looking for rstblog tips, here's mine: rm -r _build/ every time you run-rstblog build.

I have also added a link to select projects in the header and generally cleaned and centralized everything.

Getting my blog in a somewhat finalized form also marks the end of the beginning of my movement toward setting up my own web server to function as a place to host my own projects, including the blog. I realize for most people who will read this running a webserver isn't that big a deal, and maybe even something you were doing in high school or before. But for me, this has been a new thing and a tremendous learning experience. Much thanks to Brett Hoerner for his `post on configuring Apache2 and nginx`_ for mod_wsgi. They've been a great reference source as I fumble with those two services.

.. _some projects: http://mattdeboard.net/projects
.. _rstblog: https://github.com/mitsuhiko/rstblog
.. _same guy: http://lucumr.pocoo.org
.. _Morten Siebuhr: http://sbhr.dk/2010/11/30/using_rstblog/
.. _post on configuring Apache2 and nginx: http://bretthoerner.com/2008/10/9/configs-for-nginx-and-apache-mod-wsgi
.. _flask: http://flask.pocoo.org
