# Pointer-based model for graphs with algorithms for traversal, shortest path,
# shortest spanning tree, shortest visit to every city, and shortest loop.

# Works for both directed and undirected & both weighted and unweighted graphs.

# Current implementation optimized for named destinations with distances.

class Graph
  attr_accessor :vertices

  def initialize
    @vertices = []
  end

  def add_vertex(name)
    @vertices << Vertex.new(name)
  end

  def add_edge(start_name, end_name, weight = nil, undirected = true)
    from = vertices.index { |v| v.name == start_name }
    to   = vertices.index { |v| v.name == end_name }
    vertices[from].neighbors[to] = true
    vertices[from].weights[to] = weight if weight
    if undirected
      vertices[to].neighbors[from] = true
      vertices[to].weights[from] = weight if weight
    end
  end

  def find_vertex_by_name(name)
    vertices.each do |v|
      return v if v.name == name
    end
    nil
  end

  def count
    vertices.length
  end

  # traversal #1
  def breadth_first(start_index = rand(count))
    q = Queue.new
    arr  = []
    done = []
    q.enqueue(vertices[start_index])
    done[start_index] = true
    until q.empty?
      pointer = q.dequeue
      arr << pointer.name
      pointer.neighbors.each_with_index do |bool, i|
        if bool && !done[i]
          q.enqueue(vertices[i])
          done[i] = true
        end
      end
    end
    arr
  end

  # traversal #2
  def depth_first(start_index = rand(count))
    stack = Stack.new
    arr = []
    done = []
    stack.push(vertices[start_index])
    done[start_index] = true
    until stack.empty?
      pointer = stack.pop
      arr << pointer.name
      pointer.neighbors.each_with_index do |bool, i|
        if bool && !done[i]
          stack.push(vertices[i])
          done[i] = true
        end
      end
    end
    arr
  end

  # Find shortest path in O(n^2) time, optimized for named vertices
  def dijkstra(start_name, end_name)
    start_index = vertices.index { |v| v.name == start_name }
    end_index   = vertices.index { |v| v.name == end_name }

    # set up variables
    distances = Array.new(count, 1.0/0.0)
    distances[start_index] = 0
    tight = []
    prev  = []

    count.times do
      # locate unvisited vertex with minimum distance, then mark it visited
      min = 1.0/0.0
      current = 0
      distances.each_with_index do |distance, i|
        if distance < min && !tight[i]
          min = distance
          current = i
        end
      end
      tight[current] = true

      # check whether path from chosen vertex to each of its neighbors results in a new minimum
      vertices[current].neighbors.each_with_index do |bool, i|
        if bool && (distances[current] + vertices[current].weights[i] < distances[i])
            distances[i] = distances[current] + vertices[current].weights[i]
            prev[i] = current
        end
      end
    end

    if distances[end_index] == 1.0/0.0
      puts "Sorry, no path between the two points exists."
    else
      puts "The shortest distance is #{distances[end_index]}"
      puts humanize_route(prev, start_index, end_index)
      distances[end_index]
    end
  end

  # Find ALL shortest distances in O(n^3) time
  def floyd
    # set up initial distances based on immediate neighbors
    distances = Array.new(count) { Array.new(count, 1.0/0.0) }
    prev = Array.new(count) {Array.new (count)}
    vertices.each_with_index do |vertex, start|
      count.times do |destination|
        distances[start][destination] = 0 if start == destination
        if vertex.weights[destination]
          distances[start][destination] = vertex.weights[destination]
          prev[start][destination] = start
        end
      end
    end
    
    # try to find shortcuts with a triple nested loop
    count.times do |shortcut|
      count.times do |start|
        count.times do |destination|
          if distances[start][shortcut] + distances[shortcut][destination] < distances[start][destination]
            distances[start][destination] = distances[start][shortcut] + distances[shortcut][destination]
            prev[start][destination] = prev[shortcut][destination]
          end
        end
      end
    end

    # now output all distances and paths
    count.times do |start|
      count.times do |destination|
        if start == destination
          # do nothing
        elsif distances[start][destination] == 1.0/0.0
          puts "No path from #{vertices[start].name} to #{vertices[destination].name} exists."
          puts ""
        else
          puts "The shortest distance from #{vertices[start].name} to #{vertices[destination].name} is #{distances[start][destination]}."
          puts humanize_route(prev[start], start, destination)
          puts ""
        end
      end
    end
    distances
  end

  # Find a minimal spanning tree (only works on undirected graphs)
  def prim
    # initialize progress trackers
    distances = Array.new(count, 1.0/0.0)
    reached = Array.new(count, false)
    closest = []
    total_distance = 0
    
    # start at random vertex
    num = rand(count)
    tree = Tree.new(vertices[num])
    reached[num] = true

    until reached.all? && reached.length == count
      # recalculate minimum distances to unvisited vertices
      reached.each_with_index do |bool, i|
        if bool
          vertices[i].weights.each_with_index do |weight, j|
            if weight && weight < distances[j] && !reached[j]
              distances[j] = weight
              closest[j] = i
            end
          end
        end
      end

      # add minimum to tree
      vertex_to_add = distances.each_with_index.min.last
      originating_vertex = closest[vertex_to_add]
      spot_on_tree = tree.find_node(vertices[originating_vertex])
      spot_on_tree.add_child(Tree.new(vertices[vertex_to_add]))
      
      # mark the vertex as in the set
      total_distance += distances[vertex_to_add]
      distances[vertex_to_add] = 1.0/0.0
      reached[vertex_to_add] = true
    end
    [tree, total_distance]
  end

  # Brute force solution to the Traveling Salesman Problem (works up until ~10 vertices)
  # Optional flag to determine shortest distance required to visit every vertex exactly once
  def brute_force_tsp(return_to_origin = true)
    min_distance = 1.0/0.0
    best_path = nil
    paths = (0...count).to_a.permutation.to_a

    paths.each do |path|
      cumulative_distance = 0

      path[0..path.length - 2].each_with_index do |start_index, i|
        end_index = path[i + 1]
        if vertices[start_index].weights[end_index]
          cumulative_distance += vertices[start_index].weights[end_index]
        else
          cumulative_distance += 1.0/0.0
        end
      end

      if return_to_origin
        if vertices[path[-1]].weights[path[0]]
          cumulative_distance += vertices[path[-1]].weights[path[0]]
        else
          cumulative_distance += 1.0/0.0
        end
      end

      if cumulative_distance < min_distance
        min_distance = cumulative_distance
        best_path = path
      end
    end

    if return_to_origin
      puts "The shortest distance for a complete loop is #{min_distance}"
    else
      puts "The shortest route to visit each vertex exactly once is #{min_distance}"
    end
    puts humanize_tsp_route(best_path, return_to_origin)
    [min_distance, best_path]
  end


  private

    def humanize_route(prev, start_node, end_node)
      str = vertices[end_node].name
      pointer = end_node
      until pointer == start_node
        str = vertices[prev[pointer]].name + " -> " + str
        pointer = prev[pointer]
      end
      str
    end

    def humanize_tsp_route(arr, return_to_origin = true)
      str = ""
      arr[0..-2].each do |place|
        str += vertices[place].name + " -> "
      end
      str += vertices[arr[-1]].name
      str = str + " -> " + vertices[arr[0]].name if return_to_origin
      str
    end

end

"=============================="


class Vertex
  attr_accessor :name, :neighbors, :weights

  def initialize(name)
    @name = name
    @neighbors = []
    @weights = []
  end

end

flights = [
    ['JFK', 'ATL', 150],
    ['ATL', 'SFO', 400],
    ['ORD', 'LAX', 200],
    ['LAX', 'DFW', 80],
    ['JFK', 'HKG', 800],
    ['ATL', 'ORD', 90],
    ['JFK', 'LAX', 500],
]

"==========================="

vertices = flights.map{ |v| [v[0], v[1]]}.flatten.uniq
g = Graph.new
vertices.each { | v| g.add_vertex(v) }

flights.each do |f| 
  g.add_edge(f[0], f[1], f[2])
end


p g.dijkstra('JFK', 'ORD')
