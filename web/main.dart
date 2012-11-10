//---------------------------------------------------------------------
// Library imports
//
// Allows libraries to be accessed by the application.
// Core libraries are prefixed with dart.
// Third party libraries are specified in the pubspec.yaml file
// and imported with the package prefix.
//---------------------------------------------------------------------

library webgl_lab;

import 'dart:html';
import 'dart:math';
import 'package:spectre/spectre.dart';
import 'package:vector_math/vector_math_browser.dart';

//---------------------------------------------------------------------
// Source files
//---------------------------------------------------------------------

part 'texture_dialog.dart';
part 'application/frame_counter.dart';
part 'application/game.dart';

/// The [FrameCounter] associated with the application
FrameCounter _counter;
/// The [TextureDialog] associated with the application
TextureDialog _textureDialog;

/**
 * Update function for the application.
 *
 * The current [time] is passed in.
 */
void _onUpdate(double time)
{
  _counter.update(time);
  Game.onUpdate(time);

  // For the animation to continue the function
  // needs to set itself again
  window.requestAnimationFrame(_onUpdate);
}

/**
 * Opens the texture dialog.
 */
void _openTextureDialog(_)
{
  _textureDialog.show();
}

/**
 * Callback for when the texture is changed.
 */
void _onTextureChange(String value)
{
  Game instance = Game.instance;

  instance.texture = value;
}

/**
 * Callback for when the model is changed.
 */
void _onModelChange(String value)
{
  Game instance = Game.instance;

  instance.mesh = value;
}

/**
 * Initializes the model buttons.
 */
void _initModelButtons()
{
  DivElement cubeMesh = document.query('#cube_button') as DivElement;
  assert(cubeMesh != null);

  cubeMesh.on.click.add((_) {
    _onModelChange('web/resources/meshes/cube.mesh');
  });

  DivElement sphereMesh = document.query('#sphere_button') as DivElement;
  assert(sphereMesh != null);

  sphereMesh.on.click.add((_) {
    _onModelChange('web/resources/meshes/sphere.mesh');
  });

  DivElement planeMesh = document.query('#plane_button') as DivElement;
  assert(planeMesh != null);

  planeMesh.on.click.add((_) {
    _onModelChange('web/resources/meshes/plane.mesh');
  });

  DivElement cylinderMesh = document.query('#cylinder_button') as DivElement;
  assert(cylinderMesh != null);

  cylinderMesh.on.click.add((_) {
    _onModelChange('web/resources/meshes/cylinder.mesh');
  });
}

/**
 * Main entrypoint for every Dart application.
 */
void main()
{
  // Initialize the WebGL side
  Game.onInitialize();
  _counter = new FrameCounter('#frame_counter');

  // Initialize the UI side
  _textureDialog = new TextureDialog();
  _textureDialog.submitCallback = _onTextureChange;

  DivElement replaceButton = document.query('#replace') as DivElement;
  replaceButton.on.click.add(_openTextureDialog);

  _initModelButtons();

  // Start the animation loop
  window.requestAnimationFrame(_onUpdate);
}
