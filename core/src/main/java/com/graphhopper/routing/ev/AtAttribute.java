package com.graphhopper.routing.ev;

import java.util.Set;

import com.graphhopper.routing.util.AtAttributeCalculator;

public class AtAttribute {
    public static final Set<String> KEYS = AtAttributeCalculator.GH_KEYS;

    public static DecimalEncodedValue create(String key) {
        // Range is 0.0-10.0
        return new DecimalEncodedValueImpl(key, 5, 0.0, 0.3226,
                false, false, false);
    }
}
