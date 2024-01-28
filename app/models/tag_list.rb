# frozen_string_literal: true

module Model
  class TagList

    def normalize(tags:)
      # check for nil

      return [] if tags.nil?

      # convert tags to array

      tags = tags.split(",").map{ |s| s.strip } if tags.is_a?(String)

      # normalize tags; downcase, hyphenize

      tags.select{ |s| !s.nil? }.map{ |s| s.downcase.gsub(" ", "-") }.sort.uniq
    end

  end
end