
/// Callback type for when the value is submitted
typedef void SubmitEvent(String value);

/**
 * Modal dialog for loading textures.
 */
class TextureDialog
{
  //---------------------------------------------------------------------
  // Class constants
  //---------------------------------------------------------------------

  static const String _textureDisplayId = '#texture_display';
  static const String _modalDialogId = '#texture_dialog';
  static const String _uploadImageId = '#upload_image';
  static const String _uploadImageContentId = '#upload_image_content';
  static const String _urlImageId = '#url_image';
  static const String _urlImageContentId = '#url_image_content';
  static const String _dropImageId = '#drop_image';
  static const String _submitTextureId = '#texture_submit';
  static const String _cancelTextureId = '#texture_cancel';
  static const String _urlInputId = '#url';
  static const String _selectedTabClass = 'selected_tab';
  static const String _leftClass = 'left_area';
  static const String _overClass = 'over_area';
  static const String _hiddenClass = 'hidden';

  /// UI tab allowing dragged images
  static const int _dragInput = 0;
  /// UI tab allowing url input
  static const int _urlInput = 1;

  /// The parent container holding the modal dialog.
  DivElement _modalDialog;
  /// The image container holding the texture preview.
  ImageElement _textureContainer;
  /// The tabs associated with the dialog.
  List<DivElement> _tabs;
  /// The content to display when the tab is selected.
  List<DivElement> _tabContent;
  /// Input element for a URL.
  InputElement _urlInputElement;
  /// The selected tab
  int _selected;
  /// Callback for when the texture is changed.
  SubmitEvent submitCallback;
  /// Filesystem for the application.
  DOMFileSystem _fileSystem;

  /**
   * Initializes an instance of the [TextureDialog] class.
   */
  TextureDialog()
  {
    _modalDialog = _query(_modalDialogId);

    // Setup the tabs
    _tabs = new List<DivElement>();
    _tabContent = new List<DivElement>();

    DivElement uploadTab = _query(_uploadImageId);
    uploadTab.on.click.add((_) {
      _showTabContent(0);
    });

    _tabs.add(uploadTab);
    _tabContent.add(_query(_uploadImageContentId));

    DivElement imageContent = _query(_uploadImageContentId);
    DivElement dropArea = _query(_dropImageId);
    dropArea.on.dragEnter.add((e) {
      e.stopPropagation();

      imageContent.classes.add(_overClass);
      imageContent.classes.remove(_leftClass);
    });

    dropArea.on.dragLeave.add((e) {
      e.stopPropagation();

      imageContent.classes.add(_leftClass);
      imageContent.classes.remove(_overClass);
    });

    dropArea.on.drop.add((e) {
      e.stopPropagation();
      e.preventDefault();

      imageContent.classes.add(_leftClass);
      imageContent.classes.remove(_overClass);

      _onDrop(e.dataTransfer.files);
    });

    DivElement urlTab = _query(_urlImageId);
    urlTab.on.click.add((_) {
      _showTabContent(1);
    });

    _tabs.add(urlTab);
    _tabContent.add(_query(_urlImageContentId));

    _urlInputElement = document.query(_urlInputId) as InputElement;
    assert(_urlInputElement != null);

    // Setup the buttons
    DivElement submitButton = _query(_submitTextureId);
    submitButton.on.click.add((_) {
      _submit();
    });

    DivElement cancelButton = _query(_cancelTextureId);
    cancelButton.on.click.add((_) {
      hide();
    });

    // Get the texture container to display
    _textureContainer = document.query(_textureDisplayId) as ImageElement;

    // File system has not been requested
    _fileSystem = null;
  }

  /**
   * Helper method to query the document for the given [id].
   */
  DivElement _query(id)
  {
    DivElement element = document.query(id) as DivElement;
    assert(element != null);

    return element;
  }

  //---------------------------------------------------------------------
  // UI methods
  //---------------------------------------------------------------------

  /**
   * Hides the texture dialog.
   */
  void hide()
  {
    _modalDialog.style.pointerEvents = 'none';
    _modalDialog.style.opacity = '0';
  }

  /**
   * Shows the texture dialog.
   *
   * Requests a file system if necessary.
   */
  void show()
  {
    if (_fileSystem == null)
    {
      int size = 20 * 1024 * 1024;

      // Request a quota
      window.webkitStorageInfo.requestQuota(LocalWindow.PERSISTENT, size, (grantedBytes) {
        // Request the file system
        window.webkitRequestFileSystem(LocalWindow.TEMPORARY, grantedBytes, _onFileSystemCreated, _onFileSystemError);
      }, _onQuotaError);
    }
    else
    {
      _modalDialog.style.pointerEvents = 'auto';
      _modalDialog.style.opacity = '1';
      _urlInputElement.value = '';

      _showTabContent(0);
    }
  }

  /**
   * Called when a file has been dropped on the area.
   */
  void _onDrop(List<File> files)
  {
    if (files.length > 0)
    {
      File file = files[0];

      _writeFile(file.name, file);
    }
  }

  /**
   * Called when the submit button is pressed.
   */
  void _submit()
  {
    if (submitCallback != null)
    {
      String value;

      if (_selected == _urlInput)
      {
        _fetchResource(_urlInputElement.value);
      }
    }
  }

  /**
   * Shows the [selected] tab.
   */
  void _showTabContent(int selected)
  {
    int length = _tabs.length;
    for (int i = 0; i < length; ++i)
    {
      if (i == selected)
      {
        _tabs[i].classes.add(_selectedTabClass);
        _tabContent[i].classes.remove(_hiddenClass);
      }
      else
      {
        _tabs[i].classes.remove(_selectedTabClass);
        _tabContent[i].classes.add(_hiddenClass);
      }
    }

    _selected = selected;
  }

  //---------------------------------------------------------------------
  // File system methods
  //---------------------------------------------------------------------

  /**
   * Callback for when a quota error occurs.
   */
  void _onQuotaError(DOMException error) { }

  /**
   * Callback for when the file system is created.
   */
  void _onFileSystemCreated(DOMFileSystem fileSystem)
  {
    _fileSystem = fileSystem;

    show();
  }

  /**
   * Callback for when an error occurs with the file system API.
   */
  void _onFileSystemError(FileError error)
  {
    String messageCode = '';

    switch (error.code) {
      case FileError.QUOTA_EXCEEDED_ERR: messageCode = 'Quota Exceeded'; break;
      case FileError.NOT_FOUND_ERR: messageCode = 'Not found '; break;
      case FileError.SECURITY_ERR: messageCode = 'Security Error'; break;
      case FileError.INVALID_MODIFICATION_ERR: messageCode = 'Invalid Modificaiton'; break;
      case FileError.INVALID_STATE_ERR: messageCode = 'Invalid State'; break;
      default: messageCode = 'Unknown error'; break;
    }

    print('Filesystem error: $messageCode');
  }

  /**
   * Fetches a resource at the given [url].
   *
   * The texture at the given location is then copied to the local
   * file system.
   */
  void _fetchResource(String url)
  {

    HttpRequest request = new HttpRequest();
    request.responseType = 'blob';
    request.open('GET', url);

    request.on.loadEnd.add((_) {
      if (request.status == 200)
      {
        Blob blob = request.response;
        String fileName = url.substring(url.lastIndexOf('/') + 1);

        _writeFile(fileName, blob);
      }
    });

    request.send();
  }

  /**
   * Write a file to the local filesystem.
   */
  void _writeFile(String fileName, Blob data)
  {
    Map options = { 'create': true };

    _fileSystem.root.getFile(fileName, options: { 'create': true }, successCallback: (fileEntry) {
      fileEntry.createWriter((fileWriter) {
        fileWriter.on.writeEnd.add((_) {
          String url = fileEntry.toURL();

          submitCallback(url);

          // Change the texture container
          _textureContainer.src = url;

          // Hide the dialog
          hide();
        });

        fileWriter.write(data);
      });
    }, errorCallback: _onFileSystemError);
  }
}
