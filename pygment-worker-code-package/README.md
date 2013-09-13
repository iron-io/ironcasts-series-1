README
======

This is the code package for the pygments worker from the <a href="https://github.com/iron-io/ironcasts-series-1-samplecode">sample repository</a>. 

You can find the .worker file <a href="https://github.com/iron-io/ironcasts-series-1-samplecode/blob/master/workers/pygments.worker">here</a>.

```ruby
runtime "ruby"

# include postgresql and activerecord
gem "pg"
gem "activerecord"


exec "pygments_worker.rb"

# Merging models
dir '../../app/models/'


full_remote_build true
```

#### Let's breakdown this file line by line:

1. ``` gem "pg" ``` and ``` gem "activerecord" ``` will package up the two gems into the <a href="https://github.com/sidazhang/example-code-packages/tree/master/iron-worker-101-pygment-worker/__gems__">``` __gem__ ``` folder in the root directory of the worker</a>

2. ``` exec "pygments_worker.rb" ``` will package up the ``` pygments_worker.rb ``` ruby file and this execute this file when a worker is run.

3. ``` dir '../../app/models/' ``` means that we will go two directories up from our <a href="https://github.com/sidazhang/iron-worker-101/tree/master/workers/pygments">current directory (location of the .worker file)</a> and then go into the app directory and then package up all the files in the <a href="https://github.com/sidazhang/iron-worker-101/tree/master/app/models">``` models ``` directory</a> and then we will basically save the directory in the root directory of the worker. As you can see <a href="https://github.com/sidazhang/example-code-packages/tree/master/iron-worker-101-pygment-worker/models">here</a>.

4. ``` full_remote_build true ``` means that for gems like ``` pg ``` which <a href="http://patshaughnessy.net/2011/10/31/dont-be-terrified-of-building-native-extensions">requires building native extensions</a>. We will build the native extension on iron.io server.

#### More information
Here is the <a href="http://dev.iron.io/worker/reference/dotworker/#syntax_reference">corresponding documentation</a> on how to construct your .worker file.
