import 'package:flutter/widgets.dart';
import 'package:mentions_chat/src/suggestions/suggestion_result.dart';

abstract class OnSuggestionsVisibilityChangeListener {
  /// Called when the suggestion list in the {@link com.linkedin.android.spyglass.ui.RichEditorView} is displayed.
  void onSuggestionsDisplayed();

  /// Called when the suggestion list in the {@link com.linkedin.android.spyglass.ui.RichEditorView} is hidden.
  void onSuggestionsHidden();
}

/// class for a model to implement in order for it to be able to be suggested.
/// <p/>
/// Note that the information gathered from the below methods are used in the default layout for the
/// {@link SuggestionsAdapter}.

abstract class Suggestible {
  /// Must be unique (useful for eliminating duplicate suggestions)
  ///
  /// @return int the suggestible id
  ///
  int getSuggestibleId();

  /// Main text for the given suggestion, as will be shown to the user. Note other data fields can
  /// be added (other text, pictures), but this is the only required field, as it is used for the
  /// default layout.
  ///
  /// @return String the user visible suggestion
  ///
  String getSuggestiblePrimaryText();
}

/// class that defines the list of suggestions to display and how to display them.
////
abstract class SuggestionsListBuilder {
  /// Create the list of suggestions from the newest {@link SuggestionsResult} received for every bucket. This
  /// allows you to control the exact order of the suggestions.
  ///
  /// @param latestResults      newest {@link SuggestionsResult} for every bucket
  /// @param currentTokenString the most recent token, as typed by the user
  ///
  /// @return a list of {@link Suggestible} representing the suggestions in proper order
  ////

  List<Suggestible> buildSuggestions(
      final Map<String, SuggestionsResult> latestResults,
      final String currentTokenString);

  /// Build a basic view for the given object.
  ///
  /// @param suggestion  object implementing {@link Suggestible} to build a view for
  /// @param convertView the old view to reuse, if possible
  /// @param parent      parent view
  ///
  /// @return a view for the corresponding {@link Suggestible} object in the adapter
  ////
  Widget getView(final Suggestible suggestion, Widget convertView,
      Widget parent, final BuildContext context);
}

/// class used to listen for the results of a mention suggestion query via a {@link QueryTokenReceiver}.
////
abstract class SuggestionsResultListener {
  /// Callback to return a {@link SuggestionsResult} so that the suggestions it contains can be added to a
  /// {@link SuggestionsAdapter} and rendered accordingly.
  /// <p>
  /// Note that for any given {@link QueryToken} that the {@link QueryTokenReceiver} handles, onReceiveSuggestionsResult
  /// may be called multiple times. For example, if you can suggest both people and companies, the
  /// {@link QueryTokenReceiver} will receive a single {@link QueryToken}, but it should call onReceiveSuggestionsResult
  /// twice (once with people suggestions and once with company suggestions), using a different bucket each time.
  ///
  /// @param result a {@link SuggestionsResult} representing the result of the query
  /// @param bucket a string representing the type of mention (used for grouping in the {@link SuggestionsAdapter}
  ////
  void onReceiveSuggestionsResult(
      final SuggestionsResult result, final String bucket);
}

/// class for a class to handle when the suggestions are visible.
////
abstract class SuggestionsVisibilityManager {
  /// Displays or hides the mentions suggestions list.
  ///
  /// @param display whether the mentions suggestions should be displayed
  ////
  void displaySuggestions(bool display);

  /// @return true if the mention suggestions list is currently being displayed
  ////
  bool isDisplayingSuggestions();
}
