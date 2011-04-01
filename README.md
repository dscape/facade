# facade
`facade` is a [rewrite][9] sample application. It exposes [MarkLogic Server][2] by implementing a small subset of the [CouchDB][7] [HTTP API][8]. The objective of `facade` is to demonstrate how to use [rewrite][9] to create a JSON backed web-service. Simple decisions were made in implementing the service and it should not be regarded as an real MVC implementation.

In the future `facade` could be used as a compatibility layer between [MarkLogic Server][2] and [CouchDB][7], leveraging drivers and replication amongst each other. At this point that is not the objective of the project.

`facade` includes [futon][6] which is part of [CouchDB][7]. A [small fix][10] to support multiple versions of attachments.

## Usage

Create a MarkLogic HTTP AppServer and configuration make `rewrite.xqy` the default rewriter script.

You can now visit create databases and documents using [futon][6] by accessing `/_utis/`  (e.g. localhost:8953/_utils/)

*This section doesn't cover how to set up an HTTP Application Server in MarkLogic. If you are a beginner I suggest you start by browsing the [MarkLogic Developer Community site][4] or sign up for [training][5].*

## Contribute

Think the documentation sucks? Think the performance is crap? Think `facade` is cool but is missing feature X? Then contribute to the project.

1. Message `dscape` on github talking about what you want to accomplish.
2. Fork facade in github
3. Create a new branch - `git checkout -b my-branch`
4. Develop/fix the functionality
5. Test your changes
6. Commit your changes
7. Push to your branch - `git push origin my-branch`
8. Create an pull request

### Running the tests

To run the tests simply access `/_test/`:
(assuming 127.0.0.1 is the host and 8090 is the port)

    http://127.0.0.1:8090/test/

**Make sure all the tests pass before sending in a pull request!**

### Report a bug

If you want to contribute with a test case please file a [issue][1].

## Meta

* Code: `git clone git://github.com/dscape/facade.git`
* Home: <http://github.com/dscape/facade>
* Discussion: <http://convore.com/marklogic>
* Bugs: <http://github.com/dscape/facade/issues>

(oO)--',- in [caos][3]

[1]: http://github.com/dscape/facade/issues
[2]: http://marklogic.com
[3]: http://caos.di.uminho.pt
[4]: http://developer.marklogic.com
[5]: http://www.marklogic.com/services/training.html
[6]: https://github.com/apache/couchdb/tree/trunk/share/www
[7]: http://couchdb.apache.org/
[8]: http://wiki.apache.org/couchdb/HTTP_Document_API
[9]: http://github.com/dscape/rewrite
[10]: https://gist.github.com/baa888d42be7d8e264b2
