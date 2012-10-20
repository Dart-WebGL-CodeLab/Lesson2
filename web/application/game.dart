
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
  /**
   * List containing the rendering commands to run.
   */
  List _renderCommands;
  /**
   * Rendering command interpreter.
   *
   * Spectre creates programs, which contain rendering commands,
   * that need to be executed to draw the scene.
   */
  Interpreter _interpreter;
  /**
   * Resource handler for the game.
   *
   * All resources, texture, mesh, shader, etc, that require loading should
   * go through the resource handler. This ensures that resources are not
   * loaded redundantly.
   */
  ResourceManager _resourceManager;
  /// Handle to the viewport.
  int _viewport;
  /// Clear color for the rendering.
  vec3 _color;
  /// Direction to modify the color.
  vec3 _direction;
  /// Random number generator
  Random _randomGenerator;

  /// The time of the last frame
  int _lastFrameTime;
  /// The angle to rotate by
  double _angle;

  //---------------------------------------------------------------------
  // Transform variables
  //---------------------------------------------------------------------

  mat4 _modelMatrix;

  Float32Array _modelMatrixArray;

  Float32Array _viewProjectitonMatrixArray;

  //---------------------------------------------------------------------
  // Mesh variables
  //---------------------------------------------------------------------

  /**
   * A handle to the vertex buffer for the mesh.
   */
  int _meshVertexBuffer;
  /**
   * A handle to the vertex attributes to use.
   *
   * The vertex attributes specify how the vertices are laid out
   * in memory. A vertex buffer can have multiple attributes interleaved
   * within it.
   */
  int _meshInputLayout;
  /**
   * A handle to the index buffer.
   *
   * The index buffer contains indices into the vertex buffer to use
   * when drawing. This allows for vertex data to be repeated during drawing.
   */
  int _meshIndexBuffer;
  /// The number of indices in the buffer
  int _meshIndexCount;

  //---------------------------------------------------------------------
  // Shader variables
  //---------------------------------------------------------------------

  /**
   * A handle to the vertex shader to use.
   *
   * A vertex shader is a program that runs once per vertex.
   * It is run first within the pipeline.
   */
  int _vertexShader;

  /**
   * A handle to the fragment shader to use.
   *
   * A fragment shader is a program that runs once per pixel.
   * It is run after the vertex shader within the pipeline.
   */
  int _fragmentShader;

  /**
   * A handle to the shader program to use.
   *
   * A shader program is the result of linking together
   * vertex and fragment shaders. By setting it the rendering
   * pipeline is run through the vertex and fragment shader
   * code.
   */
  int _shaderProgram;

  //---------------------------------------------------------------------
  // State variables
  //---------------------------------------------------------------------

  int _blendState;

  int _depthState;

  int _rasterizerState;

  int _samplerState;

  //---------------------------------------------------------------------
  // Texture variables
  //---------------------------------------------------------------------

  /// Handle to the texture to use.
  int _texture;

  //---------------------------------------------------------------------
  // Construction
  //---------------------------------------------------------------------

  /**
   * Creates an instance of the [Game] class.
   *
   * The [id] specifies the canvas element to use.
   */
  Game(String id)
  {
    CanvasElement canvas = document.query(id) as CanvasElement;

    assert(canvas != null);
    WebGLRenderingContext gl = canvas.getContext('experimental-webgl');

    assert(gl != null);

    // Initialize Spectre
    initSpectre();

    // Setup the Spectre device
    _graphicsDevice = new Device(gl);
    _context = _graphicsDevice.immediateContext;

    // Setup the resource manager
    _resourceManager = new ResourceManager();

    String baseUrl = "${window.location.href.substring(0, window.location.href.length - "engine.html".length)}web/resources";
    _resourceManager.setBaseURL(baseUrl);

    // Setup the rendering commands an interpreter
    _renderCommands = new List();
    _interpreter = new Interpreter();

    // Create the viewport
    var viewportProperties = {
      'x': 0,
      'y': 0,
      'width': 800,
      'height': 600
    } ;

    // Create the viewport
    _viewport = _graphicsDevice.createViewport('view', viewportProperties);

    // Setup the clear color
    _color = new vec3(0.0, 0.0, 0.0);
    _direction = new vec3(1.0, 1.0, 1.0);
    _randomGenerator = new Random();
    _lastFrameTime = 0;
    _angle = 0.0;

    _createTransforms();
    _createShaders();
    _createState();
    _createMesh();
  }

  /**
   * Create the transforms.
   */
  void _createTransforms()
  {
    // Create the view-projection matrix
    mat4 viewProjectionMatrix = makePerspective(
      0.785398163, // Field of view in radians (45 degrees)
      800 / 600,   // Aspect ratio (canvas.width / canvas.height)
      0.01,        // Near plane
      100.0        // Far plane
    );

    mat4 viewMatrix = makeLookAt(
      new vec3.raw(0.0, 0.0, -5.0), // Eye position
      new vec3.raw(0.0, 0.0,  0.0), // Look at
      new vec3.raw(0.0, 1.0,  0.0)  // Up direction
    );

    viewProjectionMatrix.multiply(viewMatrix);

    _viewProjectitonMatrixArray = new Float32Array(16);
    viewProjectionMatrix.copyIntoArray(_viewProjectitonMatrixArray);

    // Create the model matrix
    // Center it at 0.0, 0.0, 0.0
    // This is just the identiry matrix
    _modelMatrix = new mat4.identity();

    _modelMatrixArray = new Float32Array(16);
  }

  /**
   * Create the shaders to use for rendering.
   */
  void _createShaders()
  {
    // Create the shader program object
    _shaderProgram = _graphicsDevice.createShaderProgram('Texture Program', {});

    // Create the vertex shader
    _vertexShader = _graphicsDevice.createVertexShader('Texture Vertex Shader', {});

    int vertexShaderResource = _resourceManager.registerResource('/shaders/simple_texture.vs');

    _resourceManager.addEventCallback(vertexShaderResource, ResourceEvents.TypeUpdate, (type, resource) {
      _context.compileShaderFromResource(_vertexShader, vertexShaderResource, _resourceManager);
      _graphicsDevice.configureDeviceChild(_shaderProgram, { 'VertexProgram': _vertexShader });
    });

    _resourceManager.loadResource(vertexShaderResource);

    // Create the fragment shader
    _fragmentShader = _graphicsDevice.createFragmentShader('Texture Fragment Shader', {});

    int fragmentShaderResource = _resourceManager.registerResource('/shaders/simple_texture.fs');

    _resourceManager.addEventCallback(fragmentShaderResource, ResourceEvents.TypeUpdate, (type, resource) {
      _context.compileShaderFromResource(_fragmentShader, fragmentShaderResource, _resourceManager);
      _graphicsDevice.configureDeviceChild(_shaderProgram, { 'FragmentProgram': _fragmentShader });
    });

    _resourceManager.loadResource(fragmentShaderResource);
  }

  /**
   * Create all the rendering state.
   */
  void _createState()
  {
    // Create the blend state
    Map blendStateProperties = {
      'blendEnable':true,
      'blendSourceColorFunc': BlendState.BlendSourceShaderAlpha,
      'blendDestColorFunc': BlendState.BlendSourceShaderInverseAlpha,
      'blendSourceAlphaFunc': BlendState.BlendSourceShaderAlpha,
      'blendDestAlphaFunc': BlendState.BlendSourceShaderInverseAlpha
    };

    _blendState = _graphicsDevice.createBlendState('Blend State', blendStateProperties);

    // Create the depth state
    Map depthStateProperties = {
      'depthTestEnabled': true,
      'depthComparisonOp': DepthState.DepthComparisonOpLess
    };

    _depthState = _graphicsDevice.createDepthState('Depth State', depthStateProperties);

    // Create the sampler state
    Map samplerStateProperties = { };

    _samplerState = _graphicsDevice.createSamplerState('Sampler State', samplerStateProperties);

    // Create the rasterizer state
    Map rasterizerStateProperties = {
      'cullEnabled': true,
      'cullMode': RasterizerState.CullBack,
      'cullFrontFace': RasterizerState.FrontCCW
    };

    _rasterizerState = _graphicsDevice.createRasterizerState('Rasterizer State', rasterizerStateProperties);
  }

  /**
   * Create all the mesh data.
   */
  void _createMesh()
  {
    // The vertex and index buffer will not be modified each frame.
    // So mark it as static. This does not mean the contents can't be
    // changed, but the driver shouldn't expect it to happen often
    // and can optimize based on this assumption
    Map staticBufferUsage = { 'usage': 'static' };

    // Create the vertex buffer
    _meshVertexBuffer = _graphicsDevice.createVertexBuffer('Vertex Buffer', staticBufferUsage);
    _meshInputLayout = _graphicsDevice.createInputLayout('Input Layout', {});

    // Create the index buffer
    _meshIndexBuffer = _graphicsDevice.createIndexBuffer('Index Buffer', staticBufferUsage);
    _meshIndexCount = 0;

    // Create the texture
    Map textureUsage = {
      'textureFormat': Texture.TextureFormatRGB,
      'pixelFormat': Texture.PixelFormatUnsignedByte
    };

    _texture = _graphicsDevice.createTexture2D('Texture', textureUsage);
  }

  /**
   * Create the rendering commands.
   *
   * Rendering commands can be created before the resources are loaded, but
   * not before the associated handles have been created.
   */
  void _createRenderingCommands()
  {
    ProgramBuilder builder = new ProgramBuilder();

    builder.setPrimitiveTopology(ImmediateContext.PrimitiveTopologyTriangles);
    builder.setRasterizerState(_rasterizerState);
    builder.setDepthState(_depthState);
    builder.setShaderProgram(_shaderProgram);
    builder.setUniformMatrix4('objectTransform', _modelMatrixArray);
    builder.setUniformMatrix4('cameraTransform', _viewProjectitonMatrixArray);
    builder.setTextures(0, [_texture]);
    builder.setSamplers(0, [_samplerState]);
    builder.setInputLayout(_meshInputLayout);
    builder.setIndexBuffer(_meshIndexBuffer);
    builder.setVertexBuffers(0, [_meshVertexBuffer]);
    builder.drawIndexed(_meshIndexCount, 0);

    // Get the commands
    _renderCommands = builder.ops;
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
    // Get the change in time
    double dt = (time - _lastFrameTime) * 0.001;
    _lastFrameTime = time;

    // Rotate the model
    _angle += dt * PI;

    mat4 rotation = new mat4.rotationZ(_angle);
    _modelMatrix = _modelMatrix * rotation;

    _modelMatrix.copyIntoArray(_modelMatrixArray);

    //vec3 translation = _modelMatrix.getTranslation();
    //print('Translation ${translation.x} ${translation.y} ${translation.z}');


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
    // Clear the buffers
    _context.clearColorBuffer(
      _color.x,
      _color.y,
      _color.z,
      1.0
    );
    _context.clearDepthBuffer(1.0);
    _context.reset();

    _context.setBlendState(_blendState);
    _context.setRasterizerState(_rasterizerState);
    _context.setDepthState(_depthState);
    _context.setViewport(_viewport);

    // Run the render commands
    _interpreter.run(_renderCommands, _graphicsDevice, _resourceManager, _context);
  }

  //---------------------------------------------------------------------
  // Properties
  //---------------------------------------------------------------------

  /**
   * Sets the mesh to display.
   */
  set mesh(String value)
  {
    int meshResource = _resourceManager.registerResource(value);

    _resourceManager.addEventCallback(meshResource, ResourceEvents.TypeUpdate, (type, resource) {
      print('Mesh loaded');
      MeshResource mesh = resource;

      // Get the description of the layout
      var elements = [
        InputLayoutHelper.inputElementDescriptionFromMesh(new InputLayoutDescription('vPosition', 0, 'POSITION' ), mesh),
        InputLayoutHelper.inputElementDescriptionFromMesh(new InputLayoutDescription('vTexCoord', 0, 'TEXCOORD0'), mesh)
      ];

      _graphicsDevice.configureDeviceChild(_meshInputLayout, { 'elements': elements });
      _graphicsDevice.configureDeviceChild(_meshInputLayout, { 'shaderProgram': _shaderProgram });

      // Get the number of indices
      _meshIndexCount = mesh.numIndices;

      // Update the contents of the buffer
      _context.updateBuffer(_meshVertexBuffer, mesh.vertexArray);
      _context.updateBuffer(_meshIndexBuffer, mesh.indexArray);

      // Recreate the rendering commands
      // This is because the index count has changed
      _createRenderingCommands();
    });

    _resourceManager.loadResource(meshResource);
  }

  /**
   * Sets the texture to use on the mesh.
   */
  set texture(String value)
  {
    int textureResource = _resourceManager.registerResource(value);

    _resourceManager.addEventCallback(textureResource, ResourceEvents.TypeUpdate, (type, resource) {
      print('texture loaded: ${_texture}');
      _context.updateTexture2DFromResource(_texture, textureResource, _resourceManager);
      _context.generateMipmap(_texture);
    });

    _resourceManager.loadResource(textureResource);
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

    // Set the mesh and associated texture
    _gameInstance.texture = '/textures/dart_tex.png';
    _gameInstance.mesh = '/meshes/cube.mesh';
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
