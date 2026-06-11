# frozen_string_literal: true

module Charming
  module Components
    # FuzzyMatcher implements fzf-style subsequence matching with contiguity and
    # word-boundary scoring. Used by CommandPalette (and available to any component
    # that filters labels against typed input).
    #
    #   FuzzyMatcher.score("opl", "Open palette")  # => positive score
    #   FuzzyMatcher.score("xyz", "Open palette")  # => nil (not a subsequence)
    #   FuzzyMatcher.filter("op", commands, &:label)
    module FuzzyMatcher
      # Score bonuses: base per matched char, consecutive-run bonus, word-start bonus.
      # The run bonus outweighs the word-start bonus so a literal substring match
      # ("pal" in "Open palette") beats the same letters scattered across word starts.
      CHAR_SCORE = 1
      CONSECUTIVE_BONUS = 4
      WORD_START_BONUS = 3

      module_function

      # Returns a relevance score when every character of *query* appears in order
      # within *candidate* (case-insensitive), nil otherwise. Higher is better:
      # contiguous runs and matches at word starts score above scattered matches.
      # All alignments are considered (memoized), so "pal" finds the contiguous run
      # in "Open palette" rather than the scattered greedy match.
      def score(query, candidate)
        q = query.to_s.downcase
        c = candidate.to_s.downcase
        return 0 if q.empty?

        best_alignment(q, 0, c, 0, false, {})
      end

      # Finds the best-scoring alignment of q[qi..] within c[ci..]. *consecutive_at_ci*
      # is true when the previous query char matched at ci - 1 (enabling the run bonus
      # for a match exactly at ci). Returns nil when no alignment exists.
      def best_alignment(q, qi, c, ci, consecutive_at_ci, memo)
        return 0 if qi == q.length

        key = [qi, ci, consecutive_at_ci]
        return memo[key] if memo.key?(key)

        best = nil
        index = ci
        while (index = c.index(q[qi], index))
          points = CHAR_SCORE
          points += CONSECUTIVE_BONUS if consecutive_at_ci && index == ci
          points += WORD_START_BONUS if word_start?(c, index)
          rest = best_alignment(q, qi + 1, c, index + 1, true, memo)
          if rest
            total = points + rest
            best = total if best.nil? || total > best
          end
          index += 1
        end

        memo[key] = best
      end

      # Filters *candidates* to those matching *query*, ordered best-score first
      # (original order breaks ties). The optional block extracts the searchable
      # label from each candidate (defaults to to_s).
      def filter(query, candidates, &label)
        scored = candidates.each_with_index.filter_map do |candidate, index|
          text = label ? yield(candidate) : candidate.to_s
          candidate_score = score(query, text)
          [candidate_score, index, candidate] if candidate_score
        end

        scored.sort_by { |candidate_score, index, _| [-candidate_score, index] }.map(&:last)
      end

      # True when the character at *index* starts a word: position 0 or preceded by
      # a separator (space, underscore, hyphen, slash, dot, colon).
      def word_start?(text, index)
        return true if index.zero?

        text[index - 1].match?(%r{[\s_\-/.:]})
      end
    end
  end
end
