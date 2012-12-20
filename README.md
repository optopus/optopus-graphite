## Optopus Graphite Plugin
This plugin utilizes the plugin partials feature of Optopus in order to display graphs on a node page. The included graphs are for systems using collectd -> graphite. It is easy to override how graphs look by changing a few configuration settings. All graphs utilize the DSL provided by the [graphite_graph](https://github.com/ripienaar/graphite-graph-dsl) gem.


### Configuration
To get started, you will likely want to change a few configuration pieces. Below is the full set of configuration options with their defaults:

    ..rest of your optopus config..
    plugins:
        graphite:
            # Change this to your graphite url, example: http://graphite.foo.bar
            base_url: graphite

            # Directory in which your custom graph definitions exist
            graphs_dir: graphs

            # Graph template names, relative to graphs_dir
            graphs:
                interface: interface.graph
                memory: memory.graph
                cpu: cpu.graph
                disk: disk.graph

            # When converting a FQDN in collectd to a graphite value,
            # you usually wind up replacing '.' with a character, set this to
            # the character that you have chosen. 
            hostname_dot_substitution: _
