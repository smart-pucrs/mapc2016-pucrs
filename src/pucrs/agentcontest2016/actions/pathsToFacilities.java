package pucrs.agentcontest2016.actions;

import java.math.BigDecimal;
import java.math.RoundingMode;
import jason.asSemantics.DefaultInternalAction;
import jason.asSemantics.TransitionSystem;
import jason.asSemantics.Unifier;
import jason.asSyntax.ListTerm;
import jason.asSyntax.ListTermImpl;
import jason.asSyntax.Literal;
import jason.asSyntax.Term;
import pucrs.agentcontest2016.env.MapHelper;

public class pathsToFacilities extends DefaultInternalAction {

	private static final long serialVersionUID = -2883308113671739682L;

@Override
	public Object execute(TransitionSystem ts, Unifier un, Term[] args) throws Exception {
		
		ListTerm proposals = new ListTermImpl();
		
		String name = args[0].toString();
		String role = args[1].toString();
		int speed 	= Integer.valueOf(args[2].toString());
		String type = "road";
		if(role.equals("\"Drone\"")){
			type = "air";
		}
		ListTerm ids   = (ListTerm) args[3];
		
		double len  	= 0;
		double steps 	= 0;
		String from = ts.getUserAgArch().getAgName();
		
		
		for (Term term : ids) {
			String to = term.toString();
			len 	= MapHelper.getNewRoute(from, to, type).getRouteLength();
			
			steps 	= (len / speed);
			BigDecimal bd = new BigDecimal(steps).setScale(1, RoundingMode.UP);
			
			proposals.add(Literal.parseLiteral("proposal("+name+","+to+","+bd.intValue()+")"));
		}
		
		boolean ret = true;
		if(proposals.size() > 0){			
			ret = un.unifies(args[4], proposals); 
		}
		return ret;
	}
}
