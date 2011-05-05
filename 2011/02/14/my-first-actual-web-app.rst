public: yes
tags: [flask, web, python]
summary: My latest projects

============
Latest work
============

I have put my latest project live. I started `Yuk`_ (`source`_) a couple of weeks ago as an exercise in developing an understanding of an MVC web framework, instead of using `flask`_ for everything. flask is great, but not knowing Django (and more importantly, Django's underlying principles) is a huge knowledge gap I wanted to address.

So, Yuk. The least important point first: The name is stupid. Since Yuk is a bookmarking service, I thought it would be cute to play off "delicious" with ... well, you get it. Dumb idea. "Rebranding" isn't really a priority though.

Though the name was a play off "del.icio.us", I have actually written the site using `pinboard.in`_ as a model, at least in terms of features and design. Pinboard is a really fast, dead simple bookmark service with a lot of great features that don't overshadow/obscure the site's core functionality. Having a model to base my work on has been very helpful.

My first task was to set about getting Yuk's own core functionality -- saving user-defined URLs to a database -- working. For the framework I chose Django, and for the database I chose sqlite3, for simplicity. An additional point to this project was to gain familiarity with databases, especially how to design them so that model relations not only work, but make sense. I've still got a long, long way to go on this point. Be that as it may, as I said I chose sqlite3 for simplicity (simplicity being a codeword for what the Django docs recommended for a small project). It is fine for my uses and has been a great hands-on exercise.

One side effect of this project was finally getting a handle on Python classes. Since I'd never undertaken a project that called for them, I'd never really understood what they were for/why they would be used. That is, I could implement a class by regurgitating I'd read -- the 'self' concept, the __init__ function, and so forth -- but I wouldn't actually understand. However, because of some of the details of implementing a bookmarking service, I have had the opportunity to define classes, subclasses, overwrite functions, and so forth within Django's MVC structure. If I learned absolutely nothing else, the time I've spent on this project would have been worth it simply for having a reason to implement classes.

After nailing down storing bookmarks to the database, then came user registration/accounts. I don't have much to say about this since Django core and the `django-registration`_ app make it ridiculously simple. I still need to customize the URL config for the registration/login/logout views, but since it works so well right out of the box, it has been a low priority.

Since then, I've put in a few additional features, such as timestamps, tagging, RSS importing (a chance to reuse `some code`_ I'd written for another self-learning `project`_), editing and deleting. Thanks to that last item, I finally wrote some JavaScript, thanks to the JQuery library. It's not impressive code but it works, and enhances the UI (though in kind of a hacky fashion). 

Yuk isn't done. It's really ugly, and there are some features on my back-of-a-napkin roadmap I'll be implementing this week. That being said I think I can start tightening my code up without it being "premature optimization." 

.. _pinboard.in: http://pinboard.in
.. _Yuk: http://yuk.mattdeboard.net
.. _source: https://github.com/mattdeboard/Yuk
.. _flask: http://flask.pocoo.org
.. _django-registration: http://code.google.com/p/django-registration/
.. _some code: https://github.com/mattdeboard/trunkly-rss
.. _project: http://mattdeboard.net/2010/12/27/Taking-initiative-and-offering-assistance


