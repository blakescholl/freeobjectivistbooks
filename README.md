# Free Objectivist Books

This is the code for http://freeobjectivistbooks.org.

The purpose of this site is to match up students who want to read Objectivist books with donors who are willing to send them. The goal is to get more students reading Ayn Rand.

Free Objectivist Books is a community project. It lives at: https://github.com/jasoncrawford/freeobjectivistbooks

This README is a guide for developers who want to help out.

## How to help

1. Read this README
2. Fork the repo
3. Browse [issues](https://github.com/jasoncrawford/freeobjectivistbooks/issues) and [milestones](https://github.com/jasoncrawford/freeobjectivistbooks/issues/milestones); find an issue to tackle, or add one of your own
4. Assign the issue to yourself
5. Code it up, including tests
6. Send me a pull request
7. I'll review it, pull it, and deploy
8. Go to step 3

## Developer setup

Here's how to get yourself set up to develop the app:

1. Make sure you have Ruby 1.9.2 installed (on a Mac, you may have 1.8 by default). Check with `ruby -v`. If you need to install or upgrade Ruby, I recommend RVM: https://rvm.io/
2. Make sure you have Bundler installed: Try `bundle -v` and do `gem install bundler` if needed.
3. Fork the repo at https://github.com/jasoncrawford/freeobjectivistbooks, then clone it with `git clone`.
4. Once you have the repo locally, you should be able to run `bundle` in the project directory, and it will install all the dependencies (including Rails 3.1.3 if you don't already have it).
5. Install Foreman if needed: `gem install foreman`. Then you can run the app using `foreman start`. That runs both the server and a delayed_jobs worker thread. (This will run the app at **port 5000, not 3000** as is the default when you run `rails server`.) Go to http://localhost:5000 to see the app.
6. To make sure everything is working, run `rake test` to run all the tests.

Let me know if you have any trouble at all getting set up; I'm happy to help, and I'll update these instructions for the next developer, as well.

## In case you don't know Ruby or Rails

A good quick-start intro to Ruby is [Ruby in Twenty Minutes](http://www.ruby-lang.org/en/documentation/quickstart/).

For Rails, I recommend the official guide, [Getting Started with Rails](http://guides.rubyonrails.org/v3.1.3/getting_started.html).

From each of those sites you can find more tutorials and other documentation, including books.

## Developer guidelines

* Use GitHub to manage workflow: issues, pull requests, etc.
* Follow Ruby & Rails conventions.
* Develop for Ruby 1.9.2 (it's what we use in production on Heroku).
* Write [fat models and skinny controllers](http://weblog.jamisbuck.org/2006/10/18/skinny-controller-fat-model).
* Write tests for everything. We should be able to deploy with confidence without manual regression testing. Run the tests (with `rake test`) and make sure they're all green before submitting a pull request.
* Write brief class-level and (where appropriate) method-level comments suitable for RDoc.
* Create custom Rake tasks for any management commands, including any scheduled tasks.
* Use delayed jobs for any long-running task that can be done in the background.
* [Long-running scheduled tasks should also be put in the delayed job queue.](https://devcenter.heroku.com/articles/scheduler#longrunning-jobs)

## A few practical tips

* Documentation is available (via RDoc); find it in doc/app/index.html and regenerate it with `rake doc:app`.
* We use Delayed::Jobs for long-running tasks. Worth reading up on if you're touching notifications/reminders.
* We're using the 960 Grid System: http://960.gs/. You may want to familiarize yourself with it if you're touching views.
* Do your best work, and have fun!
