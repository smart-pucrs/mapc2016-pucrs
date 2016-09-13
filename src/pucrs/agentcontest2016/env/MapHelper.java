package pucrs.agentcontest2016.env;

import java.io.File;
import java.util.HashMap;
import java.util.Iterator;
import java.util.Map;
import java.util.logging.Logger;

import com.graphhopper.GHRequest;
import com.graphhopper.GHResponse;
import com.graphhopper.GraphHopper;
import com.graphhopper.routing.util.EncodingManager;
import com.graphhopper.util.PointList;
import com.graphhopper.util.shapes.GHPoint;
import com.graphhopper.util.shapes.GHPoint3D;

import massim.competition2015.scenario.Location;
import massim.competition2015.scenario.Route;

public class MapHelper {

	private Logger logger = Logger.getLogger(MapHelper.class.getName());

	private static String mapName = null;
	private static GraphHopper hopper = null;
	private static Map<String, Location> locations = null;
	private static double cellSize;

	public static void init(String newMapName, double cellSize, double proximity) {
		if (newMapName.equals(mapName)) {
			return;
		}
		MapHelper.cellSize = cellSize;
		Location.setProximity(proximity);
		mapName = newMapName;
		locations = new HashMap<String, Location>();
		hopper = new GraphHopper().forDesktop();
		hopper.setOSMFile("osm" + File.separator + mapName + ".osm.pbf");
		hopper.setGraphHopperLocation("graphs" + File.separator + mapName);
		hopper.setEncodingManager(new EncodingManager(EncodingManager.CAR));
		hopper.importOrLoad();
	}

	public static GraphHopper getHopper() {
		return hopper;
	}

	public static Location getLocation(String id) {
		return locations.get(id);
	}
	
	public static Route getNewRoute(String from, String to, String type) {
		return getNewRoute(getLocation(from), getLocation(to), type);
	}
	
	public static Route getNewRoute(Location from, String to, String type) {
		return getNewRoute(from, getLocation(to), type);
	}

	public static Route getNewRoute(Location from, Location to, String type) {
		if (from == null || to == null) {
			return null;
		}
		Route route = null;
		if (type.equals("air")) {
			route = getNewAirRoute(from, to);
		} else if (type.equals("road")) {
			route = getNewCarRoute(from, to);
		}
		return route;
	}

	private static Route getNewAirRoute(Location from, Location to) {
		Route route = new Route();
		double fractions = getLength(from, to) / MapHelper.cellSize;
		Location loc = null;
		for (long i = 1; i <= fractions; i++) {
			loc = getIntermediateLoc(from, to, fractions, i);
			route.addPoint(loc);
		}
		if (!to.equals(loc)) {
			route.addPoint(to);
		}
		return route;
	}

	private static Route getNewCarRoute(Location from, Location to) {

		GHRequest req = new GHRequest(from.getLat(), from.getLon(), to.getLat(), to.getLon()).setWeighting("shortest").setVehicle("car");
		GHResponse rsp = MapHelper.getHopper().route(req);

		if (rsp.hasErrors()) {
			return null;
		}

		Route route = new Route();
		PointList pointList = rsp.getPoints();
		Iterator<GHPoint3D> pIterator = pointList.iterator();
		if (!pIterator.hasNext())
			return null;
		GHPoint prevPoint = pIterator.next();

		double remainder = 0;
		Location loc = null;
		while (pIterator.hasNext()) {
			GHPoint nextPoint = pIterator.next();
			double length = getLength(prevPoint, nextPoint);
			if (length == 0) {
				prevPoint = nextPoint;
				continue;
			}

			long i = 0;
			for (; i * MapHelper.cellSize + remainder < length; i++) {
				loc = getIntermediateLoc(prevPoint, nextPoint, length, i * MapHelper.cellSize + remainder);
				if (!from.equals(loc)) {
					route.addPoint(loc);
				}
			}
			remainder = i * MapHelper.cellSize + remainder - length;
			prevPoint = nextPoint;
		}

		if (!to.equals(loc)) {
			route.addPoint(to);
		}

		return route;
	}

	public static double getLength(Location loc1, Location loc2) {
		return Math.sqrt(Math.pow(loc1.getLon() - loc2.getLon(), 2) + Math.pow(loc1.getLat() - loc2.getLat(), 2));
	}

	public static Location getIntermediateLoc(Location loc1, Location loc2, double fractions, long i) {
		double lon = (loc2.getLon() - loc1.getLon()) * i / fractions + loc1.getLon();
		double lat = (loc2.getLat() - loc1.getLat()) * i / fractions + loc1.getLat();
		return new Location(lon, lat);
	}

	public static double getLength(GHPoint loc1, GHPoint loc2) {
		return Math.sqrt(Math.pow(loc1.getLon() - loc2.getLon(), 2) + Math.pow(loc1.getLat() - loc2.getLat(), 2));
	}

	public static Location getIntermediateLoc(GHPoint loc1, GHPoint loc2, double length, double i) {
		double lon = (loc2.getLon() - loc1.getLon()) * i / length + loc1.getLon();
		double lat = (loc2.getLat() - loc1.getLat()) * i / length + loc1.getLat();
		return new Location(lon, lat);
	}

	public static boolean hasLocation(String name) {
		return locations.containsKey(name);
	}

	public static void addLocation(String name, Location location) {
		locations.put(name, location);
	}
}
