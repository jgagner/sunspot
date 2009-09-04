module Sunspot
  module DSL
    # 
    # This DSL exposes the functionality provided by Solr's fulltext Dismax
    # handler.
    #
    class Fulltext
      def initialize(query) #:nodoc:
        @query = query
      end

      # 
      # Specify which fields to search. Field names specified as arguments are
      # given default boost; field boosts can be specified by passing a hash of
      # field names keyed to boost values as the last argument.
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     fulltext 'search is cool' do
      #       fields(:body, :title => 2.0)
      #     end
      #   end
      #
      # This would search the :body field with default boost (1.0), and the :title
      # field with a boost of 2.0
      #
      def fields(*fields)
        boosted_fields = fields.pop if fields.last.is_a?(Hash)
        fields.each do |field_name|
          @query.add_fulltext_field(field_name)
        end
        boosted_fields.each_pair do |field_name, boost|
          @query.add_fulltext_field(field_name, boost)
        end
      end

      # 
      # Enable keyword highlighting for this search. Options are the following:
      #
      # Full disclosure: I barely understand what these options actually do;
      # this documentation is pretty much just copied from the
      # (http://wiki.apache.org/solr/HighlightingParameters#head-23ecd5061bc2c86a561f85dc1303979fe614b956)[Solr Wiki]
      # 
      # :max_snippets::
      #   The maximum number of highlighted snippets to generate per field
      # :fragment_size::
      #   The number of characters to consider for a highlighted fragment
      # :merge_continuous_fragments::
      #   Collapse continuous fragments into a single fragment
      # :phrase_highlighter::
      #   Highlight phrase terms only when they appear within the query phrase
      #   in the document
      # :require_field_match::
      #   If true, a field will only be highlighted if the query matched in
      #   this particular field (only has an effect if :phrase_highlighter is
      #   true as well)
      #
      def highlight(options = {})
        @query.set_highlight(options)
      end

      # 
      # Phrase fields are an awesome dismax feature that adds extra boost to
      # documents for which all the fulltext keywords appear in close proximity
      # in one of the given fields. Excellent for titles, headlines, etc.
      #
      def phrase_fields(*fields)
        boosted_fields = fields.pop if fields.last.is_a?(Hash)
        fields.each do |field_name|
          @query.add_phrase_field(field_name)
        end
        if boosted_fields
          boosted_fields.each_pair do |field_name, boost|
            @query.add_phrase_field(field_name, boost)
          end
        end
      end

      # 
      # Boost queries allow specification of an arbitrary scope for which
      # matching documents should receive an extra boost. The block is evaluated
      # in the usual scope DSL, and field names are attribute fields, not text
      # fields, as in other scope.
      #
      # === Example
      #
      #   Sunspot.search(Post) do
      #     keywords 'super fan' do
      #       boost(2.0) do
      #         with(:featured, true)
      #       end
      #     end
      #   end
      #
      # In the above search, featured posts will receive a boost of 2.0.
      #
      def boost(factor, &block)
        Sunspot::Util.instance_eval_or_call(
          Scope.new(@query.create_boost_query(factor)),
          &block
        )
      end
    end
  end
end
