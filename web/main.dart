//---------------------------------------------------------------------
// Library imports
//
// Allows libraries to be accessed by the application.
// Core libraries are prefixed with dart.
// Third party libraries are specified in the pubspec.yaml file
// and imported with the package prefix.
//---------------------------------------------------------------------

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
void _onUpdate(int time)
{
  _counter.update(time);
  Game.onUpdate(time);

  // For the animation to continue the function
  // needs to set itself again
  window.requestAnimationFrame(_onUpdate);
}

void _openTextureDialog(_)
{
  _textureDialog.show();
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

  DivElement replaceButton = document.query('#replace') as DivElement;
  replaceButton.on.click.add(_openTextureDialog);

  // Start the animation loop
  window.requestAnimationFrame(_onUpdate);
}
