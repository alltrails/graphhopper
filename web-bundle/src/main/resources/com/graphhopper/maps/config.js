const config = {
    routingApi: location.origin + (location.pathname.includes('graphhopper-service-test')
        ? '/api/alltrails/graphhopper-service-test/'
        : (location.pathname.includes('graphhopper-service')
            ? '/api/alltrails/graphhopper-service/'
            : '/')), // Default to '/' for localhost
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
