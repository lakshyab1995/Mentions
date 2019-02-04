import 'package:flutter/widgets.dart';
import 'package:mentions_chat/src/mentions.dart';
import 'package:mentions_chat/src/tokenization/token_interfaces.dart';
import 'package:mentions_chat/src/utils.dart';
import 'dart:math' as math;

/// Class that represents a token from a {@link Tokenizer} that can be used to query for suggestions.
/// <p>
/// Note that if the query is explicit, the explicit character has not been removed from the start of the token string.
/// To get the string without any explicit character, use {@link #getKeywords()}.

class QueryToken {
  // what the user typed, exactly, as detected by the tokenizer
  String mTokenString;

  // if the query was explicit, then this was the character the user typed (otherwise, null char)
  String mExplicitChar;

  QueryToken({String tokenString, String explicitChar}) {
    mTokenString = tokenString;
    mExplicitChar = explicitChar;
  }

  /// @return query as typed by the user and detected by the {@link Tokenizer}

  String getTokenString() {
    return mTokenString;
  }

  /// Returns a String that should be used to perform the query. It is equivalent to the token string without an explicit
  /// character if it exists.
  ///
  /// @return one or more words that the {@link QueryTokenReceiver} should use for the query

  String getKeywords() {
    return (mExplicitChar != 0) ? mTokenString.substring(1) : mTokenString;
  }

  /// @return the explicit character used in the query, or the null character if the query is implicit

  String getExplicitChar() {
    return mExplicitChar;
  }

  /// @return true if the query is explicit

  bool isExplicit() {
    return mExplicitChar != 0;
  }

  bool equals(Object o) {
    QueryToken that = o as QueryToken;
    return mTokenString != null &&
        that != null &&
        mTokenString == that.getTokenString();
  }

  int hashCode() {
    return mTokenString.hashCode;
  }
}

/// Class used to configure various parsing options for the {@link WordTokenizer}. Instantiate using the
/// {@link WordTokenizerConfig.Builder} class.
class WordTokenizerConfig {

  final String LINE_SEPARATOR;

  // Number of characters required in a word before returning a mention suggestion starting with the word
  // Note: These characters are required to be either letters or digits
  int THRESHOLD;

  // Max number of words to consider as keywords in a query
  int MAX_NUM_KEYWORDS;

  // Characters to use as explicit mention indicators
  final String EXPLICIT_CHARS;

  // Characters to use to separate words
  final String WORD_BREAK_CHARS;

  WordTokenizerConfig({this.LINE_SEPARATOR = "\n",
    this.THRESHOLD = 4,
    this.MAX_NUM_KEYWORDS = 1,
    this.EXPLICIT_CHARS = "@",
    this.WORD_BREAK_CHARS = " .\n"});
}


/// Tokenizer class used to determine the keywords to be used when querying for mention suggestions.

class WordTokenizer implements Tokenizer {

  final WordTokenizerConfig mConfig;

  WordTokenizer({this.mConfig});

  int findTokenStart(final TextSpan text, final int cursor) {
    int start = getSearchStartIndex(text.text, cursor);
    int i = cursor;

    // If it is explicit, return the index of the first explicit character
    if (isExplicit(text.text, cursor)) {
      i--;
      while (i >= start) {
        String currentChar = String.fromCharCode(text.codeUnitAt(i));
        if (isExplicitChar(currentChar)) {
          if (i == 0 || isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1)))) {
            return i;
          }
        }
        i--;
      }
      // Could not find explicit character before the cursor
      // Note: This case should never happen (means that isExplicit
      // returned true when it should have been false)
      return -1;
    } else {
      // For implicit tokens, we need to go back a certain number of words to find the start
      // of the token (with the max number of words to go back defined in the config)
      int maxNumKeywords = mConfig.MAX_NUM_KEYWORDS;

      // Go back to the start of the word that the cursor is currently in
      while (i > start && !isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1)))) {
        i--;
      }

      // Cursor is at beginning of current word, go back MaxNumKeywords - 1 now
      for (int j = 0; j < maxNumKeywords - 1; j++) {
        // Decrement through only one word-breaking character, if it exists
        if (i > start && isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1)))) {
          i--;
        }
        // If there is more than one word-breaking space, break out now
        // Do not consider queries with words separated by more than one word-breaking char
        if (i > start && isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1)))) {
          break;
        }
        // Decrement until the next space
        while (i > start && !isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1)))) {
          i--;
        }
      }

      // Ensures that text.char(i) is not a word-breaking or explicit char (i.e. cursor must have a
      // word-breaking char in front of it and a non-word-breaking char behind it)
      while (i < cursor && (isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i - 1))) ||
          isExplicitChar(String.fromCharCode(text.codeUnitAt(i - 1))))) {
        i++;
      }

      return i;
    }
  }

  int findTokenEnd(final TextSpan text, final int cursor) {
    int i = cursor;
    int end = getSearchEndIndex(text, cursor);

    // Starting from the cursor, increment i until it reaches the first word-breaking char
    while (i >= 0 && i < end) {
      if (isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i)))) {
        return i;
      } else {
        i++;
      }
    }

    return i;
  }

  bool isValidMention(final TextSpan text, final int start, final int end) {
    // Get the token
    String token = text.text.substring(start, end);

    // Null or empty string is not a valid mention
    if (isEmpty(token)) {
      return false;
    }

    // Handle explicit mentions first, then implicit mentions
    final int threshold = mConfig.THRESHOLD;
    bool multipleWords = containsWordBreakingChar(token);
    bool containsExplChar = containsExplicitChar(token);

    if (!multipleWords && containsExplChar) {
      // If it is one word and has an explicit char, the explicit char must be the first char
      if (!isExplicitChar(String.fromCharCode(token.codeUnitAt(0)))) {
        return false;
      }

      // Ensure that the character before the explicit character is a word-breaking character
      // Note: Checks the explicit character closest in front of the cursor
      if (!hasWordBreakingCharBeforeExplicitChar(text, end)) {
        return false;
      }

      // Return true if string is just an explicit character
      if (token.length == 1) {
        return true;
      }

      // If input has length greater than one, the second character must be a letter or digit
      // Return true if and only if second character is a letter or digit, i.e. "@d"
      return isLetterOrDigit(token.codeUnitAt(1));
    } else if (token.length >= threshold) {
      // Change behavior depending on if keywords is one or more words
      if (!multipleWords) {
        // One word, no explicit characters
        // input is only one word, i.e. "u41"
        return onlyLettersOrDigits(token, threshold, 0);
      } else if (containsExplChar) {
        // Multiple words, has explicit character
        // Must have a space, the explicit character, then a letter or digit
        return hasWordBreakingCharBeforeExplicitChar(text, end)
            && isExplicitChar(String.fromCharCode(token.codeUnitAt(0)))
            && isLetterOrDigit(token.codeUnitAt(1));
      } else {
        // Multiple words, no explicit character
        // Either the first or last couple of characters must be letters/digits
        bool firstCharactersValid = onlyLettersOrDigits(token, threshold, 0);
        bool lastCharactersValid = onlyLettersOrDigits(
            token, threshold, token.length - threshold);
        return firstCharactersValid || lastCharactersValid;
      }
    }

    return false;
  }

  TextSpan terminateToken(final TextSpan text) {
    // Note: We do not need to modify the text to terminate it
    return text;
  }

  bool isExplicitChar(final String c) {
    final String explicitChars = mConfig.EXPLICIT_CHARS;
    for (int i = 0; i < explicitChars.length; i++) {
      String explicitChar = String.fromCharCode(explicitChars.codeUnitAt(i));
      if (c == explicitChar) {
        return true;
      }
    }
    return false;
  }

  bool isWordBreakingChar(final String c) {
    final String wordBreakChars = mConfig.WORD_BREAK_CHARS;
    for (int i = 0; i < wordBreakChars.length; i++) {
      String wordBreakChar = String.fromCharCode(wordBreakChars.codeUnitAt(i));
      if (c == wordBreakChar) {
        return true;
      }
    }
    return false;
  }

  // --------------------------------------------------
  // Public Methods
  // --------------------------------------------------


  /// Returns true if and only if there is an explicit character before the cursor
  /// but after any previous mentions. There must be a word-breaking character before the
  /// explicit character.
  ///
  /// @param text   String to determine if it is explicit or not
  /// @param cursor position of the cursor in text
  ///
  /// @return true if the current keywords are explicit (i.e. explicit character typed before cursor)
  bool isExplicit(final String text, final int cursor) {
    return getExplicitChar(text, cursor) != String.fromCharCode(0);
  }


  /// Returns the explicit character if appropriate (i.e. within the keywords).
  /// If not currently explicit, then returns the null character (i.e. '/0').
  ///
  /// @param text   String to get the explicit character from
  /// @param cursor position of the cursor in text
  ///
  /// @return the current explicit character or the null character if not currently explicit
  String getExplicitChar(final String text, final int cursor) {
    if (cursor < 0 || cursor > text.length) {
      return String.fromCharCode(0);
    }
//    SpannableStringBuilder ssb = new SpannableStringBuilder(text);
    StringBuffer ssb = StringBuffer(text);
    int start = getSearchStartIndex(ssb.toString(), cursor);
    int i = cursor - 1;
    int numWordBreakingCharsSeen = 0;
    while (i >= start) {
      String currentChar =String.fromCharCode(text.codeUnitAt(i));
      if (isExplicitChar(currentChar)) {
        // Explicit character must have a word-breaking character before it
        if (i == 0 || isWordBreakingChar(String.fromCharCode(text.codeUnitAt(i-1)))) {
          return currentChar;
        } else {
          // Otherwise, explicit character is not in a valid position, return null char
          return String.fromCharCode(0);
        }
      } else if (isWordBreakingChar(currentChar)) {
        // Do not allow the explicit mention to exceed
        numWordBreakingCharsSeen++;
        if (numWordBreakingCharsSeen == mConfig.MAX_NUM_KEYWORDS) {
          // No explicit char in maxNumKeywords, so return null char
          return String.fromCharCode(0);
        }
      }
      i--;
    }
    return String.fromCharCode(0);
  }


  /// Returns true if the input string contains an explicit character.
  ///
  /// @param input a {@link CharSequence} to test
  ///
  /// @return true if input contains an explicit character
  bool containsExplicitChar(final String input) {
    if (!isEmpty(input)) {
      for (int i = 0; i < input.length; i++) {
        String c = String.fromCharCode(input.codeUnitAt(i));
        if (isExplicitChar(c)) {
          return true;
        }
      }
    }
    return false;
  }


  /// Returns true if the input string contains a word-breaking character.
  ///
  /// @param input a {@link CharSequence} to test
  ///
  /// @return true if input contains a word-breaking character
  bool containsWordBreakingChar(final String input) {
    if (!isEmpty(input)) {
      for (int i = 0; i < input.length; i++) {
        String c = String.fromCharCode(input.codeUnitAt(i));
        if (isWordBreakingChar(c)) {
          return true;
        }
      }
    }
    return false;
  }


  /// Given a string and starting index, return true if the first "numCharsToCheck" characters at
  /// the starting index are either a letter or a digit.
  ///
  /// @param input           a {@link CharSequence} to test
  /// @param numCharsToCheck number of characters to examine at starting position
  /// @param start           starting position within the input string
  ///
  /// @return true if the first "numCharsToCheck" at the starting index are either letters or digits
  bool onlyLettersOrDigits(final String input,
      final int numCharsToCheck, final int start) {
    // Starting position must be within the input string
    if (start < 0 || start > input.length) {
      return false;
    }

    // Check the first "numCharsToCheck" characters to ensure they are a letter or digit
    for (int i = 0; i < numCharsToCheck; i++) {
      int positionToCheck = start + i;
      // Return false if we would throw an Out-of-Bounds exception
      if (positionToCheck >= input.length) {
        return false;
      }
      // Return false early if current character is not a letter or digit
      int charToCheck = input.codeUnitAt(positionToCheck);
      if (!isLetterOrDigit(charToCheck)) {
        return false;
      }
    }

    // First "numCharsToCheck" characters are either letters or digits, so return true
    return true;
  }

  // --------------------------------------------------
  // Protected Helper Methods
  // --------------------------------------------------


  /// Returns the index of the end of the last span before the cursor or
  /// the start of the current line if there are no spans before the cursor.
  ///
  /// @param text   the {@link Spanned} to examine
  /// @param cursor position of the cursor in text
  ///
  /// @return the furthest in front of the cursor to search for the current keywords
  int getSearchStartIndex(final String text, int cursor) {
    if (cursor < 0 || cursor > text.length) {
      cursor = 0;
    }

    // Get index of the end of the last span before the cursor (or 0 if does not exist)
    MentionSpan[] spans = text.substring(0, text.length);
    int closestToCursor = 0;
    for (MentionSpan span : spans) {
      int end = text.getSpanEnd(span);
      if (end > closestToCursor && end <= cursor) {
        closestToCursor = end;
      }
    }

    // Get the index of the start of the line
    String textString = text.toString().substring(0, cursor);
    int lineStartIndex = 0;
    if (textString.contains(mConfig.LINE_SEPARATOR)) {
      lineStartIndex = textString.lastIndexOf(mConfig.LINE_SEPARATOR) + 1;
    }

    // Return whichever is closer before to the cursor
    return math.max(closestToCursor, lineStartIndex);
  }


  /// Returns the index of the beginning of the first span after the cursor or
  /// length of the text if there are no spans after the cursor.
  ///
  /// @param text   the {@link Spanned} to examine
  /// @param cursor position of the cursor in text
  ///
  /// @return the furthest behind the cursor to search for the current keywords
  int getSearchEndIndex(final TextSpan text, int cursor) {
    if (cursor < 0 || cursor > text.text.length) {
      cursor = 0;
    }

    // Get index of the start of the first span after the cursor (or text.length if does not exist)
    MentionSpan[] spans = text.children;
    int closestAfterCursor = text.text.length;
    for (MentionSpan span : spans) {
      int start = text.getSpanStart(span);
      if (start < closestAfterCursor && start >= cursor) {
        closestAfterCursor = start;
      }
    }

    // Get the index of the end of the line
    String textString = text.toString().substring(cursor, text.length);
    int lineEndIndex = text.length;
    if (textString.contains(mConfig.LINE_SEPARATOR)) {
      lineEndIndex = cursor + textString.indexOf(mConfig.LINE_SEPARATOR);
    }

    // Return whichever is closest after the cursor
    return math.min(closestAfterCursor, lineEndIndex);
  }

  /// Ensure the the character before the explicit character is a word-breaking character.
  /// Note that the function only uses the input string to determine which explicit character was
  /// typed. It uses the complete contents of the {@link EditText} to determine if there is a
  /// word-breaking character before the explicit character, as the input string may start with an
  /// explicit character, i.e. with an input string of "@John Doe" and an {@link EditText} containing
  /// the string "Hello @John Doe", this should return true.
  ///
  /// @param text   the {@link Spanned} to check for a word-breaking character before the explicit character
  /// @param cursor position of the cursor in text
  ///
  /// @return true if there is a space before the explicit character, false otherwise
  bool hasWordBreakingCharBeforeExplicitChar(final Spanned text, final int cursor) {
    String beforeCursor = text.subSequence(0, cursor);
    // Get the explicit character closest before the cursor and make sure it
    // has a word-breaking character in front of it
    int i = cursor - 1;
    while (i >= 0 && i < beforeCursor.length) {
      char c = beforeCursor.charAt(i);
      if (isExplicitChar(c)) {
        return i == 0 || isWordBreakingChar(beforeCursor.charAt(i - 1));
      }
      i--;
    }
    return false;
  }

}
