import 'dart:core';

import 'package:mentions_chat/src/suggestions/suggestion_interfaces.dart';
import 'package:mentions_chat/src/tokenization/work_tokenizer.dart';

/// Class representing the results of a query for suggestions.
class SuggestionsResult {
  final QueryToken mQueryToken;
  final List<Suggestible> mSuggestions;

  SuggestionsResult({this.mQueryToken, this.mSuggestions}) {}

  /// Get the {@link QueryToken} used to generate the mention suggestions.
  ///
  /// @return a {@link QueryToken}
  QueryToken getQueryToken() {
    return mQueryToken;
  }

  /// Get the list of mention suggestions corresponding to the {@link QueryToken}.
  ///
  /// @return a List of {@link com.linkedin.android.spyglass.suggestions.interfaces.Suggestible} representing mention suggestions
  List<Suggestible> getSuggestions() {
    return mSuggestions;
  }
}
