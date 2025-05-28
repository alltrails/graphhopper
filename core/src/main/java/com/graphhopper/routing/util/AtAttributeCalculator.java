package com.graphhopper.routing.util;

import com.graphhopper.reader.ReaderWay;
import com.graphhopper.routing.ev.DecimalEncodedValue;
import com.graphhopper.routing.ev.EdgeIntAccess;
import com.graphhopper.routing.util.parsers.TagParser;
import com.graphhopper.storage.IntsRef;

import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

import com.graphhopper.AtGlobals;

public class AtAttributeCalculator implements TagParser {

    private final DecimalEncodedValue attributeEnc;
    private final String attributeKey;

    private static final Map<String, String> GH_KEY_TO_AT_CSV_KEY = Map.of(
        "at_scenic_value", "at_scenic_value",
        "at_popularity", "at_popularity_on_foot",
        "at_racingbike_popularity", "at_popularity_road_biking",
        "at_mtb_popularity", "at_popularity_off_road_biking",
        "at_other_popularity", "at_popularity_other"
    );

    public static final Set<String> GH_KEYS = GH_KEY_TO_AT_CSV_KEY.keySet();
    public static final Set<String> AT_CSV_KEYS = new HashSet<String>(GH_KEY_TO_AT_CSV_KEY.values());

    public AtAttributeCalculator(DecimalEncodedValue attributeEnc, String attributeKey) {
        this.attributeEnc = attributeEnc;
        this.attributeKey = GH_KEY_TO_AT_CSV_KEY.get(attributeKey);
    }

    @Override
    public void handleWayTags(int edgeId, EdgeIntAccess edgeIntAccess, ReaderWay way, IntsRef relationFlags) {
        HashMap<Long, Double> attributeMap = AtGlobals.atAttributes.get(this.attributeKey);
        if (attributeMap != null) {
            long wayId = way.getId();
            Double value = attributeMap.get(wayId);
            if (value != null) {
                // String name = way.getTag("name", null);
                // System.out.println(name + ": " + wayId + " " + this.attributeKey + ": " + value);
                attributeEnc.setDecimal(false, edgeId, edgeIntAccess, value);
            }
        }
    }
}
