package pucrs.agentcontest2016.actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;
import massim.competition2015.scenario.Location;
import massim.competition2015.scenario.Route;
import pucrs.agentcontest2016.env.MapHelper;

public class route extends DefaultInternalAction {

	private static final long serialVersionUID = 3044142657303654485L;

	// There are three ways to call this function:
	//////// pucrs.agentcontest2016.actions.route(Role, FacilityId, RouteLen)
	// This returns the route length from current agent position to Facility indicated by FacilityId
	//////// pucrs.agentcontest2016.actions.route(Role, FacilityId1, FacilityId2, RouteLen)
	// This returns the route length from Facility indicated by FacilityId1 to FacilityId2
	//////// pucrs.agentcontest2016.actions.route(Role, Lat, Lon, FacilityId, RouteLen)
	// This returns the route length from location indicated by (Lat, Lon) to Facility (FacilityId)
	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {

		// Define role (always first parameter)
		String role = args[0].toString();
		String type = "road";
		if (role.equals("\"Drone\"")) {
			type = "air";
		}

		Route route = null;
		if (args.length == 3){
			String from = ts.getUserAgArch().getAgName();
			String to = args[1].toString();
			route = MapHelper.getNewRoute(from, to, type);
		} else if (args.length == 4) {
			String from = args[1].toString();
			String to = args[2].toString();
			route = MapHelper.getNewRoute(from, to, type);
		} else if (args.length == 5) {
			// Create a location with Lat (1) and Lon (2) parameter
			NumberTermImpl a1 = (NumberTermImpl) args[1];
			NumberTermImpl a2 = (NumberTermImpl) args[2];
			double locationLat = a1.solve();
			double locationLon = a2.solve();
			// Location is first LONGITUDE and then LATITUDE
			Location from = new Location(locationLon, locationLat);
			String to = args[3].toString();
			route = MapHelper.getNewRoute(from, to, type);
		} else {
			return false;
		}

		boolean ret = true;
		// Return parameter (route length) is always the last parameter (args.length - 1)
		ret = ret & un.unifies(args[args.length - 1], new NumberTermImpl(route.getRouteLength()));
		return ret;
	}
}