public: yes
tags: [django,haystack,tastypie,python,REST,API]
summary: A drop-in Haystack resource class for django-tastypie APIs.

===========================
REST API for search results
===========================

**Updated:** *So after talking with the author of Tastypie I added the* `SearchDeclarativeMetaclass` *and* `SearchOptions` *to handle inheritance of the metaclass attributes on* `SearchResource`. *I almost entirely copied his* `ModelDeclarativeMetaclass` *and it works well. In-house, we further subclass* `SearchResource` *to model our job postings data in our search index, and it works great.*

So, first things first: `django-tastypie <https://github.com/toastdriven/django-tastypie>`_ is pretty great. If you're running a Django web application and want to expose your data via a REST API, tastypie will do it. I got everything up-and-running in just a few hours (95% reading, 5% writing).

Tastypie -- written by `Daniel Lindsley <https://twitter.com/#!/daniellindsley>`_, the guy behind `django-haystack <http://haystacksearch.org>`_ -- uses a `Resource` class to handle all the API hairiness; it comes with a `ModelResource` subclass out of the box to provide an interface to a Django model & the ORM. If you want a better explanation, or want to know more, go `read the docs <http://django-tastypie.readthedocs.org/en/latest/index.html>`_.

Speaking of the documentation, there is an example `Resource` subclass in the docs' `cookbook <http://readthedocs.org/docs/django-tastypie/en/latest/cookbook.html#adding-search-functionality>`_, though that was more about adding search to an existing resource. We want to serve resources -- i.e. Solr documents -- exclusively from Lucene. Our resource is literally a document from the search engine, so we needed a class to model that behavior. (You can read more about how we use Solr `here <http://mattdeboard.net/2011/12/29/displacing-mysql-with-solr/>`_.) To accomplish this, I put together `this <https://github.com/mattdeboard/mattdeboard.net/blob/master/2012/02/07/resources.py>`_ `SearchResource` subclass which others may find useful. 

If you use Haystack, you know that it goes to great lengths to emulate the API of Django's ORM to provide a familiar interface to the search index. In that vein, `SearchResource` emulates the `ModelResource` class.

One issue we have in-house is that there are in some cases discrepancies between the semantics we want to expose as part of our API and the fields we're going to be leveraging to look up resources. To address that, I created a map of querystring parameters to the actual fields in the search index in which their values would be sought:

.. sourcecode:: python

 class JobSearchResource(SearchResource):
     field_aliases = {
         'city': 'city_exact__exact',
         'state': 'state_exact__exact',
         'country': 'country_exact__exact',
         'company': 'company_exact__exact',
         'title': None,
         'date_new': None,
         'uid': None
     }
 
     <snip declared fields>
 
     def __init__(self, **kwargs):
         super(JobSearchResource, self).__init__(**kwargs)
         self._meta.index_fields = self.field_aliases.keys()

We use `field_aliases.keys()` to populate `index_fields`, so now we need to add in logic to look up those keys and replace them in the query logic with the fields we actually want to search against. In this case, we want to search against `(country|state|city|company)_exact`, which, if you're familiar with Lucene, are stored, unanalyzed fields. We use Haystack's `__exact` lookup which has the effect of turning the term query into a phrase by wrapping it in quotes, e.g. `q=country_exact:"United States"`. We don't want tokenized field lookup because we don't want to match, say, "United Kingdom" when we are looking for "United States" due to the match on "United." (There are a million ways to do this of course, but this is how we chose to do it.)

Now we need to override `SearchResource.build_filters`:

.. sourcecode:: python
 
     def build_filters(self, filters=None):
         terms = []
 
         if filters is None:
             filters = {}
 
         for param_alias, value in filters.items():
             
             if param_alias not in self._meta.index_fields:
                 continue
 
             param = self.field_aliases.get(param_alias, param_alias) # <---
             tokens = value.split(self._meta.lookup_sep)
             field_queries = []
             
             for token in tokens:
                 
                 if token:
                     field_queries.append(self._meta.query_object((param,
                                                                   token)))
 
             terms.append(reduce(operator.or_,
                                 filter(lambda x: x, field_queries)))
 
         if terms:
             return reduce(operator.and_, filter(lambda x: x, terms))
         else:
             return terms

Note the line with the commented `<---`: This is where the alias->index field translation takes place. If you find yourself with a need to alias search fields this may be a solution for you.

Finally, I made the decision to force some additional configuration overhead -- about 5 attributes on the metaclass -- in order to completely preserve the amazing extensibility of Haystack. I know that `in-house <http://directemployersfoundation.org>`_ we subclass just about everything from Haystack, including the `SearchQuerySet`; I assume there are others out there doing the same, and more, so you are not forced to use Haystack's built-in `SQ` object to compose query trees if you've created your own. (If you have I'd be curious to see it.)

Let me know in the comments if you have any problems, spot bugs or think I'm an idiot.




          

