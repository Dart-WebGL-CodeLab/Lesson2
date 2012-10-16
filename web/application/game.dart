
class Game
{
  //---------------------------------------------------------------------
  // Class variables
  //---------------------------------------------------------------------

  /// Singleton holding the [Game] instance.
  static Game _gameInstance;

  //---------------------------------------------------------------------
  // Member variables
  //---------------------------------------------------------------------

  /// Spectre graphics device.
  Device _graphicsDevice;
  /// Immediate rendering context.
  ImmediateContext _context;
  /// Handle to the viewport.
  int _viewport;
  /// Clear color for the rendering.
  vec3 _color;
  /// Direction to modify the color.
  vec3 _direction;
  /// Random number generator
  Random _randomGenerator;

  //---------------------------------------------------------------------
  // Construction
  //---------------------------------------------------------------------

  Game(String id)
  {
    CanvasElement canvas = document.query(id) as CanvasElement;

    assert(canvas != null);
    WebGLRenderingContext gl = canvas.getContext('experimental-webgl');

    assert(gl != null);

    // Setup the Spectre device
    _graphicsDevice = new Device(gl);
    _context = _graphicsDevice.immediateContext;

    // Create the viewport
    var viewportProperties = {
      'x': 0,
      'y': 0,
      'width': 800,
      'height': 600
    } ;

    _viewport = _graphicsDevice.createViewport('view', viewportProperties);
    _context.setViewport(_viewport);

    // Setup the clear color
    _color = new vec3(0.0, 0.0, 0.0);
    _direction = new vec3(1.0, 1.0, 1.0);
    _randomGenerator = new Random();
  }

  //---------------------------------------------------------------------
  // Public methods
  //---------------------------------------------------------------------

  /**
   * Update method for the [Game].
   *
   * All game logic should be updated within this method.
   * Any animation should be based upon the current [time].
   */
  void update(int time)
  {
    for (int i = 0; i < 3; ++i)
    {
      // Add a random difference
      _color[i] += _direction[i] * (_randomGenerator.nextDouble() * 0.01);

      // Colors range from [0, 1]
      // Change direction when necessary
      if (_color[i] > 1.0)
      {
        _color[i] = 1.0;
        _direction[i] = -1.0;
      }
      else if (_color[i] < 0.0)
      {
        _color[i] = 0.0;
        _direction[i] = 1.0;
      }
    }
  }

  /**
   * Draw method for the [Game].
   *
   * All rendering logic should go here.
   */
  void draw()
  {
    _context.clearColorBuffer(
      _color.x,
      _color.y,
      _color.z,
      1.0
    );
  }

  //---------------------------------------------------------------------
  // Static methods
  //---------------------------------------------------------------------

  /**
   * Initializes the [Game] instance.
   */
  static void onInitialize()
  {
    _gameInstance = new Game('#webgl_host');
  }

  /**
   * Update loop for the [Game].
   *
   * The current [time] is passed in.
   */
  static void onUpdate(int time)
  {
    _gameInstance.update(time);
    _gameInstance.draw();
  }
}
