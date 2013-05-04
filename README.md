# NCBO Ontologies API Client

## Install

    gem install ontologies_api_client

## Configuration

Configuration is provided by calling the <code>config</code> method

    LinkedData::Client.config do |config|
      config.rest_url   = "http://stagedata.bioontology.org/"
      config.apikey     = "your_apikey"
      config.links_attr = "links"
      config.cache      = false
    end
    
## Usage

The client is designed to consume resources from the [NCBO Ontologies API](https://github.com/ncbo/ontologies_api). 
Resources are defined in the client using media types that we know about and
providing attribute names that we want to retreive for each media type.

For example:

    class Category < LinkedData::Client::Base
      include LinkedData::Client::Collection
      @media_type = "http://data.bioontology.org/metadata/Category"
    end

### Collections

Resources that are available via collections should include the Collection mixin (LinkedData::Client::Collection).
By 'collection', we mean that the all resources are available at a single endpoint.
For example, 'Ontology' is a resource with collections because you can see all ontologgies
at the "/ontologies" URL.

### Read/Write

Resources that should have save, update, and delete methods will need to include the ReadWrite mixin (LinkedData::Client::ReadWrite).

### Retrieval

There are multiple ways to retrieve individual or groups of resources.

***Find***

To retrieve a single record by id:

    Category.find("http://data.bioontology.org/categories/all_organisms")

***Where***

To retrieve all records that match a particular an in-code filter. The code is a block that should return a 
boolean that indicates whether or not the item should be included in the results.

    categories = Category.where do |ont|
      ont.name.include?("health")
    end
    
***Find By***

You can use shortcut methods to find by particular attribute/value pairs
(attributes are named in the method and multiple can be provided by connecting them with 'and').

    categories = Category.find_by_parentCategory("http://data.bioontology.org/categories/anatomy")
    
## Questions

For questions please email [support@bioontology.org](support@bioontology.org.)

## License

Copyright (c) 2013, The Board of Trustees of Leland Stanford Junior University All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:

    Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer.

    Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution.

THIS SOFTWARE IS PROVIDED BY THE BOARD OF TRUSTEES OF LELAND STANFORD JUNIOR UNIVERSITY ''AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL The Board of Trustees of Leland Stanford Junior University OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

The views and conclusions contained in the software and documentation are those of the authors and should not be interpreted as representing official policies, either expressed or implied, of The Board of Trustees of Leland Stanford Junior University.