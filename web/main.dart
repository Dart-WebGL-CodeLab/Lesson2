//---------------------------------------------------------------------
// Library imports
//
// Allows libraries to be accessed by the application.
// Core libraries are prefixed with dart.
// Third party libraries are specified in the pubspec.yaml file
// and imported with the package prefix.
//---------------------------------------------------------------------

#import('dart:html');
#import('dart:math');
#import('package:spectre/spectre.dart');
#import('package:dartvectormath/vector_math_html.dart');

//---------------------------------------------------------------------
// Source files
//---------------------------------------------------------------------

#source('application/frame_counter.dart');
#source('application/game.dart');

/// The [FrameCounter] associated with the application
FrameCounter _counter;
/// The [TextureDialog] associated with the application


/**
 * Update function for the application.
 *
 * The current [time] is passed in.
 */
bool _onUpdate(int time)
{
  _counter.update(time);
  Game.onUpdate(time);

  // For the animation to continue the function
  // needs to set itself again
  window.requestAnimationFrame(_onUpdate);
}

void _openTextureDialog()
{

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


  // Start the animation loop
  window.requestAnimationFrame(_onUpdate);
}
