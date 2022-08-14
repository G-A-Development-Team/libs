
class GraphicsEngine
  new: =>
    @components = {}
    @windows = {}

  DrawRectangle: (id, vector) =>
    print "called"
    @components[id] = -> 
      print id
      draw.Color 255, 255, 255, 255
      draw.OutlinedRect vector["X"], vector["Y"], vector["W"], vector["H"]
      @

  CreateWindow: (id, vector) =>
    @windows[id] = ->
      @DrawRectangle id, vector
      @

  Run: =>
    callbacks.Register "Draw", -> 
      for key, value in pairs @components
        value!


Engine = GraphicsEngine!

Engine\CreateWindow "Header", {X:10, Y:10, W:100, H:100}

Engine\Run!

print "script loaded"
