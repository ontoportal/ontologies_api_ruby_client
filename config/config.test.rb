$API_CLIENT_INVALIDATE_CACHE = false
$DEBUG_API_CLIENT = false

LinkedData::Client.config do |config|
  config.rest_url = 'https://data.bioontology.org/'
  config.apikey = '8b5b7825-538d-40e0-9e9e-5ab9274a9aeb'
  config.links_attr = 'links'
  config.cache = true
  config.debug_client = false
  config.debug_client_keys = []
  config.federated_portals = {
    bioportal: {
      api: 'https://data.agroportal.eu/',
      apikey: '1de0a270-29c5-4dda-b043-7c3580628cd5',
      color: '#234979',
    },
    ecoportal: {
      api: 'https://data.ecoportal.lifewatch.eu/',
      apikey: "43a437ba-a437-4bf0-affd-ab520e584719",
      color: '#0f4e8a',
    },
    # earthportal: {
    #   api: 'https://earthportal.eu:8443/',
    #   apikey: "c9147279-954f-41bd-b068-da9b0c441288",
    #   color: '#1e2251',
    # },
    biodivportal: {
      api: 'https://data.biodivportal.gfbio.org/',
      apikey: "47a57aa3-7b54-4f34-b695-dbb5f5b7363e",
      color: '#1e2251',
    }
  }

end
