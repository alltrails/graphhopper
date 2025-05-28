package com.graphhopper;

import java.io.FileReader;
import java.util.HashMap;

import com.graphhopper.routing.util.AtAttributeCalculator;

import au.com.bytecode.opencsv.CSVReader;

/**
 * Crude hack to allow custom weights to be loaded from a CSV into a HashMap
 * so they may be merged-in during an OSM import
 */
public class AtGlobals {
    public static HashMap<String, HashMap<Long, Double>> atAttributes = new HashMap<String, HashMap<Long, Double>>();

    public static void loadAllTrailsCsv(String filename) {
      try {
          CSVReader reader = new CSVReader(new FileReader(filename));
          String[] headers = reader.readNext();
          if (headers == null) {
            System.out.println("CSV parse error: no header row");
            reader.close();
            return;
          }

          // Build lookup map of column name to index.
          // For each named column, create an empty map for its wayId:value pairs to go into
          HashMap<String, Integer> headerMap = new HashMap<>();
          int osmIdColumnIndex = -1;
          for (int i = 0; i < headers.length; i++) {
            if ("osm_id".equals(headers[i]))
              osmIdColumnIndex = i;
            else if (AtAttributeCalculator.AT_CSV_KEYS.contains(headers[i])) {
              headerMap.put(headers[i], i);
              atAttributes.put(headers[i], new HashMap<Long, Double>());
            } else {
              System.out.println("CSV parse ignore: " + headers[i]);
            }
          }
          if (osmIdColumnIndex == -1) {
            System.out.println("CSV parse error: no osm_id column");
            reader.close();
            return;
          }
          System.out.println("CSV attributes: " + headerMap.toString());

          String [] nextLine;
          while ((nextLine = reader.readNext()) != null) {
              try {
                String osmId = nextLine[osmIdColumnIndex];
                if (osmId.isEmpty())
                  continue;
                Long wayId = Double.valueOf(osmId).longValue();

                // For each column, store wayId:value lookup in map with same name as column
                for (String key : headerMap.keySet()) {
                  Integer index = headerMap.get(key);
                  if (!nextLine[index].isEmpty()) {
                    Double value = Double.valueOf(nextLine[index]);
                    if (value > 0.0)
                      atAttributes.get(key).put(wayId, value);
                  }
                }
              } catch (Exception ex) {
                  System.out.println("CSV parse exception: " + ex.getMessage());
              }
          }
          reader.close();
      } catch (Exception ex) {
          System.out.println("CSV read exception: " + ex.getMessage());
      }
  }
}