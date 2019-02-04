import 'package:flutter/material.dart';
import 'package:mentions_chat/src/suggestions/suggestion_interfaces.dart';

/// Various display modes that change the text for the mention.
enum MentionDisplayMode { FULL, PARTIAL, NONE }

/// What action to take when the span is deleted
enum MentionDeleteStyle {
  // Clear the underlying text (remove the whole span).
  FULL_DELETE,

  // First clear everything but the first name. On a second delete, delete the first name.
  PARTIAL_NAME_DELETE
}

/// Interface for a model to implement in order for it to be able to be mentioned. This is specifically
/// used by the {@link MentionsEditText}. Note that all mentions, by definition, are suggestible.
abstract class Mentionable extends Suggestible {
  /// Get the string representing what the mention should currently be displaying, depending on the given
  /// {@link MentionDisplayMode}.
  ///
  /// @param mode the {@link MentionDisplayMode} tp ise
  ///
  /// @return the current text to display to the user

  String getTextForDisplayMode(MentionDisplayMode mode);

  /// Determines how the mention should be handled by a MentionSpan as it is being deleted.
  ///
  /// @return the proper {@link MentionDeleteStyle}
  MentionDeleteStyle getDeleteStyle();
}

/// Class used to configure various options for the {@link MentionSpan}. Instantiate using the
/// {@link MentionSpanConfig.Builder} class.
class MentionSpanConfig {
  final Color NORMAL_TEXT_COLOR;

  final Color NORMAL_TEXT_BACKGROUND_COLOR;

  final Color SELECTED_TEXT_COLOR;

  final Color SELECTED_TEXT_BACKGROUND_COLOR;

  MentionSpanConfig(
      {this.NORMAL_TEXT_BACKGROUND_COLOR = Colors.transparent,
      this.NORMAL_TEXT_COLOR = const Color(0xff00a0dc),
      this.SELECTED_TEXT_BACKGROUND_COLOR = const Color(0xff0077b5),
      this.SELECTED_TEXT_COLOR = Colors.white}) {}
}

/// Class representing a spannable {@link Mentionable} in an {@link EditText}. This class is
/// specifically used by the {@link MentionsEditText}.
class MentionSpan {
  Mentionable mention;
  MentionSpanConfig config;

  bool isSelected = false;
  MentionDisplayMode mDisplayMode = MentionDisplayMode.FULL;

  MentionSpan({Mentionable mention, MentionSpanConfig config}) {
    this.mention = mention;
    this.config = config ?? MentionSpanConfig();
  }

  void updateDrawState(final TextPainter tp) {
//    if (isSelected) {
//      tp.setColor(config.SELECTED_TEXT_COLOR);
//      tp.bgColor = config.SELECTED_TEXT_BACKGROUND_COLOR;
//    } else {
//      tp.setColor(config.NORMAL_TEXT_COLOR);
//      tp.bgColor = config.NORMAL_TEXT_BACKGROUND_COLOR;
//    }
//    tp.setUnderlineText(false);
  }

  Mentionable getMention() {
    return mention;
  }

  MentionDisplayMode getDisplayMode() {
    return mDisplayMode;
  }

  void setDisplayMode(MentionDisplayMode mode) {
    mDisplayMode = mode;
  }

  String getDisplayString() {
    return mention.getTextForDisplayMode(mDisplayMode);
  }
}
