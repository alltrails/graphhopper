package com.graphhopper.routing.ev;

public class AtGainPercent {
    public static final String KEY = "at_gain_percent";

    public static DecimalEncodedValue create() {
        // We're passing storeTwoDirections = true, so can store gain in each direction
        return new DecimalEncodedValueImpl(KEY, 5, 0, 1, false, true, false);
    }
}
