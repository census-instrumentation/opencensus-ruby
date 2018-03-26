# Hello World example

This example application demonstrates how to use OpenCensus to record traces for a Sinatra-based web application.

## Prerequisites

Ruby 2.2 or later is required. Make sure you have Bundler installed as well.

    gem install bundler

## Installation

Get the example from the OpenCensus Ruby repository on Github, and cd into the example application directory.

    git clone https://github.com/census-instrumentation/opencensus-ruby.git
    cd opencensus-ruby/examples/hello-world

Install the dependencies using Bundler.

    bundle install

## Running the example

Run the application locally on your workstation with:

    bundle exec ruby hello.rb

This will run on port 4567 by default, and display application logs on the terminal. From a separate shell, you can send requests using a tool such as curl:

    curl http://localhost:4567/
    curl http://localhost:4567/lengthy

The running application will log the captured traces.
