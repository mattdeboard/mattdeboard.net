public: yes
tags: [supervisor,mono,mono-service,clr,dotnet]
summary: mono-service + supervisor

==============================================
How to Run a Windows Service As A Linux Daemon
==============================================

**Premise:** You've got a Windows service that you want to run on a Linux server

**Problem:** Your code is written using the .NET framework and some language that targets the CLR (C#, VB, Clojure-CLR, etc.)

**Solution:** `Mono <http://www.mono-project.com/Main_Page>`_ is an open-source implementation of the .NET framework. By installing mono you gain access to a ton of useful stuff, but the relevant item here is the `mono-service` executable. (Installing mono is out of the scope of this blog post, but odds are pretty good mono is available from your distro's package management system.)

Once installed, you can run your compiled code like so::

  mono-service SomeExecutable.exe

By default, this creates a lockfile in `/tmp`. You can change this by using the `-l:<lockfile>` option. This is great, because now your service is running in the background! However, this is really flimsy; what if the process dies? What if the server needs rebooted? To solve this I'm using `supervisor <http://supervisord.org/>`_.

Get It Running In 4 Steps
=========================

Once you've got supervisor and mono installed, follow these steps:

1. Create a supervisor file in `/etc/supervisor/conf.d/` with a descriptive name. We'll use `mysvc.conf`. 
2. Edit `mysvc.conf` so it looks similar to this\ :sup:`1,2`\ ::

     [program:mysvc]
     command=mono-service MyWindowsService.exe --no-daemon
     directory=/path/to/executable
     user=someuser
     stdout_logfile=/home/someuser/mysvc/out.log
     redirect_stderr=true

3. `sudo service supervisor stop`. Wait a beat\ :sup:`3`\ , then run `sudo service supervisor start`.
4. To confirm that your process started, run `ps aux|grep mono`. You should see it in the process list.

Conclusion
==========

Hope this helps. Supervisor has a ton of different options for configuring how a process runs, it's worth it to RTFM. 


Footnotes
---------

**1.** The directory specified in your `stdout_logfile` parameter must already exist. If you try to start the `mysvc` process without creating it, supervisor will throw an error. Also, the `user` parameter should be set to a user that has permissions to write to the directory where you're keeping the `stdout_logfile`. Please consult the relevant `supervisor docs <http://supervisord.org/configuration.html#program-x-section-values>`_ for more about users & processes.

**2**. You must use the `--no-daemon` flag to avoid creation of the lockfile which indirectly allows supervisor to capture/redirect stdout/stderr to a logfile.

**3.** If you run e.g. `sudo service supervisor stop && sudo service supervisor start` supervisor will throw an exception. Waiting about as long as it takes to type out the second half of that command is usually enough. Alternatively, you can try `sudo service supervisor restart` but in my experience that does not cause changes to or creation of conf files to be processed.
