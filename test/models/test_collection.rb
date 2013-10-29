require_relative '../test_case'

class TestOntology < LinkedData::Client::Base
  include LinkedData::Client::Collection
  include LinkedData::Client::ReadWrite

  @media_type    = "http://data.bioontology.org/metadata/Ontology"
  @include_attrs = "all"
end

class CollectionTest < LinkedData::Client::TestCase
  def test_all
    onts = LinkedData::Client::Models::Ontology.all
    assert onts.length > 350
  end

  def test_class_for_type
    media_type = "http://data.bioontology.org/metadata/Category"
    type_cls = LinkedData::Client::Base.class_for_type(media_type)
    assert type_cls == LinkedData::Client::Models::Category
  end

  def test_find_by
    bro = TestOntology.find_by_acronym("BRO")
    assert bro.length >= 1
    assert bro.any? {|o| o.acronym.eql?("BRO")}

    onts = TestOntology.find_by_hasDomain_and_doNotUpdate("http://data.bioontology.org/categories/health", true)
    assert onts.length >= 1

    onts = TestOntology.find_by_hasDomain_and_hasDomain("http://data.bioontology.org/categories/phenotype", "http://data.bioontology.org/categories/human")
    assert onts.length >= 1
  end

  def test_where
    onts = TestOntology.where {|o| o.name.downcase.start_with?("c")}
    assert onts.length >= 1
  end

  def test_find
    ont = TestOntology.find("http://data.bioontology.org/ontologies/CAMRQ")
    assert !ont.nil?
  end
end
