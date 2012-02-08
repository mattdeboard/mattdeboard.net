public: yes
tags: [django,haystack,tastypie,python,REST,API]
summary: A drop-in Haystack resource class for django-tastypie APIs.

===========================
REST API for search results
===========================

**Updated:** *So after talking with the author of Tastypie I added the* `SearchDeclarativeMetaclass` *and* `SearchOptions` *to handle inheritance of the metaclass attributes on* `SearchResource`. *I almost entirely copied his* `ModelDeclarativeMetaclass` *and it works well. In-house, we further subclass* `SearchResource` *to model our job postings data in our search index, and it works great.*

So, first things first: `django-tastypie <https://github.com/toastdriven/django-tastypie>`_ is pretty great. If you're running a Django web application and want to expose your data via a REST API, tastypie will do it. I got everything up-and-running in just a few hours (95% reading, 5% writing).

Tastypie -- written by `Daniel Lindsley <https://twitter.com/#!/daniellindsley>`_, the guy behind `django-haystack <http://haystacksearch.org>`_ -- uses a `Resource` class to handle all the API hairiness; it comes with a `ModelResource` subclass out of the box to provide an interface to a Django model & the ORM. If you want a better explanation, or want to know more, go `read the docs <http://django-tastypie.readthedocs.org/en/latest/index.html>`_.

Speaking of the documentation, there is an example `Resource` subclass in the docs' `cookbook <http://readthedocs.org/docs/django-tastypie/en/latest/cookbook.html#adding-search-functionality>`_, though that was more about adding search to an existing resource. We want to serve resources -- i.e. Solr documents -- exclusively from Lucene. Our resource is literally a document from the search engine, so we needed a class to model that behavior. (You can read more about how we use Solr `here <http://mattdeboard.net/2011/12/29/displacing-mysql-with-solr/>`_.) To accomplish this, I put together this `SearchResource` subclass which others may find useful.

.. sourcecode:: python

  import operator
  
  from haystack.query import SearchQuerySet, SQ
  
  from tastypie.bundle import Bundle
  from tastypie.resources import Resource

  
  class SearchOptions(ResourceOptions):
      # One of the great strengths of Haystack is its extensibility. We have
      # subclassed many of Haystack's internal classes, including a subclass
      # of SearchQuerySet. I did not want to be locked in to using Haystack's
      # built-in SearchQuerySet nor its SQ object in this module, so I put in
      # the ``query_object`` attribute on the metaclass.
      resource_name = 'search'
      object_class = SearchQuerySet
      query_object = SQ
      index_fields = []
      # Override document_uid_field with whatever field in your index
      # you use to uniquely identify a single document. This value will be
      # used wherever the ModelResource references the ``pk`` kwarg.
      document_uid_field = 'id'
      lookup_sep = ','
    

  class SearchDeclarativeMetaclass(DeclarativeMetaclass):
      def __new__(cls, name, bases, attrs):
          meta = attrs.get('Meta')
          new_class = super(SearchDeclarativeMetaclass, cls)\
              .__new__(cls, name, bases, attrs)
          include_fields = getattr(new_class._meta, 'fields', [])
          excludes = getattr(new_class._meta, 'excludes', [])
          field_names = new_class.base_fields.keys()
          
          for field_name in field_names:
              if field_name == 'resource_uri':
                  continue
              if field_name in new_class.declared_fields:
                  continue
              if len(include_fields) and not field_name in include_fields:
                  del(new_class.base_fields[field_name])
              if len(excludes) and field_name in excludes:
                  del(new_class.base_fields[field_name])
  
          if getattr(new_class._meta, 'include_absolute_url', True):
              if not 'absolute_url' in new_class.base_fields:
                  new_class.base_fields['absolute_url'] = fields.CharField(
                      attribute='get_absolute_url', readonly=True)
          elif 'absolute_url' in new_class.base_fields and not 'absolute_url' in attrs:
              del(new_class.base_fields['absolute_url'])
  
          return new_class


  class SearchResource(Resource):
      """
      Blueprint for implementing an HTTP API to access documents in a
      search engine via Haystack. The design of the class adds some
      additional configuration overhead (i.e. a handful of metaclass
      fields) in exchange for flexibility & portability.
  
      To implement this class in your own application, you will need to:
      1. Define which fields to return in your results;
      2. Override index_fields in the metaclass to limit or expand which
         fields consumers can access from your index via the API;
      3. Override document_uid_field in the metaclass to specify which
         field in the index is used to uniquely identify individual
         documents;
      4. Additionally, you will override query_object and object_class to
         utilize any subclasses you may be using in your project.
  
      """
      __metaclass__ = SearchDeclarativeMetaclass
      
      def apply_filters(self, request, applicable_filters):
          objects = self.get_object_list(request)
  
          if applicable_filters:
              return objects.filter(applicable_filters)
          else:
              return objects
  
      def build_filters(self, filters=None):
          """
          Create a single SQ filter from querystring parameters that
          correspond to SearchIndex fields that have been "registered" in
          the ``self._meta.index_fields``.
  
          Default behavior is to ``OR`` terms for the same parameter, and
          ``AND`` between parameters. For example:
  
          ``?format=json&state_exact=Indiana,Illinois&company_exact=IBM``
  
          would yield an SQ expressing the following logic:
  
          ``q=state_exact:(Indiana OR Illinois) AND company_exact:IBM``
  
          Any querystring parameters that are not registered in
          self._meta.index_fields and are not consumed elsewhere in the
          response operation will be ignored.
  
          """
          terms = []
  
          if filters is None:
              filters = {}
  
          for param, value in filters.items():
              
              if param not in self._meta.index_fields:
                  continue
                  
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
          
      def get_resource_uri(self, bundle_or_obj):
          """
          Generate direct link to individual document in our datastore.
  
          """
          kwargs = {
              'resource_name': self._meta.resource_name
          }
          uid = self._meta.document_uid_field
          
          if isinstance(bundle_or_obj, Bundle):
              kwargs['pk'] = getattr(bundle_or_obj.obj, uid, '')
          else:
              kwargs['pk'] = getattr(bundle_or_obj, uid, '')
  
          if self._meta.api_name is not None:
              kwargs['api_name'] = self._meta.api_name
  
          return self._build_reverse_url("api_dispatch_detail", kwargs=kwargs)
              
      def get_object_list(self, request):
          """
          A Haystack-specific implementation of ``get_object_list``.
  
          Returns a SearchQuerySet that may have been limited by other
          filter/narrow/etc. operations.
          
          """
          return self._meta.object_class()._clone()
  
      def obj_get_list(self, request=None, **kwargs):
          filters = {}
  
          if hasattr(request, 'GET'):
              filters = request.GET.copy()
  
          filters.update(kwargs)
          applicable_filters = self.build_filters(filters=filters)
          return self.apply_filters(request, applicable_filters)
  
      def obj_get(self, request=None, **kwargs):
          """
          Fetch a single document from the datastore according to whatever
          unique identifier is available for that document in the
          SearchIndex.
  
          """
          # Don't let the use of 'pk' here and throughout confuse you.
          # Think of it as a metaphor standing for "whatever field there
          # is in your SearchIndex that uniquely identifies a single
          # document."
          doc_uid = kwargs.get('pk')
          uid_field = self._meta.document_uid_field
          sqs = self.get_object_list(request)
          
          if doc_uid:
              sqs = sqs.filter(self._meta.query_object((uid_field, doc_uid)))
  
              if sqs:
                  return sqs[0]
              else:
                  return sqs

If you use Haystack, you know that it goes to great lengths to emulate the API of Django's ORM to provide a familiar interface to the search index. In that vein, `SearchResource` emulates the `ModelResource` class. 

I made the decision to force some additional configuration overhead -- about 5 attributes on the metaclass -- in order to completely preserve the amazing extensibility of Haystack. I know that `in-house <http://directemployersfoundation.org>`_ we subclass just about everything from Haystack, including the `SearchQuerySet`; I assume there are others out there doing the same, and more, so you are not forced to use Haystack's built-in `SQ` object to compose query trees if you've created your own. (If you have I'd be curious to see it.)

Let me know in the comments if you have any problems, spot bugs or think I'm an idiot.




          

