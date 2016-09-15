package pucrs.agentcontest2016.actions;

import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.ListTerm;
import jason.asSyntax.Literal;
import jason.asSyntax.NumberTermImpl;
import jason.asSyntax.Term;
import massim.competition2015.scenario.Location;
import massim.competition2015.scenario.Route;
import pucrs.agentcontest2016.env.MapHelper;

public class closest extends DefaultInternalAction {

	private static final long serialVersionUID = 5552929201215381277L;

	@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		String role = args[0].toString();
		String type = "road";
		String closest = null;
		double len = Integer.MAX_VALUE;
		if(role.equals("\"Drone\"")){
			type = "air";
		}
		if (args.length == 5) {
			ListTerm ids = (ListTerm) args[3];
			NumberTermImpl a1 = (NumberTermImpl) args[1];
			NumberTermImpl a2 = (NumberTermImpl) args[2];
			double locationLat = a1.solve();
			double locationLon = a2.solve();
			// Location is first LONGITUDE and then LATITUDE
			Location from = new Location(locationLon, locationLat);
			for (Term term : ids) {
				String to = term.toString();
				Route route = MapHelper.getNewRoute(from, to, type);
				if(route.getRouteLength() < len){
					closest = to;
					len = route.getRouteLength();
				}
			}
		}
		else {
			ListTerm ids = (ListTerm) args[1];
			String from = null;
			if (args.length == 4){
				from = args[2].toString();
			}
			else {
				from = ts.getUserAgArch().getAgName();
			}
			for (Term term : ids) {
				String to = term.toString();
				Route route = MapHelper.getNewRoute(from, to, type);
				if(route.getRouteLength() < len){
					closest = to;
					len = route.getRouteLength();
				}
			}
		}
		boolean ret = true;
		if(closest != null){
			ret = un.unifies(args[args.length - 1], Literal.parseLiteral(closest)); 
		}
		return ret;
	}
}
