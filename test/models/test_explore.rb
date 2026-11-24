require_relative '../test_case'
require 'pry'

module Models
  def self.method_missing
    binding.pry
  end
end
class LinkExploreTest < LinkedData::Client::TestCase

  def test_explore
    sub_direct_explore = LinkedData::Client::Models::Ontology.explore('SNOMEDCT')
                                                             .latest_submission
                                                             .get(include: 'all')

    sub_indirect_explore = LinkedData::Client::Models::Ontology.find('SNOMEDCT').explore.latest_submission
    sub_direct_explore.to_hash.each do |key, value|
      value_to_compare = sub_indirect_explore[key]
      if value.class.ancestors.include?(LinkedData::Client::Base)
        value = value.to_hash
        value_to_compare = value_to_compare.to_hash
      end
      assert_equal value, value_to_compare
    end
  end

  def test_explore_class

    id = 'http://purl.org/sig/ont/fma/fma62955'
    cls = LinkedData::Client::Models::Ontology.explore('FMA')
                                              .classes(id)
                                              .children
                                              .get

    assert_not_empty cls.collection

    cls = LinkedData::Client::Models::Ontology.explore('FMA')
                                              .classes(id)
                                              .children
                                              .get(include: 'prefLabel')

    assert_not_empty cls.collection
  end

end
