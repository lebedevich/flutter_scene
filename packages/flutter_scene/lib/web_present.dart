/// Web-only: show the scene in a DOM canvas instead of copying each frame
/// into Flutter's canvas. Import from web-only code.
library;

export 'src/gpu/web/webgl/_webgl.dart' show presentInDomCanvas;
