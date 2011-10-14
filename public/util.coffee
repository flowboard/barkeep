# Some common utility functions
window.Util =
  # A more sane ordering of arguments for setTimeout and setInterval.
  setTimeout: (milliseconds, callback) -> window.setTimeout callback, milliseconds
  setInterval: (milliseconds, callback) -> window.setInterval callback, milliseconds

  # A timeout that doesn't delay if jQuery.fx.off == true
  animateTimeout: (milliseconds, callback) ->
    if jQuery.fx.off then callback() else @setTimeout milliseconds, callback

  # Keep some amount of context on-screen to pad the selection position
  scrollWithContext: (selector, scroll="all") ->
    selection = $(selector)
    return unless selection.size() > 0
    selectionTop = selection.offset().top
    selectionBottom = selectionTop + selection.height()
    windowTop = $(window).scrollTop()
    windowBottom = windowTop + $(window).height()
    # If the selection if off-screen, center on it
    if selectionBottom < windowTop or selectionTop > windowBottom
      window.scroll(0, (selectionTop + selectionBottom) / 2 - $(window).height() / 2)
    # Otherwise ensure there is enough buffer
    else if (selectionTop - windowTop < Constants.CONTEXT_BUFFER_PIXELS) and
        (scroll == "all" or scroll == "top")
      window.scroll(0, selectionTop - Constants.CONTEXT_BUFFER_PIXELS)
    else if windowBottom - selectionBottom < Constants.CONTEXT_BUFFER_PIXELS and
        (scroll == "all" or scroll == "bottom")
      window.scroll(0, selectionBottom + Constants.CONTEXT_BUFFER_PIXELS - $(window).height())

window.ShortcutOverlay =
  init: ->
    $(".kbShortcuts.overlay .container").focus -> $(".kbShortcuts.overlay").css("visibility", "visible")
    $(".kbShortcuts.overlay .container").blur -> $(".kbShortcuts.overlay").css("visibility", "hidden")
    shortcutsPopup = $(".kbShortcuts.overlay .container")
    KeyboardShortcuts.createShortcutContext shortcutsPopup
    KeyboardShortcuts.registerPageShortcut "shift+/", -> shortcutsPopup.focus()
    # Hitting both "escape" and "?" again will get rid of the overlay
    for shortcut in ["esc", "shift+/"]
      KeyboardShortcuts.registerShortcut shortcutsPopup, shortcut, ->
        shortcutsPopup.blur()
        false
    $(".kbShortcuts.overlay .shortcuts .close a").click (e) -> shortcutsPopup.blur()

window.KeyboardShortcuts =
  init: ->
    @suspended = false
    @registerGlobals()

  # Register some shortcut on a page element.
  # element - some jquery element
  # shortcut - the jquery.hotkeys-formatted shortcut string
  # callback - the associated callback
  registerShortcut: (element, shortcut, callback) ->
    # Dumb special-casing we have to do for FF on Mac, because it doesn't give any keycodes when you press
    # shift-/ (question mark).
    if shortcut == "shift+/"
      element.keypress (e) =>
        return unless e.which == 63
        return if @suspended and not $(e.target).is(element)
        return if not $(e.target).is(element) and e.target.type == "text"
        callback(e)
      return
    element.bind "keydown", shortcut, (e) =>
      return if @suspended and not $(e.target).is(element)
      callback(e)

  registerPageShortcut: (shortcut, callback) -> @registerShortcut($(document), shortcut, callback)

  # A convenience function for specifying that an element is its own "shortcut context", which means that when
  # it is focused, page and global keyboard shortcuts will not apply.
  #
  # element - jquery element
  createShortcutContext: (element) ->
    # Make blur be fired for non-input elements. This terrible, wonderful hack courtesy of
    # http://www.barryvan.com.au/2009/01/onfocus-and-onblur-for-divs-in-fx/
    unless element.attr("tabindex")?
      element.attr("tabindex", -1)
      element.addClass "noFocusOutline"
    element.focus =>
      @suspended = true
      true
    element.blur =>
      @suspended = false
      true

  registerGlobals: ->
    @registerPageShortcut "c", -> window.location.href = "/commits"
    @registerPageShortcut "s", -> window.location.href = "/stats"
    @registerPageShortcut "i", -> window.location.href = "/inspire"

$(document).ready ->
  ShortcutOverlay.init()
  KeyboardShortcuts.init()
