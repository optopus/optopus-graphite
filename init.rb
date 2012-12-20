require 'graphite_graph'
module Optopus
  module Plugin
    module Graphite
      extend Optopus::Plugin

      plugin do
        register_partial :node, :graphite_graphs, :display => 'Graphs'
      end

      helpers do
        def graphite_settings
          settings.plugins['graphite']
        end

        # Return a list of graphite URLs
        def graphite_endpoint
          graphite_settings['base_url']
        end

        # Replace any dots in a nodes hostname with the specified character
        def graphite_hostname(hostname)
          hostname.gsub('.', graphite_settings['hostname_dot_substitution'])
        end

        def graphite_graph_dir
          graphite_settings['graphs_dir']
        end

        def graphite_graph_settings
          { :width => 800, :height => 200, :area => :all, :area_alpha => 0.7 }
        end

        def graph_file(type)
          File.join(graphite_settings['graphs_dir'], graphite_settings['graphs'][type])
        end

        def graph_excludes(type, str)
          return false unless graphite_settings['graph_excludes']
          return false unless regex = graphite_settings['graph_excludes'][type]
          # In case user supplied '/regex/' rather than just 'regex'
          regex.gsub!(/(^\/|\/$)/, '')
          str.match(Regexp.new(regex))
        end

        def graphite_graphs
          return @graphite_graphs if @graphite_graphs
          graphs = {
            :cpu        => [],
            :disk       => [],
            :interfaces => [],
            :memory     => [],
          }
          graphs[:memory] << GraphiteGraph.new(graph_file('memory'),
                                      graphite_graph_settings.merge({:area => :stacked }),
                                      { :hostname => graphite_hostname(@node.hostname) })
          graphs[:cpu] << GraphiteGraph.new(graph_file('cpu'),
                                      graphite_graph_settings.merge({:area => :stacked }),
                                      { :hostname => graphite_hostname(@node.hostname) })
          if @node.facts.include?('mounts')
            @node.facts['mounts'].split(',').sort.each do |mount|
              if mount == '/'
                mount = 'root'
              else
                mount = mount.gsub('/', '-').gsub(/^-/,'')
              end
              next if graph_excludes('disk', mount)
              locals = { :hostname => graphite_hostname(@node.hostname), :mount => mount }
              graphs[:disk] << GraphiteGraph.new(graph_file('disk'), graphite_graph_settings, locals)
            end
          end
          if @node.facts.include?('interfaces')
            @node.facts['interfaces'].split(',').sort.each do |interface|
              # Facter stores interfaces with . replaced with _, while collectd
              # does not replace the . in interface names.
              interface.gsub!('_', '.')
              next if graph_excludes('interface', interface)
              locals = { :hostname => graphite_hostname(@node.hostname), :interface => interface }
              graphs[:interfaces] << GraphiteGraph.new(graph_file('interface'), graphite_graph_settings, locals)
            end
          end
          @graphite_graphs = graphs
        end
      end

      def self.registered(app)
        default_settings = {
          'base_url' => 'graphite',
          'graphs' => {
            'interface' => 'interface.graph',
            'memory'    => 'memory.graph',
            'cpu'       => 'cpu.graph',
            'disk'      => 'disk.graph',
          },
          'graphs_dir' => File.join(File.dirname(__FILE__), 'graphs'),
          'hostname_dot_substitution' => '_',
        }
        app.settings.plugins['graphite'] = default_settings.merge(app.settings.plugins['graphite'])
        super(app)
      end
    end
  end
end
