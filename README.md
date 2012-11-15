BUILDING THE PROJECT
====================

### Prerequisites

 * Perl
   * Path::Class
   * File::Copy::Recursive
   * Template
 * CoffeeScript
 * Handlebars ( $ npm install handlebars -g )

### Optional Dependencies

 * Plack (to run a local server)
 * HTML::Packer (minify HTML)
 * JavaScript::Packer (minify JavaScript)
 * CSS::Packer (minify CSS)

Generate the project
--------------------

    ./build

Run the built-in server
--------------------

    ./build server

Point your browser to http://localhost:1337/index.html
