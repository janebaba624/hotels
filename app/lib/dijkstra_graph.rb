class DijkstraGraph
  attr_reader :graph, :nodes, :previous, :distance #getter methods
  INFINITY = 1 << 64

  def initialize
    @graph = {} # the graph // {node => { edge1 => weight, edge2 => weight}, node2 => ...
    @nodes = Array.new
  end

  # connect each node with target and weight
  def connect_graph(source, target, weight)
    if (!graph.has_key?(source))
      graph[source] = {target => weight}
    else
      graph[source][target] = weight
    end
    if (!nodes.include?(source))
      nodes << source
    end
  end

  # connect each node bidirectional
  def add_edge(source, target, weight)
    connect_graph(source, target, weight) #directional graph
    connect_graph(target, source, INFINITY) #non directed graph (inserts the other edge too)
  end


  # based of wikipedia's pseudocode: http://en.wikipedia.org/wiki/Dijkstra's_algorithm
  def dijkstra(source)
    @distance={}
    @previous={}
    nodes.each do |node|#initialization
      @distance[node] = INFINITY #Unknown distance from source to vertex
      @previous[node] = -1 #Previous node in optimal path from source
    end

    @distance[source] = 0 #Distance from source to source

    unvisited_node = nodes.compact #All nodes initially in Q (unvisited nodes)

    while (unvisited_node.size > 0)
      u = nil;

      unvisited_node.each do |min|
        if (not u) or (@distance[min] and @distance[min] < @distance[u])
          u = min
        end
      end

      if (@distance[u] == INFINITY)
        break
      end

      unvisited_node = unvisited_node - [u]

      graph[u].keys.each do |vertex|
        alt = @distance[u] + graph[u][vertex]

        if (alt < @distance[vertex])
          @distance[vertex] = alt
          @previous[vertex] = u  #A shorter path to v has been found
        end

      end

    end

  end


  # To find the full shortest route to a node
  def find_path(dest)
    if @previous[dest] != -1
      find_path @previous[dest]
    end
    @path << dest
  end


  # Gets all shortests paths using dijkstra
  def shortest_paths(source)
    @graph_paths=[]
    @source = source
    dijkstra source
    nodes.each do |dest|
      @path=[]

      find_path dest

      if @distance[dest] != INFINITY
        @graph_paths<< [dest,  @path, @distance[dest]]
      end
    end
    @graph_paths
  end

  # print result
  def print_result
    @graph_paths.each do |graph|
      puts "#{"%3d" % graph[0]}:#{"%3d" % graph[2]}: #{graph[1].join(' -> ')}"
    end
  end
end