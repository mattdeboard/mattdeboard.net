tags: [django, python, haystack, whoosh]
public: yes
summary: Haystack/Whoosh auto-update script for Django

======================================
Haystack index update script + cronjob
======================================

`Yukmarks <http://yukmarks.com>`_ doesn't really have any users except for me and my girlfriend, so updating the search index manually has never been very difficult. Just punch up my `fabfile <http://mattdeboard.net/2011/05/06/if-you-dont-use-fabric-do/>`_ and run update_search(). Trivial. 

However, I am seriously, profoundly lazy, so all those keystrokes were getting annoying. Plus, manually updating search is just stupid & inefficient. I could use the same amount -- or less -- of keystrokes to just Ctrl-F on my Yukmarks `profile page <http://yukmarks.com/u:matt>`_. So I wrote a script to automatically update my `Haystack <http://haystacksearch.org/>`_ search. A cron job runs it every 15 minutes.

--------
The code
--------

.. sourcecode:: python

  import subprocess
  import sys
  import logging
 
  domain_dir = "/a/mattdeboard.net/"
  appdir = domain_dir + "src/yukproj/"
  whoosh_dir = appdir + "yuk/whoosh/"
 
  def update():
      logging.basicConfig(filename='/a/mattdeboard.net/src/index.log', 
                          level=logging.INFO,
                          format='%(asctime)s %(levelname)s:%(message)s', 
                          datefmt='%m/%d/%Y %H:%M:%S')
      logging.info('Starting index update.')
      update_index = subprocess.Popen(['sudo', '-u', 'www-data', 
                                     domain_dir+'bin/python',
                                     appdir+'manage.py', 'update_index'],
                                    stdout=subprocess.PIPE, 
                                    stderr=subprocess.STDOUT)
      update_index.wait()
      apachereload = subprocess.Popen(['sudo', 
                                       '/etc/init.d/apache2', 
                                       'force-reload'],
                                      stdout=subprocess.PIPE, 
                                      stderr=subprocess.STDOUT)
      apachereload.wait()
      if not any((update_index.returncode, apachereload.returncode)):
          logging.info('Index successfully updated.')
      else:
          subs = [update_index, apachereload]
          logging.error('**INDEX UPDATE FAILED**')
          logging.error('The following exit codes were returned:')
          logging.error('- update_index: %s' % update_index.returncode)
          logging.error('- apachereload: %s' % apachereload.returncode)
          for sub in subs:
              if sub.returncode:
                  logging.error('Error information:')
                  logging.error('stdout: %s' % sub.communicate()[0])
                  logging.error('stderr: %s' % sub.communicate()[1])
  
  if __name__ == '__main__':
      update()

The (root) cron job:

.. sourcecode:: bash

  0,15,30,45 * * * * /a/mattdeboard.net/bin/python /a/mattdeboard.net/src/yukproj/ \\
  srchupdate.py -c|mail -s "Search Update Complete" matt

(I have it all on one line in crontab, but broken up into two here for ease of reading.)

-------
What do
-------

So basically every 15 minutes, the server runs `srchupdate.py <https://github.com/mattdeboard/Yuk/srchupdate.py>`_, and logs the results to a log file outside the project directory. If the update fails, it logs the exit status values, stderr and stdout data (using the communicate() method and returnvalue attribute of Python's excellent ``subprocess.Popen``). This captures traceback info and has made debugging much easier.

One obvious problem here is update() runs every 15 minutes, whether it needs to or not. I'll probably add a quick function to get the diff between current index size and size at last update, and only run update() if there's a change. However, it's taken me a couple of days to learn enough to flesh this script out, and I'm tired of putting off `learnin' me some Haskell <http://learnyouahaskell.com>`_. So that optimization will have to wait.

Another problem is `Whoosh <https://bitbucket.org/mchaput/whoosh/wiki/Home>`_, which powers my Haystack install. Whoosh is pure Python, and very easy to install. However, it is *extremely* slow. I'd probably even say ponderous. For ~350 bookmark entries on Yuk, it takes about 10 seconds to update. From what I understand, Solr is much faster, but has a much steeper learning curve. For Yukmarks, I think Whoosh is fine, but I doubt going forward I'd use it for any serious projects where speed is important. 

If you got here after Googling for a Haystack auto-update solution, I hope this helps.
