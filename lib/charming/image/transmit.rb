# frozen_string_literal: true

module Charming
  module Image
    # Transmit is a single out-of-band terminal graphics payload: the escape-sequence string that
    # transmits an image (and creates its virtual placement) for a given *image_id*. It travels on
    # {Response}#graphics and is written verbatim to the backend by the {Runtime}, bypassing the
    # line-based frame pipeline. *image_id* is retained for deduplication and spec assertions.
    Transmit = Data.define(:image_id, :payload)
  end
end
