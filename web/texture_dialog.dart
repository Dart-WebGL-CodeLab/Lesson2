
/**
 * Modal dialog for loading textures.
 */
class TextureDialog
{
  //---------------------------------------------------------------------
  // Class constants
  //---------------------------------------------------------------------

  static const String _modalDialogId = '#texture_dialog';
  static const String _uploadImageId = '#upload_image';
  static const String _uploadImageContentId = '#upload_image_content';
  static const String _urlImageId = '#url_image';
  static const String _urlImageContentId = '#url_image_content';
  static const String _submitTextureId = '#texture_submit';
  static const String _cancelTextureId = '#texture_cancel';
  static const String _selectedTabClass = 'selected_tab';
  static const String _hiddenClass = 'hidden';

  /// The parent container holding the modal dialog.
  DivElement _modalDialog;
  /// The tabs associated with the dialog.
  List<DivElement> _tabs;
  /// The content to display when the tab is selected.
  List<DivElement> _tabContent;

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

    DivElement urlTab = _query(_urlImageId);
    urlTab.on.click.add((_) {
      _showTabContent(1);
    });

    _tabs.add(urlTab);
    _tabContent.add(_query(_urlImageContentId));

    // Setup the buttons
    DivElement submitButton = _query(_submitTextureId);
    submitButton.on.click.add((_) {

    });

    DivElement cancelButton = _query(_cancelTextureId);
    cancelButton.on.click.add((_) {
      hide();
    });
  }

  void hide()
  {
    _modalDialog.style.pointerEvents = 'none';
    _modalDialog.style.opacity = '0';
  }

  void show()
  {
    _modalDialog.style.pointerEvents = 'auto';
    _modalDialog.style.opacity = '1';

    _showTabContent(0);
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
  }
}
