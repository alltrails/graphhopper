const config = {
    routingApi: location.origin + ((location.host === 'alpha.mostpaths.com' || location.host === 'www.alltrails.com') ? '/api/alltrails/graphhopper-service/' : '/'), // Localhost does not want the extra pathing.
    geocodingApi: '',
    defaultTiles: 'OpenStreetMap',
    keys: {
        graphhopper: "",
        maptiler: "missing_api_key",
        omniscale: "missing_api_key",
        thunderforest: "missing_api_key",
        kurviger: "missing_api_key"
    },
    routingGraphLayerAllowed: true,
    request: {
        details: [
            'road_class',
            'road_environment',
            'max_speed',
            'average_speed',
        ],
        snapPreventions: ['ferry'],
    },
}
