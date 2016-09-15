package pucrs.agentcontest2016.env;

import jason.JasonException;
import jason.NoValueException;
import jason.asSyntax.Literal;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.HashSet;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentSkipListSet;
import java.util.logging.Logger;

import massim.competition2015.scenario.Location;
import cartago.AgentId;
import cartago.Artifact;
import cartago.INTERNAL_OPERATION;
import cartago.OPERATION;
import cartago.ObsProperty;
import eis.EILoader;
import eis.EnvironmentInterfaceStandard;
import eis.exceptions.ActException;
import eis.exceptions.NoEnvironmentException;
import eis.exceptions.PerceiveException;
import eis.iilang.Action;
import eis.iilang.EnvironmentState;
import eis.iilang.Parameter;
import eis.iilang.Percept;

public class EISArtifact extends Artifact {

	private Logger logger = Logger.getLogger(EISArtifact.class.getName());

	private Map<String, AgentId> agentIds;
	private Map<String, String> agentToEntity;
	
	private static Set<String> agents = new ConcurrentSkipListSet<String>();

	private EnvironmentInterfaceStandard ei;
	private boolean receiving;
	private int lastStep = -1;
	private int round = 0;
	private String maps[] = new String[] { "london", "hannover", "sanfrancisco" };
	public EISArtifact() {
		agentIds      = new ConcurrentHashMap<String, AgentId>();
		agentToEntity = new ConcurrentHashMap<String, String>();
		MapHelper.init(maps[round], 0.001, 0.0002);
	}

	protected void init() throws IOException, InterruptedException {
		try {
			ei = EILoader.fromClassName("massim.eismassim.EnvironmentInterface");
			if (ei.isInitSupported())
				ei.init(new HashMap<String, Parameter>());
			if (ei.getState() != EnvironmentState.PAUSED)
				ei.pause();
			if (ei.isStartSupported())
				ei.start();
		} catch (Exception e) {
			e.printStackTrace();
		}
		
		receiving = true;
		execInternalOp("receiving");
	}
	
	public static Set<String> getRegisteredAgents(){
		return agents;
	}
	
	@OPERATION
	void register(String entity)  {
		try {
			String agent = getOpUserId().getAgentName();
			agents.add(agent);
			ei.registerAgent(agent);
			ei.associateEntity(agent, entity);
			agentToEntity.put(agent, entity);
			agentIds.put(agent, getOpUserId());
			logger = Logger.getLogger(EISArtifact.class.getName()+"_"+agent);
			logger.info("Registering " + agent + " to entity " + entity);
		} catch (Exception e) {
			e.printStackTrace();
		}
	}	

	@OPERATION
	void action(String action) throws NoValueException {
		try {
			String agent = getOpUserName();
			Action a = Translator.literalToAction(action);
			ei.performAction(agent, a, agentToEntity.get(agent));
		} catch (ActException e) {
			e.printStackTrace();
		}
	}
	
	@INTERNAL_OPERATION
	void setMap(){
		round++;
		MapHelper.init(maps[round], 0.001, 0.0002);
		System.out.println("$> MAP: " + maps[round]);
	}
	
	@INTERNAL_OPERATION
	void receiving() throws JasonException {
		lastStep = -1;
		Collection<Percept> previousPercepts = new ArrayList<Percept>();
		
		while (receiving) {
			await_time(100);
			for (String agent: agentIds.keySet()) {
				try {
					Collection<Percept> percepts = ei.getAllPercepts(agent).get(agentToEntity.get(agent));
					populateTeamArtifact(percepts);
					//logger.info("***"+percepts);
					if (percepts.isEmpty())
						break;
					int currentStep = getCurrentStep(percepts);
					if (lastStep != currentStep) { // only updates if it is a new step
						lastStep = currentStep;
						filterLocations(agent, percepts);
						//logger.info("Agent "+agent);
						updatePerception(agent, previousPercepts, percepts);
						previousPercepts = percepts;
					}
				} catch (PerceiveException | NoEnvironmentException e) {
					e.printStackTrace();
				}
			}
		}
	}

	private int getCurrentStep(Collection<Percept> percepts) {
		for (Percept percept : percepts) {
			if (percept.getName().equals("step")) {
				//logger.info(percept+" "+percept.getParameters().getFirst());
				return new Integer(percept.getParameters().getFirst().toString());
			}
		}
		return -10;
	}
	
	private void populateTeamArtifact(Collection<Percept> percepts){
		for (Percept percept : percepts) {
			String name = percept.getName();
			/*Verifying available items in a nearby shop*/
			if(name.equals("shop")){
				for(Parameter p: percept.getParameters())
					if(p.toString().contains("availableItem"))
						TeamArtifact.addShopItemsPrice(percept.getParameters().get(0).toString(), percept.getParameters().get(3).toString());
			}
		}
	}

	private void updatePerception(String agent, Collection<Percept> previousPercepts, Collection<Percept> percepts) throws JasonException {
		if (agent.equals("vehicle15")) {
			// compute removed perception
			for (Percept old: previousPercepts) {
				if (step_obs_propv1.contains(old.getName())) {
					if (!percepts.contains(old)) { // not perceived anymore
						Literal literal = Translator.perceptToLiteral(old);
						removeObsPropertyByTemplate(old.getName(), (Object[]) literal.getTermsArray());
//						logger.info("removing old perception "+literal);
					}
				}
			}
		}
		else {
			for (Percept old: previousPercepts) {
				if (step_obs_prop.contains(old.getName())) {
					if (!percepts.contains(old)) { // not perceived anymore
						Literal literal = Translator.perceptToLiteral(old);
						removeObsPropertyByTemplate(old.getName(), (Object[]) literal.getTermsArray());
						//logger.info("removing old perception "+literal);
					}
				}
			}
		}
		
		// compute new perception
		Literal step = null;
		if (agent.equals("vehicle15")) {
			for (Percept percept: percepts) {
				if (step_obs_propv1.contains(percept.getName())) {
					if (!previousPercepts.contains(percept) || percept.getName().equals("lastAction")) { // really new perception 
						Literal literal = Translator.perceptToLiteral(percept);
						if (percept.getName().equals("step")) {
							step = literal;
						} else if (percept.getName().equals("simEnd")) {
//							cleanObsProps(step_obs_propv1);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
							cleanObsProps(match_obs_prop);
							lastStep = -1;
							break;
						} else {
//							logger.info("adding "+literal);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
						}
					}
				} if (match_obs_prop.contains(percept.getName())) {
					Literal literal = Translator.perceptToLiteral(percept);
//					logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());				
				}
			}
		}
		else {
			for (Percept percept: percepts) {
				if (step_obs_prop.contains(percept.getName())) {
					if (!previousPercepts.contains(percept) || percept.getName().equals("lastAction")) { // really new perception 
						Literal literal = Translator.perceptToLiteral(percept);
						if (percept.getName().equals("step")) {
							step = literal;
						} else if (percept.getName().equals("simEnd")) {
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
							cleanObsProps(match_obs_prop);
							lastStep = -1;						
							break;
						} else {
//							logger.info("adding "+literal);
							defineObsProperty(percept.getName(), (Object[]) literal.getTermsArray());
						}
					}
				} if (match_obs_prop.contains(percept.getName())) {
					Literal literal = Translator.perceptToLiteral(percept);
					//logger.info("adding "+literal);
					defineObsProperty(literal.getFunctor(), (Object[]) literal.getTermsArray());				
				}
			}
		}
		
		if (step != null) {
//			logger.info("adding "+step);
			defineObsProperty(step.getFunctor(), (Object[]) step.getTermsArray());
		}

	}
	
	private void cleanObsProps(Set<String> obSet) {
		for (String obs: obSet) {
			cleanObsProp(obs);
		}
	}

	private void cleanObsProp(String obs) {
		ObsProperty ob = getObsProperty(obs);
		while (ob != null) {
//			logger.info("Removing "+ob);
			removeObsProperty(obs);
			ob = getObsProperty(obs);
		}
	}

	@OPERATION
	void stopReceiving() {
		receiving = false;
	}

	static Set<String> match_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"simStart",
		"map",
		"steps",
		"product",
		"role",
	}));
	
	static Set<String> step_obs_prop = new HashSet<String>( Arrays.asList(new String[] {
		"simStart",
		"map",
		"chargingStation",
//		"visibleChargingStation",
		"shop",			
		"storage",
//		"workshop",
		"dump",
		"lat",
		"lon",
		"charge",
		"load",
		"inFacility",
		"item",
//		"jobTaken",
		"step",
		"simEnd",		
//		"pricedJob",
//		"auctionJob",
		"lastAction",
		"lastActionResult",
	}));
	
	static Set<String> step_obs_propv1 = new HashSet<String>( Arrays.asList(new String[] {
			"simStart",
			"map",
			"chargingStation",
//			"visibleChargingStation",
			"shop",			
			"storage",
//			"workshop",
			"dump",
			"lat",
			"lon",
			"charge",
			"load",
			"inFacility",
			"item",
//			"jobTaken",
			"step",
			"simEnd",		
			"pricedJob",
//			"auctionJob",
			"lastAction",
			"lastActionResult",
		}));	
	
	static List<String> location_perceptions = Arrays.asList(new String[] { "shop", "storage", "workshop", "chargingStation", "dump", "entity" });

	private void filterLocations(String agent, Collection<Percept> perceptions) {
		double agLat = Double.NaN, agLon = Double.NaN;
		for (Percept perception : perceptions) {
			if(perception.getName().equals("lon")){
				agLon = Double.parseDouble(perception.getParameters().get(0).toString());
			}
			if(perception.getName().equals("lat")){
				agLat = Double.parseDouble(perception.getParameters().get(0).toString());
			}
			if (location_perceptions.contains(perception.getName())) {
				boolean isEntity = perception.getName().equals("entity"); // Second parameter of entity is the team. :(
				LinkedList<Parameter> parameters = perception.getParameters();
				String facility = parameters.get(0).toString();
				if (!MapHelper.hasLocation(facility)) {
					String local = parameters.get(0).toString();
					double lat = Double.parseDouble(parameters.get(isEntity ? 2 : 1).toString());
					double lon = Double.parseDouble(parameters.get(isEntity ? 3 : 2).toString());
					MapHelper.addLocation(local, new Location(lon, lat));
				}
			}
		}
		if(!Double.isNaN(agLat) && !Double.isNaN(agLon)){
			MapHelper.addLocation(agent, new Location(agLon, agLat));
		}
	}	
}