public: yes
tags: [solr, nosql, django, python, haystack]

=============================
Displacing MySQL with...Solr?
=============================


We recently completed a big refactor at `work <http://directemployers.org>`_, the intent for which was implementing search for one of our products, a Django-based web CMS called DirectSEO. It did not take long, however, to realize that by choosing Solr as our search backend, we had the opportunity to make some much-needed optimizations. Now, after analyzing three weeks' worth of data related to the refactor, I can say the time investment has yielded real, measurable gains. They came mainly from removing some very expensive database calls from our views, then fetching the same data via calls to the `Solr <http://lucene.apache.org/solr/>`_ index. This resulted in a simplified code base and decreased page-load times. This post is intended to explain a bit about our approach to leveraging Solr's feature set.

(This is my first truly technical post so I'm sure I'm leaving things out, or explaining poorly. Please contact me or leave comments if I didn't cover something in enough detail or if you've got any questions.)


Some Background
===============


As part of their membership in DirectEmployers, member organizations are provided with a job board on a domain of their choosing to present their job listings in an SEO-friendly way. These sites often live on the `.jobs TLD <http://en.wikipedia.org/wiki/.jobs>`_; however, members can -- and often do -- use subdomains of their own site for their job board. An example of each: `Lockheed-Martin <http://lockheedmartin.jobs>`_ (.jobs); `Arrow Electronics <http://jobsearch.arrow.com>`_ (other).


How It Works
------------


The job boards are generated dynamically. Members give us some basic information -- header images, brand colors, and so forth -- which we use to create a site configuration. This configuration is then referenced to lookup all the jobs associated with a particular member organization. Sometimes, a member organization may have multiple job sites catering to specific job categories: `IBM Brazil <http://ibm-brazil.jobs>`_ or `Lockheed-Martin InfoSec <http://lockheedmartin-infosec.jobs>`_, for example. In these cases, the corpus of jobs for that member organization are then refined to only include jobs which fall into that category.

From here, users can drill down into the jobs using standard navigation links which we generated based on facets for title, location and custom facets we call `Saved Search <https://github.com/DirectEmployers/saved-search>`_ (not to be confused with `saved-searches <https://github.com/toastdriven/saved_searches>`_).


Implementation Details
======================


Simply put, we use Django to deal with MySQL, and we use `Django-Haystack <http://haystacksearch.org>`_ to deal with Solr. We run our `own fork <https://github.com/DirectEmployers/django-haystack>`_ of Haystack, which capitalizes on some hacks in my own `fork of pysolr <https://github.com/mattdeboard/pysolr>`_.

Our saved-search app gives our members a way to create and maintain persistent, user-defined queries. In practice we use these to create sites like the aforementioned `Lockheed-Martin InfoSec <http://lockheedmartin-infosec.jobs>`_. They also give our members the ability to create custom job verticals. `Hilton <http://hiltonworldwide.jobs>`_ has saved searches built around departments; `Unilever <http://unilevercareers.jobs>`_ has a saved search for "hot jobs" they want to fill quickly.


Architectural Aside
-------------------


A problem arises, however, when a site has a lot of saved searches. But to understand the problem, I should explain a little bit about how our data is stored in the database and how it gets indexed.

Each job listing is a row on our `joblisting` table. This is currently the only table Solr indexes. Haystack uses a module called `search_indexes.py <http://p.mattdeboard.net/search_indexes.py.html>`_ to set the parameters in `schema.xml`. In it, we specify model fields to index directly, plus several fields Haystack calls "prepared fields," which contain denormalized or calculated data. Native model fields like `title`, `state`, `country`, etc., can be used to create `facets <http://www.lucidimagination.com/devzone/technical-articles/faceted-search-solr>`_. Facets are what you see under "Filter by (Title|City|State|Country)" `here <http://arinc.jobs/>`_. Something like the below snippet will return all the values for those fields along with counts of each (which is what faceting is):

.. sourcecode:: python

 sqs = SearchQuerySet().facet('title_slab').facet('city_slab')\
                       .facet('state_slab').facet('country_slab')
 facet_counts = sqs.facet_counts()['fields']

("slabs" are calculated fields such that the `city_slab` field would have a format like::

  "/manassas/virginia/usa/jobs/::Manassas, VA"

We use these to precalculate URL segments in the index so we can keep string manipulation to a minimum in the application. We split on "::" and handle those substrings as needed.)

However, since saved searches are ad-hoc filters that can be composed of any permutation of index fields, they cannot be properly faceted. This means that to get counts of job listings for each saved search, we'd normally have to perform a single HTTP request for each. 

To circumvent this costly routine, I hacked up pysolr to implement support for Solr's `field collapsing/group query functionality <http://wiki.apache.org/solr/FieldCollapsing>`_, then wrote `a backend <https://github.com/DirectEmployers/saved-search/blob/master/saved_search/groupsearch.py>`_ to support it. The effect is that for *n* saved searches configured for a particular site, only one query is required; the saved search concept would otherwise involve far too many HTTP requests to be practical.


Haystack & Solr Setup
---------------------

On the Python side, we use Haystack's `RealTimeSearchIndex <http://docs.haystacksearch.org/dev/searchindex_api.html#realtimesearchindex>`_ class as the basis for our index. In short, it's the exact same as the SearchIndex class, but with post-save/delete listeners for the jobListing table. It gets us as close as we really need to get to ElasticSearch-style real-time search. While Solr 4.0 is going to have "near real-time" search, it's just not a feature we have a need for now. If that changes in the future, we'll re-evaluate.

For Solr, we run two servers in a master-slave configuration. The master handles the real-time updates. The (read-only) slave handles all the queries, and is set to do replication checks every 60 seconds. The side effect of this is that when the master is handling a large volume of updates, average query response time by the slave slows by 50-75ms. For comparison, it normally takes around 200ms for our application to calculate and return an HTTP response.

The one caveat for using Solr in this way is that unlike some other document databases, there is absolutely no notion of relations whatsoever. Plus, obviously, it wouldn't be responsible to use Solr as a primary datastore (A good read on why can be found in `this <http://stackoverflow.com/questions/4960952/when-to-consider-solr/4961973#4961973>`_ response on SO). 


Performance & Reliability
=========================

Performance has improved measurably, especially on `pages with a lot of jobs, a lot of facets and a lot of saved searches <http://lockheedmartin.jobs>`_. Some very costly SQL queries have been eliminated. By utilizing Solr's query-tuning tools like `facet.mincount`, `start` and `offset`, we've kept the amount of data transfered per request is low. Using Solr to power saved searches eliminates a lot of complexity from our code base.

Getting data reliability right has taken longer, involving some diligent bug-hunting. I've spent the past four months learning about how Solr works, how to intelligently leverage Haystack's API, and implementing some features of Solr in Haystack that aren't included out-of-the-box. It is important to keep in mind that a Solr match is not necessarily binary. A thing might match, it might not, but more likely it will "kinda" match. Tightening up queries as needed is vital if you want exact results *only*. One of my big hurdles in getting this working right was making sure matches were fuzzy where they should be fuzzy, and exact where they should be exact.

Finally, I think that as we add more features to our application, we'll have to start putting standard RDBMS queries back into play in some areas. For the past 3 months I've been rewiring a Django application, cutting out the old relational stuff and replacing it with simpler, faster methods. It is a dramatic shift. As time goes on we'll be building out more features that will require relational information.


Conclusion
==========


Utilizing Solr in this way is both ordinary and novel. It's novel because when people think of Solr, they think a search box with a button that says "Search". You click on the button and get results. It's ordinary because Solr is, after all, a document database. It stores documents in a flat structure, and you compose queries to retrieve them. Not exotic, unusual or special in any way. In a use case such as ours, however, where the need for relations is minimal and practically all of our content is generated based on text searching, Solr is great.

