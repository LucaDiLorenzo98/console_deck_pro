import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HotkeyInputField extends StatefulWidget {
  final TextEditingController controller;
  final String labelText;
  final String hintText;
  final String clearTooltip;

  const HotkeyInputField({
    super.key,
    required this.controller,
    required this.labelText,
    required this.hintText,
    required this.clearTooltip,
  });

  @override
  State<HotkeyInputField> createState() => _HotkeyInputFieldState();
}

class _HotkeyInputFieldState extends State<HotkeyInputField> {
  final FocusNode _focusNode = FocusNode();
  String _initialValue = '';

  @override
  void initState() {
    super.initState();
    _initialValue = widget.controller.text;
    _focusNode.addListener(_onFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _focusNode.dispose();
    // If this handler is still active when the widget is disposed, remove it.
    if (RawKeyboard.instance.keyEventHandler == _handleRawKeyEvent) {
      RawKeyboard.instance.keyEventHandler = null;
    }
    super.dispose();
  }

  void _onFocusChange() {
    if (_focusNode.hasFocus) {
      _initialValue = widget.controller.text;
      widget.controller.text = widget.hintText;
      RawKeyboard.instance.keyEventHandler = _handleRawKeyEvent;
    } else {
      // Unsubscribe from keyboard events
      RawKeyboard.instance.keyEventHandler = null;
      // If we lost focus and the text is the hint, revert to the initial value
      if (widget.controller.text == widget.hintText) {
        widget.controller.text = _initialValue;
      }
    }
  }

  bool _handleRawKeyEvent(RawKeyEvent event) {
    if (event is RawKeyDownEvent) {
      final keys = RawKeyboard.instance.keysPressed;
      _updateHotkeyFromPressedKeys(keys);
    }
    // Return false to indicate that the event has not been handled and should be propagated.
    return false;
  }


  void _updateHotkeyFromPressedKeys(Set<LogicalKeyboardKey> keys) {
    final List<String> modifiers = [];
    String? mainKey;

    for (final key in keys) {
      if (_isModifier(key)) {
        final modifierName = _getModifierName(key);
        if (!modifiers.contains(modifierName)) {
          modifiers.add(modifierName);
        }
      } else {
        mainKey = _getKeyName(key);
      }
    }
    modifiers.sort();

    List<String> parts = [...modifiers];
    if (mainKey != null) {
      parts.add(mainKey);
    }

    final newHotkey = parts.join('+');
    // To prevent the hint text from being part of the hotkey
    if (widget.controller.text != newHotkey.toUpperCase()) {
      widget.controller.text = newHotkey.toUpperCase();
    }
  }

  bool _isModifier(LogicalKeyboardKey key) {
    return [
      LogicalKeyboardKey.control,
      LogicalKeyboardKey.controlLeft,
      LogicalKeyboardKey.controlRight,
      LogicalKeyboardKey.shift,
      LogicalKeyboardKey.shiftLeft,
      LogicalKeyboardKey.shiftRight,
      LogicalKeyboardKey.alt,
      LogicalKeyboardKey.altLeft,
      LogicalKeyboardKey.altRight,
      LogicalKeyboardKey.meta,
      LogicalKeyboardKey.metaLeft,
      LogicalKeyboardKey.metaRight,
    ].contains(key);
  }

  String _getModifierName(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.control ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight) return 'ctrl';
    if (key == LogicalKeyboardKey.shift ||
        key == LogicalKeyboardKey.shiftLeft ||
        key == LogicalKeyboardKey.shiftRight) return 'shift';
    if (key == LogicalKeyboardKey.alt ||
        key == LogicalKeyboardKey.altLeft ||
        key == LogicalKeyboardKey.altRight) return 'alt';
    if (key == LogicalKeyboardKey.meta ||
        key == LogicalKeyboardKey.metaLeft ||
        key == LogicalKeyboardKey.metaRight) return 'meta';
    return '';
  }

  String _getKeyName(LogicalKeyboardKey key) {
    final specialKeys = {
      LogicalKeyboardKey.space: 'space',
      LogicalKeyboardKey.enter: 'enter',
      LogicalKeyboardKey.tab: 'tab',
      LogicalKeyboardKey.backspace: 'backspace',
      LogicalKeyboardKey.delete: 'delete',
      LogicalKeyboardKey.escape: 'escape',
      LogicalKeyboardKey.home: 'home',
      LogicalKeyboardKey.end: 'end',
      LogicalKeyboardKey.pageUp: 'pageup',
      LogicalKeyboardKey.pageDown: 'pagedown',
      LogicalKeyboardKey.arrowUp: 'up',
      LogicalKeyboardKey.arrowDown: 'down',
      LogicalKeyboardKey.arrowLeft: 'left',
      LogicalKeyboardKey.arrowRight: 'right',
    };
    return specialKeys[key] ?? key.keyLabel.toLowerCase();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        _focusNode.requestFocus();
      },
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        readOnly: true,
        decoration: InputDecoration(
          labelText: widget.labelText,
          border: const OutlineInputBorder(),
          suffixIcon: IconButton(
            icon: const Icon(Icons.clear),
            tooltip: widget.clearTooltip,
            onPressed: () {
              widget.controller.clear();
              _initialValue = ''; // Also clear initial value on manual clear
              if (_focusNode.hasFocus) {
                widget.controller.text = widget.hintText;
              }
            },
          ),
        ),
      ),
    );
  }
}
