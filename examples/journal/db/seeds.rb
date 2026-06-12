# frozen_string_literal: true

SAMPLE_ENTRIES = [
  ["Shipped the prototype", "good", <<~MD],
    # Big day

    Finally got the **prototype** in front of real users. Notes:

    - Onboarding took under two minutes
    - The *export* button confused two people
    - Everyone loved the keyboard shortcuts

    > "This feels fast." — first tester

    Next: fix the export labeling.
  MD
  ["Rainy Tuesday", "meh", <<~MD],
    Worked from the kitchen table. Mostly maintenance:

    1. Cleared the inbox
    2. Reviewed two PRs
    3. Wrote half a design doc

    Nothing exciting, nothing broken.
  MD
  ["Debugging marathon", "rough", <<~MD],
    Six hours chasing a race condition in the task executor.

    ```ruby
    threads.each { |t| t.join(timeout) }
    ```

    The fix was a one-liner. The finding was not. Sleep now.
  MD
  ["Long walk, clear head", "good", <<~MD],
    Took the afternoon off and walked the coast trail. Came back with
    the answer to the layout problem that's been stuck all week:
    *constraints, not fixed sizes*.
  MD
  ["Quarterly planning", "meh", <<~MD],
    Planning day. Lots of sticky notes, three real decisions:

    - Ship the journal demo this month
    - Defer the plugin system
    - Hire one more person for docs
  MD
  ["The demo crashed", "rough", <<~MD],
    Live demo, twenty people, and the app crashed on a nil mood.
    Added validation and a regression test. Lesson re-learned:
    **seed data is not test data**.
  MD
  ["First outside contributor", "good", <<~MD],
    Someone I've never met opened a PR fixing a typo *and* adding a spec.
    Open source is good actually.
  MD
  ["Slow Friday", "meh", <<~MD]
    Coasted. Read docs, tidied the backlog, left early. That's allowed.
  MD
]

SAMPLE_ENTRIES.each_with_index do |(title, mood, body), index|
  next if Journal::Entry.exists?(title: title)

  Journal::Entry.create!(
    title: title,
    mood: mood,
    body: body,
    favorite: index.zero?,
    created_at: Time.now - (SAMPLE_ENTRIES.length - index) * 86_400
  )
end
