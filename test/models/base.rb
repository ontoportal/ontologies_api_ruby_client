require_relative '../test_case'

class TestOntology < LinkedData::Client::Base
  include LinkedData::Client::Collection
  include LinkedData::Client::ReadWrite

  @media_type = "http://data.bioontology.org/metadata/Ontology"
  @include_attrs    = "all"
end

class OntologyTest < LinkedData::Client::TestCase
  def test_all
    # onts = TestOntology.all
    # assert onts.length > 350
  end
  
  def test_class_for_type
    media_type = "http://data.bioontology.org/metadata/Category"
    type_cls = LinkedData::Client::Base.class_for_type(media_type)
    assert type_cls == LinkedData::Client::Models::Category
  end
end
  