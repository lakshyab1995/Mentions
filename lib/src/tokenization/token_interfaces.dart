import 'package:flutter/widgets.dart';
import 'package:mentions_chat/src/tokenization/work_tokenizer.dart';

/// An interface representing a tokenizer. Similar to {@link android.widget.MultiAutoCompleteTextView.Tokenizer}, but
/// it operates on {@link Spanned} objects instead of {@link CharSequence} objects.

abstract class Tokenizer {
  /// Returns the start of the token that ends at offset cursor within text.
  ///
  /// @param text   the {@link Spanned} to find the token in
  /// @param cursor position of the cursor in text
  ///
  /// @return index of the first character in the token
  int findTokenStart(final TextSpan text, final int cursor);

  /// Returns the end of the token that begins at offset cursor within text.
  ///
  /// @param text   the {@link Spanned} to find the token in
  /// @param cursor position of the cursor in text
  ///
  /// @return index after the last character in the token
  int findTokenEnd(final TextSpan text, final int cursor);

  /// Return true if the given text is a valid token (either explicit or implicit).
  ///
  /// @param text  the {@link Spanned} to check for a valid token
  /// @param start index of the first character in the token (see {@link #findTokenStart(Spanned, int)})
  /// @param end   index after the last character in the token (see (see {@link #findTokenEnd(Spanned, int)})
  ///
  /// @return true if input is a valid mention
  bool isValidMention(final TextSpan text, final int start, final int end);

  /// Returns text, modified, to ensure that it ends with a token terminator if necessary.
  ///
  /// @param text the given {@link Spanned} object to modify if necessary
  ///
  /// @return the modified version of the text
  TextSpan terminateToken(final TextSpan text);

  ///
  /// Determines if given character is an explicit character according to the current settings of the tokenizer.
  ///
  /// @param c character to test
  ///
  /// @return true if c is an explicit character
  ///
  bool isExplicitChar(final String c);

  /// Determines if given character is an word-breaking character according to the current settings of the tokenizer.
  ///
  /// @param c character to test
  ///
  /// @return true if c is an word-breaking character
  bool isWordBreakingChar(final String c);
}

/// Interface representing a source to generate and retrieve tokens.
abstract class TokenSource {
  /// Gets the text that the {@link Tokenizer} is currently considering for suggestions. Note that this text does not
  /// have to resemble a valid query token.
  ///
  /// @return a string representing currently being considered for a possible query, as the user typed it
  String getCurrentTokenString();

  /// Determine if the token between the given start and end indexes represents a valid token. If it is valid, return
  /// the corresponding {@link QueryToken}. Otherwise, return null.
  ///
  /// @return the valid {@link QueryToken} if it is valid, otherwise null
  QueryToken getQueryTokenIfValid();
}

/// Interface used to query an object with a {@link QueryToken}. The client is responsible for calling an instance of
/// {@link SuggestionsResultListener} with the results of the query once the query is complete.
///
abstract class QueryTokenReceiver {
  /// Called to the client, expecting the client to return a {@link SuggestionsResult} at a later time via the
  /// {@link SuggestionsResultListener} interface. It returns a List of String that the adapter will use to determine
  /// if there are any ongoing queries at a given time.
  ///
  /// @param queryToken the {@link QueryToken} to process
  ///
  /// @return a List of String representing the buckets that will be used when calling {@link SuggestionsResultListener}
  List<String> onQueryReceived(final QueryToken queryToken);
}
